class_name ReadingPanel
extends CanvasLayer

## Modal overlay that presents the end-of-run tarot reading.

var _panel: PanelContainer
var _heading: Label
var _body: Label
var _close: Button


func _ready() -> void:
	layer = 6
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(720, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#241b21f2")
	style.border_color = Color("#9d7951")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 22
	style.content_margin_bottom = 20
	_panel.add_theme_stylebox_override("panel", style)
	_panel.theme = UiFonts.build_ui_theme(19)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_panel.add_child(column)

	_heading = Label.new()
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heading.add_theme_font_size_override("font_size", 26)
	_heading.add_theme_color_override("font_color", Color("#d6ba8c"))
	column.add_child(_heading)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_color_override("font_color", Color("#ffebce"))
	column.add_child(_body)

	_close = Button.new()
	_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_close.pressed.connect(hide_reading)
	column.add_child(_close)

	hide_reading()


func show_reading(text: String) -> void:
	_heading.text = Loc.t("reading.title")
	_body.text = text
	_close.text = Loc.t("reading.close")
	visible = true


func hide_reading() -> void:
	visible = false
