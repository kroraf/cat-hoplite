extends Node2D

@onready var movement_layer = $MovementLayer
@onready var interaction_layer = $InteractionLayer
@onready var attack_layer = $AttackLayer

var movement_color := Color(0.2, 0.6, 1.0, 0.7)    # Blue for movement
var interaction_color := Color(1.0, 0.8, 0.2, 0.7) # Yellow for interaction
var attack_color := Color(1.0, 0.2, 0.2, 0.7)      # Red for attack

func _ready():
	# Set colors for each layer
	movement_layer.modulate = movement_color
	interaction_layer.modulate = interaction_color
	attack_layer.modulate = attack_color

func highlight_movement_cell(cell: Vector2i) -> void:
	movement_layer.set_cell(cell, 0, Vector2i(0, 0), 0)

func highlight_interaction_cell(cell: Vector2i) -> void:
	interaction_layer.set_cell(cell, 0, Vector2i(0, 0), 0)

func highlight_attack_cell(cell: Vector2i) -> void:
	attack_layer.set_cell(cell, 0, Vector2i(0, 0), 0)

func clear_all_highlights() -> void:
	movement_layer.clear()
	interaction_layer.clear()
	attack_layer.clear()

# Optional: Clear specific layers
func clear_movement_highlights() -> void:
	movement_layer.clear()

func clear_interaction_highlights() -> void:
	interaction_layer.clear()

func clear_attack_highlights() -> void:
	attack_layer.clear()
