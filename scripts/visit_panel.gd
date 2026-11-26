class_name VisitPanel
extends CanvasLayer
# Visiting UI: the picker of nearby parks, and while visiting the Send panel with the ledger strip and Back home.

signal picked(offer: Dictionary)
signal sent(kind: String)
signal home
signal join_address(text: String)

var last_address := ""  # the last address typed into Join, for this session
var _picker := PanelContainer.new()
var _choices := VBoxContainer.new()
var _send := PanelContainer.new()
var _title := Hud._label(18)
var _ledger := Hud._label(15)

func _ready() -> void:
	var pbox := BuildBar.box(Palette.CREAM, 20)
	pbox.set_content_margin_all(20)
	_picker.add_theme_stylebox_override("panel", pbox)
	_choices.add_theme_constant_override("separation", 10)
	_picker.add_child(_choices)
	add_child(_picker)
	_picker.hide()

	_send.add_theme_stylebox_override("panel", BuildBar.box(Palette.STONE, 20))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	top.add_child(_title)
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", BuildBar.box(Palette.CREAM))
	chip.add_child(_ledger)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(chip)
	col.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for kind: String in Visit.PRICES:
		var b := Hud._button("Send %s\n$%d" % [kind, Visit.PRICES[kind]], sent.emit.bind(kind))
		b.custom_minimum_size = Vector2(96, 0)
		row.add_child(b)
	var back := Hud._button("Back\nhome", home.emit)
	back.add_theme_stylebox_override("normal", BuildBar.box(Palette.BUTTER))
	back.add_theme_stylebox_override("hover", BuildBar.box(Palette.shade(Palette.BUTTER, 0.04)))
	back.custom_minimum_size = Vector2(84, 0)
	row.add_child(back)
	col.add_child(row)
	_send.add_child(col)
	add_child(_send)
	_send.hide()

## Show the picker: real parks on the network (with a live dot), the join-by-address field and `own` (our address
## for a friend to type), then the bot parks, plus Cancel.
func open(offers: Array[Dictionary], nearby: Array[Dictionary] = [], own := "") -> void:
	for c in _choices.get_children():
		c.queue_free()
	var head := Hud._label(18)
	head.text = "Visit a park"
	_choices.add_child(head)
	_choices.add_child(_section("Nearby"))
	for o in nearby:
		var b := _choice(o, "%s\n%s · %s" % [o["name"], o["player"], o["theme"]])
		b.draw.connect(func() -> void:  # live dot just left of the park name
			var f := b.get_theme_font("font")
			var fs := b.get_theme_font_size("font_size")
			var w := f.get_string_size(o["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var at := Vector2((b.size.x - w) / 2 - 12, b.size.y / 2 - f.get_height(fs) / 2)
			b.draw_colored_polygon(Squircle.points(at, Vector2(7, 7), 4.0, 24), Palette.GRASS)
			b.draw_colored_polygon(Squircle.points(at, Vector2(4.5, 4.5), 4.0, 24), Palette.MOSS))
	if nearby.is_empty():
		var none := Hud._label(14)
		none.text = "No parks on your network yet"
		none.modulate.a = 0.6
		_choices.add_child(none)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var field := LineEdit.new()
	field.placeholder_text = "Join by address"
	field.text = last_address
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_theme_font_size_override("font_size", 14)
	for k in ["font_color", "font_placeholder_color", "caret_color"]:
		field.add_theme_color_override(k, Palette.INK if k != "font_placeholder_color" else Palette.shade(Palette.STONE, 0.3))
	for k in ["normal", "focus"]:
		field.add_theme_stylebox_override(k, BuildBar.box(Palette.STONE if k == "normal" else Palette.SKY))
	var go := func() -> void:
		last_address = field.text.strip_edges()
		_picker.hide()
		join_address.emit(last_address)
	field.text_submitted.connect(func(_t: String) -> void: go.call())
	row.add_child(field)
	row.add_child(Hud._button("Join", go))
	_choices.add_child(row)
	var mine := Hud._label(13)
	mine.text = "Your park: %s" % (own if own != "" else "not on a network")
	mine.modulate.a = 0.7
	_choices.add_child(mine)
	_choices.add_child(_section("Bot parks"))
	for o in offers:
		_choice(o, "%s\n%s · %d guards" % [o["name"], o["theme"], o["guards"]])
	_choices.add_child(Hud._button("Cancel", _picker.hide))
	_picker.show()
	_picker.reset_size()
	_picker.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)

func _choice(o: Dictionary, text: String) -> Button:
	var b := Hud._button(text, func() -> void:
		_picker.hide()
		picked.emit(o))
	b.custom_minimum_size = Vector2(220, 0)
	_choices.add_child(b)
	return b

func _section(text: String) -> Label:
	var l := Hud._label(13)
	l.text = text
	l.modulate.a = 0.7
	return l

## While visiting `name`: show the Send panel; call show_ledger every frame.
func watch(park_name: String) -> void:
	_title.text = park_name
	_send.show()
	show_ledger({"guests": 0, "hidden": 0, "wanted": 0, "earned": 0, "fines": 0}, 0)
	_send.reset_size()
	_send.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 16)

func show_ledger(t: Dictionary, money: int) -> void:
	_ledger.text = "$ %d   Yours inside: %d guests · %d hidden · %d wanted   Earned $ %d   Fines $ %d" % [
		money, t["guests"], t["hidden"], t["wanted"], t["earned"], t["fines"]]

func close() -> void:
	_send.hide()
