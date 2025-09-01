class_name DieCommand extends Command

func _init(src: Character) -> void:
	super(src, null)

func execute():
	print("{0} dies.".format([source.name]))
	await source.die()
