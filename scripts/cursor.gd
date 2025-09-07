extends Node2D
class_name Cursor

@onready var sprite = $Sprite

func _ready():
	sprite.hide()
	sprite.modulate.a = 0.8

var cursor_cell_position: Vector2i = Vector2i.ZERO:
	set(cell):
		cursor_cell_position = cell
		if not cell in Navigation.map.get_used_cells():
			sprite.hide()
		else:
			sprite.show()
		position = Navigation.map_to_global(cell)

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
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
