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
	
#iterates over units and groups. the values are then used in other functions
func _step_turn() -> void:
	current_unit_index += 1
	if current_unit_index >= current_group.get_child_count():
		current_group_index = wrapi(current_group_index + 1, 0, groups.size())
		current_group = groups[current_group_index]
		current_unit_index = 0
		print("group switch to: ", current_group.name)
	_begin_turn()
	
func _begin_turn() -> void:
	current_unit = current_group.get_child(current_unit_index)
	EventBus.turn_started.emit()
	print("current unit ", current_unit_index, " from ", current_group.name)
	has_moved = false
	if current_group.name == "Group1":
		_update_movement_field()
	else:
		print("Enemy turn started")
		var ai_controler = MeleeAIController.new()
		ai_controler.initialize(current_unit, groups[0].get_children()[0])
		ai_controler.take_turn()
		_on_end_turn()

func _update_movement_field() -> void:
	EventBus.show_movement_field.emit(current_unit)

func _on_end_turn():
	print("_on_end_turn")
	_step_turn()
	
func get_current_unit():
	return current_unit
	
func _on_movement_started() -> void:
	animation_playing = true

func _on_movement_complete():
	animation_playing = false
