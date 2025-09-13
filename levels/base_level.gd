class_name BaseLevel
extends Node2D

# Common properties
@export var level_name: String = "Unnamed Level"
@export var level_music: AudioStream
@export var next_level_path: String = ""
@export var player_start_position: Vector2i

func _ready():
	_initialize_interactable_objects()
	EventBus.level_loaded.emit(self)

func get_hexgrid() -> TileMapLayer:
	return $Terrain/MainTerrain

func get_all_units() -> Array[Character]:
	var units: Array[Character] = []
	
	# Only return level-specific units (enemies)
	var enemies_node = $LevelUnits/Enemies
	if enemies_node:
		for child in enemies_node.get_children():
			if child is Character:
				units.append(child)
	
	return units
	
func get_player_start_position() -> Vector2i:
	return player_start_position

func complete_level():
	EventBus.level_completed.emit(self)

func fail_level():
	EventBus.level_failed.emit(self)

func _initialize_interactable_objects():
	#OccupancyManager.clear()
	var interactables = _find_all_interactable_objects()
	for obj in interactables:
		obj.initialize_object()

func _find_all_interactable_objects() -> Array:
	var objects = []
	var objects_node = $Objects
	if objects_node:
		for child in objects_node.get_children():
			if child.has_method("initialize_object"):
				objects.append(child)
	return objects
