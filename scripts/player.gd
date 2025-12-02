class_name Player
extends Unit

# Export custom SFX for player - these will override the inherited ones
@export var player_sfx_run: AudioStream
@export var player_sfx_hit: AudioStream  
@export var player_sfx_attack: AudioStream
@export var player_sfx_die: AudioStream

func _ready():
	super._ready()
	_swap_sfx()

func _swap_sfx() -> void:
	# Replace the inherited SFX with player-specific ones
	if player_sfx_run:
		sfx_run.stream = player_sfx_run
	if player_sfx_hit:
		sfx_hit.stream = player_sfx_hit
	if player_sfx_attack:
		sfx_attack.stream = player_sfx_attack
	if player_sfx_die:
		sfx_die.stream = player_sfx_die
	
	# Ensure is_enemy is false
	is_enemy = false
