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
var _reason := Hud._label(13)
var _sends: Array[Button] = []
var _here := HBoxContainer.new()  # "Also here:" and a dot + name per other character in the park
var also_here: Array = []         # [name, color] it shows (Net.others)

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
	_here.add_theme_constant_override("separation", 6)
	_here.hide()
	top.add_child(_here)
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
		b.add_theme_stylebox_override("disabled", BuildBar.box(Palette.shade(Palette.STONE, 0.06)))
		b.add_theme_color_override("font_disabled_color", Palette.shade(Palette.STONE, 0.35))
		_sends.append(b)
		row.add_child(b)
	var back := Hud._button("Back\nhome", home.emit)
	back.add_theme_stylebox_override("normal", BuildBar.box(Palette.BUTTER))
	back.add_theme_stylebox_override("hover", BuildBar.box(Palette.shade(Palette.BUTTER, 0.04)))
	back.custom_minimum_size = Vector2(84, 0)
	row.add_child(back)
	col.add_child(row)
	_reason.modulate.a = 0.75
	col.add_child(_reason)
	_send.add_child(col)
	add_child(_send)
	_send.hide()

## At least MIN_PARKS on offer: friends on the network first, bot parks fill the rest (pure, so tests reach it).
const MIN_PARKS := 3
const REFRESH := 1.0  # s between list refreshes while the picker is open

static func merge(nearby: Array, bots: Array) -> Array:
	var out: Array = nearby.duplicate()
	for o in bots:
		if out.size() >= MIN_PARKS:
			break
		out.append(o)
	return out

## `source` returns {nearby: Array, bots: Array, own: String, listening: int, player: String}; called on open and
## every REFRESH s while the picker is open, so friends appear (and drop off) live.
var source: Callable
var _list := VBoxContainer.new()
var _status := Hud._label(13)
var _field := LineEdit.new()
var _mine := Hud._label(13)
var _refresh_in := 0.0
var _time := 0.0

## Show the picker: one list of parks (friends found on the network, topped up with bots to MIN_PARKS), a live
## search status, the join-by-address field and our own address, plus Cancel.
func open() -> void:
	if _choices.get_child_count() == 0:
		_build()
	_field.text = last_address
	_picker.show()
	_refresh()

## The picker's fixed parts, once: heading, search status, the park list (refilled by _refresh), join row, own address.
func _build() -> void:
	var head := Hud._label(18)
	head.text = "Visit a park"
	_choices.add_child(head)
	_choices.add_child(_status)
	_list.add_theme_constant_override("separation", 10)
	_choices.add_child(_list)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_field.placeholder_text = "Join by address"
	_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field.add_theme_font_size_override("font_size", 14)
	for k in ["font_color", "font_placeholder_color", "caret_color"]:
		_field.add_theme_color_override(k, Palette.INK if k != "font_placeholder_color" else Palette.shade(Palette.STONE, 0.3))
	for k in ["normal", "focus"]:
		_field.add_theme_stylebox_override(k, BuildBar.box(Palette.STONE if k == "normal" else Palette.SKY))
	var go := func() -> void:
		last_address = _field.text.strip_edges()
		_picker.hide()
		join_address.emit(last_address)
	_field.text_submitted.connect(func(_t: String) -> void: go.call())
	row.add_child(_field)
	row.add_child(Hud._button("Join", go))
	_choices.add_child(row)
	_mine.modulate.a = 0.7
	_choices.add_child(_mine)
	_choices.add_child(Hud._button("Cancel", _picker.hide))

func _process(delta: float) -> void:
	if not _picker.visible:
		return
	_time += delta
	_status.modulate.a = 0.55 + 0.25 * sin(_time * 3.0)  # a slow pulse: still searching
	_refresh_in -= delta
	if _refresh_in <= 0.0:
		_refresh()

func _refresh() -> void:
	_refresh_in = REFRESH
	var d: Dictionary = source.call() if source.is_valid() else {}
	var nearby: Array = d.get("nearby", [])
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	for o in merge(nearby, d.get("bots", [])):
		if o.get("live", false):
			_live_choice(o)
		else:
			_choice(o, "%s\nbot park · %s · %d guards" % [o["name"], o["theme"], o["guards"]])
	var found := nearby.size()
	if int(d.get("listening", 0)) == 0:
		_status.text = "Can't look for friends: the network port is busy"
	elif found == 0:
		_status.text = "● Looking for friends on your network…"
	else:
		_status.text = "● Found %d friend%s · still looking" % [found, "" if found == 1 else "s"]
	var own: String = d.get("own", "")
	_mine.text = "Your park: %s%s" % [own if own != "" else "not on a network",
		"  ·  you are %s" % d["player"] if d.get("player", "") != "" else ""]
	_picker.reset_size()
	_picker.size.y = minf(_picker.size.y, get_viewport().get_visible_rect().size.y - 40)
	_picker.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)

func _live_choice(o: Dictionary) -> void:
	var b := _choice(o, "%s\n%s · %s" % [o["name"], o["player"], o["theme"]])
	b.draw.connect(func() -> void:  # live dot just left of the park name
		var f := b.get_theme_font("font")
		var fs := b.get_theme_font_size("font_size")
		var w := f.get_string_size(o["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var at := Vector2((b.size.x - w) / 2 - 12, b.size.y / 2 - f.get_height(fs) / 2)
		b.draw_colored_polygon(Squircle.points(at, Vector2(7, 7), 4.0, 24), Palette.GRASS)
		b.draw_colored_polygon(Squircle.points(at, Vector2(4.5, 4.5), 4.0, 24), Palette.MOSS)
		var who := "%s · %s" % [o["player"], o["theme"]]  # their colour chip just left of the second line
		var col := IdentityCard.colour_of(o.get("colour", ""))
		var cw := f.get_string_size(who, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var cat := Vector2((b.size.x - cw) / 2 - 12, b.size.y / 2 + f.get_height(fs) / 2)
		b.draw_colored_polygon(Squircle.points(cat, Vector2(6.5, 6.5), 4.0, 24), Palette.shade(col, 0.12))
		b.draw_colored_polygon(Squircle.points(cat, Vector2(5, 5), 4.0, 24), col))

func _choice(o: Dictionary, text: String) -> Button:
	var b := Hud._button(text, func() -> void:
		_picker.hide()
		picked.emit(o))
	b.custom_minimum_size = Vector2(260, 0)
	_list.add_child(b)
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
	show_ledger({"guests": 0, "hidden": 0, "wanted": 0, "earned": 0, "fines": 0, "limit": 1}, 0)
	_send.reset_size()
	_send.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 16)

## `t` is sent_by() in the park on screen (or the host's copy of it), with our send limit there.
func show_ledger(t: Dictionary, money: int) -> void:
	_ledger.text = "$ %d   Inside: %d / %d   %d guests · %d hidden · %d wanted   Earned $ %d   Fines $ %d" % [
		money, inside(t), t["limit"], t["guests"], t["hidden"], t["wanted"], t["earned"], t["fines"]]
	var full := not can_send(t)
	for b in _sends:
		b.disabled = full
	_reason.text = ("Full: at most %d of yours inside at once (3 + your park level). Send more when some leave." if full
		else "Up to %d of yours inside at once (3 + your park level).") % t["limit"]

## Everyone else in the park we visit, the host too while their character is there; hidden when nobody is.
func show_here(list: Array) -> void:
	if list == also_here:
		return
	also_here = list
	for c in _here.get_children():
		c.queue_free()
	_here.visible = not list.is_empty()
	var head := Hud._label(14)
	head.text = "Also here:"
	head.modulate.a = 0.7
	_here.add_child(head)
	for p: Array in list:
		_here.add_child(Hud.dot(p[1]))
		var n := Hud._label(14)
		n.text = p[0]
		_here.add_child(n)
	_send.reset_size()
	_send.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 16)

## Our people in the park (the gate queue included).
static func inside(t: Dictionary) -> int:
	return t["guests"] + t["hidden"] + t["wanted"]

## Room for one more of ours under the send limit.
static func can_send(t: Dictionary) -> bool:
	return inside(t) < t["limit"]

func close() -> void:
	_send.hide()
