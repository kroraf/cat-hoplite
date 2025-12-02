extends Node2D

@onready var level_manager: LevelManager = $LevelManager
@onready var unit_manager = %UnitManager
@onready var overlay = $Overlay
@onready var camera: Camera2D = $Camera
@onready var menu = $UI/Menu
@onready var xy_label = $UI/XYLabel

var mouse_click_coordinates: Vector2i
var first_unit: Unit
var current_level: BaseLevel
var hexgrid: TileMapLayer
var player: Player


func _ready() -> void:
	EventBus.show_movement_field.connect(_on_show_movement_field)
	EventBus.movement_complete.connect(_on_movement_complete)
	EventBus.movement_started.connect(_on_movement_started)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.action_started.connect(_on_action_started)
	EventBus.action_complete.connect(_on_action_complete)
	
	EventBus.level_loaded.connect(_on_level_loaded)
	EventBus.level_completed.connect(_on_level_completed)
	EventBus.level_failed.connect(_on_level_failed)
	
	level_manager.load_level("res://levels/level_01.tscn")
	
func _on_level_loaded(level: BaseLevel):
	current_level = level
	hexgrid = level.get_hexgrid()
	var player_start_position = level.get_player_start_position()
	unit_manager.initialize_level_units(level)
	var persistent_units = get_tree().root.find_child("PersistentUnits", true, false)
	first_unit = persistent_units.get_node("Player")
	player = first_unit
	first_unit.grid_position = player_start_position
	first_unit.position = Navigation.map_to_global(player_start_position)
	unit_manager.start_battle()
	
	_setup_camera()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("right_mouse_button"):
		print(">>", hexgrid.local_to_map(get_global_mouse_position()))
		xy_label.text = str(hexgrid.local_to_map(get_global_mouse_position()))
	if event.is_action_pressed("left_mouse_button"):
		_select_hex(hexgrid.local_to_map(get_global_mouse_position()))
	if event is InputEventScreenTouch:
		if event.pressed:
			_select_hex(hexgrid.local_to_map(event.position))
		else:
			pass

func _setup_camera():
	if current_level:
		if first_unit:
			camera.target_node = first_unit
			camera.global_position = first_unit.global_position
			print("Camera target set to: ", first_unit.name)
		else:
			print("No player found in level")
	else:
		print("No current level for camera setup")
			
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
	
func move_unit_to_cell(unit: Unit, path: Array[Vector2i]) -> void:
	print("Moving unit: ", unit.name, " along path: ", path)
	unit.move_along_path(path)

func _on_show_movement_field(unit):
	update_movement_overlay(unit)
	
func update_movement_overlay(unit: Unit) -> void:
	overlay.clear_all_highlights()
	
	# Highlight movement cells (walkable but not interactable)
	var movement_cells = Navigation.get_walkable_cells(unit)
	for cell in movement_cells:
		if hexgrid.is_cell_valid(cell) and not hexgrid.is_cell_solid(cell):
			overlay.highlight_movement_cell(cell)
	
	# Highlight interaction cells (both walkable and interactable)
	var interaction_cells = Navigation.get_interactable_cells(unit)
	for cell in interaction_cells:
		if hexgrid.is_cell_valid(cell) and not hexgrid.is_cell_solid(cell):
			overlay.highlight_interaction_cell(cell)
		
func _on_movement_started():
	overlay.clear_all_highlights()
	
func _on_movement_complete(unit):
	if unit_manager.is_player_turn():
		update_movement_overlay(first_unit)
	
func _on_turn_started():
	update_movement_overlay(unit_manager.get_current_unit())
	
func _on_action_started(unit):
	overlay.clear_all_highlights()
	
func _on_action_complete(unit):
	update_movement_overlay(first_unit)

func _on_level_completed(level: BaseLevel):
	print("Game: Level completed - ", level.level_name)

func _on_level_failed(level: BaseLevel):
	print("Game: Level failed - ", level.level_name)


func _on_attack_button_pressed():
	player.scan_for_enemies_and_attack()
	player.decrease_ap(1)
	player._evaluate_ap()
