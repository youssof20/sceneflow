extends Node

signal transition_started(from_path: String, to_path: String)
signal transition_completed(new_scene_path: String)

enum TransitionType {
	NONE = 0,
	FADE = 1,
	FADE_WHITE = 2,
	SLIDE_LEFT = 3,
	SLIDE_RIGHT = 4,
	# Pro values (defined here for API stability; Lite returns null for these).
	SLIDE_UP = 100,
	SLIDE_DOWN = 101,
	WIPE_LEFT = 102,
	WIPE_RIGHT = 103,
	WIPE_UP = 104,
	WIPE_DOWN = 105,
	CIRCLE_WIPE_IN = 106,
	CIRCLE_WIPE_OUT = 107,
	DISSOLVE = 108,
	CURTAIN = 109,
	ZOOM_IN = 110,
	ZOOM_OUT = 111,
	DIAGONAL_WIPE_NE = 112,
	DIAGONAL_WIPE_NW = 113,
	DIAGONAL_WIPE_SE = 114,
	DIAGONAL_WIPE_SW = 115,
	LUMA = 200,
}

@export var transition_color: Color = Color.BLACK
@export var default_duration: float = 0.3
@export var default_transition: TransitionType = TransitionType.FADE
@export var debug_logging: bool = false
@export var block_input_during_transition: bool = true

enum InterruptPolicy { IGNORE, QUEUE, INTERRUPT }
@export var interrupt_policy: InterruptPolicy = InterruptPolicy.IGNORE

var _transition_active: bool = false
var _transition_node: TransitionBase = null
var _queued: Array[Dictionary] = []

const FadeTransitionScene := preload("res://addons/sceneflow/transitions/fade_transition.tscn")
const SlideLeftTransitionScene := preload("res://addons/sceneflow/transitions/slide_left_transition.tscn")
const SlideRightTransitionScene := preload("res://addons/sceneflow/transitions/slide_right_transition.tscn")
var _overlay_ref: WeakRef = null
var _overlay_path: String = ""


# Accepts either a TransitionType or an int (Godot 4.6 is stricter about inference).
func go_to(scene_path: String, transition: int = default_transition, duration: float = -1.0) -> void:
	if _transition_active:
		match interrupt_policy:
			InterruptPolicy.IGNORE:
				return
			InterruptPolicy.QUEUE:
				_queued.append({"scene_path": scene_path, "transition": int(transition), "duration": float(duration)})
				return
			InterruptPolicy.INTERRUPT:
				if is_instance_valid(_transition_node):
					_transition_node.queue_free()
				_transition_node = null
				_transition_active = false

	var from_path := _current_scene_path()
	var to_path := scene_path
	emit_signal("transition_started", from_path, to_path)

	if not ResourceLoader.exists(scene_path):
		push_error("SceneFlow: Scene does not exist: %s" % scene_path)
		return

	var packed := load(scene_path)
	if not (packed is PackedScene):
		push_error("SceneFlow: Resource is not a PackedScene: %s" % scene_path)
		return

	var d := (default_duration if duration < 0.0 else duration)
	var t: int = int(transition)
	if debug_logging:
		print("SceneFlow.go_to from=", from_path, " to=", scene_path, " transition=", t, " duration=", d)

	if t == TransitionType.NONE:
		get_tree().change_scene_to_packed(packed)
		emit_signal("transition_completed", scene_path)
		return

	var transition_node: TransitionBase = _create_transition(t)
	if transition_node == null:
		if debug_logging:
			print("SceneFlow: no transition node for type=", t, " (falling back to cut)")
		get_tree().change_scene_to_packed(packed)
		emit_signal("transition_completed", scene_path)
		return
	if debug_logging:
		print("SceneFlow: transition node=", transition_node.name, " script=", transition_node.get_script())

	_transition_active = true
	_transition_node = transition_node
	get_tree().root.add_child(transition_node)

	var out_color := _transition_color_for(t)
	transition_node.out_complete.connect(func() -> void:
		if debug_logging:
			print("SceneFlow: out_complete (swap)")
		get_tree().change_scene_to_packed(packed)
		transition_node.play_in(d, out_color)
	)
	transition_node.in_complete.connect(func() -> void:
		if debug_logging:
			print("SceneFlow: in_complete (done)")
		if is_instance_valid(transition_node):
			transition_node.queue_free()
		_transition_active = false
		_transition_node = null
		emit_signal("transition_completed", scene_path)
		_drain_queue()
	)

	transition_node.play_out(d, out_color)


func _input(event: InputEvent) -> void:
	if _transition_active and block_input_during_transition:
		get_viewport().set_input_as_handled()


func _drain_queue() -> void:
	if _transition_active:
		return
	if _queued.is_empty():
		return
	var next := _queued.pop_front()
	go_to(String(next["scene_path"]), int(next["transition"]), float(next["duration"]))


func reload(transition: int = default_transition, duration: float = -1.0) -> void:
	var path := _current_scene_path()
	if path == "":
		push_error("SceneFlow: Cannot reload; no current scene path.")
		return
	go_to(path, transition, duration)


func push(scene_path: String) -> void:
	var existing := (_overlay_ref.get_ref() if _overlay_ref else null)
	if existing != null:
		push_error("SceneFlow (Lite): Only one pushed scene is supported. Pop first.")
		return
	if not ResourceLoader.exists(scene_path):
		push_error("SceneFlow: Scene does not exist: %s" % scene_path)
		return
	var packed := load(scene_path)
	if not (packed is PackedScene):
		push_error("SceneFlow: Resource is not a PackedScene: %s" % scene_path)
		return
	var instance: Node = packed.instantiate()
	_overlay_ref = weakref(instance)
	_overlay_path = scene_path

	var root := get_tree().root
	root.add_child(instance)
	root.move_child(instance, root.get_child_count() - 1)


func pop() -> void:
	var existing := (_overlay_ref.get_ref() if _overlay_ref else null)
	if existing == null:
		_overlay_ref = null
		_overlay_path = ""
		return
	existing.queue_free()
	_overlay_ref = null
	_overlay_path = ""


func stack_depth() -> int:
	return 1 if (_overlay_ref and _overlay_ref.get_ref()) else 0


func _current_scene_path() -> String:
	var cs := get_tree().current_scene
	if cs and cs.scene_file_path != "":
		return cs.scene_file_path
	return ""


func _create_transition(t: int) -> TransitionBase:
	match t:
		TransitionType.FADE, TransitionType.FADE_WHITE:
			return FadeTransitionScene.instantiate()
		TransitionType.SLIDE_LEFT:
			return SlideLeftTransitionScene.instantiate()
		TransitionType.SLIDE_RIGHT:
			return SlideRightTransitionScene.instantiate()
		_:
			return null


func _transition_color_for(t: int) -> Color:
	if t == TransitionType.FADE_WHITE:
		return Color.WHITE
	return transition_color
