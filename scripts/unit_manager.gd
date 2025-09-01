extends Node
class_name UnitManager

enum Team {PLAYER, ENEMY}

var groups: Array = []
var current_team: Team = Team.PLAYER
var current_unit: Character
var current_unit_index: int = 0
var is_animation_playing: bool = false

signal turn_started(unit: Character)
signal turn_ended(unit: Character)
signal battle_ended(winning_team: Team)

func _ready() -> void:
	_connect_signals()
	_initialize_groups()

func _connect_signals() -> void:
	EventBus.end_turn.connect(_on_end_turn)
	EventBus.movement_started.connect(_on_movement_started)
	EventBus.movement_complete.connect(_on_movement_complete)
	EventBus.unit_died.connect(_on_unit_died)

func _initialize_groups() -> void:
	for child in get_children():
		if child.get_child_count() > 0:
			groups.append(child)

func init_units() -> void:
	for group in groups:
		for unit in group.get_children():
			unit.init()

func start_battle() -> void:
	current_team = Team.PLAYER
	_begin_turn()

func _step_turn() -> void:
	# Check if battle should end first
	if _should_end_battle():
		_end_battle()
		return
	
	var next_unit = _find_next_active_unit()
	
	if not next_unit:
		_end_battle()
		return
	
	current_unit = next_unit
	_begin_turn()

func _find_next_active_unit() -> Character:
	var start_group_index = current_team
	var start_unit_index = current_unit_index
	var max_iterations = groups.size() * 10  # Safety limit
	
	for iteration in max_iterations:
		current_unit_index += 1
		
		# Move to next group if needed
		if current_unit_index >= groups[current_team].get_child_count():
			current_team = (current_team + 1) % groups.size()
			current_unit_index = 0
		
		# Check if unit is valid and alive
		var unit = _get_current_unit_candidate()
		if unit and not unit.dead:
			return unit
		
		# Break if we've checked all units
		if current_team == start_group_index and current_unit_index == start_unit_index:
			break
	
	return null

func _get_current_unit_candidate() -> Character:
	if current_team < groups.size() and current_unit_index < groups[current_team].get_child_count():
		return groups[current_team].get_child(current_unit_index)
	return null

func _begin_turn() -> void:
	current_unit = _get_current_unit_candidate()
	
	if not current_unit or current_unit.dead:
		print("Invalid unit selected, progressing turn")
		_step_turn()
		return
	
	print("Turn started for: ", current_unit.name, " (Team: ", current_team, ")")
	
	turn_started.emit(current_unit)
	current_unit.reset_ap()
	
	if current_team == Team.PLAYER:
		_update_movement_field()
	else:
		_process_enemy_turn()

func _process_enemy_turn() -> void:
	var player_unit = _get_first_player_unit()
	if player_unit:
		var ai_controller = MeleeAIController.new()
		ai_controller.initialize(current_unit, player_unit)
		ai_controller.take_turn()
	else:
		# No players left, end turn quickly
		EventBus.end_turn.emit()

func _get_first_player_unit() -> Character:
	if groups[Team.PLAYER].get_child_count() > 0:
		return groups[Team.PLAYER].get_child(0)
	return null

func _update_movement_field() -> void:
	EventBus.show_movement_field.emit(current_unit)

func _on_end_turn() -> void:
	if not CommandProcessor.is_queue_empty():
		await CommandProcessor.queue_empty
	
	turn_ended.emit(current_unit)
	_step_turn()

func get_current_unit() -> Character:
	return current_unit

func _on_movement_started() -> void:
	is_animation_playing = true

func _on_movement_complete(unit: Character) -> void:
	is_animation_playing = false

func is_player_turn() -> bool:
	return current_team == Team.PLAYER

func _on_unit_died(dead_unit: Character) -> void:
	print("Unit died: ", dead_unit.name)
	
	for group in groups:
		if dead_unit in group.get_children():
			group.remove_child(dead_unit)
			break

	if dead_unit == current_unit:
		_step_turn()

func _end_battle() -> void:
	var winning_team = Team.PLAYER if groups[Team.ENEMY].get_child_count() == 0 else Team.ENEMY
	print("--- BATTLE ENDED! Winner: Team ", winning_team, " ---")
	battle_ended.emit(winning_team)
	
	_disable_all_units()

# Helper function to get team from group name (if you need it)
func _get_team_from_group_name(group_name: String) -> Team:
	match group_name:
		"Group1": return Team.PLAYER
		"Group2": return Team.ENEMY
		_: return Team.PLAYER

func can_accept_input() -> bool:
	return current_team == Team.PLAYER and not is_animation_playing and not CommandProcessor.is_queue_empty()
	
func _disable_all_units() -> void:
	for group in groups:
		for unit in group.get_children():
			unit.set_process(false)
			unit.set_process_input(false)
			unit.set_process_unhandled_input(false)
	
func _has_living_units(team_index: int) -> bool:
	# Assuming team_index is always valid
	if groups[team_index].get_children().size() > 0:
		return true
	else:
		return false
		
func _should_end_battle() -> bool:
	# Battle ends when only one team has living units
	var teams_with_units = 0
	
	for team_index in groups.size():
		if _has_living_units(team_index):
			teams_with_units += 1
			if teams_with_units > 1:
				return false  # Multiple teams still have units
	return true
