class_name MoveCommand extends Command

var path: Array = []

func _init(src: Character, move_path: Array) -> void:
	super(src, null)
	path = move_path
	pass

func execute():
	print("{0} is moving to {1}".format([source.name, str(path)]))
	await source.move_along_path(path)
