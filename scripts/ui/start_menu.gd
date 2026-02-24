extends CanvasLayer

signal start_pressed
signal world_pressed
signal quit_pressed

const NORMAL_COLOR := Color(0.85, 0.85, 0.85, 1.0)
const SELECTED_COLOR := Color(1.0, 0.85, 0.0, 1.0)

# Fractions of viewport height — scale-factor-agnostic.
# Works correctly regardless of window/stretch/scale in project.godot.
const _TITLE_FRAC: float = 0.08   # title font  ≈ 8 % of viewport height
const _ITEM_FRAC: float  = 0.055  # item font   ≈ 5.5 %
const _SEP_FRAC: float   = 0.03   # vbox gap    ≈ 3 %
const _SPACE_FRAC: float = 0.02   # title spacer ≈ 2 %
const _WIDTH_FRAC: float = 0.35   # item min-width ≈ 35 %

var _selected_index: int = 0
var _items: Array[Label] = []


func _ready() -> void:
	layer = 10
	_build_ui()
	_update_highlight()


func _build_ui() -> void:
	var vh := get_viewport().get_visible_rect().size.y

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.72)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", maxi(2, int(vh * _SEP_FRAC)))
	center.add_child(vbox)

	var title := Label.new()
	title.text = "NEWBIE GAME"
	title.add_theme_font_size_override("font_size", maxi(8, int(vh * _TITLE_FRAC)))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.modulate = Color(1.0, 0.9, 0.35, 1.0)
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, maxf(2.0, vh * _SPACE_FRAC))
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)

	var label_start := _make_item("Start", vh)
	var label_world := _make_item("World", vh)
	var label_options := _make_item("Options", vh)
	var label_quit := _make_item("Quit", vh)
	vbox.add_child(label_start)
	vbox.add_child(label_world)
	vbox.add_child(label_options)
	vbox.add_child(label_quit)
	_items = [label_start, label_world, label_options, label_quit]


func _make_item(text: String, vh: float) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", maxi(6, int(vh * _ITEM_FRAC)))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(maxf(60.0, vh * _WIDTH_FRAC), 0.0)
	label.modulate = NORMAL_COLOR
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _update_highlight() -> void:
	for i: int in _items.size():
		_items[i].modulate = SELECTED_COLOR if i == _selected_index else NORMAL_COLOR


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_up") and not event.is_echo():
		_selected_index = (_selected_index - 1 + _items.size()) % _items.size()
		_update_highlight()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") and not event.is_echo():
		_selected_index = (_selected_index + 1) % _items.size()
		_update_highlight()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_confirm_selection()
	elif event is InputEventMouseMotion:
		_check_mouse_hover(event.position)
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			_check_mouse_click(event.position)


func _check_mouse_hover(mouse_pos: Vector2) -> void:
	for i: int in _items.size():
		var rect := _items[i].get_global_rect()
		if rect.has_point(mouse_pos):
			if _selected_index != i:
				_selected_index = i
				_update_highlight()
			return


func _check_mouse_click(mouse_pos: Vector2) -> void:
	for i: int in _items.size():
		if _items[i].get_global_rect().has_point(mouse_pos):
			_selected_index = i
			_update_highlight()
			_confirm_selection()
			return


func _confirm_selection() -> void:
	match _selected_index:
		0:
			start_pressed.emit()
		1:
			world_pressed.emit()
		2:
			pass  # Options — not yet implemented
		3:
			quit_pressed.emit()


func set_resume_mode(enabled: bool) -> void:
	_items[0].text = "Resume" if enabled else "Start"


func show_menu() -> void:
	visible = true
	_selected_index = 0
	_update_highlight()


func hide_menu() -> void:
	visible = false
