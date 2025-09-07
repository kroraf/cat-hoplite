extends TileMapLayer

# Configuration
var gray_hex_atlas_coords := Vector2i(0, 0)
var yellow_hex_atlas_coords := Vector2i(0, 1)
var original_tiles := {}  # Dictionary to store original tile data

func _ready():
	modulate = Color(0.6, 0.5, 0.8, 0.7)

func highlight_cell(cell: Vector2i) -> void:
	# Backup original tile
	original_tiles[cell] = {
		"source_id": get_cell_source_id(cell),
		"atlas_coords": get_cell_atlas_coords(cell)
	}
	# Apply highlight tile
	set_cell(cell, 1, gray_hex_atlas_coords, 0)

# Public method to restore a cell to its original state
func restore_original_tile(cell: Vector2i) -> void:
	if original_tiles.has(cell):
		var data = original_tiles[cell]
		set_cell(cell, data.source_id, data.atlas_coords, 0)
		original_tiles.erase(cell)  # Optional: remove from dictionary after restoring

# Public method to clear all highlights
func clear_all_highlights() -> void:
	for cell in original_tiles.keys():
		restore_original_tile(cell)
