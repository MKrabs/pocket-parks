class_name Hud
extends CanvasLayer
# Screen corners over the running day. Top-left: park name, level badge, day bar. Top-right: money,
# guests, mood face. Bottom-left: pause / play / fast. Bottom-right: Visit. Plus the end-of-day card.

signal visit_pressed
signal new_park  # F9's card, confirmed

const MARGIN := 16
const SPEEDS := [0, 1, 3]
const VISIT_SIZE := 96.0

var sim: ParkSim
var speed := 1  # sim steps per tick of game time; 0 = paused
var day := 1
var level := 1
var progress := 0.0  # 0..1 of the way to the next level (park level comes in L1)

var park_name := _label(20)
var guests := _label(18)
var money := _label(20)
var mood := 0  # 1 happy, 0 neutral, -1 sad (drawn as a face)
var speed_buttons: Array[Button] = []
var visit: Button
var _clock := ProgressBar.new()
var _day_label := _label(13)
var _badge := Control.new()
var _face := Control.new()
var _chip: PanelContainer  # the money chip
var _shown := 0.0  # money the chip shows while it counts to sim.money
var _target := 0
var _count: Tween
var _bounced := -INF
var _time := 0.0
var _card := PanelContainer.new()
var _card_text := _label(18)
var _xp := -1  # sim.xp the badge last drew
var level_card := PanelContainer.new()
var _level_text := _label(16)
var _level_title := _label(24)
var new_card := PanelContainer.new()  # F9: start a new park?
var blacklist_open := false  # the Blacklist chip under the park name, unfolded
var _bl := VBoxContainer.new()
var _bl_drawn: Array = []  # [open, ban_days, blacklist] it was last built for

## Mood face for an average happiness (0..100).
static func face_for(happiness: float) -> int:
	return 1 if happiness >= 60.0 else (0 if happiness >= 35.0 else -1)

## Park level on the badge; `p` fills its ring (0..1).
func set_level(lv: int, p: float) -> void:
	level = lv
	progress = clampf(p, 0.0, 1.0)
	_badge.queue_redraw()

func _ready() -> void:
	_target = sim.money
	_shown = sim.money
	park_name.text = "Pocket Zoo"

	# top-left: badge, name, day bar
	var left := _panel()
	var lrow := HBoxContainer.new()
	lrow.add_theme_constant_override("separation", 12)
	_badge.custom_minimum_size = Vector2(48, 48)
	_badge.draw.connect(_draw_badge)
	lrow.add_child(_badge)
	var lcol := VBoxContainer.new()
	lcol.add_theme_constant_override("separation", 4)
	lcol.alignment = BoxContainer.ALIGNMENT_CENTER
	lcol.add_child(park_name)
	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 8)
	_clock.custom_minimum_size = Vector2(110, 6)
	_clock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_clock.show_percentage = false
	_clock.max_value = ParkSim.DAY_TICKS
	_clock.add_theme_stylebox_override("background", _flat(Palette.CREAM))
	_clock.add_theme_stylebox_override("fill", _flat(Palette.BUTTER))
	drow.add_child(_clock)
	_day_label.modulate.a = 0.7
	drow.add_child(_day_label)
	lcol.add_child(drow)
	lrow.add_child(lcol)
	left.add_child(lrow)
	var tl := VBoxContainer.new()
	tl.add_theme_constant_override("separation", 8)
	tl.add_child(left)
	var bl := _panel()
	bl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_bl.add_theme_constant_override("separation", 6)
	bl.add_child(_bl)
	tl.add_child(bl)
	add_child(tl)
	tl.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, MARGIN)

	# top-right: money, guests, mood
	var right := _panel()
	var rrow := HBoxContainer.new()
	rrow.add_theme_constant_override("separation", 8)
	_chip = _chip_of(Palette.BUTTER, [money])
	rrow.add_child(_chip)
	rrow.add_child(_chip_of(Palette.CREAM, [_icon(Vector2(18, 26), _draw_person), guests]))
	_face.custom_minimum_size = Vector2(28, 28)
	_face.draw.connect(_draw_face)
	rrow.add_child(_chip_of(Palette.CREAM, [_face]))
	right.add_child(rrow)
	add_child(right)
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, MARGIN)
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN

	# bottom-left: speed
	var speeds := _panel()
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 6)
	var group := ButtonGroup.new()
	for s: int in SPEEDS:
		var b := _button("", func() -> void: speed = s)
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = s == speed
		b.custom_minimum_size = Vector2(40, 36)
		b.draw.connect(_draw_speed.bind(b, s))
		speed_buttons.append(b)
		srow.add_child(b)
	speeds.add_child(srow)
	add_child(speeds)
	speeds.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, MARGIN)
	speeds.grow_vertical = Control.GROW_DIRECTION_BEGIN

	# bottom-right: Visit, a big round button with a cloud
	visit = _button("Visit", visit_pressed.emit)
	for k in ["normal", "hover", "pressed", "hover_pressed"]:
		var st := BuildBar.box(Palette.shade(Palette.BUTTER, 0.04) if k == "hover" else Palette.BUTTER, int(VISIT_SIZE * 0.42))
		st.content_margin_top = 46
		visit.add_theme_stylebox_override(k, st)
	visit.add_theme_font_size_override("font_size", 18)
	visit.custom_minimum_size = Vector2.ONE * VISIT_SIZE
	var cloud := Puff.new()
	cloud.size = 44
	cloud.position = Vector2(VISIT_SIZE * 0.5, 30)
	visit.add_child(cloud)
	add_child(visit)
	visit.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, MARGIN)
	visit.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	visit.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var card_box := BuildBar.box(Palette.CREAM, 20)
	card_box.set_content_margin_all(22)
	_card.add_theme_stylebox_override("panel", card_box)
	_card.custom_minimum_size = Vector2(240, 0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.add_child(_card_text)
	col.add_child(_button("Next day", func() -> void:
		sim.new_day()
		day += 1))
	_card.add_child(col)
	add_child(_card)
	_card.hide()

	var lbox := BuildBar.box(Palette.BUTTER, 20)
	lbox.set_content_margin_all(18)
	level_card.add_theme_stylebox_override("panel", lbox)
	level_card.custom_minimum_size = Vector2(220, 0)
	var lc := VBoxContainer.new()
	lc.add_theme_constant_override("separation", 8)
	_level_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lc.add_child(_level_title)
	lc.add_child(_level_text)
	lc.add_child(_button("Nice", func() -> void: Motion.vanish(level_card, false).finished.connect(level_card.hide)))
	level_card.add_child(lc)
	add_child(level_card)
	level_card.hide()
	level = ParkLevel.of(sim.xp)

	var nbox := BuildBar.box(Palette.CREAM, 20)
	nbox.set_content_margin_all(22)
	new_card.add_theme_stylebox_override("panel", nbox)
	var nc := VBoxContainer.new()
	nc.add_theme_constant_override("separation", 12)
	var ask := _label(18)
	ask.text = "Start a new park?\nThis one is gone for good."
	ask.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nc.add_child(ask)
	var nrow := HBoxContainer.new()
	nrow.add_theme_constant_override("separation", 8)
	nrow.add_child(_button("Keep playing", new_card.hide))
	nrow.add_child(_button("New park", new_park.emit))
	nc.add_child(nrow)
	new_card.add_child(nc)
	add_child(new_card)
	new_card.hide()

func _process(delta: float) -> void:
	_time += delta
	if sim.money != _target:  # count to the new value; bounce at most once per MONEY_EVERY
		_target = sim.money
		if _count:
			_count.kill()
		_count = create_tween()
		_count.tween_property(self, "_shown", float(_target), Motion.COUNT_TIME).set_ease(Tween.EASE_OUT)
		if _time - _bounced >= Motion.MONEY_EVERY:
			_bounced = _time
			_chip.pivot_offset = _chip.size * 0.5
			Motion.bounce(_chip)
	if sim.xp != _xp:
		_xp = sim.xp
		var lv := ParkLevel.of(sim.xp)
		if lv > level:
			_level_up(lv)
		set_level(lv, ParkLevel.progress(sim.xp))
	var r := sim.day_report()
	_day_label.text = "Day %d" % day
	_clock.value = sim.tick
	money.text = "$ %d" % roundi(_shown)
	guests.text = str(sim.guests.size())
	var m := face_for(r["happiness"]) if sim.guests.size() > 0 else 1
	if m != mood:
		mood = m
		_face.queue_redraw()
	var over := sim.tick >= ParkSim.DAY_TICKS
	if over and not _card.visible:
		_card_text.text = "Day %d is over\nIncome   $ %d\nGuests   %d\nHappiness   %d%%\nWages   $ %d" % [
			day, r["income"], r["guests"], roundi(r["happiness"]), r["wages"]]
		_card.reset_size()
		_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_card.visible = over
	var now := [blacklist_open, sim.ban_days, sim.blacklist.duplicate()]
	if now != _bl_drawn:
		_bl_drawn = now
		_fill_blacklist()

## The Blacklist chip: folded, its name and count; unfolded, the guard-catch default and each name with days left
## and a Lift button (docs/design/game.md → Visiting in person).
func _fill_blacklist() -> void:
	for c in _bl.get_children():
		_bl.remove_child(c)
		c.queue_free()
	var n := sim.blacklist.size()
	var head := _button("Blacklist · %d" % n if n > 0 else "Blacklist", func() -> void: blacklist_open = not blacklist_open)
	head.add_theme_font_size_override("font_size", 14)
	_bl.add_child(head)
	if not blacklist_open:
		return
	var def := HBoxContainer.new()
	def.add_theme_constant_override("separation", 6)
	var l := _label(14)
	l.text = "Guard catches: %d day%s" % [sim.ban_days, "" if sim.ban_days == 1 else "s"]
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	def.add_child(l)
	def.add_child(_button("−", func() -> void: sim.ban_days = maxi(sim.ban_days - 1, 1)))
	def.add_child(_button("+", func() -> void: sim.ban_days = mini(sim.ban_days + 1, ParkSim.BAN_MAX)))
	_bl.add_child(def)
	if n == 0:
		var none := _label(14)
		none.text = "Nobody is banned"
		none.modulate.a = 0.7
		_bl.add_child(none)
	for who: String in sim.blacklist:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var w := _label(14)
		var d: int = sim.blacklist[who]
		w.text = "%s · %d day%s left" % [who, d, "" if d == 1 else "s"]
		w.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(w)
		row.add_child(_button("Lift", func() -> void: sim.blacklist.erase(who)))
		_bl.add_child(row)

## F9: the small "start a new park?" card in the centre.
func confirm_new_park() -> void:
	new_card.show()
	new_card.reset_size()
	new_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	new_card.pivot_offset = new_card.size * 0.5
	Motion.pop(new_card)

## Badge pops; the "Level up!" card drops in at the top centre listing what `lv` unlocks.
func _level_up(lv: int) -> void:
	_badge.pivot_offset = _badge.size * 0.5
	Motion.bounce(_badge)
	_level_title.text = "Level up!"
	var lines := ["Park level %d" % lv]
	lines.append_array(ParkLevel.describe(lv))
	_level_text.text = "\n".join(lines)
	level_card.modulate.a = 1.0
	level_card.show()
	level_card.reset_size()
	level_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, MARGIN * 6)
	level_card.pivot_offset = level_card.size * 0.5
	Motion.pop(level_card)

## Money in (amount > 0): a BUTTER coin flies from `screen` to the chip. Out: a CORAL coin flies from it to `screen`.
func coin_fly(screen: Vector2, amount: int) -> void:
	var chip := _chip.get_global_rect().get_center()
	var c := Feedback.coin(Palette.BUTTER if amount > 0 else Palette.CORAL)
	c.position = screen if amount > 0 else chip
	add_child(c)
	Motion.pop(c)
	Motion.fly_to(c, chip if amount > 0 else screen, func() -> void: Motion.vanish(c))

func _draw_badge() -> void:
	var c := _badge.size * 0.5
	var ring := Squircle.points(c, c - Vector2(2, 2), 4.0, 48)
	_badge.draw_colored_polygon(ring, Palette.CREAM)
	ring.append(ring[0])
	_badge.draw_polyline(ring, Palette.shade(Palette.STONE, 0.12), 4.0, true)
	if progress > 0.0:  # clockwise from the top
		var steps := 48
		var part := ring.slice(0, 0)
		for i in roundi(steps * progress) + 1:
			part.append(ring[(i + steps * 3 / 4) % steps])
		_badge.draw_polyline(part, Palette.shade(Palette.BUTTER, 0.22), 4.0, true)
	var font := Palette.FONT
	var t := "Lv %d" % level
	var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	_badge.draw_string(font, c + Vector2(-w * 0.5, 5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Palette.INK)

func _draw_face() -> void:
	var c := _face.size * 0.5
	var col: Color = [Palette.CORAL, Palette.STONE, Palette.BUTTER][mood + 1]
	_face.draw_colored_polygon(Squircle.points(c, Vector2(13, 13), 3.2, 40), Palette.shade(col, 0.12))
	_face.draw_colored_polygon(Squircle.points(c, Vector2(11.5, 11.5), 3.2, 40), col)
	var ink := Color(Palette.INK, 0.85)
	for x in [-4.5, 4.5]:
		_face.draw_colored_polygon(Squircle.points(c + Vector2(x, -3), Vector2(1.6, 2.0), 3.0, 12), ink)
	var mouth := PackedVector2Array()
	for i in 9:
		var x := (i / 8.0 - 0.5) * 10.0
		mouth.append(c + Vector2(x, 4.0 + mood * (2.5 - x * x / 10.0)))
	_face.draw_polyline(mouth, ink, 1.8, true)

func _draw_person(ci: Control) -> void:
	var c := ci.size * 0.5
	var ink := Palette.shade(Palette.SKY, 0.3)
	ci.draw_colored_polygon(Squircle.points(c + Vector2(0, -5), Vector2(4.5, 4.5), 3.0, 24), ink)
	ci.draw_colored_polygon(Squircle.points(c + Vector2(0, 8), Vector2(7.5, 5), 3.0, 24), ink)

func _draw_speed(b: Button, s: int) -> void:
	var c := b.size * 0.5
	var ink := Color(Palette.INK, 0.85)
	match s:
		0:
			for x in [-3.5, 3.5]:
				b.draw_colored_polygon(Squircle.points(c + Vector2(x, 0), Vector2(2.2, 7), 4.0, 20), ink)
		1:
			b.draw_colored_polygon(_tri(c + Vector2(1.5, 0), 7.0), ink)
		_:
			for x in [-4.0, 4.0]:
				b.draw_colored_polygon(_tri(c + Vector2(x, 0), 6.0), ink)

## A play triangle pointing right with softened corners, centred on `at`, about 2r tall.
static func _tri(at: Vector2, r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var k := r * 0.25
	for p: Vector2 in [Vector2(-0.6, -1), Vector2(0.9, 0), Vector2(-0.6, 1)]:
		out.append(at + p * r + (-p.normalized()) * k)
	return out

static func _icon(min_size: Vector2, f: Callable) -> Control:
	var c := Control.new()
	c.custom_minimum_size = min_size
	c.draw.connect(func() -> void: f.call(c))
	return c

static func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	var st := BuildBar.box(Palette.STONE, 20)
	st.set_content_margin_all(8)
	p.add_theme_stylebox_override("panel", st)
	return p

static func _chip_of(c: Color, kids: Array) -> PanelContainer:
	var chip := PanelContainer.new()
	var st := BuildBar.box(c)
	st.content_margin_top = 6
	st.content_margin_bottom = 6
	chip.add_theme_stylebox_override("panel", st)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for k: Control in kids:
		k.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(k)
	chip.add_child(row)
	return chip

static func _label(size: int) -> Label:
	var l := Label.new()
	l.add_theme_color_override("font_color", Palette.INK)
	l.add_theme_font_size_override("font_size", size)
	return l

static func _flat(c: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(3)
	s.corner_detail = 6
	return s

static func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", BuildBar.box(Palette.CREAM))
	b.add_theme_stylebox_override("hover", BuildBar.box(Palette.shade(Palette.CREAM, 0.04)))
	b.add_theme_stylebox_override("pressed", BuildBar.box(Palette.SKY))
	b.add_theme_stylebox_override("hover_pressed", BuildBar.box(Palette.SKY))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, Palette.INK)
	b.pressed.connect(on_press)
	return b
