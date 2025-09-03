extends Camera2D

@export var target_node: Node2D
@export var follow_speed: float = 5.0
@export var smooth_follow: bool = true

func _ready():
	if target_node:
		print("Found target node: ", target_node.name)
	else:
		print("No target node assigned")

func _process(delta):
	if not target_node:
		return
		
	if smooth_follow:
		# Smoothly interpolate towards the target position
		global_position = global_position.lerp(target_node.global_position, delta * follow_speed)
	else:
		# Instantly follow the target
		global_position = target_node.global_position
