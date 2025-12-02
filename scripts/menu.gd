extends NinePatchRect

@onready var new_game = $VBoxContainer/NewGame
	
"res://scenes/game.tscn"

func _ready():
	#visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func _on_new_game_pressed():
	if not get_tree().root.find_child("Game", true, false):
		SceneTransitionHandler.fade_out(get_tree().get_current_scene(), "res://scenes/game.tscn", 0.8, Color.BLACK)
	else:
		OccupancyManager.clear()
		get_tree().paused = false
		get_tree().reload_current_scene()


func _on_load_pressed():
	print("This will load the game in the future. Maybe.")


func _on_quit_pressed():
	get_tree().quit()
