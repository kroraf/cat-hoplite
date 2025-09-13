extends HBoxContainer

@export var full_heart_texture: Texture2D

var heart_nodes = []
var max_hearts = 3
func _ready():
	EventBus.player_hp_changed.connect(_on_health_changed)
	#initialize_health_bar()
	
func _on_health_changed(new_hp):
	for child in get_children():
		child.queue_free()
	
	for i in range(new_hp):
		var heart_texture_rect = TextureRect.new()
		heart_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		heart_texture_rect.custom_minimum_size = Vector2(16, 16)  # Adjust size as needed
		heart_texture_rect.texture = full_heart_texture
		add_child(heart_texture_rect)

		


#func initialize_health_bar():
	## Clear existing hearts
	#for child in get_children():
		#child.queue_free()
	#heart_nodes.clear()
	#
	#for i in range(max_hearts):
		#var heart_texture_rect = TextureRect.new()
		#heart_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		#heart_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		#heart_texture_rect.custom_minimum_size = Vector2(16, 16)  # Adjust size as needed
		#heart_texture_rect.texture = full_heart_texture
		#add_child(heart_texture_rect)
		#heart_nodes.append(heart_texture_rect)
