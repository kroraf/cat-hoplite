extends Node

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		toggle_pause()

func toggle_pause():
	if get_tree().paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	get_tree().paused = true
	var menu = get_tree().root.find_child("Menu", true, false)
	if menu:
		menu.visible = true
	else:
		print("Oops!")
	

func resume_game():
	get_tree().paused = false
	var menu = get_tree().root.find_child("Menu", true, false)
	if menu:
		menu.visible = false
	else:
		print("Oops!")
