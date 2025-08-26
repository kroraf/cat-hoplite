extends Node2D
@onready var units = $Units

@onready var character = $UnitManager/Group1/Player
@onready var coordinates_label = $UnitManager/Group1/Player/Camera2D/CoordinatesLabel
@onready var hexgrid = $LocalHexGrid
@onready var movement_overlay = $MovementOverlay
@onready var unit_manager = $UnitManager
@onready var end_turn_button = $UnitManager/Group1/Player/Camera2D/EndTurnButton

var mouse_click_coordinates: Vector2i
var current_unit: Character

func _ready() -> void:
	EventBus.cursor_accept_pressed.connect(_on_cursor_accept_pressed)
	EventBus.show_movement_field.connect(_on_show_movement_field)
	EventBus.movement_complete.connect(_on_movement_complete)
	EventBus.movement_started.connect(_on_movement_started)
	EventBus.turn_started.connect(_on_turn_started)
	
	Navigation.init([hexgrid])
	OccupancyManager.initialize(Navigation)
	unit_manager.init_units()
	unit_manager.start_battle()
	current_unit = unit_manager.get_current_unit()
	
var cursor_cell_position: Vector2i = Vector2i.ZERO:
	set(cell):
		cursor_cell_position = cell
		
func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		cursor_cell_position = hexgrid.local_to_map(get_global_mouse_position())
		EventBus.cursor_accept_pressed.emit(hexgrid.local_to_map(get_global_mouse_position()))
	elif event.is_action_pressed("left_mouse_button"):
		EventBus.cursor_accept_pressed.emit(hexgrid.local_to_map(get_global_mouse_position()))
		var movement_path = Navigation.get_movement_path(unit_manager.get_current_unit().grid_position, cursor_cell_position)
		if not current_unit.is_in_motion and cursor_cell_position in Navigation.get_walkable_cells(current_unit):
			move_unit_to_cell(current_unit, movement_path)
#
func _on_cursor_accept_pressed(cursor_cell):
	coordinates_label.text = str(cursor_cell)
	
func move_unit_to_cell(unit: Character, path: Array[Vector2i]) -> void:
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
	
func _on_movement_complete():
	update_movement_overlay(current_unit)

func _on_end_turn_button_pressed():
	print("End turn button pressed")
	unit_manager._step_turn()
	current_unit = unit_manager.get_current_unit()
	
func _on_turn_started():
	#update_movement_overlay(current_unit)
	print("turn started for: ", unit_manager.get_current_unit())
	update_movement_overlay(unit_manager.get_current_unit())
	pass
