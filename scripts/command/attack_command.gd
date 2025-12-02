class_name AttackCommand extends Command


func _init(src: Unit, trgt: Unit) -> void:
	super(src, trgt)

func execute():
	print("{0} attacking {1}".format([source.name, target.name]))
	await source.attack(target)
