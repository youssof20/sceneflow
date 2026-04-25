extends CanvasLayer
class_name TransitionBase

signal out_complete
signal in_complete

@export var tween_trans: Tween.TransitionType = Tween.TRANS_SINE
@export var tween_ease: Tween.EaseType = Tween.EASE_IN_OUT
var tween_curve: Curve = null


func configure(preset: Dictionary) -> void:
	# Optional: used by Pro presets.
	if preset.has("trans"):
		tween_trans = int(preset["trans"])
	if preset.has("ease"):
		tween_ease = int(preset["ease"])
	if preset.has("curve") and preset["curve"] is Curve:
		tween_curve = preset["curve"]


func _ease(p: float) -> float:
	if tween_curve:
		if tween_curve.has_method("sample_baked"):
			return clampf(float(tween_curve.call("sample_baked", p)), 0.0, 1.0)
		if tween_curve.has_method("sample"):
			return clampf(float(tween_curve.call("sample", p)), 0.0, 1.0)
	return p


func play_out(_duration: float, _color: Color) -> void:
	push_error("TransitionBase.play_out not implemented")
	emit_signal("out_complete")


func play_in(_duration: float, _color: Color) -> void:
	push_error("TransitionBase.play_in not implemented")
	emit_signal("in_complete")

