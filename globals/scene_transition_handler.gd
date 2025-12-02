extends Node

var SCREEN: Dictionary = {
	"width": ProjectSettings.get_setting("display/window/size/viewport_width"),
	"height": ProjectSettings.get_setting("display/window/size/viewport_height"),
	"center": Vector2()
}

func _ready():
	SCREEN.center = Vector2(SCREEN.width / 2, SCREEN.height / 2)
	
func fade_out(from, to, duration, color,) -> void:
	var root_control = CanvasLayer.new()
	var color_rect = ColorRect.new()
	var tween = get_tree().create_tween()
	root_control.set_process_mode(PROCESS_MODE_ALWAYS)
	color_rect.color = (Color(0,0,0,0))
	
	get_tree().get_root().add_child(root_control)
	root_control.add_child(color_rect)
	color_rect._set_size(Vector2(SCREEN.width, SCREEN.height))
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(color_rect, "color", color, duration/2)
	#var root = get_tree().root
	await tween.finished
	from.queue_free()
	
	var new_scene = load(to).instantiate()
	get_tree().get_root().add_child(new_scene)
	#get_tree().change_scene_to_file("res://scenes/game.tscn")
	
	var tween2 = get_tree().create_tween()
	tween2.set_ease(Tween.EASE_IN_OUT)
	tween2.set_trans(Tween.TRANS_LINEAR)
	tween2.tween_property(color_rect, "color", Color.BLACK, duration/2)
	
	get_tree().set_current_scene(new_scene)
	root_control.queue_free()
