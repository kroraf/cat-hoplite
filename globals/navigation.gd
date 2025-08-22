extends Node

var astar: AStar2D
var map: TileMapLayer
var hex_directions = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
]

func init(all_layers: Array) -> void:
	map = all_layers[0]
	astar = AStar2D.new()
	
	# Initialize AStar with all non-solid cells
	for layer in all_layers:
		for cell_coords in layer.get_used_cells():
			var cell_data = layer.get_cell_tile_data(cell_coords)
			if not cell_data.get_custom_data("is_solid"):
				add_hex_point(cell_coords)
	
	# Connect neighboring hex cells
	for layer in all_layers:
		for cell_coords in layer.get_used_cells():
			var cell_data = layer.get_cell_tile_data(cell_coords)
			if not cell_data.get_custom_data("is_solid"):
				connect_hex_neighbors(cell_coords)

func add_hex_point(coords: Vector2i) -> void:
	var id = point_to_id(coords)
	if id < 0:
		print(id, coords)
	if not astar.has_point(id):
		astar.add_point(id, map.map_to_local(coords))

func connect_hex_neighbors(coords: Vector2i) -> void:
	var id = point_to_id(coords)
	for dir in hex_directions:
		var neighbor_coords = coords + dir
		var neighbor_id = point_to_id(neighbor_coords)
		if astar.has_point(neighbor_id):
			astar.connect_points(id, neighbor_id, false)

func point_to_id(coords: Vector2i) -> int:
	# Handle negative coordinates properly
	return (coords.x << 16) | (coords.y & 0xFFFF)

func map_to_global(map_position: Vector2i) -> Vector2:
	return map.map_to_local(map_position)
	
func global_to_map(global_position: Vector2) -> Vector2i:
	return map.local_to_map(global_position)

func get_movement_path(start: Vector2i, destination: Vector2i) -> PackedVector2Array:
	var start_id = point_to_id(start)
	var end_id = point_to_id(destination)
	
	if astar.has_point(start_id) and astar.has_point(end_id):
		var global_path = astar.get_point_path(start_id, end_id)
		var cell_path: Array[Vector2i] = []
		for global_pos in global_path:
			cell_path.append(map.local_to_map(global_pos))
		return cell_path
	return []

func is_cell_solid(coords: Vector2i) -> bool:
	var id = point_to_id(coords)
	return not astar.has_point(id)
	
func snap_to_tile_center(pos):
	return map_to_global(global_to_map(pos))
