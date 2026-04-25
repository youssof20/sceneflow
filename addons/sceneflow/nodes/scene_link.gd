extends Node

@export_file("*.tscn") var target_scene: String = ""
@export var transition: int = 1
@export var duration: float = -1.0


func trigger() -> void:
	if target_scene == "":
		push_error("SceneLink: target_scene is empty.")
		return

	var sm := get_node_or_null("/root/SceneManager")
	if sm == null:
		push_error("SceneLink: missing autoload '/root/SceneManager'.")
		return

	# Call dynamically so the same node works in Lite and Pro.
	# (Pro may accept a Dictionary preset; Lite uses int.)
	sm.call("go_to", target_scene, int(transition), float(duration))

