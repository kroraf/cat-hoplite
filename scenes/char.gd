class_name Character
extends Area2D

var current_grid_position: Vector2i
var movement_tween: Tween
var current_path: Array = []
var is_in_motion: bool = false

@export var def: UnitDefinition

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func init():
	sprite.sprite_frames = def.frames
	current_grid_position = Navigation.global_to_map(position)
	position = Navigation.snap_to_tile_center(position)
	sprite.play("idle")

func move_along_path(path: Array) -> void:
	if path.size() <= 1:
		is_in_motion = false
		return
	EventBus.movement_started.emit()
	is_in_motion = true
	# Store path and start movement
	current_path = path.slice(1)
	_start_next_move()

func _start_next_move():
	if current_path.is_empty():
		sprite.play("idle")
		EventBus.movement_complete.emit()
		is_in_motion = false
		return
	
	# Start continuous animation if not already playing
	if sprite.animation != "run":
		sprite.play("run")
	
	var next_cell = current_path[0]
	var move_dir = next_cell - current_grid_position
	sprite.flip_h = move_dir.x < 0 || (move_dir.x >= 0 && move_dir.y > 0)
	
	# Create smooth movement
	if movement_tween:
		movement_tween.kill()
	
	movement_tween = create_tween()
	movement_tween.tween_property(
		self, 
		'global_position', 
		Navigation.map_to_global(next_cell), 
		0.2
	).set_trans(Tween.TRANS_LINEAR)
	
	movement_tween.connect("finished", _on_move_step_complete)
	current_path.remove_at(0)

func _on_move_step_complete():
	current_grid_position = Navigation.global_to_map(global_position)
	_start_next_move()
