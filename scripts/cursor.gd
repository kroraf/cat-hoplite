extends Node2D
class_name Cursor

@onready var sprite = $Sprite
@onready var overlay = $"../Overlay"

func _ready():
	sprite.hide()
	sprite.modulate.a = 0.6

var cursor_cell_position: Vector2i = Vector2i.ZERO:
	set(cell):
		cursor_cell_position = cell
		if not cell in Navigation.map.get_used_cells():
			sprite.hide()
		else:
			sprite.show()
		position = Navigation.map_to_global(cell)
		var unit = get_unit_in_cell(cursor_cell_position)
		if unit:
			attack_range = get_units_attack_range(unit)
			update_attack_overlay()
		else:
			overlay.clear_attack_highlights()
		
var attack_range

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		if cursor_cell_position != Navigation.global_to_map(get_global_mouse_position()):
			cursor_cell_position = Navigation.global_to_map(get_global_mouse_position())
	
	var should_move := event.is_pressed() 
	if event.is_echo():
		should_move = should_move
	if not should_move:
		return
		
	if event.is_action_pressed("ui_right"):
		cursor_cell_position += Vector2i.RIGHT
	elif event.is_action_pressed("ui_up"):
		cursor_cell_position += Vector2i.UP
	elif event.is_action_pressed("ui_left"):
		cursor_cell_position += Vector2i.LEFT
	elif event.is_action_pressed("ui_down"):
		cursor_cell_position += Vector2i.DOWN
		
func get_unit_in_cell(cell_position):
	var occupant = OccupancyManager.get_occupant(cell_position)
	if occupant is Unit:
		return occupant
	else:
		return
	
func get_units_attack_range(unit: Unit):
	return unit.get_actionable_cells()
	
func update_attack_overlay() -> void:
	overlay.clear_attack_highlights()

	for cell in attack_range:
		overlay.highlight_attack_cell(cell)
