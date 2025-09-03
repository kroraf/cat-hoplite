extends Node2D
class_name Cursor

@onready var sprite = $Sprite

func _ready():
	sprite.hide()

var cursor_cell_position: Vector2i = Vector2i.ZERO:
	set(cell):
		cursor_cell_position = cell
		if not cell in Navigation.map.get_used_cells():
			sprite.hide()
		else:
			sprite.show()
		position = Navigation.map_to_global(cell)
		#moved.emit(cell)

#signal moved(cursor_cell: Vector2i)

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		cursor_cell_position = Navigation.global_to_map(get_global_mouse_position())
	#elif event.is_action_pressed("left_click") or event.is_action_pressed("ui_accept"):
		#EventBus.cursor_accept_pressed.emit(Navigation.global_to_map(get_global_mouse_position()))
		#get_viewport().set_input_as_handled()
		
	#So that keys pressed won't be registered twice per press
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
