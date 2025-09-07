extends Node

var occupied_tiles := {}  # Dictionary: Vector2i -> Character
var navigation: Node

func initialize(nav_system: Node) -> void:
	navigation = nav_system

func register_object(obj: Object, cell: Vector2i) -> void:
	#print("Registering ", character.name, " at ", cell)
	occupied_tiles[cell] = obj
	navigation.update_obstacle(cell, true)

func unregister_object(obj: Object, cell: Vector2i) -> void:
	#print("Unregistering ", character.name, " from ", cell)
	if occupied_tiles.get(cell) == obj:
		occupied_tiles.erase(cell)
		navigation.update_obstacle(cell, false)
		
func move_character(character: Character, from_cell: Vector2i, to_cell: Vector2i) -> void:
	unregister_object(character, from_cell)
	register_object(character, to_cell)

func is_tile_occupied(cell: Vector2i) -> bool:
	return occupied_tiles.has(cell)

func get_occupant(cell: Vector2i) -> Object:
	return occupied_tiles.get(cell)
