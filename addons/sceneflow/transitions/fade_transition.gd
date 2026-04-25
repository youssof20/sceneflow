extends "res://addons/sceneflow/transitions/transition_base.gd"

@onready var _rect: ColorRect = %Rect


func _ready() -> void:
	layer = 99
	_rect.color = Color.BLACK
	_rect.modulate.a = 0.0


func play_out(duration: float, color: Color) -> void:
	_rect.color = color
	_rect.modulate.a = 0.0
	var t := create_tween()
	if tween_curve:
		t.tween_method(func(p: float) -> void:
			_rect.modulate.a = lerpf(0.0, 1.0, _ease(p))
		, 0.0, 1.0, max(duration, 0.0))
	else:
		t.set_trans(tween_trans)
		t.set_ease(tween_ease)
		t.tween_property(_rect, "modulate:a", 1.0, max(duration, 0.0))
	t.finished.connect(func() -> void: emit_signal("out_complete"))


func play_in(duration: float, color: Color) -> void:
	_rect.color = color
	_rect.modulate.a = 1.0
	var t := create_tween()
	if tween_curve:
		t.tween_method(func(p: float) -> void:
			_rect.modulate.a = lerpf(1.0, 0.0, _ease(p))
		, 0.0, 1.0, max(duration, 0.0))
	else:
		t.set_trans(tween_trans)
		t.set_ease(tween_ease)
		t.tween_property(_rect, "modulate:a", 0.0, max(duration, 0.0))
	t.finished.connect(func() -> void: emit_signal("in_complete"))

