extends Node2D

const interactable: bool = true

var grid_position: Vector2i:
	get:
		return Navigation.global_to_map(position)
	
func init():
	position = Navigation.snap_to_tile_center(position)
	OccupancyManager.register_object(self, grid_position)
