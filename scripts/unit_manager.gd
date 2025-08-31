extends Node
class_name UnitManager

var groups: Array = []
var current_group: Node
var current_unit: Character
var has_moved: bool = false
var current_unit_index: int = 0
var current_group_index: int = 0
var animation_playing := false

func _ready() -> void:
	EventBus.end_turn.connect(_on_end_turn)
	EventBus.movement_started.connect(_on_movement_started)
	EventBus.movement_complete.connect(_on_movement_complete)
	EventBus.unit_died.connect(_on_unit_died)
	
	for child in get_children():
		if child.get_child_count() > 0:
			groups.append(child)

func init_units():
	for group in groups:
		for unit in group.get_children():
			unit.init()

func start_battle() -> void:
	current_group = groups[0]
	_begin_turn()
	
func _step_turn() -> void:
	current_unit_index += 1
	if current_unit_index >= current_group.get_child_count():
		current_group_index = wrapi(current_group_index + 1, 0, groups.size())
		current_group = groups[current_group_index]
		current_unit_index = 0
		
	if current_group.get_child_count() <= 0:
		print("--- GAME OVER! ---")
		queue_free()

	current_unit = current_group.get_child(current_unit_index)
	if current_unit.dead:
		_step_turn()
		return
	print("> Group switched to: ", current_group.name, current_group.get_child_count())
	_begin_turn()
	
func _begin_turn() -> void:
	current_unit = current_group.get_child(current_unit_index)
	print("Current group: ", current_group.name)
	print("Current unit: ", current_unit.name)
	EventBus.turn_started.emit()
	current_unit.reset_ap()
	if current_group.name == "Group1": #change that to group instead of name
		_update_movement_field()
	else:
		_process_enemy_turn()
		
func _process_enemy_turn():
	await AnimationManager.wait_for_all()
	var ai_controller = MeleeAIController.new()
	ai_controller.initialize(current_unit, groups[0].get_children()[0])
	ai_controller.take_turn()

func _update_movement_field() -> void:
	EventBus.show_movement_field.emit(current_unit)

func _on_end_turn():
	print(">> ON TURN END - Waiting for animations...")
	await get_tree().create_timer(0.1).timeout
	await AnimationManager.wait_for_all()
	print("<< All animations done, proceeding to next turn")
	_step_turn()
	
func get_current_unit():
	return current_unit
	
func _on_movement_started() -> void:
	animation_playing = true

func _on_movement_complete(unit):
	animation_playing = false

func is_player_turn() -> bool:
	return current_group.name == "Group1"

func is_animation_playing() -> bool:
	return animation_playing
	
func _on_unit_died(dead_unit: Character):
	print("Unit died: ", dead_unit.name)
	# Find which group the dead unit belongs to
	for group in groups:
		if dead_unit in group.get_children():
			# Remove from group
			group.remove_child(dead_unit)
			# If it was the current unit, handle turn progression
			if dead_unit == current_unit:
				print("Current unit died, ending turn")
				#EventBus.end_turn.emit()
				_step_turn()
			break
	
