extends Node

var occupied_tiles := {}  # Dictionary: Vector2i -> Character
var navigation: Node

func initialize(nav_system: Node) -> void:
	navigation = nav_system

func register_character(character: Character, cell: Vector2i) -> void:
	#print("Registering ", character.name, " at ", cell)
	occupied_tiles[cell] = character
	navigation.update_obstacle(cell, true)

func unregister_character(character: Character, cell: Vector2i) -> void:
	#print("Unregistering ", character.name, " from ", cell)
	if occupied_tiles.get(cell) == character:
		occupied_tiles.erase(cell)
		navigation.update_obstacle(cell, false)
		
func move_character(character: Character, from_cell: Vector2i, to_cell: Vector2i) -> void:
	unregister_character(character, from_cell)
	register_character(character, to_cell)

func is_tile_occupied(cell: Vector2i) -> bool:
	return occupied_tiles.has(cell)

func get_occupant(cell: Vector2i) -> Character:
	return occupied_tiles.get(cell)
