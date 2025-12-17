class_name UnitDefinition
extends Resource

enum Type {
	PlayerChar,
	Enemy
}

@export var name: String
@export var type: Type
@export var frames: SpriteFrames
@export var hp: int
@export var move_def: Array[ActionDefinition]
@export var action_def: Array[ActionDefinition]
@export var action_points: int
@export var sprite_hue: Color
