class_name PinView
extends Node2D
# Map-pin bubbles above buildings with a sim building_status. Fixed screen size (scale = 1 / zoom),
# gentle bob, hover shows the text, a click on a pin emits `clicked`. Also owns the status glyphs.

signal clicked(origin: Vector2i, kind: String)

const COLORS := {"wrecked": Palette.CORAL, "littered": Palette.SAND, "robbed": Palette.BUTTER, "spied": Palette.SKY,
	"caught": Palette.MOSS, "wrongful": Palette.CORAL, "repaired": Palette.MOSS}
const WORD := {"wrecked": "Repair", "littered": "Clean", "robbed": "Robbed", "spied": "Spied"}
const HEAD := 12.0  # pin head half size, screen px
const RISE := 30.0  # tail tip to head centre, screen px
const GAP := 30.0   # between pins on the same building
const FONT := 14
const OPEN_TIME := 0.16  # s for a hovered pin to widen into its pill

var sim: ParkSim
var map: ParkMap
var cam: Camera2D
var pins: Array[Dictionary] = []  # {origin, kind, at (world), alpha}
var hovered := -1
var _time := 0.0
var _born: Dictionary = {}  # pin key -> time it appeared (pops in)
var _gone: Array[Dictionary] = []  # pins that went, still vanishing
var _open: Dictionary = {}  # pin key -> 0..1, how far it has widened into a pill

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
			pins.append({"origin": o, "kind": st[i], "at": top(map.buildings[o], o, map.rotation(o)), "i": i, "n": st.size(), "key": key,
				"alpha": _robbed_alpha(o) if st[i] == "robbed" else 1.0,
				"scale": Tween.interpolate_value(0.0, 1.0, minf(_time - _born[key], Motion.POP_TIME), Motion.POP_TIME,
					Tween.TRANS_BACK, Tween.EASE_OUT)})
	var live := pins.map(func(p: Dictionary) -> String: return p["key"])
	for p: Dictionary in old:  # pins that just went vanish
		if not p["key"] in live:
			_born.erase(p["key"])
			_open.erase(p["key"])
			p["gone"] = _time
			_gone.append(p)
	_gone.assign(_gone.filter(func(p: Dictionary) -> bool: return _time - p["gone"] < Motion.VANISH_TIME))
	for p: Dictionary in _gone:
		var k: float = (_time - p["gone"]) / Motion.VANISH_TIME
		p["scale"] = lerpf(1.0, Motion.VANISH_SCALE, k)
		p["fade"] = 1.0 - k
		pins.append(p)
	var m := get_local_mouse_position()
	var was: String = pins[hovered]["key"] if hovered >= 0 and hovered < pins.size() else ""
	hovered = -1
	for i in pins.size():
		var d := (m - _head(i)) * _zoom()
		if absf(d.x) < half_width(i) + 2 and absf(d.y) < HEAD * 1.3 and (hovered < 0 or pins[i]["key"] == was):
			hovered = i
	for i in pins.size():
		var key: String = pins[i]["key"]
		_open[key] = move_toward(_open.get(key, 0.0), 1.0 if i == hovered else 0.0, delta / OPEN_TIME)
	queue_redraw()

## Eased 0..1 widening of pin i.
func openness(i: int) -> float:
	return smoothstep(0.0, 1.0, _open.get(pins[i]["key"], 0.0))

## Half width of pin i's head in screen px: HEAD when calm, the full pill (glyph + word) when open.
func half_width(i: int) -> float:
	var w := Palette.FONT.get_string_size(WORD.get(pins[i]["kind"], ""), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT).x
	return HEAD + openness(i) * (w + 8) * 0.5

## World point just above a building's tallest part, over its footprint centre.
static func top(id: String, origin: Vector2i, rot := 0) -> Vector2:
	var b: Dictionary = Buildings.get_def(id)
	var h := 0.0
	for p in b["parts"]:
		h = maxf(h, p["h"] + p["z"])
	var fp := ParkMap.size(id, rot)
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
	var order := range(pins.size())
	if hovered >= 0:  # the open pill on top of its neighbours
		order.erase(hovered)
		order.append(hovered)
	var font := Palette.FONT
	for i: int in order:
		var p := pins[i]
		var c: Color = COLORS[p["kind"]]
		var a: float = p["alpha"] * p.get("fade", 1.0)
		var head := _head(i)
		var k: float = s * p["scale"]
		if k < 0.01:
			continue
		var hw := half_width(i)
		var o := openness(i)
		if o > 0.0:
			a = lerpf(a, 1.0, o)  # a faded robbed pin reads fully while hovered
		draw_set_transform(head, 0.0, Vector2(k, k))
		var tip: Vector2 = (p["at"] - head) / k
		var tail := PackedVector2Array([Vector2(-HEAD * 0.4, HEAD * 0.6), Vector2(HEAD * 0.4, HEAD * 0.6), tip])
		var outline := Color(Palette.shade(c, 0.18), a)
		var n := lerpf(4.0, 6.0, o)  # flatter ends as it widens, so the pill keeps a soft squircle feel
		draw_colored_polygon(Squircle.points(Vector2.ZERO, Vector2(hw, HEAD) + Vector2.ONE * 1.5, n, 48), outline)
		draw_colored_polygon(PackedVector2Array([tail[0] + Vector2(-1.5, 0), tail[1] + Vector2(1.5, 0), tip + Vector2(0, 2)]), outline)
		draw_colored_polygon(tail, Color(c, a))
		draw_colored_polygon(Squircle.points(Vector2.ZERO, Vector2(hw, HEAD), n, 48), Color(c, a))
		var g := Vector2(HEAD - hw, 0)  # glyph slides to the left end of the pill
		glyph(self, p["kind"], g, 1.0, a)
		if o > 0.05:
			var y := (font.get_ascent(FONT) - font.get_descent(FONT)) * 0.5
			draw_string(font, g + Vector2(HEAD - 2, y), WORD.get(p["kind"], ""), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT,
				Color(Palette.shade(c, 0.6), a * o * o))
	draw_set_transform(Vector2.ZERO)

## Status icon in a box of about ±7 px × k around `at`: hammer, broom, coin with a minus, eye (other kinds: coin).
static func glyph(ci: CanvasItem, kind: String, at: Vector2, k := 1.0, alpha := 1.0) -> void:
	var c := Color(Palette.shade(COLORS[kind], 0.45), alpha)
	var light := Color(Palette.CREAM, alpha)
	match kind:
		"wrecked":  # hammer, head up-left, tilted
			var xf := Transform2D(-0.7, Vector2(k, k), 0.0, at)
			ci.draw_colored_polygon(xf * Squircle.points(Vector2(0, 2.5), Vector2(1.3, 6.0), 4.0, 20), c)
			ci.draw_colored_polygon(xf * Squircle.points(Vector2(-0.8, -4.5), Vector2(5.0, 2.4), 4.0, 24), c)
		"littered":  # broom, bristles down-left, tilted
			var xf := Transform2D(0.6, Vector2(k, k), 0.0, at + Vector2(0.5, -0.5) * k)
			ci.draw_colored_polygon(xf * Squircle.points(Vector2(0, -3.5), Vector2(1.1, 4.8), 4.0, 20), c)
			ci.draw_colored_polygon(xf * Squircle.points(Vector2(0, 1.8), Vector2(2.8, 1.0), 4.0, 16), c)
			ci.draw_colored_polygon(xf * PackedVector2Array([Vector2(-2.8, 3.2), Vector2(2.8, 3.2), Vector2(4.6, 7.6),
				Vector2(-4.6, 7.6)]), c)
		"spied":  # almond eye: dark rim, light white, dark pupil
			ci.draw_colored_polygon(Squircle.points(at, Vector2(7.5, 4.8) * k, 2.2, 32), c)
			ci.draw_colored_polygon(Squircle.points(at, Vector2(6.0, 3.4) * k, 2.2, 32), light)
			ci.draw_colored_polygon(Squircle.points(at, Vector2(2.4, 2.4) * k, 3.0, 20), c)
		"robbed":  # coin with a minus
			ci.draw_colored_polygon(Squircle.points(at, Vector2(6.5, 6.5) * k, 3.0, 28), c)
			ci.draw_colored_polygon(Squircle.points(at, Vector2(3.6, 1.2) * k, 4.0, 16), light)
		_:  # coin
			ci.draw_colored_polygon(Squircle.points(at, Vector2(6.5, 6.5) * k, 3.0, 24), c)
			ci.draw_colored_polygon(Squircle.points(at, Vector2(1.6, 3.6) * k, 4.0, 16), Color(Palette.shade(COLORS[kind], 0.1), alpha))
