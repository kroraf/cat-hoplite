extends Node2D

const interactable: bool = true

var current_level: BaseLevel
var grid_position: Vector2i:
	get:
		return Navigation.global_to_map(position)

func _ready():
	EventBus.level_loaded.connect(_on_level_loaded)
	
func initialize_object():
	position = Navigation.snap_to_tile_center(position)
	OccupancyManager.register_object(self, grid_position)
	
func complete_level():
	if not current_level:
		print("No level loaded yet")
		return
	EventBus.level_completed.emit(current_level)
	
func _on_level_loaded(lvl: BaseLevel):
	current_level = lvl
