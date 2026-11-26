class_name PinView
extends Node2D
# Map-pin bubbles above buildings with a sim building_status. Fixed screen size (scale = 1 / zoom),
# gentle bob, hover shows the text, a click on a pin emits `clicked`. Also owns the status glyphs.

signal clicked(origin: Vector2i, kind: String)

const COLORS := {"wrecked": Palette.CORAL, "littered": Palette.SAND, "robbed": Palette.BUTTER, "spied": Palette.SKY,
	"caught": Palette.MOSS, "wrongful": Palette.CORAL, "repaired": Palette.MOSS}
const TEXT := {"wrecked": "Wrecked: needs rebuilding", "littered": "Littered: needs cleaning", "robbed": "Robbed"}
const HEAD := 14.0  # pin head half size, screen px
const RISE := 32.0  # tail tip to head centre, screen px
const GAP := 34.0   # between pins on the same building

var sim: ParkSim
var map: ParkMap
var cam: Camera2D
var pins: Array[Dictionary] = []  # {origin, kind, at (world), alpha}
var hovered := -1
var _time := 0.0
var _born: Dictionary = {}  # pin key -> time it appeared (pops in)
var _gone: Array[Dictionary] = []  # pins that went, still vanishing

func _ready() -> void:
	z_index = 1500  # above buildings, walkers and the ghost

func _process(delta: float) -> void:
	_time += delta
	var old := pins.filter(func(p: Dictionary) -> bool: return not p.has("gone"))
	pins.clear()
	for o: Vector2i in map.buildings:
		var st := sim.building_status(o)
		for i in st.size():
			var key := "%s %s" % [o, st[i]]
			if not _born.has(key):
				_born[key] = _time
			pins.append({"origin": o, "kind": st[i], "at": top(map.buildings[o], o), "i": i, "n": st.size(), "key": key,
				"alpha": _robbed_alpha(o) if st[i] == "robbed" else 1.0,
				"scale": Tween.interpolate_value(0.0, 1.0, minf(_time - _born[key], Motion.POP_TIME), Motion.POP_TIME,
					Tween.TRANS_BACK, Tween.EASE_OUT)})
	var live := pins.map(func(p: Dictionary) -> String: return p["key"])
	for p: Dictionary in old:  # pins that just went vanish
		if not p["key"] in live:
			_born.erase(p["key"])
			p["gone"] = _time
			_gone.append(p)
	_gone.assign(_gone.filter(func(p: Dictionary) -> bool: return _time - p["gone"] < Motion.VANISH_TIME))
	for p: Dictionary in _gone:
		var k: float = (_time - p["gone"]) / Motion.VANISH_TIME
		p["scale"] = lerpf(1.0, Motion.VANISH_SCALE, k)
		p["fade"] = 1.0 - k
		pins.append(p)
	hovered = -1
	var m := get_local_mouse_position()
	for i in pins.size():
		if m.distance_to(_head(i)) < HEAD * 1.3 / _zoom():
			hovered = i
	queue_redraw()

## World point just above a building's tallest part, over its footprint centre.
static func top(id: String, origin: Vector2i) -> Vector2:
	var b: Dictionary = Buildings.get_def(id)
	var h := 0.0
	for p in b["parts"]:
		h = maxf(h, p["h"] + p["z"])
	var fp: Vector2i = b["footprint"]
	return IsoGrid.project(Vector2(origin) + Vector2(fp - Vector2i.ONE) * 0.5) - Vector2(0, h + 4)

func _zoom() -> float:
	return cam.zoom.x if cam else 1.0

## Head centre of pin i in world space, bobbing.
func _head(i: int) -> Vector2:
	var p := pins[i]
	var s := 1.0 / _zoom()
	var spread: float = (p["i"] - (p["n"] - 1) * 0.5) * GAP
	var bob := sin(_time * 2.2 + p["origin"].x * 1.3 + p["i"]) * 2.0
	return p["at"] + Vector2(spread, -RISE + bob) * s

func _robbed_alpha(o: Vector2i) -> float:
	for k in range(sim.events.size() - 1, -1, -1):
		var e: Dictionary = sim.events[k]
		if e["kind"] == "robbed" and e["origin"] == o:
			return clampf(1.0 - float(sim.tick - e["tick"]) / ParkSim.ROBBED_TICKS, 0.25, 1.0)
	return 1.0

func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and hovered >= 0 and hovered < pins.size():
		clicked.emit(pins[hovered]["origin"], pins[hovered]["kind"])
		get_viewport().set_input_as_handled()

func _draw() -> void:
	var s := 1.0 / _zoom()
	for i in pins.size():
		var p := pins[i]
		var c: Color = COLORS[p["kind"]]
		var a: float = p["alpha"] * p.get("fade", 1.0)
		var head := _head(i)
		var k: float = s * p["scale"]
		if k < 0.01:
			continue
		draw_set_transform(head, 0.0, Vector2(k, k))
		var tip: Vector2 = (p["at"] - head) / k
		var tail := PackedVector2Array([Vector2(-HEAD * 0.45, HEAD * 0.6), Vector2(HEAD * 0.45, HEAD * 0.6), tip])
		var outline := Color(Palette.shade(c, 0.25), a)
		draw_colored_polygon(Squircle.points(Vector2.ZERO, Vector2.ONE * (HEAD + 1.5), 4.0, 32), outline)
		draw_colored_polygon(PackedVector2Array([tail[0] + Vector2(-1.5, 0), tail[1] + Vector2(1.5, 0), tip + Vector2(0, 2)]), outline)
		draw_colored_polygon(tail, Color(c, a))
		draw_colored_polygon(Squircle.points(Vector2.ZERO, Vector2.ONE * HEAD, 4.0, 32), Color(c, a))
		glyph(self, p["kind"], Vector2.ZERO, 1.2, a)
	draw_set_transform(Vector2.ZERO)
	if hovered >= 0:
		var p := pins[hovered]
		var text: String = TEXT[p["kind"]]
		if p["kind"] == "wrecked":
			text += "\nClick to repair now: $%d" % sim._repair_cost(p["origin"])
		var font := ThemeDB.fallback_font
		var size := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		draw_set_transform(_head(hovered) + Vector2(HEAD + 8, -size.y * 0.5) * s, 0.0, Vector2(s, s))
		var box := Squircle.points(size * 0.5, size * 0.5 + Vector2(10, 7), 5.0, 40)
		draw_colored_polygon(box, Palette.CREAM)
		box.append(box[0])
		draw_polyline(box, Color(Palette.INK, 0.25), 1.5, true)
		draw_multiline_string(font, Vector2(0, font.get_ascent(14)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, -1, Palette.INK)
		draw_set_transform(Vector2.ZERO)

## Status icon in a box of about ±7 px × k around `at`: crack, specks, coin, eye.
static func glyph(ci: CanvasItem, kind: String, at: Vector2, k := 1.0, alpha := 1.0) -> void:
	var c := Color(Palette.shade(COLORS[kind], 0.45), alpha)
	var light := Color(Palette.CREAM, alpha)
	match kind:
		"wrecked":  # a block split by a zigzag crack
			var left := PackedVector2Array([Vector2(-7, -5), Vector2(-0.5, -5), Vector2(-2.5, -1), Vector2(0.5, 2), Vector2(-1.5, 6), Vector2(-7, 6)])
			var right := PackedVector2Array([Vector2(1.5, -5), Vector2(7, -5), Vector2(7, 6), Vector2(0.5, 6), Vector2(2.5, 2), Vector2(-0.5, -1)])
			ci.draw_colored_polygon(_xf(left, at + Vector2(-0.8, 0.6) * k, k), c)
			ci.draw_colored_polygon(_xf(right, at + Vector2(0.8, -0.6) * k, k), c)
		"littered":  # specks
			for p: Vector2 in [Vector2(-4, 2), Vector2(2, -3), Vector2(4, 3), Vector2(-1, -1)]:
				ci.draw_colored_polygon(Squircle.points(at + p * k, Vector2(2.0, 1.6) * k, 4.0, 12), c)
		"spied":  # almond eye with a pupil
			ci.draw_colored_polygon(Squircle.points(at, Vector2(7, 4) * k, 2.4, 24), c)
			ci.draw_colored_polygon(Squircle.points(at, Vector2(2.6, 2.6) * k, 4.0, 16), light)
		_:  # coin
			ci.draw_colored_polygon(Squircle.points(at, Vector2(6.5, 6.5) * k, 3.0, 24), c)
			ci.draw_colored_polygon(Squircle.points(at, Vector2(1.6, 3.6) * k, 4.0, 16), Color(Palette.shade(COLORS[kind], 0.1), alpha))

static func _xf(pts: PackedVector2Array, at: Vector2, k: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(at + p * k)
	return out
