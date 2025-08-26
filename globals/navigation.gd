extends Node

var astar: AStar2D
var map: TileMapLayer
var hex_directions = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
]
var dynamic_obstacles := {}

func init(all_layers: Array) -> void:
	map = all_layers[0]
	astar = AStar2D.new()

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
				
func update_obstacle(cell: Vector2i, occupied: bool) -> void:
	var id = point_to_id(cell)
	#print("dynamic_obstacles", dynamic_obstacles)
	if occupied:
		# Add to dynamic obstacles and disable point
		dynamic_obstacles[cell] = true
		if astar.has_point(id):
				astar.set_point_disabled(id, true)
	else:
		# Remove from obstacles and enable point
		dynamic_obstacles.erase(cell)
		if astar.has_point(id):
			astar.set_point_disabled(id, false)

func is_cell_walkable(cell: Vector2i) -> bool:
	return (
		astar.has_point(point_to_id(cell)) and
		not dynamic_obstacles.has(cell) and
		not map.get_cell_tile_data(cell).get_custom_data("is_solid")
	)

func add_hex_point(coords: Vector2i) -> void:
	var id = point_to_id(coords)
	if id < 0:
		print("ERROR! ", id, coords)
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
	
func get_walkable_cells(unit: Character) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var movement_dirs = unit.def.move_def
	
	for dir in movement_dirs:
		var target_cell = unit.grid_position + dir.end_point
		if _is_cell_walkable(target_cell):
			cells.append(target_cell)
	return cells
	
func _is_cell_walkable(cell: Vector2i) -> bool:
	return (
		map.is_cell_valid(cell) and
		not map.is_cell_solid(cell) and
		not OccupancyManager.is_tile_occupied(cell)
	)
	
func find_nearest_available_cell(target_cell: Vector2i, max_distance: int = 2) -> Vector2i:
	# If the target cell is walkable, return it
	if _is_cell_walkable(target_cell):
		return target_cell
	
	# Check immediate neighbors first (distance 1)
	for dir in hex_directions:
		var neighbor_cell = target_cell + dir
		if _is_cell_walkable(neighbor_cell):
			return neighbor_cell
	
	# If no immediate neighbors, check distance 2
	for distance in range(2, max_distance + 1):
		var ring_cells = _get_ring_around_cell(target_cell, distance)
		for cell in ring_cells:
			if _is_cell_walkable(cell):
				return cell
	
	# Fallback: return the original target
	return target_cell

func _get_ring_around_cell(center: Vector2i, radius: int) -> Array[Vector2i]:
	var ring_cells: Array[Vector2i] = []
	var current = center + Vector2i(radius, -radius)
	
	for i in range(6):
		for j in range(radius):
			ring_cells.append(current)
			# Move in the current direction
			current += hex_directions[i]
	
	return ring_cells
