extends Node
class_name MeleeAIController

enum AIState { DECIDE, MOVE, ATTACK, END_TURN }
@export var current_state: AIState = AIState.DECIDE

var unit: Character
var blackboard: Dictionary = {}
var player: Character  # Reference to player character

func initialize(unit_node: Character, player_node: Character) -> void:
	unit = unit_node
	player = player_node
	blackboard["character"] = unit
	blackboard["current_cell"] = unit.grid_position

func take_turn() -> void:
	current_state = AIState.DECIDE
	_process_ai()

func _process_ai() -> void:
	match current_state:
		AIState.DECIDE:
			_decide_action()
		AIState.MOVE:
			_execute_move()
		AIState.ATTACK:
			_execute_attack()
		AIState.END_TURN:
			_end_turn()

func _decide_action() -> void:
	var can_attack = _can_attack_player()
	
	if can_attack:
		# Attack immediately if possible
		blackboard["action"] = "attack"
		current_state = AIState.ATTACK
	else:
		# Move toward player
		blackboard["action"] = "move_toward_player"
		current_state = AIState.MOVE
	
	_process_ai()

func _get_path_to_player() -> PackedVector2Array:
	var enemy_cell = unit.grid_position
	var player_cell = player.grid_position
	
	# Get both optimal cell and path in one call
	var result = Navigation.find_optimal_approach_cell_and_path(player_cell, enemy_cell)
	
	print("Optimal approach cell: ", result.cell, " | Path length: ", result.path.size() - 1)
	return result.path

func _execute_move() -> void:
	await AnimationManager.wait_for_all()
	var path = _get_path_to_player()
	
	if path.size() > 1:
		var next_cell = Vector2i(path[1])
		
		if Navigation.is_cell_walkable(next_cell):
			var move_path: Array[Vector2i] = [unit.grid_position, next_cell]
			
			print(unit.name, " moving to: ", next_cell)
			unit.move_along_path(move_path)
			# Don't call _on_move_complete here - let the movement complete signal handle it
		else:
			print("Cell not walkable, ending turn")
			current_state = AIState.END_TURN
			_process_ai()
	else:
		print("No path found, ending turn")
		current_state = AIState.END_TURN
		_process_ai()

# Also update the movement complete handler:
func _on_move_complete():
	# After moving, check if we can now attack
	if _can_attack_player():
		current_state = AIState.ATTACK
	else:
		current_state = AIState.END_TURN
	_process_ai()

func _execute_attack() -> void:
	print(unit.name, " attacks ", player.name, "!")
	unit.scan_for_enemies_and_attack()
	current_state = AIState.END_TURN
	_process_ai()

func _end_turn() -> void:
	EventBus.end_turn.emit()
	current_state = AIState.DECIDE

func _can_attack_player() -> bool:
	var enemy_cell = unit.grid_position
	var player_cell = player.grid_position
	var distance = Navigation.hex_distance(enemy_cell, player_cell)
	return distance == 1  # Adjacent hex
