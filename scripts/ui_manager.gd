extends CanvasLayer

const P_SETUP := 0
const P_SELECT := 1
const P_RESOLVE := 2
const P_FINAL := 3
const P_GAME_OVER := 4

const C_PANEL := Color(1.0, 0.92, 0.80, 0.96)
const C_BORDER := Color(0.64, 0.43, 0.24, 0.95)
const C_TEXT := Color(0.27, 0.18, 0.12, 1.0)
const C_MUTED := Color(0.46, 0.36, 0.27, 1.0)
const C_GOLD := Color(0.63, 0.39, 0.12, 1.0)
const C_READY := Color(0.24, 0.52, 0.29, 1.0)
const C_DANGER := Color(0.68, 0.22, 0.24, 1.0)

const ICON_CAT := "res://assets/icons/cat.png"
const ICON_FIRE := "res://assets/icons/fire.png"
const ICON_EYE := "res://assets/icons/eye.png"
const ICON_STAR := "res://assets/icons/star.png"
const ICON_LEAVES := "res://assets/icons/leaves.png"
const ICON_FIRE_DARK := "res://assets/icons/fire_dark.png"
const ICON_EYE_DARK := "res://assets/icons/eye_dark.png"
const ICON_STAR_DARK := "res://assets/icons/star_dark.png"
const ICON_LEAVES_DARK := "res://assets/icons/leaves_dark.png"
const ICON_CARDS := "res://assets/icons/cards.png"
const ICON_REFRESH_DARK := "res://assets/icons/refresh_dark.png"

const STAT_ORDER: Array[String] = ["passion", "intuition", "curiosity", "comfort"]
const STAT_ICONS := {
	"passion": ICON_FIRE,
	"intuition": ICON_EYE,
	"curiosity": ICON_STAR,
	"comfort": ICON_LEAVES,
}
const STAT_COLORS := {
	"passion": Color(0.84, 0.27, 0.32),
	"intuition": Color(0.29, 0.47, 0.82),
	"curiosity": Color(0.72, 0.55, 0.12),
	"comfort": Color(0.24, 0.58, 0.43),
}

var root: Control
var stat_values: Dictionary = {}
var stat_fills: Dictionary = {}
var progress_value: Label
var phase_label: Label
var lang_button: Button
var restart_button: Button
var modal_layer: Control

var _modal_kind: String = ""


func _ready() -> void:
	_build_ui()
	GameManager.state_changed.connect(_refresh)
	GameManager.game_started.connect(_on_game_started)
	Loc.language_changed.connect(_on_language_changed)
	_refresh()


func _build_ui() -> void:
	root = Control.new()
	root.name = "UIRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cute_font := load("res://assets/fonts/lemi_zhixia_qianfeng.ttf") as Font
	if cute_font != null:
		var theme := Theme.new()
		theme.default_font = cute_font
		theme.default_font_size = 16
		root.theme = theme
	add_child(root)

	var top_bar := _panel()
	top_bar.anchor_left = 0.0
	top_bar.anchor_right = 1.0
	top_bar.anchor_top = 0.0
	top_bar.anchor_bottom = 0.0
	top_bar.offset_left = 16.0
	top_bar.offset_right = -16.0
	top_bar.offset_top = 10.0
	top_bar.offset_bottom = 88.0
	root.add_child(top_bar)
	var top_box := HBoxContainer.new()
	top_box.add_theme_constant_override("separation", 12)
	top_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_bar.add_child(top_box)
	top_box.add_child(_icon(ICON_CAT, 26, C_GOLD))
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	stats.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_box.add_child(stats)
	for key in STAT_ORDER:
		_add_stat_widget(stats, key)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_box.add_child(spacer)
	var progress_box := HBoxContainer.new()
	progress_box.add_theme_constant_override("separation", 4)
	progress_box.add_child(_icon(ICON_CARDS, 20, C_GOLD))
	progress_value = Label.new()
	progress_value.add_theme_font_size_override("font_size", 15)
	progress_value.add_theme_color_override("font_color", C_TEXT)
	progress_box.add_child(progress_value)
	top_box.add_child(progress_box)
	phase_label = Label.new()
	phase_label.add_theme_font_size_override("font_size", 15)
	phase_label.add_theme_color_override("font_color", C_TEXT)
	phase_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_box.add_child(phase_label)
	lang_button = _small_text_button("EN", 50, 30, _on_language_pressed)
	top_box.add_child(lang_button)
	restart_button = _small_icon_button(ICON_REFRESH_DARK, 34, 30, _on_restart_pressed)
	top_box.add_child(restart_button)

	modal_layer = Control.new()
	modal_layer.name = "ModalLayer"
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_layer.visible = false
	root.add_child(modal_layer)


func _add_stat_widget(parent: HBoxContainer, key: String) -> void:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.tooltip_text = Loc.stat_name(key)
	parent.add_child(box)
	box.add_child(_icon(STAT_ICONS[key], 20, STAT_COLORS[key]))
	var value_box := VBoxContainer.new()
	value_box.add_theme_constant_override("separation", 0)
	box.add_child(value_box)
	var value := Label.new()
	value.add_theme_font_size_override("font_size", 16)
	value.add_theme_color_override("font_color", C_TEXT)
	value_box.add_child(value)
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(58, 6)
	value_box.add_child(bar)
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.14, 0.1, 0.25)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.add_child(bg)
	var fill := ColorRect.new()
	fill.color = STAT_COLORS[key]
	fill.position = Vector2.ZERO
	fill.size = Vector2(0, 6)
	bar.add_child(fill)
	stat_values[key] = value
	stat_fills[key] = fill


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = C_PANEL
	style.border_color = C_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0.25, 0.14, 0.07, 0.2)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _icon(path: String, size: int, color: Color) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = load(path) as Texture2D
	icon.custom_minimum_size = Vector2(size, size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = color
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _style_button(button: Button, font_size: int) -> void:
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", C_TEXT)
	button.add_theme_color_override("font_hover_color", C_TEXT)
	button.add_theme_color_override("font_pressed_color", C_TEXT)
	button.add_theme_color_override("font_disabled_color", Color(0.55, 0.48, 0.4))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1.0, 0.965, 0.88, 1.0)
	normal.border_color = C_BORDER
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(10)
	normal.set_content_margin_all(6)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1.0, 0.88, 0.66, 1.0)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.95, 0.78, 0.50, 1.0)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.88, 0.82, 0.74, 1.0)
	disabled.border_color = Color(0.74, 0.69, 0.62, 1.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", hover)


func _small_text_button(text: String, width: int, height: int, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, height)
	_style_button(button, 13)
	button.pressed.connect(callback)
	return button


func _small_icon_button(icon_path: String, width: int, height: int, callback: Callable) -> Button:
	var button := Button.new()
	button.icon = load(icon_path) as Texture2D
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 20)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.custom_minimum_size = Vector2(width, height)
	_style_button(button, 13)
	button.pressed.connect(callback)
	return button


func _refresh() -> void:
	if root == null:
		return
	_refresh_stats()
	_sync_modals()


func _refresh_stats() -> void:
	for key in STAT_ORDER:
		var value := int(GameManager.stats[key])
		stat_values[key].text = str(value)
		var color: Color = C_DANGER if value <= 1 or value >= 9 else STAT_COLORS[key]
		stat_values[key].add_theme_color_override("font_color", color)
		var fill: ColorRect = stat_fills[key]
		fill.color = color
		fill.size = Vector2(58.0 * clampf(float(value) / 10.0, 0.0, 1.0), 6)
	progress_value.text = "%d/%d" % [GameManager.choices_completed, GameManager.TOTAL_CARDS]
	phase_label.text = Loc.phase_name(GameManager.phase)
	lang_button.text = Loc.t("ui.lang_switch")
	lang_button.tooltip_text = Loc.t("ui.lang_tip")
	restart_button.tooltip_text = Loc.t("ui.restart")


func request_roll() -> void:
	GameManager.roll_die()


func _on_game_started(_seed: int) -> void:
	_close_modal()
	_refresh()


func _on_language_pressed() -> void:
	Loc.toggle_language()


func _on_restart_pressed() -> void:
	_close_modal()
	GameManager.new_game(0)


func _on_language_changed() -> void:
	_close_modal()
	_refresh()


func _sync_modals() -> void:
	if GameManager.phase == P_GAME_OVER:
		if _modal_kind != "gameover":
			_show_game_over()
		return
	if _modal_kind == "gameover":
		_close_modal()


func _open_modal(title: String, kind: String) -> VBoxContainer:
	for child in modal_layer.get_children():
		modal_layer.remove_child(child)
		child.queue_free()
	_modal_kind = kind
	modal_layer.visible = true
	var dim := ColorRect.new()
	dim.color = Color(0.25, 0.15, 0.10, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_layer.add_child(center)
	var panel := _panel()
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", C_GOLD)
	box.add_child(title_label)
	box.add_child(HSeparator.new())
	return box


func _close_modal() -> void:
	_modal_kind = ""
	if modal_layer == null:
		return
	modal_layer.visible = false
	for child in modal_layer.get_children():
		modal_layer.remove_child(child)
		child.queue_free()


func _dialog_text(parent: VBoxContainer, text: String, size: int = 14, color: Color = C_TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(560, 0)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _dialog_button(parent: VBoxContainer, text: String, callback: Callable, disabled: bool = false, icon_path: String = "") -> Button:
	var button := Button.new()
	button.text = text
	if icon_path != "":
		button.icon = load(icon_path) as Texture2D
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 22)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.custom_minimum_size = Vector2(560, 38)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_button(button, 14)
	button.disabled = disabled
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _show_game_over() -> void:
	var died := GameManager.game_over_reason_key == "reason.death"
	var title := Loc.t("ui.death_title") if died else Loc.t("ui.world_end")
	var body := Loc.t("ui.death_end_body") if died else Loc.t("ui.world_end_body")
	var box := _open_modal(title, "gameover")
	_dialog_text(box, body, 16, C_GOLD)
	var stat_texts: Array[String] = []
	for key in STAT_ORDER:
		stat_texts.append("%s %d" % [Loc.stat_name(key), int(GameManager.stats[key])])
	_dialog_text(box, "  ·  ".join(stat_texts), 13)
	_dialog_text(box, Loc.tf("ui.world_end_summary", [GameManager.marks.size(), GameManager.choices_completed]), 13)
	_dialog_button(box, Loc.t("ui.new_run"), _on_new_run)


func _on_new_run() -> void:
	_close_modal()
	GameManager.new_game(0)
