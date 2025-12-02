extends Node
class_name LevelManager

var current_level: BaseLevel

func _ready():
	# Connect to EventBus signals
	EventBus.level_completed.connect(_on_level_completed)
	EventBus.level_failed.connect(_on_level_failed)

func load_level(level_path: String) -> void:
	# Clean up current level
	if current_level:
		current_level.queue_free()
		await current_level.tree_exited
	
	# Load new level
	var level_scene = load(level_path)
	current_level = level_scene.instantiate()
	var target_node = get_tree().root.find_child("Game", true, false)
	target_node.add_child(current_level)
	
	# Level will emit level_loaded signal via EventBus in its _ready()

func _on_level_completed(level: BaseLevel):
	OccupancyManager.clear()
	if level == current_level:
		print("Level completed: ", level.level_name)
		_load_next_level(level.next_level_path)

func _on_level_failed(level: BaseLevel):
	if level == current_level:
		print("Level failed: ", level.level_name)
		# Handle failure (restart, menu, etc.)

func _load_next_level(next_level_path: String):
	if next_level_path != "":
		await get_tree().create_timer(1.0).timeout  # Brief delay
		load_level(next_level_path)
	else:
		# No next level - game completed!
		#EventBus.game_ended.emit(true)
		print("NO NEXT LEVEL. GAME OVER.")  # victory = true

func get_current_level() -> BaseLevel:
	return current_level

func restart_current_level():
	if current_level:
		load_level(current_level.scene_file_path)
