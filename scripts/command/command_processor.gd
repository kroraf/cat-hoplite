extends Node

signal queue_empty

var command_queue: Array[Command] = []
var undo_queue: Array[Command]
var executing: bool = false

func _ready() -> void:
	EventBus.post_command.connect(_on_post_command)
	EventBus.execute_next_command.connect(_on_execute_next_command)
	
func _on_post_command(command):
	print("- Adding {0} to queue.".format([command]))
	command_queue.append(command)
	EventBus.execute_next_command.emit()
	
func _on_execute_next_command():
	print("> command_queue: ", command_queue)
	if executing or command_queue.is_empty():
		if command_queue.is_empty():
			queue_empty.emit()
		return
	executing = true
	var c: Command = command_queue.pop_front()
	await c.execute()
	executing = false
	if not command_queue.is_empty():
		EventBus.execute_next_command.emit()
	else:
		queue_empty.emit()
		
func is_queue_empty() -> bool:
	return command_queue.is_empty() and not executing
