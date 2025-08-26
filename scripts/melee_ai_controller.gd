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
	
	print("Enemy at: ", enemy_cell, " | Player at: ", player_cell)
	
	# Find the nearest available cell to the player
	var target_cell = Navigation.find_nearest_available_cell(player_cell)
	
	print("nearest_available_cell: ", target_cell)
	
	var path = Navigation.get_movement_path(enemy_cell, target_cell)
	print("Calculated path: ", path)
	
	return path

# In melee_ai_controller.gd, modify the _execute_move() method:
# In melee_ai_controller.gd, modify the _execute_move() method:
func _execute_move() -> void:
	var path = _get_path_to_player()
	
	if path.size() > 1:  # Has at least one move toward player
		# Move only ONE step toward the player
		var move_cell = path[1]  # First step toward player
		
		# Create a path with just the current position and the next cell
		var move_path: Array[Vector2i] = [unit.grid_position, move_cell]
		
		# Connect to the EventBus movement_complete signal
		if not EventBus.movement_complete.is_connected(_on_move_complete):
			EventBus.movement_complete.connect(_on_move_complete, CONNECT_ONE_SHOT)
		
		print(unit.name, " moving to: ", move_cell)
		unit.move_along_path(move_path)
	else:
		# No path to player, end turn
		print(unit.name, " cannot move toward player")
		current_state = AIState.END_TURN
		_process_ai()

func _execute_attack() -> void:
	print(unit.name, " attacks ", player.name, "!")
	# Add your attack logic here - damage, animations, etc.
	print("POOOOOW!!!!")
	current_state = AIState.END_TURN
	_process_ai()

func _end_turn() -> void:
	#EventBus.end_turn.emit()
	current_state = AIState.DECIDE

func _on_move_complete() -> void:
	# After moving, check if we can now attack
	if _can_attack_player():
		current_state = AIState.ATTACK
	else:
		current_state = AIState.END_TURN
	_process_ai()

func _can_attack_player() -> bool:
	var enemy_cell = unit.grid_position
	var player_cell = player.grid_position
	var distance = _hex_distance(enemy_cell, player_cell)
	return distance == 1  # Adjacent hex

func _hex_distance(a: Vector2i, b: Vector2i) -> int:
	# Simple hex distance calculation for offset coordinates
	var dx = abs(b.x - a.x)
	var dy = abs(b.y - a.y)
	return max(dx, dy, dx + dy)  # Approximate hex distance
