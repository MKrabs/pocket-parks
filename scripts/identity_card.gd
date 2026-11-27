class_name IdentityCard
extends CanvasLayer
# Who you are (docs/design/game.md → M5 identity): your name, your park's name and your colour. Opens on first start
# and from the park name in the HUD. Net keeps the values; this card only edits them.

signal saved(nick: String, park: String, colour: String)

const NAME_MIN := 2
const NAME_MAX := 16
const PARK_MAX := 24  # guess: park names may be a bit longer than player names
const COLOURS := {"SKY": Palette.SKY, "CORAL": Palette.CORAL, "BUTTER": Palette.BUTTER, "MOSS": Palette.MOSS,
	"CLAY": Palette.CLAY, "WATER": Palette.WATER}

var colour := "SKY"
var _card := PanelContainer.new()
var _nick := LineEdit.new()
var _park := LineEdit.new()
var _swatches: Array[Button] = []
var _ok: Button

## A name of NAME_MIN..`most` characters once trimmed.
static func valid(text: String, most := NAME_MAX) -> bool:
	var n := text.strip_edges().length()
	return n >= NAME_MIN and n <= most

## The palette colour for a saved colour name (SKY for an unknown one).
static func colour_of(id: String) -> Color:
	return COLOURS.get(id, Palette.SKY)

func _ready() -> void:
	layer = 50
	var box := BuildBar.box(Palette.CREAM, 20)
	box.set_content_margin_all(22)
	_card.add_theme_stylebox_override("panel", box)
	_card.custom_minimum_size = Vector2(300, 0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	var head := Hud._label(20)
	head.add_theme_font_override("font", Palette.FONT_BOLD)
	head.text = "Who are you?"
	col.add_child(head)
	for f: Array in [[_nick, "Your name", NAME_MAX], [_park, "Your park's name", PARK_MAX]]:
		col.add_child(_hint(f[1]))
		col.add_child(_field(f[0], f[2]))
	col.add_child(_hint("Your colour"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for id: String in COLOURS:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(36, 36)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for k in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(k, StyleBoxEmpty.new())
		b.draw.connect(_draw_swatch.bind(b, id))
		b.pressed.connect(func() -> void:
			colour = id
			for s in _swatches:
				s.queue_redraw())
		_swatches.append(b)
		row.add_child(b)
	col.add_child(row)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_child(Hud._button("Cancel", _card.hide))
	_ok = Hud._button("Save", _save)
	for k in ["normal", "hover"]:
		_ok.add_theme_stylebox_override(k, BuildBar.box(Palette.shade(Palette.BUTTER, 0.04) if k == "hover" else Palette.BUTTER))
	_ok.add_theme_stylebox_override("disabled", BuildBar.box(Palette.STONE))
	_ok.add_theme_color_override("font_disabled_color", Color(Palette.INK, 0.5))
	buttons.add_child(_ok)
	col.add_child(buttons)
	_card.add_child(col)
	add_child(_card)
	_card.hide()

func is_open() -> bool:
	return _card.visible

## Show the card filled with the current values.
func open(nick: String, park: String, colour_id: String) -> void:
	_nick.text = nick
	_park.text = park
	colour = colour_id if COLOURS.has(colour_id) else "SKY"
	_check()
	_card.show()
	_card.reset_size()
	_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_card.pivot_offset = _card.size * 0.5
	Motion.pop(_card)
	for s in _swatches:
		s.queue_redraw()

func _check() -> void:
	_ok.disabled = not (valid(_nick.text) and valid(_park.text, PARK_MAX))

func _save() -> void:
	_check()
	if _ok.disabled:
		return
	_card.hide()
	saved.emit(_nick.text.strip_edges(), _park.text.strip_edges(), colour)

func _field(e: LineEdit, most: int) -> LineEdit:
	e.max_length = most + 4  # room for spaces that get trimmed
	e.add_theme_font_size_override("font_size", 16)
	for k in ["font_color", "caret_color"]:
		e.add_theme_color_override(k, Palette.INK)
	for k in ["normal", "focus"]:
		e.add_theme_stylebox_override(k, BuildBar.box(Palette.STONE if k == "normal" else Palette.SKY))
	e.text_changed.connect(func(_t: String) -> void: _check())
	e.text_submitted.connect(func(_t: String) -> void: _save())
	return e

func _hint(text: String) -> Label:
	var l := Hud._label(13)
	l.text = text
	l.modulate.a = 0.7
	return l

func _draw_swatch(b: Button, id: String) -> void:
	var c := b.size * 0.5
	var col: Color = COLOURS[id]
	if id == colour:
		b.draw_colored_polygon(Squircle.points(c, Vector2(17, 17), 4.0, 40), Palette.shade(Palette.STONE, 0.22))
		b.draw_colored_polygon(Squircle.points(c, Vector2(15, 15), 4.0, 40), Palette.CREAM)
	b.draw_colored_polygon(Squircle.points(c, Vector2(12, 12), 4.0, 40), Palette.shade(col, 0.12))
	b.draw_colored_polygon(Squircle.points(c, Vector2(10.5, 10.5), 4.0, 40), col)
