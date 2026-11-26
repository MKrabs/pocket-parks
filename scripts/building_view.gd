class_name BuildingView
extends Node2D
# Draws one catalog building. Node origin = centre of the building's origin cell.

var id: String
var origin := Vector2i.ZERO
var level := 1:  # 2-3 add flags (attractions, shops) or a bigger canopy (decor)
	set(l):
		level = l
		queue_redraw()
var label := ""  # short text in a pill above the building (the upgrade ghost's price)
var wrecked := false:  # wrecked by a hooligan: drawn grey and tilted (eases in and out)
	set(w):
		wrecked = w
		if not is_inside_tree():
			rotation = 0.18 if w else 0.0
			grey = 1.0 if w else 0.0
			return
		var t := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
		t.tween_property(self, "rotation", 0.18 if w else 0.0, Motion.TILT_TIME)
		t.tween_property(self, "grey", 1.0 if w else 0.0, Motion.TILT_TIME)
var grey := 0.0:  # 0 = own colours, 1 = wrecked grey
	set(g):
		grey = g
		queue_redraw()
var fresh := 1.0:  # scale of the flags this level added (pops 0 -> 1 after an upgrade)
	set(f):
		fresh = f
		queue_redraw()

var site := -1.0:  # under construction: progress 0..1 (scaffold + ring); -1 = done
	set(s):
		if s != site:
			site = s
			queue_redraw()
var site_upgrade := false  # the scaffold stands around the existing building instead of replacing it

var turn := 0:  # quarter turns clockwise (0-3), as stored in ParkMap.rotations
	set(t):
		turn = t
		queue_redraw()

static var _turned: Dictionary = {}  # "id turn" -> parts, rotated and re-sorted back to front

func _init(building_id: String) -> void:
	id = building_id

## The building's parts turned `turn` quarter turns around the footprint centre, back to front.
## Parts that overlap in plan keep their catalog order (stacking); side-by-side parts go by depth.
static func turned(building_id: String, turn: int) -> Array:
	var key := "%s %d" % [building_id, turn]
	if _turned.has(key):
		return _turned[key]
	var parts: Array = Buildings.get_def(building_id)["parts"]
	if turn % 4 == 0:
		return parts
	var rest: Array = []
	for p: Dictionary in parts:
		var q := p.duplicate()
		for i in turn % 4:
			q["at"] = Vector2(-q["at"].y, q["at"].x)
			q["half"] = Vector2(q["half"].y, q["half"].x)
		rest.append(q)
	var left: Array = range(rest.size())  # catalog indices still to draw
	var out: Array = []
	while not left.is_empty():  # ponytail: O(n³) topological pick, fine for ~40 parts and cached
		var pick := 0  # on a cycle, fall back to catalog order
		for i: int in left:
			if not left.any(func(j: int) -> bool: return j != i and _before(rest[j], rest[i], j < i)):
				pick = left.find(i)
				break
		out.append(rest[left.pop_at(pick)])
	_turned[key] = out
	return out

## True if part a must be drawn before part b (a_first: a comes first in the catalog).
static func _before(a: Dictionary, b: Dictionary, a_first: bool) -> bool:
	var gap: Vector2 = (b["at"] - a["at"]).abs() - a["half"] - b["half"]
	if gap.x < 0.0 and gap.y < 0.0:  # overlap in plan
		if a["z"] + a["h"] <= b["z"] or b["z"] + b["h"] <= a["z"]:
			return a["z"] < b["z"]  # stacked: lower first
		if _holds(a, b["at"]) or _holds(b, a["at"]):
			return a_first  # one stands on/in the other (fence posts on a slab): catalog order
		return a["at"].x + a["at"].y < b["at"].x + b["at"].y  # sticks out the side (a hatch): by depth
	return a["at"].x < b["at"].x if gap.x >= gap.y else a["at"].y < b["at"].y

static func _holds(p: Dictionary, at: Vector2) -> bool:
	var d: Vector2 = (at - p["at"]).abs()
	return d.x < p["half"].x and d.y < p["half"].y

func _draw() -> void:
	var b: Dictionary = Buildings.get_def(id)
	var fp := ParkMap.size(id, turn)
	var mid := Vector2(fp.x - 1, fp.y - 1) * 0.5  # footprint centre in grid coords
	var parts := turned(id, turn)
	var top := 0.0
	for p in parts:
		top = maxf(top, p["z"] + p["h"])
	var grow := 1.0
	var scaffold := _scaffold(fp, top) if site >= 0.0 else [[], []]
	for p: Dictionary in scaffold[0]:
		block(self, Squircle.iso_points(IsoGrid.project(mid + p["at"]), p["half"], 4.0, 24), p["h"], p["z"], p["color"])
	if site >= 0.0 and not site_upgrade:
		parts = []  # a new site: only the scaffold
	elif Buildings.upgradable(id) and b["role"] != "decor" and level >= 2:
		var c := Vector2(fp) * 0.5 - Vector2(0.2, 0.2)  # just inside the footprint corners
		var spots := [Vector2(-c.x, -c.y)]  # level 2: a flag at the back
		if level >= 3:
			spots += [Vector2(-c.x, c.y), Vector2(c.x, -c.y)]  # level 3: and at the sides
		for i in spots.size():
			var k := fresh if (level == 2) == (i == 0) else 1.0  # level 2 added spot 0, level 3 the others
			if k > 0.01:
				_flag(IsoGrid.project(mid + spots[i]), (maxf(top, 10.0) + 14.0) * k, k)
	elif b["role"] == "decor":
		grow = 1.0 + 0.14 * (level - 1)  # decor: a bigger canopy
	for p in parts:
		var foot := Squircle.iso_points(IsoGrid.project(mid + p["at"] * grow), p["half"] * grow, 4.0, 48)
		block(self, foot, p["h"] * grow, p["z"] * grow, _tint(p["color"]))
	for p: Dictionary in scaffold[1]:
		block(self, Squircle.iso_points(IsoGrid.project(mid + p["at"]), p["half"], 4.0, 24), p["h"], p["z"], p["color"])
	if site >= 0.0:
		_ring(IsoGrid.project(mid) + Vector2(0, -_scaffold_h(top) - 20))
	if label != "":
		var f := Palette.FONT
		var at := IsoGrid.project(mid) + Vector2(0, -maxf(top, 10.0) * grow - 38)  # clear of the flags
		var w := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_colored_polygon(Squircle.points(at, Vector2(w * 0.5 + 9, 11), 4.0, 32), Palette.BUTTER)
		draw_string(f, at + Vector2(-w * 0.5, 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Palette.INK)

func _scaffold_h(top: float) -> float:
	return (top if site_upgrade else 14.0) + 8.0

## Wood posts at the footprint corners with beams on top; a SAND tarp (a covered stack on a new site,
## a sheet on the front-right face of an upgrade). Returns [behind the building, in front of it].
func _scaffold(fp: Vector2i, top: float) -> Array:
	var c := Vector2(fp) * 0.5 - Vector2(0.1, 0.1)
	var h := _scaffold_h(top)
	var P := Buildings.part
	var post := Vector2(0.05, 0.05)
	var back: Array = [
		P.call(Vector2(-c.x, -c.y), post, h, Palette.WOOD),
		P.call(Vector2(0, -c.y), Vector2(c.x, 0.04), 3, Palette.WOOD, h - 3),
		P.call(Vector2(-c.x, 0), Vector2(0.04, c.y), 3, Palette.WOOD, h - 3),
		P.call(Vector2(c.x, -c.y), post, h, Palette.WOOD),
		P.call(Vector2(-c.x, c.y), post, h, Palette.WOOD),
	]
	var front: Array = []
	if site_upgrade:
		front.append(P.call(Vector2(c.x, 0), Vector2(0.03, c.y - 0.06), h * 0.45, Palette.SAND, h * 0.2))
	else:
		back.append(P.call(Vector2.ZERO, c * 0.8, h * 0.55, Palette.SAND))
		back.append(P.call(Vector2.ZERO, c * 0.55, h * 0.2, Palette.shade(Palette.SAND, 0.06), h * 0.55))
	front += [
		P.call(Vector2(c.x, c.y), post, h, Palette.WOOD),
		P.call(Vector2(0, c.y), Vector2(c.x, 0.04), 3, Palette.WOOD, h - 3),
		P.call(Vector2(c.x, 0), Vector2(0.04, c.y), 3, Palette.WOOD, h - 3),
	]
	return [back, front]

## Progress ring on a small CREAM squircle badge: STONE track, MOSS sweep from the top.
func _ring(at: Vector2) -> void:
	draw_colored_polygon(Squircle.points(at, Vector2(12, 12), 4.0, 32), Palette.CREAM)
	draw_arc(at, 7.5, 0.0, TAU, 32, Palette.STONE, 3.5, true)
	if site > 0.0:
		draw_arc(at, 7.5, -PI / 2, -PI / 2 + TAU * site, 32, Palette.MOSS, 3.5, true)

func _tint(c: Color) -> Color:
	return c.lerp(Palette.STONE.lerp(c, 0.2), grey)

## A thin pole with a small rounded BUTTER pennant at its top, pennant scaled by k.
func _flag(base: Vector2, h: float, k := 1.0) -> void:
	block(self, Squircle.iso_points(base, Vector2(0.03, 0.03), 4.0, 16), h, 0.0, _tint(Palette.WOOD))
	var tip := base + Vector2(0, -h)
	draw_colored_polygon(Squircle.points(tip + Vector2(6, 4) * k, Vector2(6, 3.6) * k), _tint(Palette.BUTTER))

## Extruded squircle: sides for edges facing the viewer, then the top face lifted by z + h.
static func block(ci: CanvasItem, foot: PackedVector2Array, h: float, z: float, c: Color) -> void:
	var lift := Vector2(0, -z)
	var up := Vector2(0, -z - h)
	if h > 0.0:
		for i in foot.size():
			var a := foot[i]
			var b := foot[(i + 1) % foot.size()]
			var nrm := (b - a).orthogonal()  # outward normal for a clockwise-on-screen loop
			if nrm.y <= 0.0:
				continue  # faces away from the camera
			# Left-facing sides lighter, right-facing darker, blended for a soft round look.
			var amt := lerpf(0.12, 0.22, clampf(nrm.normalized().x * 0.5 + 0.5, 0.0, 1.0))
			ci.draw_colored_polygon(PackedVector2Array([a + lift, b + lift, b + up, a + up]), Palette.shade(c, amt))
	var top := PackedVector2Array()
	for p in foot:
		top.append(p + up)
	ci.draw_colored_polygon(top, c)
