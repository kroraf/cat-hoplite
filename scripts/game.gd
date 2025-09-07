extends Node2D

@onready var character = $UnitManager/Player/Player
@onready var hexgrid = $LocalHexGrid
@onready var movement_overlay = $MovementOverlay
@onready var unit_manager: UnitManager = $UnitManager
@onready var exit = $Exit

var mouse_click_coordinates: Vector2i
var first_unit: Character

func _ready() -> void:
	EventBus.show_movement_field.connect(_on_show_movement_field)
	EventBus.movement_complete.connect(_on_movement_complete)
	EventBus.movement_started.connect(_on_movement_started)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.action_started.connect(_on_action_started)
	EventBus.action_complete.connect(_on_action_complete)
	
	Navigation.init([hexgrid])
	OccupancyManager.initialize(Navigation)
	unit_manager.init_units()
	unit_manager.start_battle()
	first_unit = unit_manager.get_current_unit()
	exit.init()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("left_mouse_button"):
		_select_hex(hexgrid.local_to_map(get_global_mouse_position()))
	if event is InputEventScreenTouch:
		if event.pressed:
			_select_hex(hexgrid.local_to_map(event.position))
		else:
			# Finger was lifted from the screen
			pass
			
func _select_hex(hex_coordinates: Vector2i) -> void:
	if unit_manager.is_player_turn() and CommandProcessor.is_queue_empty():
			var actual_current_unit = unit_manager.get_current_unit()
			if hex_coordinates in Navigation.get_walkable_cells(actual_current_unit):
				var movement_path = Navigation.get_movement_path(actual_current_unit.grid_position, hex_coordinates)
				var move_cmd = MoveCommand.new(actual_current_unit, movement_path)
				move_cmd.name = "Plr mov"
				EventBus.post_command.emit(move_cmd)
			if hex_coordinates in Navigation.get_interactable_cells(actual_current_unit):
				var interactable_object = OccupancyManager.get_occupant(hex_coordinates)
				var interact_cmd = InteractionCommand.new(actual_current_unit, interactable_object)
				interact_cmd.name = "Plr interaction"
				EventBus.post_command.emit(interact_cmd)
	
func move_unit_to_cell(unit: Character, path: Array[Vector2i]) -> void:
	print("Moving unit: ", unit.name, " along path: ", path)
	unit.move_along_path(path)
	
func _on_show_movement_field(unit):
	update_movement_overlay(unit)
	
func update_movement_overlay(unit: Character) -> void:
	movement_overlay.clear_all_highlights()
	var cells = Navigation.get_walkable_cells(unit)
	for cell in cells:
		if hexgrid.is_cell_valid(cell) and not hexgrid.is_cell_solid(cell):
			movement_overlay.highlight_cell(cell)
		
func _on_movement_started():
	movement_overlay.clear_all_highlights()
	
func _on_movement_complete(unit):
	if unit_manager.is_player_turn():
		update_movement_overlay(first_unit)
	
func _on_turn_started():
	update_movement_overlay(unit_manager.get_current_unit())
	
func _on_action_started(unit):
	movement_overlay.clear_all_highlights()
	
func _on_action_complete(unit):
	update_movement_overlay(first_unit)
