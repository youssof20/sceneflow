@tool
extends Control

var _editor_interface: EditorInterface = null

@onready var _current_scene_label: Label = %CurrentSceneLabel
@onready var _quick_path_edit: LineEdit = %QuickScenePath
@onready var _pro_enabled: CheckBox = %ProEnabled
@onready var _autoload_path: Label = %AutoloadPath
@onready var _restart_banner: PanelContainer = %RestartBanner
@onready var _transition_option: OptionButton = %TransitionOption
@onready var _duration: SpinBox = %Duration
@onready var _color_label: Label = %ColorLabel
@onready var _color: ColorPickerButton = %Color
@onready var _circle_feather_label: Label = %CircleFeatherLabel
@onready var _circle_feather: HSlider = %CircleFeather
@onready var _dissolve_cells_label: Label = %DissolveCellsLabel
@onready var _dissolve_cells: HSlider = %DissolveCells
@onready var _luma_texture_label: Label = %LumaTextureLabel
@onready var _luma_texture_path: LineEdit = %LumaTexturePath
@onready var _capture_source: CheckBox = %CaptureSource
@onready var _target_scene_path: LineEdit = %TargetScenePath

const _AUTOLOAD_NAME := "SceneManager"
const _PRO_PATH := "res://addons/sceneflow_pro/scene_manager_pro.gd"
const _LITE_PATH := "res://addons/sceneflow/scene_manager.gd"

const _T_FADE := 1
const _T_FADE_WHITE := 2
const _T_SLIDE_LEFT := 3
const _T_SLIDE_RIGHT := 4
const _T_CIRCLE_WIPE_OUT := 107
const _T_DISSOLVE := 108
const _T_LUMA := 200

var _has_pro_files: bool = false


func set_editor_interface(editor_interface: EditorInterface) -> void:
	_editor_interface = editor_interface


func _ready() -> void:
	_has_pro_files = ResourceLoader.exists(_PRO_PATH)
	_pro_enabled.visible = _has_pro_files
	_pro_enabled.disabled = not _has_pro_files
	if not _has_pro_files:
		_pro_enabled.button_pressed = false
	else:
		_pro_enabled.button_pressed = _is_pro_autoload_active()

	_target_scene_path.text = "res://demo/transition_gallery_a.tscn"
	_quick_path_edit.text = "res://demo/showcase_a.tscn"
	_setup_transitions()
	_apply_pro_visibility(_pro_enabled.button_pressed)
	_restart_banner.visible = false
	_refresh()


func _process(_delta: float) -> void:
	# Best-effort live update while playing.
	_refresh()


func _refresh() -> void:
	_autoload_path.text = "SceneManager autoload: %s" % _get_scene_manager_autoload()
	var edited := get_tree().edited_scene_root
	if edited and edited.scene_file_path != "":
		_current_scene_label.text = edited.scene_file_path
	else:
		_current_scene_label.text = "(no edited scene)"


func _on_quick_open_pressed() -> void:
	var path := _quick_path_edit.text.strip_edges()
	if path == "":
		return
	if not ResourceLoader.exists(path):
		push_error("SceneFlow: Scene does not exist: %s" % path)
		return
	if _editor_interface:
		_editor_interface.open_scene_from_path(path)


func _on_open_gallery_pressed() -> void:
	if _editor_interface:
		_editor_interface.open_scene_from_path("res://demo/transition_gallery_a.tscn")


func _on_open_showcase_pressed() -> void:
	if _editor_interface:
		_editor_interface.open_scene_from_path("res://demo/showcase_a.tscn")


func _on_pro_enabled_toggled(on: bool) -> void:
	if not _has_pro_files:
		_pro_enabled.button_pressed = false
		return
	_set_scene_manager_autoload(_PRO_PATH if on else _LITE_PATH)
	_apply_pro_visibility(on)
	_setup_transitions()
	_restart_banner.visible = true


func _apply_pro_visibility(on: bool) -> void:
	_color_label.visible = on
	_color.visible = on
	_circle_feather_label.visible = on
	_circle_feather.visible = on
	_dissolve_cells_label.visible = on
	_dissolve_cells.visible = on
	_luma_texture_label.visible = on
	_luma_texture_path.visible = on
	_capture_source.visible = on


func _setup_transitions() -> void:
	_transition_option.clear()
	_transition_option.add_item("FADE (Lite)", _T_FADE)
	_transition_option.add_item("FADE_WHITE (Lite)", _T_FADE_WHITE)
	_transition_option.add_item("SLIDE_LEFT (Lite)", _T_SLIDE_LEFT)
	_transition_option.add_item("SLIDE_RIGHT (Lite)", _T_SLIDE_RIGHT)

	if _pro_enabled.visible and _pro_enabled.button_pressed:
		_transition_option.add_separator()
		_transition_option.add_item("CIRCLE_WIPE_OUT (Pro)", _T_CIRCLE_WIPE_OUT)
		_transition_option.add_item("DISSOLVE (Pro)", _T_DISSOLVE)
		_transition_option.add_item("LUMA (Pro)", _T_LUMA)

	_transition_option.select(0)


func _on_copy_code_pressed() -> void:
	var scene_path := _target_scene_path.text.strip_edges()
	if scene_path == "":
		scene_path = "res://your_scene.tscn"

	var t_id := _transition_option.get_selected_id()
	var dur := float(_duration.value)

	var code := ""
	if _pro_enabled.visible and _pro_enabled.button_pressed and (t_id == _T_CIRCLE_WIPE_OUT or t_id == _T_DISSOLVE or t_id == _T_LUMA):
		var preset_lines: Array[String] = []
		preset_lines.append("\"type\": %d" % t_id)
		preset_lines.append("\"duration\": %.2f" % dur)
		var c := _color.color
		preset_lines.append("\"color\": Color(%.3f, %.3f, %.3f, %.3f)" % [c.r, c.g, c.b, c.a])
		if t_id == _T_CIRCLE_WIPE_OUT:
			preset_lines.append("\"circle_feather\": %.3f" % float(_circle_feather.value))
		if t_id == _T_DISSOLVE:
			preset_lines.append("\"dissolve_cells\": %.1f" % float(_dissolve_cells.value))
		if t_id == _T_LUMA:
			var mask_path := _luma_texture_path.text.strip_edges()
			if mask_path != "":
				preset_lines.append("\"texture\": load(\"%s\")" % mask_path)
			preset_lines.append("\"capture_source\": %s" % ("true" if _capture_source.button_pressed else "false"))

		code = "var preset := {\n\t%s,\n}\nSceneManager.call(\"go_to\", \"%s\", preset)\n" % [",\n\t".join(preset_lines), scene_path]
	else:
		code = "SceneManager.go_to(\"%s\", %d, %.2f)\n" % [scene_path, t_id, dur]

	DisplayServer.clipboard_set(code)


func _on_browse_luma_texture_pressed() -> void:
	if _editor_interface == null:
		return
	var dlg := EditorFileDialog.new()
	dlg.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dlg.access = EditorFileDialog.ACCESS_RESOURCES
	dlg.add_filter("*.png, *.jpg, *.jpeg, *.webp ; Images")
	dlg.title = "Pick luma mask image"
	add_child(dlg)
	dlg.file_selected.connect(func(p: String) -> void:
		_luma_texture_path.text = p
		dlg.queue_free()
	)
	dlg.canceled.connect(func() -> void:
		dlg.queue_free()
	)
	dlg.popup_centered_ratio(0.6)


func _is_pro_autoload_active() -> bool:
	var key := "autoload/%s" % _AUTOLOAD_NAME
	if not ProjectSettings.has_setting(key):
		return false
	return String(ProjectSettings.get_setting(key)).contains(_PRO_PATH)

func _get_scene_manager_autoload() -> String:
	var key := "autoload/%s" % _AUTOLOAD_NAME
	if not ProjectSettings.has_setting(key):
		return "(not set)"
	return String(ProjectSettings.get_setting(key))


func _set_scene_manager_autoload(path: String) -> void:
	var key := "autoload/%s" % _AUTOLOAD_NAME
	ProjectSettings.set_setting(key, "*" + path)
	ProjectSettings.save()

