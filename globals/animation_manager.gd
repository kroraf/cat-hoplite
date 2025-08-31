extends Node

#var active_animations: int = 0
#signal all_animations_complete

#func register_animation() -> void:
	#active_animations += 1
	#print("Animation registered. Total: ", active_animations)

#func unregister_animation() -> void:
	#active_animations = max(0, active_animations - 1)
	#print("Animation completed. Remaining: ", active_animations)
	#
	#if active_animations == 0:
		#all_animations_complete.emit()
#
#func wait_for_animations() -> void:
	#if active_animations > 0:
		#print("Waiting for ", active_animations, " animations to complete...")
		#await all_animations_complete
		#print("All animations completed")

var _blocking_by_node: Dictionary = {}   # Node -> count of blocking anims
signal all_finished

func register(node: Node) -> void:
	if not _blocking_by_node.has(node):
		_blocking_by_node[node] = 0
		if not node.is_connected("tree_exited", Callable(self, "_on_node_freed")):
			node.connect("tree_exited", Callable(self, "_on_node_freed").bind(node))
	_blocking_by_node[node] += 1

func unregister(node: Node) -> void:
	if not _blocking_by_node.has(node):
		return

	_blocking_by_node[node] -= 1
	if _blocking_by_node[node] <= 0:
		_blocking_by_node.erase(node)

	if _blocking_by_node.is_empty():
		all_finished.emit()

func _on_node_freed(node: Node) -> void:
	# Node was freed mid-animation, clean it out
	_blocking_by_node.erase(node)
	if _blocking_by_node.is_empty():
		all_finished.emit()

func wait_for_all() -> void:
	if _blocking_by_node.is_empty():
		return
	await all_finished
