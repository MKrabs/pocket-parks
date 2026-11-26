class_name Hud
extends CanvasLayer
# Top bar over the running day: clock, money, guests, happiness, speed, hiring. End-of-day card.

var sim: ParkSim
var speed := 1  # sim steps per tick of game time; 0 = paused
var day := 1

var _clock := ProgressBar.new()
var _day_label := _label(16)
var _money := _label(20)
var _guests := _label(16)
var _mood := _label(16)
var _card := PanelContainer.new()
var _card_text := _label(18)

func _ready() -> void:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", BuildBar.box(Palette.STONE, 20))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)

	var clock := VBoxContainer.new()
	clock.add_theme_constant_override("separation", 4)
	clock.alignment = BoxContainer.ALIGNMENT_CENTER
	clock.add_child(_day_label)
	_clock.custom_minimum_size = Vector2(120, 8)
	_clock.show_percentage = false
	_clock.max_value = ParkSim.DAY_TICKS
	_clock.add_theme_stylebox_override("background", _flat(Palette.CREAM))
	_clock.add_theme_stylebox_override("fill", _flat(Palette.BUTTER))
	clock.add_child(_clock)
	row.add_child(clock)
	for l in [_money, _guests, _mood]:
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", BuildBar.box(Palette.BUTTER if l == _money else Palette.CREAM))
		chip.add_child(l)
		row.add_child(chip)

	var group := ButtonGroup.new()
	for s in [[0, "Pause"], [1, "1×"], [3, "3×"]]:
		var b := _button(s[1], func() -> void: speed = s[0])
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = s[0] == speed
		b.custom_minimum_size = Vector2(44, 0)
		row.add_child(b)
	for kind: String in ParkSim.STAFF:
		row.add_child(_button("Hire %s\n$%d" % [kind, ParkSim.STAFF[kind]["hire"]], func() -> void: sim.hire(kind)))
	add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 16)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH

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

func _process(_delta: float) -> void:
	var r := sim.day_report()
	_day_label.text = "Day %d   %d s" % [day, ceili(ParkSim.DAY_TICKS / float(ParkSim.TPS) - sim.day_time())]
	_clock.value = sim.tick
	_money.text = "$ %d" % sim.money
	_guests.text = "Guests %d" % sim.guests.size()
	_mood.text = "Happy %d%%" % roundi(r["happiness"])
	var over := sim.tick >= ParkSim.DAY_TICKS
	if over and not _card.visible:
		_card_text.text = "Day %d is over\nIncome   $ %d\nGuests   %d\nHappiness   %d%%\nWages   $ %d" % [
			day, r["income"], r["guests"], roundi(r["happiness"]), r["wages"]]
		_card.reset_size()
		_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_card.visible = over

static func _label(size: int) -> Label:
	var l := Label.new()
	l.add_theme_color_override("font_color", Palette.INK)
	l.add_theme_font_size_override("font_size", size)
	return l

static func _flat(c: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(4)
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
