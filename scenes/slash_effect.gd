extends Node2D

@onready var animated_sprite := $AnimatedSprite
@onready var sfx_slash = $sfx_slash

func _ready():
	#animated_sprite.is_playing()
	pass
	
func play():
	animated_sprite.play("default")
	if sfx_slash and sfx_slash.stream:
		sfx_slash.play()
	
	await animated_sprite.animation_finished
	animated_sprite.visible = false
	queue_free()
	
func stop():
	animated_sprite.playing = false
	queue_free()
