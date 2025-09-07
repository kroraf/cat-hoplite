extends CanvasLayer

@onready var turn_label = $TurnLabel

func _ready():
	turn_label.text = "Player"
	EventBus.group_round_changed.connect(_on_group_round_changed)

func _on_group_round_changed(group_name):
	turn_label.text = str(group_name)
