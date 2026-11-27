class_name BuildBar
extends CanvasLayer
# Bottom bar: category tabs over one row of items. Building tabs filter the catalog by role; Staff hires.

signal picked(id: String)  # "" = back to Select (the pressed item was clicked again)
signal hire(kind: String)

const RADIUS := 14
const TABS := {"Paths": ["entrance", "path"], "Attractions": ["attraction"], "Shops": ["shop"], "Decor": ["decor"], "Staff": ["staff"]}
# Auto-hide (docs/design/game.md → Bottom bar), tuned by feel:
const HIDE_AFTER := 1.0  # s the mouse is away before the bar slides down
const NEAR := 70.0  # px from the bottom edge that bring it back up
const MARGIN := 16  # px between the bar and the bottom edge
const HANDLE := Vector2(60, 18)  # the tab left showing when hidden

var row := HBoxContainer.new()  # every item; only the current tab's are visible
var tabs := HBoxContainer.new()
var tab := "Paths"
var stolen: Array[String] = []  # blueprints spies brought home, offered in every theme
var map: ParkMap  # your park: shed items show when the park level caps them
var panel := PanelContainer.new()
var handle := Control.new()
var pin: Button
var shown := true
var pinned := false  # saved with the park (main.gd)
var placing := false  # an item is picked: a placement ghost is out
var _away := 0.0
var _visited := true  # the mouse came to the bar since it opened (one opened with B waits for it)
var _was_near := false
var _tween: Tween

## "More sheds at park level N" for ParkMap.shed_needs, "" when not blocked.
static func shed_text(needs: int) -> String:
	return "" if needs == 0 else "No more sheds" if needs < 0 else "More sheds at park level %d" % needs

## Placing or typing: the bar must stay up.
func busy() -> bool:
	return placing or get_viewport().gui_get_focus_owner() is LineEdit

## One frame of auto-hide: up when the mouse arrives near the bottom (or busy), down after HIDE_AFTER away.
func step(delta: float, mouse: Vector2, screen_h: float) -> void:
	if Engine.get_write_movie_path() != "":  # ./gd shot has no mouse: keep the bar up for screenshots
		return
	var near := mouse.y >= screen_h - NEAR or (shown and (panel.get_global_rect().grow(8).has_point(mouse)
		or handle.get_global_rect().has_point(mouse)))
	if (near and not _was_near) or (busy() and not shown):
		set_shown(true)
	_was_near = near
	_visited = _visited or near or busy()
	_away = 0.0 if near or busy() or pinned or not _visited else _away + delta
	if shown and _away >= HIDE_AFTER:
		set_shown(false)

## B or a click on the handle. A pinned or busy bar stays up.
func toggle() -> void:
	if not shown:
		set_shown(true)
		_visited = false
	elif not pinned and not busy():
		set_shown(false)

func set_shown(on: bool) -> void:
	if on == shown:
		return
	shown = on
	_away = 0.0
	if _tween:
		_tween.kill()
	_tween = Motion.glide(self, "offset:y", 0.0 if on else panel.size.y + MARGIN)
	handle.queue_redraw()

func _process(delta: float) -> void:
	step(delta, get_viewport().get_mouse_position(), get_viewport().get_visible_rect().size.y)
	handle.position = panel.position + Vector2((panel.size.x - HANDLE.x) / 2, 2 - HANDLE.y)
	# Shed items, fence styles and size variants wait for the park level: greyed, with the level that unlocks them.
	if not map:
		return
	for b: Button in row.get_children():
		var id: String = b.get_meta("id")
		if id == "":
			continue
		var why := shed_text(map.shed_needs(id))
		var text := why.replace(" at ", "\nat ")
		if map.opens_at(id) > 0:  # keep the name: a stepped-to fence or size says which one waits
			why = "Unlocks at park level %d" % map.opens_at(id)
			text = "%s\n%s" % [Buildings.get_def(id)["name"], why]
		b.disabled = why != ""
		b.text = text if why != "" else b.get_meta("text")

static func box(c: Color, radius: int = RADIUS) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(radius)
	s.corner_detail = 12
	s.set_content_margin_all(10)
	s.border_color = Palette.shade(c, 0.12)
	s.set_border_width_all(2)
	return s

## The handle: a small rounded tab on the bar's top edge with a chevron (up = open the bar, down = hide it).
func _draw_handle() -> void:
	var s := box(Palette.STONE, 9)
	s.corner_radius_bottom_left = 0
	s.corner_radius_bottom_right = 0
	handle.draw_style_box(s, Rect2(Vector2.ZERO, HANDLE + Vector2(0, 4)))
	var c := HANDLE / 2 + Vector2(0, -1)
	var d := 3.0 if shown else -3.0
	handle.draw_polyline([c + Vector2(-7, -d), c + Vector2(0, d), c + Vector2(7, -d)], Color(Palette.INK, 0.5), 2.5, true)

## Tab a building id belongs to ("" if none).
static func tab_of(id: String) -> String:
	for t: String in TABS:
		if Buildings.get_def(id)["role"] in TABS[t]:
			return t
	return ""

func _ready() -> void:
	picked.connect(func(id: String) -> void: placing = id != "")
	handle.size = HANDLE
	handle.draw.connect(_draw_handle)
	handle.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			toggle())
	add_child(handle)  # before the panel, so the panel covers its foot
	var bar := panel
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
	pin = Hud._button("", func() -> void: pass)
	pin.toggle_mode = true
	pin.button_pressed = pinned
	pin.tooltip_text = "Keep the bar open"
	pin.custom_minimum_size = Vector2(30, 0)
	pin.add_theme_stylebox_override("pressed", box(Palette.BUTTER, 10))
	pin.add_theme_stylebox_override("hover_pressed", box(Palette.BUTTER, 10))
	for k in ["normal", "hover", "pressed", "hover_pressed"]:
		(pin.get_theme_stylebox(k) as StyleBoxFlat).set_content_margin_all(5)
	pin.toggled.connect(func(on: bool) -> void: pinned = on)
	pin.draw.connect(func() -> void:  # a push pin seen from the side, tilted: cap, waist, flange, needle
		var dark := Palette.shade(Palette.CORAL, 0.22)
		pin.draw_set_transform(pin.size / 2 + Vector2(0, 1), deg_to_rad(35))
		pin.draw_line(Vector2(0, 2), Vector2(0, 9), Color(Palette.INK, 0.7), 1.6, true)
		pin.draw_colored_polygon(Squircle.points(Vector2(0, 1.5), Vector2(6, 1.5)), dark)  # flange
		pin.draw_colored_polygon(PackedVector2Array([Vector2(-2.5, -6), Vector2(2.5, -6), Vector2(3.5, 0.5), Vector2(-3.5, 0.5)]), Palette.CORAL)
		pin.draw_colored_polygon(Squircle.points(Vector2(0, -8), Vector2(4.5, 2.4)), Palette.CORAL)  # cap
		pin.draw_set_transform(Vector2.ZERO))
	tabs.add_child(pin)
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
	var ids: Array = Buildings.ids() + stolen.filter(func(s: String) -> bool: return not s in Buildings.ids())
	for id: String in ids:
		if Buildings.family(id)[0] != id and Buildings.family(id)[0] in ids:
			continue  # one button per family: the smallest variant's
		row.add_child(button(label(id), id, group))
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
		if b != pin:
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
## A size variant switches its family's item to it.
func pick(id: String) -> void:
	show_tab(tab_of(id))
	for b: Button in row.get_children():
		if b.get_meta("id") in Buildings.family(id):
			set_variant(b, id)
			b.button_pressed = true

static func label(id: String) -> String:
	var d := Buildings.get_def(id)
	return "%s\n$%d%s" % [d["name"], d["cost"], " / cell" if d.has("habitat") else ""]

## Show variant `id` on item `b`; a pressed item swaps the placement ghost (picked(id)).
func set_variant(b: Button, id: String) -> void:
	if b.get_meta("id") == id:
		return
	b.set_meta("id", id)
	b.set_meta("text", label(id))
	b.text = label(id)
	if b.button_pressed:
		picked.emit(id)

## The pressed item's variant number `i` (1/2/3 while placing). False if nothing is pressed or no such variant.
func variant(i: int) -> bool:
	for b: Button in row.get_children():
		var fam := Buildings.family(b.get_meta("id"))
		if b.button_pressed and i < fam.size():
			set_variant(b, fam[i])
			return true
	return false

## ‹ (dir -1) or › (dir 1) on item `b`: the next smaller or bigger variant, wrapping.
func step_variant(b: Button, dir: int) -> void:
	var fam := Buildings.family(b.get_meta("id"))
	set_variant(b, fam[posmod(fam.find(b.get_meta("id")) + dir, fam.size())])

## A small chevron on the item's left (dir -1) or right edge (dir 1) that steps the variant.
func arrow(b: Button, dir: int) -> Control:
	var a := Control.new()
	a.size = Vector2(18, 28)
	a.set_anchors_preset(Control.PRESET_CENTER_LEFT if dir < 0 else Control.PRESET_CENTER_RIGHT)
	a.position = Vector2(3 if dir < 0 else -21, -14)
	a.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	a.tooltip_text = "Smaller" if dir < 0 else "Bigger"
	a.draw.connect(func() -> void:
		var c := a.size / 2
		var ink := Color(Palette.INK, 0.6)
		a.draw_polyline([c + Vector2(3 * -dir, -5), c + Vector2(3 * dir, 0), c + Vector2(3 * -dir, 5)], ink, 2.5, true))
	a.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			a.accept_event()
			step_variant(b, dir))
	return a

func button(text: String, id: String, group: ButtonGroup) -> Button:
	var b := Hud._button(text, func() -> void: pass)
	b.toggle_mode = true
	b.button_group = group
	b.custom_minimum_size = Vector2(96, 0)
	b.add_theme_stylebox_override("disabled", box(Palette.STONE))
	if Buildings.family(id).size() > 1:
		for k in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			(b.get_theme_stylebox(k) as StyleBoxFlat).content_margin_left = 22
			(b.get_theme_stylebox(k) as StyleBoxFlat).content_margin_right = 22
		b.add_child(arrow(b, -1))
		b.add_child(arrow(b, 1))
	b.set_meta("id", id)
	b.set_meta("text", text)
	b.add_theme_color_override("font_disabled_color", Color(Palette.INK, 0.55))
	b.set_meta("tab", tab_of(id))
	var need := Specialties.required(id)
	if need != "":  # specialist-only: the specialty's glyph in the top-right corner
		var g := Control.new()
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		g.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		g.draw.connect(func() -> void: Specialties.glyph(g, Vector2(-5, 5), need, 8.0))
		b.add_child(g)
		b.tooltip_text = "Needs a %s builder" % Specialties.ALL[need]["name"]
	b.toggled.connect(func(on: bool) -> void:
		if on:
			picked.emit(b.get_meta("id"))
		elif group.get_pressed_button() == null:
			picked.emit(""))
	return b
