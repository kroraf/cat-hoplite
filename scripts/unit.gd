class_name Character
extends Area2D

var grid_position: Vector2i:
	get:
		return Navigation.global_to_map(position)
var movement_tween: Tween
var current_path: Array = []
var is_in_motion: bool = false
var current_ap: int
var current_hp: int
var dead: bool = false

@export var is_enemy: bool = false
@export var def: UnitDefinition
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func init():
	EventBus.movement_complete.connect(_on_movement_complete)
	sprite.sprite_frames = def.frames
	position = Navigation.snap_to_tile_center(position)
	OccupancyManager.register_character(self, grid_position)
	sprite.play("idle")
	current_ap = def.action_points
	current_hp = def.hp

func move_along_path(path: Array) -> void:
	if path.size() <= 1:
		is_in_motion = false
		return
	
	AnimationManager.register(self)
	EventBus.movement_started.emit()
	is_in_motion = true
	current_path = path.slice(1)
	_start_next_move()

func _start_next_move():
	if current_path.is_empty():
		EventBus.movement_complete.emit(self)
		return
		
	OccupancyManager.unregister_character(self, grid_position)

	var next_cell = current_path[0]
	var move_dir = Vector2i(next_cell) - grid_position
	sprite.flip_h = move_dir.x < 0 || (move_dir.x >= 0 && move_dir.y > 0)
	_play_run_animation()
	if movement_tween:
		movement_tween.kill()
	
	movement_tween = create_tween()
	movement_tween.connect("finished", _on_move_animation_complete)
	current_path.remove_at(0)
	movement_tween.tween_property(
		self, 
		'global_position', 
		Navigation.map_to_global(next_cell), 
		.3
	).set_trans(Tween.TRANS_LINEAR)
	#await movement_tween.finished

func _on_move_animation_complete():
	OccupancyManager.register_character(self, Navigation.global_to_map(position))
	_start_next_move()
	
func scan_for_enemies_and_attack():
	EventBus.action_started.emit(self)
	var enemies_in_range: Array[Character] = []
	for cell in _get_actionable_cells():
		var occupant = OccupancyManager.get_occupant(cell)
		if occupant and occupant != self and occupant.is_enemy != self.is_enemy:
			enemies_in_range.append(occupant)
	print("Enemies in range: ", enemies_in_range)
	for unit in enemies_in_range:
		print("> ", self.name, " attacks ", unit.name)
		await _play_attack_animation()
		unit.take_damage(1)
	EventBus.action_complete.emit(self)
	
func _get_actionable_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var movement_dirs = self.def.move_def
	
	for dir in movement_dirs:
		var target_cell = self.grid_position + dir.end_point
		cells.append(target_cell)
	return cells

func _evaluate_ap():
	print("Evaluating AP ({0}) for {1}".format([current_ap, self.name]))
	if current_ap <=0:
		EventBus.end_turn.emit()
		
func decrease_ap(value):
	current_ap -= value
	print("AP decreased to ({0}) for {1}".format([current_ap, self.name]))
	
func reset_ap():
	current_ap = def.action_points
	print("AP reset ({0}) for {1}".format([current_ap, self.name]))
	
func _on_movement_complete(unit_that_moved):
	if unit_that_moved != self:
		return
	sprite.play("idle")
	is_in_motion = false
	OccupancyManager.register_character(self, grid_position)
	AnimationManager.unregister(unit_that_moved)
	await scan_for_enemies_and_attack()
	await get_tree().create_timer(0.1).timeout
	AnimationManager.wait_for_all()
	decrease_ap(1)
	_evaluate_ap()
	
func take_damage(value):
	print(self.name, ": OUCH!")
	_play_hit_animation()
	current_hp -= value
	if current_hp <= 0:
		self.die()
	
func die():
	print(self.name, " DIES!")
	dead = true
	OccupancyManager.unregister_character(self, grid_position)
	await _play_death_animation()
	EventBus.unit_died.emit(self)
	queue_free()
	#await get_tree().create_timer(1).timeout
	#EventBus.end_turn.emit()
	
func _play_run_animation():
	if sprite.animation != "run":
		sprite.play("run")

func _play_death_animation() -> void:
	print("playing death animation for ", self)
	AnimationManager.register(self)
	if sprite.sprite_frames.has_animation("die"):
		sprite.play("die")
		await sprite.animation_finished
	else:
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		await tween.finished
	print("death animation for ", self, "is finally done!")
	AnimationManager.unregister(self)
	
func _play_attack_animation():
	print("playing attack animation for ", self)
	AnimationManager.register(self)
	# Face the target
	#var direction = target.global_position - global_position
	#sprite.flip_h = direction.x < 0
	
	# Play attack animation
	if sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
		await sprite.animation_finished
		sprite.play("idle")
	else:
		# Fallback animation
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
		await tween.finished
	AnimationManager.unregister(self)
	
func _play_hit_animation():
	print("playing hit animation for ", self)
	AnimationManager.register(self)
	if sprite.sprite_frames.has_animation("hit"):
		sprite.play("hit")
		await sprite.animation_finished
		sprite.play("idle")
	else:
		var original_modulate = modulate
		var original_scale = scale
		
		var tween = create_tween()
		tween.set_parallel(false)  # Sequential tweens
		
		# First flash
		tween.tween_property(self, "modulate", Color.WHITE, 0.08)
		tween.tween_property(self, "scale", original_scale * 1.15, 0.08)
		
		# Return briefly
		tween.tween_property(self, "modulate", original_modulate, 0.06)
		tween.tween_property(self, "scale", original_scale, 0.06)
		
		# Second flash (weaker)
		tween.tween_property(self, "modulate", Color.WHITE, 0.06)
		tween.tween_property(self, "scale", original_scale * 1.08, 0.06)
		
		# Final return
		tween.tween_property(self, "modulate", original_modulate, 0.08)
		tween.tween_property(self, "scale", original_scale, 0.08)
		await tween.finished
	AnimationManager.unregister(self)
