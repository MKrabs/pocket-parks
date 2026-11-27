class_name WalkerView
extends Node2D
# Draws the sim's guests, staff, player characters (avatars) and litter. One layer node per iso depth row (x+y), with
# z_index 2*depth+1, so walkers slot between buildings (BuildingView z_index = 2*depth).

const GUEST_COLORS := [Palette.SKY, Palette.BUTTER, Palette.CLAY, Palette.WATER, Palette.WOOD]
const CAPS := {"janitor": Palette.SAND, "guard": Palette.SKY}
const LIFT := 3.0  # path tile height in px
const MARKS := {"guest": Palette.MOSS, "hooligan": Palette.CLAY, "litterbug": Palette.WOOD, "thief": Palette.INK, "spy": Palette.WATER}

var sim: ParkSim
var me := ""  # sender whose people get a dot above the bean (only we can see them)
var hovered := -1  # guest id lifted under the mouse (Select mode)
var hovered_staff := -1  # staff index lifted under the mouse
const HOVER_LIFT := 4.0
const TAG_FONT := 9  # name tag text size in world px
var _layers: Array[Node2D] = []
var _rows: Array = []  # per depth: [[kind, item], ...]
var _time := 0.0
var _hops: Dictionary = {}  # staff index -> time its hop started
var _bubbles: Dictionary = {}  # avatar name -> its speech Bubble (one each, the newest line)
const BUBBLE_TIME := 5.0
const BUBBLE_WIDTH := 130.0  # world px before the line wraps

## A speech bubble over `name`'s character for BUBBLE_TIME s (pops in, vanishes). A newer line replaces it.
func say(name: String, text: String) -> void:
	if _bubbles.has(name) and is_instance_valid(_bubbles[name]):
		_bubbles[name].queue_free()
	var b := Bubble.new()
	b.text = text
	b.z_index = 2 * (IsoGrid.SIZE.x + IsoGrid.SIZE.y) + 2  # above every row
	b.hide()  # until _process puts it over its character
	add_child(b)
	_bubbles[name] = b
	var t := Motion.pop(b)
	t.tween_interval(BUBBLE_TIME)
	t.tween_callback(func() -> void:
		if _bubbles.get(name) == b:
			_bubbles.erase(name)
		Motion.vanish(b))

## A little hop for staff member i (a guard who just caught someone).
func hop(i: int) -> void:
	_hops[i] = _time

func _ready() -> void:
	for d in IsoGrid.SIZE.x + IsoGrid.SIZE.y:
		var layer := Node2D.new()
		layer.z_index = 2 * d + 1
		layer.draw.connect(_draw_row.bind(layer, d))
		add_child(layer)
		_layers.append(layer)

func _process(delta: float) -> void:
	_time += delta
	_rows.clear()
	_rows.resize(_layers.size())
	for i in _rows.size():
		_rows[i] = []
	for c: Vector2i in sim.litter:
		_row(Vector2(c)).append(["litter", c])
	for i in sim.staff.size():
		var t: float = _time - _hops.get(i, -INF)
		var lift := sin(t / Motion.HOP_TIME * PI) * Motion.HOP if t < Motion.HOP_TIME else 0.0
		_row(sim.staff[i]["pos"]).append(["staff", sim.staff[i], lift + (HOVER_LIFT if i == hovered_staff else 0.0)])
	for b in sim.builders:
		_row(b["pos"]).append(["builder", b])
	for g in sim.guests:
		if g["state"] != "visit":  # inside the building
			_row(g["pos"]).append(["guest", g])
	for a in sim.avatars:
		_row(a["pos"]).append(["avatar", a])
	for n: String in _bubbles:
		var b: Node2D = _bubbles[n]
		b.hide()
		for a in sim.avatars:
			if a.get("label", a["name"]) == n:  # chat lines carry the shown name
				b.position = IsoGrid.project(a["pos"]) - Vector2(0, LIFT + 40.0)
				b.show()
	for l in _layers:
		l.queue_redraw()

func _row(p: Vector2) -> Array:
	return _rows[clampi(roundi(p.x + p.y), 0, _rows.size() - 1)]

func _draw_row(ci: Node2D, d: int) -> void:
	if _rows.is_empty():
		return
	for e: Array in _rows[d]:
		match e[0]:
			"litter":
				var c: Vector2i = e[1]
				var at := IsoGrid.to_screen(c) - Vector2(0, LIFT)
				for k in 3:
					var off := IsoGrid.project(Vector2(sin(c.x * 3.1 + k * 2.3), cos(c.y * 2.7 + k * 1.9)) * 0.28)
					var col: Color = [Palette.CLAY, Palette.SKY, Palette.MOSS][(c.x + c.y + k) % 3]
					ci.draw_colored_polygon(Squircle.points(at + off, Vector2(1.6, 1.1), 4.0, 12), Palette.shade(col, 0.12))
			"staff":
				var s: Dictionary = e[1]
				var cap: Color = CAPS[s["kind"]]
				var walking: bool = not s["path"].is_empty()
				_bean(ci, s["pos"], 0, Vector2(5.5, 6.5), Palette.shade(cap, 0.3), cap, walking, Color(Palette.INK, 0.0), e[2])
				# level mark: 1-3 thin upright stripes across the cap front (same bob and hop as the bean)
				var top := IsoGrid.project(s["pos"]) - Vector2(0, LIFT + 12.5 + e[2] + (absf(sin(_time * 9.0)) * 1.5 if walking else 0.0))
				var n: int = s["level"]
				for k in n:
					var at := top + Vector2((k - (n - 1) * 0.5) * 2.6, 0)
					ci.draw_colored_polygon(Squircle.points(at, Vector2(0.6, 1.7), 4.0, 10), Palette.shade(cap, 0.45))
			"builder":  # overalls and a BUTTER hard hat; bobs while walking or hammering
				var b: Dictionary = e[1]
				_bean(ci, b["pos"], 3, Vector2(5.5, 6.5), Palette.shade(Palette.SKY, 0.2), Palette.BUTTER, b["state"] != "home")
			"avatar":  # a bigger bean in the player's colour, a cap one shade darker, a name tag above
				var a: Dictionary = e[1]
				var col: Color = a["color"]
				_bean(ci, a["pos"], 5, Vector2(8.5, 10.5), col, Palette.shade(col, 0.22), not a["path"].is_empty(),
					Color(Palette.INK, 0.0), 0.0, Palette.shade(col, 0.35), 2.0)
				var name: String = a.get("label", a["name"])
				var w := Palette.FONT_BOLD.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, TAG_FONT).x
				var tag := IsoGrid.project(a["pos"]) - Vector2(0, LIFT + 32.0)
				var striking: bool = a.get("strike", 0) > 0  # exposed: the tag turns CORAL while it does its crime
				ci.draw_colored_polygon(Squircle.points(tag, Vector2(w * 0.5 + 4.0, TAG_FONT * 0.6), 4.0, 24),
					Palette.CORAL if striking else Color(Palette.CLOUD, 0.92))
				ci.draw_string(Palette.FONT_BOLD, tag + Vector2(-w * 0.5, TAG_FONT * 0.35), name, HORIZONTAL_ALIGNMENT_LEFT, -1, TAG_FONT, Palette.INK)
			"guest":
				var g: Dictionary = e[1]
				var id: int = g["id"]
				var base: Color = GUEST_COLORS[id % GUEST_COLORS.size()]
				var col := base.lerp(Palette.CORAL, clampf((60.0 - g["mood"]) / 40.0, 0.0, 1.0))
				var p := spot(g)
				_bean(ci, p, id, Vector2(4.0, 4.8), col, Color(Palette.INK, 0.0), g["state"] != "queue", Color(Palette.INK, 0.0), HOVER_LIFT if id == hovered else 0.0)
				var head := IsoGrid.project(p) - Vector2(0, LIFT + 15.0)
				if me != "" and g["sender"] == me:
					ci.draw_colored_polygon(Squircle.points(head, Vector2(4.4, 4.4), 4.0, 16), Palette.CREAM)
					ci.draw_colored_polygon(Squircle.points(head, Vector2(3.0, 3.0), 4.0, 12), MARKS[g["kind"]])
					head.y -= 7.0
				if g["wanted"]:  # a guard saw it strike: CORAL "!" over its head
					var mark := Palette.shade(Palette.CORAL, 0.15)
					ci.draw_colored_polygon(Squircle.points(head - Vector2(0, 5), Vector2(1.7, 4.0), 4.0, 16), mark)
					ci.draw_colored_polygon(Squircle.points(head + Vector2(0, 2.5), Vector2(1.7, 1.7), 4.0, 12), mark)

## Where a guest is drawn, in fractional cells (its position plus a per-id jitter).
static func spot(g: Dictionary) -> Vector2:
	var id: int = g["id"]
	return g["pos"] + Vector2(sin(id * 12.9898), cos(id * 78.233)) * 0.22

## Squircle bean standing on the path, soft shadow, optional cap and chest mark. `half` in px.
func _bean(ci: Node2D, p: Vector2, phase: int, half: Vector2, col: Color, cap: Color, walking: bool, mark := Color(Palette.INK, 0.0), hop := 0.0, line := Color(Palette.INK, 0.3), width := 1.0) -> void:
	var foot := IsoGrid.project(p) - Vector2(0, LIFT)
	var bob := absf(sin(_time * 9.0 + phase)) * 1.5 if walking else 0.0
	ci.draw_colored_polygon(Squircle.points(foot, Vector2(half.x, half.x * 0.5), 4.0, 16), Color(Palette.INK, 0.15))
	foot.y -= hop  # the shadow stays on the ground
	var body := Squircle.points(foot - Vector2(0, half.y + bob), half, 4.0, 20)
	ci.draw_colored_polygon(body, col)
	body.append(body[0])
	ci.draw_polyline(body, line, width, true)
	if cap.a > 0.0:
		var top := Squircle.points(foot - Vector2(0, half.y * 2.0 + bob - 0.5), Vector2(half.x * 0.9, half.y * 0.35), 4.0, 16)
		ci.draw_colored_polygon(top, cap)
	if mark.a > 0.0:
		ci.draw_colored_polygon(Squircle.points(foot - Vector2(0, half.y + bob), Vector2(3.0, 3.0), 4.0, 12), mark)

## A rounded speech bubble; its origin is the tip of the little tail (it grows from there when it pops).
class Bubble extends Node2D:
	var text := ""
	func _draw() -> void:
		var f := Palette.FONT
		var size := f.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, BUBBLE_WIDTH, TAG_FONT)
		var half := size * 0.5 + Vector2(7, 5)
		var centre := Vector2(0, -half.y - 4.0)
		draw_colored_polygon(Squircle.points(Vector2(0, -2.5), Vector2(2.6, 2.6), 4.0, 12), Palette.CLOUD)
		var body := Squircle.points(centre, half, 4.0, 32)
		draw_colored_polygon(body, Palette.CLOUD)
		body.append(body[0])
		draw_polyline(body, Color(Palette.INK, 0.15), 1.0, true)
		draw_multiline_string(f, centre - Vector2(size.x * 0.5, size.y * 0.5 - f.get_ascent(TAG_FONT)), text,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, TAG_FONT, -1, Palette.INK)
