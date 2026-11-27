class_name CrimeToasts
extends CanvasLayer
# Toasts stacked top-right: newest on top, at most MAX, each vanishes (Motion.vanish) after LIFE seconds.
# A toast with an origin pans the camera there when clicked (`clicked`).

signal clicked(origin: Vector2i)

const MAX := 4
const LIFE := 6.0
const NO_ORIGIN := Vector2i(-1, -1)
const TOP := 90.0  # below the hud's top-right chips
var top := TOP  # main pushes this down while the presence chip shows, so toasts never cover it

var items: Array[Dictionary] = []  # {panel, sub, event, age}, newest first
var floor_y := INF  # toasts reaching below this are hidden (main sets it to the info card's top)
var _col := VBoxContainer.new()

func _ready() -> void:
	_col.add_theme_constant_override("separation", 8)
	_col.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	_col.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_col.position.y = TOP
	_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_col)

## A toast with a status glyph. `event` (a sim event) keeps its "Seen by a guard" line live.
func add(kind: String, text: String, origin := NO_ORIGIN, event := {}) -> void:
	var panel := PanelContainer.new()
	var box := BuildBar.box(Palette.CREAM, 16)
	box.border_color = Palette.shade(PinView.COLORS[kind], 0.1)
	panel.add_theme_stylebox_override("panel", box)
	panel.custom_minimum_size = Vector2(260, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(26, 26)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func() -> void:
		icon.draw_colored_polygon(Squircle.points(Vector2(13, 13), Vector2(13, 13), 4.0, 32), PinView.COLORS[kind])
		PinView.glyph(icon, kind, Vector2(13, 13), 1.0))
	row.add_child(icon)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(Hud._label(15))
	(col.get_child(0) as Label).text = text
	var sub := Hud._label(12)
	sub.modulate.a = 0.7
	sub.text = "Seen by a guard"
	sub.visible = event.get("witnessed", false)
	col.add_child(sub)
	row.add_child(col)
	panel.add_child(row)
	if origin != NO_ORIGIN:
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.gui_input.connect(func(e: InputEvent) -> void:
			var mb := e as InputEventMouseButton
			if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				clicked.emit(origin))
	_col.add_child(panel)
	_col.move_child(panel, 0)
	items.push_front({"panel": panel, "sub": sub, "event": event, "age": 0.0})
	while items.size() > MAX:
		_vanish(items.pop_back()["panel"])

func _process(delta: float) -> void:
	_col.position.y = top
	for t in items.duplicate():
		t["age"] += delta
		t["sub"].visible = t["event"].get("witnessed", false)
		var p: Control = t["panel"]
		p.visible = p.position.y + p.size.y + top + 8 <= floor_y
		if t["age"] >= LIFE:
			items.erase(t)
			_vanish(t["panel"])

func _vanish(panel: Control) -> void:
	panel.pivot_offset = panel.size * 0.5
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Motion.vanish(panel)
