class_name UiSceneUtils
extends RefCounted

static func clear_children(container: Node) -> void:
	var children: Array[Node] = []
	for child in container.get_children():
		children.append(child)
	for child in children:
		container.remove_child(child)
		child.queue_free()

static func instantiate_required(scene: PackedScene, scene_label: String) -> Node:
	# Dynamic lists are still instanced at runtime, but the scene itself must be wired in the editor.
	assert(scene != null, "%s must be assigned in the inspector." % scene_label)
	var instance: Node = scene.instantiate()
	assert(instance != null, "%s could not be instantiated." % scene_label)
	return instance
