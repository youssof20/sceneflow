extends "res://addons/sceneflow/transitions/transition_base.gd"

enum Direction { LEFT, RIGHT }

@export var direction: Direction = Direction.LEFT

@onready var _rect: ColorRect = %Rect


func _ready() -> void:
	layer = 99
	_rect.color = Color.BLACK


func play_out(duration: float, color: Color) -> void:
	_rect.color = color
	var size := get_viewport().get_visible_rect().size
	var from_x := (size.x if direction == Direction.LEFT else -size.x)
	_rect.position = Vector2(from_x, 0.0)
	_rect.size = size

	var t := create_tween()
	if tween_curve:
		var start_x := from_x
		t.tween_method(func(p: float) -> void:
			_rect.position.x = lerpf(start_x, 0.0, _ease(p))
		, 0.0, 1.0, max(duration, 0.0))
	else:
		t.set_trans(tween_trans)
		t.set_ease(tween_ease)
		t.tween_property(_rect, "position:x", 0.0, max(duration, 0.0))
	t.finished.connect(func() -> void: emit_signal("out_complete"))


func play_in(duration: float, color: Color) -> void:
	_rect.color = color
	var size := get_viewport().get_visible_rect().size
	_rect.position = Vector2(0.0, 0.0)
	_rect.size = size

	var to_x := (-size.x if direction == Direction.LEFT else size.x)
	var t := create_tween()
	if tween_curve:
		t.tween_method(func(p: float) -> void:
			_rect.position.x = lerpf(0.0, to_x, _ease(p))
		, 0.0, 1.0, max(duration, 0.0))
	else:
		t.set_trans(tween_trans)
		t.set_ease(tween_ease)
		t.tween_property(_rect, "position:x", to_x, max(duration, 0.0))
	t.finished.connect(func() -> void: emit_signal("in_complete"))

