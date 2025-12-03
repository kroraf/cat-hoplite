extends CanvasLayer

@onready var turn_label = $TurnLabel
@onready var attack_button = $AttackButton

func _ready():
	turn_label.text = "Player"
	EventBus.group_round_changed.connect(_on_group_round_changed)
	EventBus.toggle_attack_button.connect(_on_toggle_attack_button)

func _on_group_round_changed(group_name):
	turn_label.text = str(group_name)

func _on_toggle_attack_button(enabled: bool):
	attack_button.disabled = not enabled
