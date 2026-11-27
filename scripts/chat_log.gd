class_name ChatLog
extends CanvasLayer
# Chat (M5): the last KEEP lines bottom-left, above the speed buttons, names in their colour. Each line fades out
# after FADE_AFTER s; all of them show again while you type. Enter opens the input (main), Enter sends, Esc cancels.

signal typed(text: String)

const KEEP := 6
const FADE_AFTER := 10.0
const FADE_TIME := 1.0
const MARGIN := 16
const ABOVE := 76  # px from the bottom: clears the speed buttons

var lines: Array[Dictionary] = []  # {name, color, text}, oldest first
var input := LineEdit.new()
var _box := VBoxContainer.new()

func _ready() -> void:
	_box.add_theme_constant_override("separation", 4)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	_box.anchor_top = 1.0
	_box.anchor_bottom = 1.0
	_box.offset_left = MARGIN
	_box.offset_bottom = -ABOVE
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	input.max_length = Net.SAY_MAX
	input.placeholder_text = "Say something"
	input.custom_minimum_size = Vector2(320, 0)
	input.add_theme_font_size_override("font_size", 14)
	for k in ["font_color", "font_placeholder_color", "caret_color"]:
		input.add_theme_color_override(k, Palette.INK if k != "font_placeholder_color" else Palette.shade(Palette.STONE, 0.3))
	for k in ["normal", "focus"]:
		input.add_theme_stylebox_override(k, BuildBar.box(Palette.CLOUD))
	input.text_submitted.connect(func(t: String) -> void:
		close()
		if t.strip_edges() != "":
			typed.emit(t))
	input.gui_input.connect(func(e: InputEvent) -> void:
		var k := e as InputEventKey
		if k and k.pressed and k.physical_keycode == KEY_ESCAPE:
			close()
			input.accept_event())
	input.hide()
	_box.add_child(input)

## Show the input and focus it: from here on keys go to the line, not the hotkeys.
func open() -> void:
	input.text = ""
	input.show()
	input.grab_focus()
	for c in _box.get_children():
		c.modulate.a = 1.0

func close() -> void:
	input.release_focus()
	input.hide()
	for c in _box.get_children():
		if c != input:
			_fade(c)

func typing() -> bool:
	return input.visible

## A line said in the park on screen: into the log (last KEEP kept), and a row that fades out later.
func add(name: String, color: Color, text: String) -> void:
	lines.append({"name": name, "color": color, "text": text})
	if lines.size() > KEEP:
		lines.remove_at(0)
	if not is_inside_tree():
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	var st := BuildBar.box(Color(Palette.CLOUD, 0.85), 10)
	st.set_content_margin_all(4)
	st.content_margin_left = 8
	st.content_margin_right = 8
	st.border_color = Color(Palette.INK, 0.08)
	panel.add_theme_stylebox_override("panel", st)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var who := Hud._label(13)
	who.add_theme_font_override("font", Palette.FONT_BOLD)
	who.add_theme_color_override("font_color", Palette.shade(color, 0.35))
	who.text = name
	var what := Hud._label(13)
	what.text = text
	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	inner.add_child(who)
	inner.add_child(what)
	panel.add_child(inner)
	row.add_child(panel)
	_box.add_child(row)
	_box.move_child(input, -1)
	while _box.get_child_count() > KEEP + 1:
		_box.get_child(0).free()
	_fade(row)

## Fade `row` out after FADE_AFTER s, unless the input is open by then (a newer call takes over).
func _fade(row: Control) -> void:
	if row.has_meta("fade"):
		(row.get_meta("fade") as Tween).kill()
	var t := row.create_tween()
	t.tween_interval(FADE_AFTER)
	t.tween_callback(func() -> void:
		if typing():
			t.kill()
		else:
			row.modulate.a = 1.0)
	t.tween_property(row, "modulate:a", 0.0, FADE_TIME)
	row.set_meta("fade", t)
