@tool
extends EditorPlugin

const DockScene := preload("res://addons/sceneflow/editor/sceneflow_dock.tscn")

var _dock: Control


func _enter_tree() -> void:
	_dock = DockScene.instantiate()
	if _dock.has_method("set_editor_interface"):
		_dock.call("set_editor_interface", get_editor_interface())
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)


func _exit_tree() -> void:
	if is_instance_valid(_dock):
		remove_control_from_docks(_dock)
		_dock.queue_free()
	_dock = null

