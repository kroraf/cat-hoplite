class_name ActionDefinition
extends Resource

enum ActionType {
	Move,
	Ability
}

enum BlockMode {
	Cancel,
	TruncateBefore,
	TruncateOn,
	Ignore,
}

@export var block_mode: BlockMode
@export var end_point: Vector2i
