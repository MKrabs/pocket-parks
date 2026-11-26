class_name BuildBar
extends CanvasLayer
# Bottom bar: category tabs over one row of items. Building tabs filter the catalog by role; Staff hires.

signal picked(id: String)  # "" = back to Select (the pressed item was clicked again)
signal hire(kind: String)

const RADIUS := 14
const TABS := {"Paths": ["entrance", "path"], "Attractions": ["attraction"], "Shops": ["shop"], "Decor": ["decor"], "Staff": ["staff"]}

var row := HBoxContainer.new()  # every item; only the current tab's are visible
var tabs := HBoxContainer.new()
var tab := "Paths"
var stolen: Array[String] = []  # blueprints spies brought home, offered in every theme

static func box(c: Color, radius: int = RADIUS) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(radius)
	s.corner_detail = 12
	s.set_content_margin_all(10)
	s.border_color = Palette.shade(c, 0.12)
	s.set_border_width_all(2)
	return s

## Tab a building id belongs to ("" if none).
static func tab_of(id: String) -> String:
	for t: String in TABS:
		if Buildings.get_def(id)["role"] in TABS[t]:
			return t
	return ""

func _ready() -> void:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", box(Palette.STONE, 20))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	tabs.add_theme_constant_override("separation", 4)
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	var group := ButtonGroup.new()
	for t: String in TABS:
		var b := Hud._button(t, show_tab.bind(t))
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = t == tab
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_stylebox_override("pressed", box(Palette.BUTTER, 10))
		b.add_theme_stylebox_override("hover_pressed", box(Palette.BUTTER, 10))
		for k in ["normal", "hover", "pressed", "hover_pressed"]:
			(b.get_theme_stylebox(k) as StyleBoxFlat).set_content_margin_all(5)
			(b.get_theme_stylebox(k) as StyleBoxFlat).content_margin_left = 12
			(b.get_theme_stylebox(k) as StyleBoxFlat).content_margin_right = 12
		b.set_meta("tab", t)
		tabs.add_child(b)
	col.add_child(tabs)
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)
	bar.add_child(col)
	add_child(bar)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	fill()

## (Re)build the items for the active theme, none pressed (Select mode).
func fill() -> void:
	for c in row.get_children():
		row.remove_child(c)
		c.queue_free()
	var group := ButtonGroup.new()
	group.allow_unpress = true
	for id: String in Buildings.ids() + stolen.filter(func(s: String) -> bool: return not s in Buildings.ids()):
		var b: Dictionary = Buildings.get_def(id)
		row.add_child(button("%s\n$%d" % [b["name"], b["cost"]], id, group))
	for kind: String in ParkSim.STAFF:
		var h := Hud._button("Hire %s\n$%d" % [kind, ParkSim.STAFF[kind]["hire"]], hire.emit.bind(kind))
		h.custom_minimum_size = Vector2(96, 0)
		h.set_meta("id", "")
		h.set_meta("tab", "Staff")
		row.add_child(h)
	picked.emit("")
	show_tab(tab)

## Show one tab's items; an item pressed on another tab is let go (back to Select).
func show_tab(t: String) -> void:
	tab = t
	for b: Button in tabs.get_children():
		b.set_pressed_no_signal(b.get_meta("tab") == t)
	for b: Button in row.get_children():
		b.visible = b.get_meta("tab") == t
		if not b.visible and b.button_pressed:
			b.button_pressed = false
	var bar := row.get_parent().get_parent() as Control
	if bar.is_inside_tree():
		bar.reset_size()
		bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 16)

## Ids on the current tab (hire buttons count as "").
func visible_ids() -> Array:
	return row.get_children().filter(func(b: Button) -> bool: return b.visible).map(func(b: Button) -> String: return b.get_meta("id"))

## Back to Select: unpress whatever item is pressed (emits picked("")).
func clear() -> void:
	for b: Button in row.get_children():
		b.button_pressed = false

## Press the item for `id` (emits picked(id)), as a click on it would; its tab opens first.
func pick(id: String) -> void:
	show_tab(tab_of(id))
	for b: Button in row.get_children():
		if b.get_meta("id") == id:
			b.button_pressed = true

func button(text: String, id: String, group: ButtonGroup) -> Button:
	var b := Hud._button(text, func() -> void: pass)
	b.toggle_mode = true
	b.button_group = group
	b.custom_minimum_size = Vector2(96, 0)
	b.set_meta("id", id)
	b.set_meta("tab", tab_of(id))
	b.toggled.connect(func(on: bool) -> void:
		if on:
			picked.emit(id)
		elif group.get_pressed_button() == null:
			picked.emit(""))
	return b
