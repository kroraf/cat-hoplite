extends Node
class_name UnitManager

enum Team {PLAYER, ENEMY}

var groups: Dictionary = {}  # Team -> Array of units
var current_team: Team = Team.PLAYER
var current_unit: Character
var current_unit_index: int = 0
var is_animation_playing: bool = false

signal turn_started(unit: Character)
signal turn_ended(unit: Character)
signal battle_ended(winning_team: Team)

func _ready() -> void:
	_connect_signals()

func _connect_signals() -> void:
	EventBus.end_turn.connect(_on_end_turn)
	EventBus.movement_started.connect(_on_movement_started)
	EventBus.movement_complete.connect(_on_movement_complete)
	EventBus.unit_died.connect(_on_unit_died)
	# Note: _on_level_loaded is handled by game.gd calling initialize_level_units

func initialize_level_units(level: BaseLevel) -> void:
	groups.clear()
	
	# Get persistent player units
	var persistent_units = get_tree().current_scene.get_node("PersistentUnits")
	groups[Team.PLAYER] = persistent_units.get_children()
	
	# Get level-specific enemy units
	var level_units = level.get_node("Units/Enemies")
	groups[Team.ENEMY] = level_units.get_children()
	
	# Set Z index to ensure proper draw order
	for player_unit in groups[Team.PLAYER]:
		player_unit.z_index = 1  # Players on top
	
	for enemy_unit in groups[Team.ENEMY]:
		enemy_unit.z_index = 0  # Enemies underneath
	
	init_units()

func init_units() -> void:
	for team in groups:
		for unit:Character in groups[team]:
			unit.init()

func start_battle() -> void:
	current_team = Team.PLAYER
	current_unit_index = 0
	current_unit = _get_current_unit_candidate()  # This is the key line
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
	if groups.is_empty():
		return null
	
	var teams_checked: int = 0
	var max_iterations: int = groups.size() * 10  # Safety limit
	
	for iteration in max_iterations:
		# Move to next unit in current team
		current_unit_index += 1
		
		# If we've exhausted current team, move to next team
		if current_unit_index >= groups[current_team].size():
			current_team = _get_next_team(current_team)
			current_unit_index = 0
			teams_checked += 1
			EventBus.group_round_changed.emit(_get_team_name(current_team))
		
		# Check if unit is valid and alive
		var unit = _get_current_unit_candidate()
		if unit and not unit.dead:
			return unit
		
		# Break if we've checked all teams
		if teams_checked >= groups.size():
			break
	
	return null

func _get_next_team(current_team_enum: Team) -> Team:
	# Convert Team enum to index, get next, convert back
	var current_index: int = current_team_enum
	var next_index: int = (current_index + 1) % groups.size()
	return Team.values()[next_index]

func _get_current_unit_candidate() -> Character:
	if groups.has(current_team) and current_unit_index < groups[current_team].size():
		return groups[current_team][current_unit_index]
	return null

func _begin_turn() -> void:
	# Safety check (shouldn't be needed but good practice)
	if not current_unit or current_unit.dead:
		push_error("Invalid unit in _begin_turn()! Attempting to recover...")
		_step_turn()
		return
	
	print("Turn started for: ", current_unit.name, " (Team: ", _get_team_name(current_team), ")")
	
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
	if groups.has(Team.PLAYER) and groups[Team.PLAYER].size() > 0:
		return groups[Team.PLAYER][0]
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
	
	# Remove unit from its team group
	for team in groups:
		if dead_unit in groups[team]:
			groups[team].erase(dead_unit)
			break

	if dead_unit == current_unit:
		_step_turn()

func _end_battle() -> void:
	var winning_team = Team.PLAYER if (groups.has(Team.ENEMY) and groups[Team.ENEMY].is_empty()) else Team.ENEMY
	print("--- BATTLE ENDED! Winner: Team ", _get_team_name(winning_team), " ---")
	battle_ended.emit(winning_team)
	
	_disable_all_units()

func _get_team_name(team: Team) -> String:
	match team:
		Team.PLAYER: return "Player"
		Team.ENEMY: return "Enemies"
		_: return "Unknown"

func can_accept_input() -> bool:
	return current_team == Team.PLAYER and not is_animation_playing and not CommandProcessor.is_queue_empty()
	
func _disable_all_units() -> void:
	for team in groups:
		for unit in groups[team]:
			unit.set_process(false)
			unit.set_process_input(false)
			unit.set_process_unhandled_input(false)
	
func _has_living_units(team: Team) -> bool:
	return groups.has(team) and not groups[team].is_empty()
		
func _should_end_battle() -> bool:
	# Battle ends when only one team has living units
	var teams_with_units = 0
	
	for team in groups:
		if _has_living_units(team):
			teams_with_units += 1
			if teams_with_units > 1:
				return false  # Multiple teams still have units
	return true
