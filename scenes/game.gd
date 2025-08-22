extends Node2D
@onready var units = $Units

@onready var character = $Units/Character
@onready var coordinates_label = $Units/Character/Camera2D/CoordinatesLabel
@onready var hexgrid = $LocalHexGrid
@onready var movement_overlay = $MovementOverlay

var mouse_click_coordinates: Vector2i
var current_unit: Character

func _ready() -> void:
	Navigation.init([hexgrid])
	EventBus.cursor_accept_pressed.connect(_on_cursor_accept_pressed)
	EventBus.show_movement_field.connect(_on_show_movement_field)
	EventBus.movement_complete.connect(_on_movement_complete)
	EventBus.movement_started.connect(_on_movement_started)

	for child in units.get_children():
		current_unit = child
		current_unit.init()
		EventBus.show_movement_field.emit(current_unit)
	
var cursor_cell_position: Vector2i = Vector2i.ZERO:
	set(cell):
		cursor_cell_position = cell
		
func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		cursor_cell_position = hexgrid.local_to_map(get_global_mouse_position())
		EventBus.cursor_accept_pressed.emit(hexgrid.local_to_map(get_global_mouse_position()))
	elif event.is_action_pressed("left_mouse_button"):
		EventBus.cursor_accept_pressed.emit(hexgrid.local_to_map(get_global_mouse_position()))
		var movement_path = Navigation.get_movement_path(character.current_grid_position, cursor_cell_position)
		if not character.is_in_motion and cursor_cell_position in get_walkable_cells(current_unit):
			move_unit_to_cell(character, movement_path)
#
func _on_cursor_accept_pressed(cursor_cell):
	coordinates_label.text = str(cursor_cell)
	
func move_unit_to_cell(unit: Character, path: Array[Vector2i]) -> void:
	unit.move_along_path(path)
	#await unit.movement_complete
	
func _on_show_movement_field(unit):
	_update_movement_data(unit)
	
func _update_movement_data(unit: Character) -> void:
	movement_overlay.clear_all_highlights()
	var cells = get_walkable_cells(unit)
	for cell in cells:
		if hexgrid.is_cell_valid(cell) and not hexgrid.is_cell_solid(cell):
			movement_overlay.highlight_cell(cell)
		
func _on_movement_started():
	movement_overlay.clear_all_highlights()
	
func _on_movement_complete():
	_on_show_movement_field(current_unit)
	
func get_walkable_cells(unit):
	var cells = []
	var movement_dirs = unit.def.move_def
	for dir in movement_dirs:
		var target_cell = unit.current_grid_position + dir.end_point
		if hexgrid.is_cell_valid(target_cell) and not hexgrid.is_cell_solid(target_cell):
			cells.append(Vector2i(target_cell))
	return cells
