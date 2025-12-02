class_name Enemy
extends Unit

@export var ai_behavior_scene: PackedScene
var ai_behavior: AIBehavior

func _ready():
	super._ready()
	is_enemy = true
	
	if ai_behavior_scene:
		ai_behavior = ai_behavior_scene.instantiate()
		add_child(ai_behavior)
		ai_behavior.initialize(self)
		ai_behavior.turn_completed.connect(_on_turn_completed)

func take_turn() -> void:
	if ai_behavior:
		ai_behavior.take_turn()

func _on_turn_completed():
	EventBus.end_turn.emit()
