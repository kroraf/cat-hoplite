class_name InteractionCommand extends Command

func _init(src: Unit, trgt: Node) -> void:
	super(src, trgt)

func execute():
	print("{0} is interacting with {1}".format([source.name, target.name]))
	await target.complete_level()
