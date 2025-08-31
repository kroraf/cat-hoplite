extends Node

signal cursor_accept_pressed(cursor_cell: Vector2i)
signal show_movement_field(unit)
signal movement_complete(unit)
signal movement_started
signal end_turn
signal turn_started
signal unit_died(unit)
signal action_started(unit)
signal action_complete(unit)
