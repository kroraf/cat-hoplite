extends TileMapLayer

# Configuration
var highlight_atlas_coords := Vector2i(0, 0)
var last_hovered_cell := Vector2i(-1, -1)
var original_tiles := {}  # Dictionary to store original tile data

func _ready():
	Navigation.init([self])

func highlight_cell(cell: Vector2i) -> void:
	if get_cell_source_id(cell) != -1:
		# Backup original tile
		original_tiles[cell] = {
			"source_id": get_cell_source_id(cell),
			"atlas_coords": get_cell_atlas_coords(cell)
		}
		# Apply highlight tile
		set_cell(cell, 0, highlight_atlas_coords, 0)

# Public method to restore a cell to its original state
func restore_original_tile(cell: Vector2i) -> void:
	if original_tiles.has(cell):
		var data = original_tiles[cell]
		set_cell(cell, data.source_id, data.atlas_coords, 0)
		original_tiles.erase(cell)  # Optional: remove from dictionary after restoring

# Public method to get the currently hovered cell
func get_current_hovered_cell() -> Vector2i:
	return last_hovered_cell

# Public method to clear all highlights
func clear_all_highlights() -> void:
	for cell in original_tiles.keys():
		restore_original_tile(cell)
	last_hovered_cell = Vector2i(-1, -1)
	
# Add these to your hexgrid/TileMap script
func is_cell_valid(cell: Vector2i) -> bool:
	# Check if cell exists in the tilemap
	return get_cell_source_id(cell) != -1

func is_cell_solid(cell: Vector2i) -> bool:
	# Check custom data layer for solid property
	var data = get_cell_tile_data(cell)
	return data and data.get_custom_data("is_solid")
