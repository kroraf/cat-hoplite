class_name MeleeBehavior
extends AIBehavior

enum AIState { DECIDE, MOVE, ATTACK, END_TURN }
var current_state: AIState = AIState.DECIDE

var unit: Unit
var blackboard: Dictionary = {}
var player: Unit

func initialize(unit_node: Unit) -> void:
	unit = unit_node
	player = await _find_nearest_player()
	blackboard["Unit"] = unit
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
	if await _can_attack_player():
		blackboard["action"] = "attack"
		current_state = AIState.ATTACK
	else:
		blackboard["action"] = "move_toward_player"
		current_state = AIState.MOVE
	_process_ai()

func _execute_move() -> void:
	var path = await _get_path_to_player()
	
	if path.size() > 1:
		var next_cell = Vector2i(path[1])
		if Navigation.is_cell_walkable(next_cell):
			var move_path: Array[Vector2i] = [unit.grid_position, next_cell]
			var move_cmd = MoveCommand.new(unit, move_path)
			move_cmd.name = "Enmy mov"
			EventBus.post_command.emit(move_cmd)
		else:
			current_state = AIState.END_TURN
	else:
		current_state = AIState.END_TURN
		_process_ai()

func _execute_attack() -> void:
	unit.scan_for_opponents_and_attack()
	current_state = AIState.END_TURN
	_process_ai()

func _end_turn() -> void:
	turn_completed.emit()
	current_state = AIState.DECIDE

#func _get_path_to_player() -> PackedVector2Array:
	#var enemy_cell = unit.grid_position
	#var player_cell = player.grid_position
	#var result = Navigation.find_optimal_approach_cell_and_path(player_cell, enemy_cell)
	#return result.path

#func _can_attack_player() -> bool:
	#var enemy_cell = unit.grid_position
	#var player_cell = player.grid_position
	#var distance = Navigation.hex_distance(enemy_cell, player_cell)
	#return distance == 1

func _find_nearest_player() -> Unit:
	# Wait a frame if unit_manager isn't ready
	await get_tree().process_frame
	
	var unit_manager = get_node("/root/Game/UnitManager")
	if not unit_manager or not unit_manager.groups.has(UnitManager.Team.PLAYER):
		return null
	
	var players = unit_manager.groups[UnitManager.Team.PLAYER]
	if players.is_empty():
		return null
	
	# Find the closest living player
	var closest_player: Unit = null
	var closest_distance = INF
	
	for player_unit in players:
		if is_instance_valid(player_unit) and not player_unit.dead:
			var distance = Navigation.hex_distance(unit.grid_position, player_unit.grid_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_player = player_unit
	
	return closest_player

func _get_player() -> Unit:
	# Check if cached player is still valid
	if player and is_instance_valid(player) and not player.dead:
		return player
	
	# Find new player
	player = await _find_nearest_player()
	return player

func _can_attack_player() -> bool:
	var current_player = await _get_player()
	if not current_player:
		return false
	
	return unit.get_opponents_in_attack_range().size() > 0

func _get_path_to_player() -> PackedVector2Array:
	var current_player = await _get_player()
	if not current_player:
		return PackedVector2Array()
	
	var enemy_cell = unit.grid_position
	var player_cell = current_player.grid_position
	var result = Navigation.find_optimal_approach_cell_and_path(player_cell, enemy_cell)
	return result.path
