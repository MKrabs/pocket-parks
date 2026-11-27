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
var wrecked := false:  # wrecked by a hooligan: crumbles into its damaged variant (see wreck_plan)
	set(w):
		wrecked = w
		if not is_inside_tree():
			broken = 1.0 if w else 0.0
			return
		var t := create_tween()
		if w:
			t.tween_property(self, "broken", 1.0, Motion.CRUMBLE_TIME).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		else:
			t.tween_property(self, "broken", 0.0, Motion.MEND_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
var broken := 0.0:  # 0 = intact, 1 = fully wrecked (dips below 0 as parts hop back)
	set(b):
		broken = b
		queue_redraw()

# Damaged look (tuning):
const FALL_FROM := 0.6  # parts starting at or above this share of the building's height slide off...
const FALL_MIN_TOP := 12.0  # ...if the building is at least this tall (px)
const FALL_TILT := Vector2(0.25, 0.4)  # radians the fallen parts lie tilted
const BODY_SHRINK := 0.93  # body half size and height when wrecked
const CHIP := 0.45  # chipped-out corner squircle, share of the part's half size
const CHIP_BAND := 0.35  # top share of the part's height the chips cut into
const DAMAGE_SHADE := 0.07  # wrecked colours: this much darker...
const DAMAGE_DESAT := 0.2  # ...and this much less saturated
var fresh := 1.0:  # scale of the flags this level added (pops 0 -> 1 after an upgrade)
	set(f):
		fresh = f
		queue_redraw()

var site := -1.0:  # under construction: progress 0..1 (scaffold + ring); -1 = done
	set(s):
		if s != site:
			site = s
			queue_redraw()
var tint := Color(Palette.INK, 0.0):  # charm view: every part drawn in this colour (alpha 0 = off)
	set(t):
		if t != tint:
			tint = t
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

## How this building breaks, seeded by its origin so it always breaks the same way.
## fallen: indices into turned() that slide off; shift (tiles) and tilt of where they land; drop: px they fall;
## chips: part index -> corner signs cut out of its top; rubble: parts lying around the footprint;
## gap: outline angle where shaped parts break (a breach in a wall, a tear in a dome).
static func wreck_plan(building_id: String, turn: int, at: Vector2i) -> Dictionary:
	var parts := turned(building_id, turn)
	var fp := ParkMap.size(building_id, turn)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(at)
	var top := 0.0
	for p in parts:
		top = maxf(top, p["z"] + p["h"])
	var fallen: Array = []
	var drop := 0.0
	if top >= FALL_MIN_TOP:
		drop = top
		for i in parts.size():
			if parts[i]["z"] >= top * FALL_FROM and not parts[i].has("kind"):  # shaped parts break in place
				fallen.append(i)
				drop = minf(drop, parts[i]["z"])
	var axis := rng.randi_range(0, 1)  # slides off a front side (+x or +y), so it lands in view
	var shift := Vector2.ZERO
	shift[axis] = fp[axis] * 0.5 + 0.2
	shift[1 - axis] = rng.randf_range(-0.2, 0.2) * fp[1 - axis]
	var tilt := rng.randf_range(FALL_TILT.x, FALL_TILT.y) * (1.0 if axis == 0 else -1.0)  # tips away from the body
	var chips := {}
	var corners := [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
	for i in parts.size():
		var p: Dictionary = parts[i]
		if i not in fallen and not p.has("kind") and p["h"] >= 6.0 and p["half"].x >= 0.2 and p["half"].y >= 0.2:
			var a := rng.randi_range(0, 3)
			chips[i] = [corners[a], corners[(a + rng.randi_range(1, 3)) % 4]]
	var rubble: Array = []
	for k in rng.randi_range(3, 5):
		var ang := rng.randf_range(0.0, TAU)
		var r := Vector2(fp) * 0.5 + Vector2(0.12, 0.12)
		var color := Palette.STONE if rng.randf() < 0.5 else Palette.WOOD
		var half := Vector2(rng.randf_range(0.06, 0.12), rng.randf_range(0.05, 0.1))
		rubble.append(Buildings.part(Vector2(cos(ang) * r.x, sin(ang) * r.y), half, rng.randf_range(3.0, 6.0), color))
	var gap := rng.randf_range(0.15, PI / 2 - 0.15)  # outline angle facing the viewer
	return {"fallen": fallen, "shift": shift, "tilt": tilt, "drop": drop, "chips": chips, "rubble": rubble, "gap": gap}

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
	if broken == 0.0 or parts.is_empty():
		for p in parts:
			if p.has("kind"):
				_shaped(p, mid, 0.0, 0.0)
				continue
			var foot := Squircle.iso_points(IsoGrid.project(mid + p["at"] * grow), p["half"] * grow, 4.0, 48)
			block(self, foot, p["h"] * grow, p["z"] * grow, tint if tint.a > 0.0 else p["color"])
	else:
		_draw_wrecked(parts, mid, grow, broken)
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

## The damaged variant, `b` of the way there: shrunken chipped body, fallen top parts, rubble.
func _draw_wrecked(parts: Array, mid: Vector2, grow: float, b: float) -> void:
	var plan := wreck_plan(id, turn, origin)
	var k := clampf(b, 0.0, 1.0)
	var s := lerpf(1.0, BODY_SHRINK, b)
	var front: Array = []  # [depth, callable], drawn after the body back to front
	for p: Dictionary in plan["rubble"]:
		var draw_it := func() -> void:
			if k > 0.01:
				block(self, Squircle.iso_points(IsoGrid.project(mid + p["at"]), p["half"] * k, 4.0, 16), p["h"] * k, 0.0, _tint(p["color"]))
		if p["at"].x + p["at"].y < 0.0:
			draw_it.call()
		else:
			front.append([p["at"].x + p["at"].y, draw_it])
	for i in parts.size():
		var p: Dictionary = parts[i]
		if i in plan["fallen"]:
			continue
		if p.has("kind"):
			_shaped(p, mid, k, plan["gap"])
			continue
		var c := _tint(p["color"])
		var at: Vector2 = IsoGrid.project(mid + p["at"] * grow)
		var half: Vector2 = p["half"] * grow * s
		var h: float = p["h"] * grow * s
		var z: float = p["z"] * grow * s
		var foot := Squircle.iso_points(at, half, 4.0, 48)
		if plan["chips"].has(i) and k > 0.05:
			block(self, foot, h * (1.0 - CHIP_BAND), z, c)
			for corner: Vector2 in plan["chips"][i]:
				foot = _chipped(foot, Squircle.iso_points(IsoGrid.project(mid + (p["at"] + p["half"] * corner * 0.85 * s) * grow), half * CHIP * k, 4.0, 24))
			block(self, foot, h * CHIP_BAND, z + h * (1.0 - CHIP_BAND), c)
		else:
			block(self, foot, h, z, c)
	var shift: Vector2 = plan["shift"] * b
	var lift: float = sin(PI * k) * Motion.MEND_HOP - plan["drop"] * grow * b
	front.append([plan["shift"].x + plan["shift"].y, func() -> void:
		var pivot := IsoGrid.project(mid + shift)
		draw_set_transform_matrix(Transform2D(plan["tilt"] * b, pivot) * Transform2D(0.0, -pivot))
		for i: int in plan["fallen"]:
			var p: Dictionary = parts[i]
			var foot := Squircle.iso_points(IsoGrid.project(mid + p["at"] * grow + shift), p["half"] * grow, 4.0, 48)
			block(self, foot, p["h"] * grow, p["z"] * grow + lift, _tint(p["color"]))
		draw_set_transform_matrix(Transform2D.IDENTITY)])
	front.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	for f in front:
		f[1].call()

## A shaped part (see Buildings.shaped): one silhouette. k = how wrecked (0..1), gap = where it breaks.
func _shaped(p: Dictionary, mid: Vector2, k: float, gap: float) -> void:
	var at := IsoGrid.project(mid + p["at"])
	var c := _tint(p["color"])
	match p["kind"]:
		"dome":
			_dome(at - Vector2(0, p["z"]), p["half"], p["h"] * (1.0 - DOME_SAG * k), c, k, gap)
		"water":
			var h: float = p["h"] * (1.0 - WATER_DRAIN * k)  # drains through the cracked glass
			block(self, Squircle.iso_points(at, p["half"], 4.0, 48), h, p["z"], c)
			var shine := Squircle.iso_points(at + Vector2(-5, -p["z"] - h), p["half"] * 0.6, 4.0, 48)
			draw_colored_polygon(shine, c.lerp(Palette.CLOUD, 0.35))
		_:
			_ring_shape(at - Vector2(0, p["z"]), p, c, k, gap)

# Shaped parts (tuning):
const RING_STEPS := 96  # outline samples of a ring
const THICK := {"wall": 0.16, "glass": 0.05, "fence": 0.0}  # ring thickness, tiles
const BREACH := 0.6  # wrecked ring: half width of the breach, radians of outline
const BREACH_DEPTH := 0.85  # share of the height knocked out at its middle
const GLASS_ALPHA := 0.3
const DOME_ALPHA := 0.32
const DOME_N := 2.5  # dome profile superellipse exponent (2 = round, 4 = boxy)
const DOME_SAG := 0.2  # wrecked dome: share of its height lost
const WATER_DRAIN := 0.45  # wrecked tank: share of the water lost

## A ring along the squircle outline, only its far (side -1) or near (side 1) half, segments back to front.
## Wall: STONE faces with a darker base and a lighter cap band. Glass: translucent panels with a highlight stripe
## under a STONE rim. Fence: two thin rails with a post on each diagonal. Wrecked: a breach notched in at `gap`.
func _ring_shape(base: Vector2, p: Dictionary, c: Color, k: float, gap: float) -> void:
	var kind: String = p["kind"]
	var half: Vector2 = p["half"]
	var out := Squircle.points(Vector2.ZERO, half, 4.0, RING_STEPS)
	var inn := Squircle.points(Vector2.ZERO, half - Vector2.ONE * THICK[kind], 4.0, RING_STEPS)
	var hs := PackedFloat32Array()  # height at each outline point
	for i in RING_STEPS:
		var d := absf(angle_difference(TAU * i / RING_STEPS, gap))
		hs.append(p["h"] * (1.0 - k * BREACH_DEPTH * (1.0 - smoothstep(0.0, BREACH, d))))
	var segs: Array = []
	for i in RING_STEPS:
		var j := (i + 1) % RING_STEPS
		var depth := out[i].x + out[i].y + out[j].x + out[j].y
		if (depth < 0.0) == (p["side"] < 0):
			segs.append([depth, i, j])
	segs.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	var rim := _tint(Palette.STONE)
	for s: Array in segs:
		var i: int = s[1]
		var j: int = s[2]
		var oa := base + IsoGrid.project(out[i])
		var ob := base + IsoGrid.project(out[j])
		var ha := hs[i]
		var hb := hs[j]
		var nrm := (ob - oa).orthogonal()
		if kind == "fence":
			var col := Palette.shade(c, _side_shade(nrm if nrm.y > 0.0 else -nrm))
			for y in [p["h"] * 0.45, p["h"] - 2.5]:
				_band(oa, ob, ha, hb, y, y + 2.5, col)
			if i % (RING_STEPS / 4) == RING_STEPS / 8:  # a post every quarter of the outline (~2.5 tiles)
				block(self, Squircle.iso_points(oa, Vector2(0.07, 0.07), 4.0, 16), ha + 2.0, 0.0, c)
			continue
		var ia := base + IsoGrid.project(inn[i])
		var ib := base + IsoGrid.project(inn[j])
		var nin := (ib - ia).orthogonal()
		if nin.y < 0.0:
			_face(ia, ib, ha, hb, -nin, kind, c, rim)
		if nrm.y > 0.0:
			_face(oa, ob, ha, hb, nrm, kind, c, rim)
		var up_a := Vector2(0, -ha)
		var up_b := Vector2(0, -hb)
		_poly([oa + up_a, ob + up_b, ib + up_b, ia + up_a], rim if kind == "glass" else c)

## One visible face of a wall or glass segment between outline points a and b (heights ha, hb).
func _face(a: Vector2, b: Vector2, ha: float, hb: float, nrm: Vector2, kind: String, c: Color, rim: Color) -> void:
	var amt := _side_shade(nrm)
	var h := maxf(ha, hb)
	if kind == "glass":
		_band(a, b, ha, hb, 0.0, h - 3.0, Color(Palette.shade(c, amt), GLASS_ALPHA))
		if nrm.y > 0.0:  # outer panels catch the light
			_band(a, b, ha, hb, h * 0.55, h * 0.68, Color(Palette.CLOUD, 0.45))
		_band(a, b, ha, hb, h - 3.0, h, Palette.shade(rim, amt))
		return
	_band(a, b, ha, hb, 0.0, 4.0, Palette.shade(c, amt + 0.1))  # darker base
	_band(a, b, ha, hb, 4.0, h - 3.0, Palette.shade(c, amt))
	_band(a, b, ha, hb, h - 3.0, h, Palette.shade(c, amt - 0.07))  # cap band

## The strip of a face between heights lo and hi (px), cut down to the face's height at each end.
func _band(a: Vector2, b: Vector2, ha: float, hb: float, lo: float, hi: float, col: Color) -> void:
	_poly([a - Vector2(0, minf(lo, ha)), b - Vector2(0, minf(lo, hb)), b - Vector2(0, minf(hi, hb)), a - Vector2(0, minf(hi, ha))], col)

## Polygon with repeated corners dropped; skipped if it collapses below a triangle.
func _poly(pts: Array, col: Color) -> void:
	var out := PackedVector2Array()
	for q: Vector2 in pts:
		if out.is_empty() or not q.is_equal_approx(out[-1]):
			out.append(q)
	if out.size() > 2 and out[0].is_equal_approx(out[-1]):
		out.remove_at(out.size() - 1)
	if out.size() >= 3 and absf(_area(out)) > 0.5:
		draw_colored_polygon(out, col)

static func _area(pts: PackedVector2Array) -> float:
	var s := 0.0
	for i in pts.size():
		s += pts[i - 1].cross(pts[i])
	return s * 0.5

## Side shading as in block(): left-facing lighter, right-facing darker.
static func _side_shade(nrm: Vector2) -> float:
	return lerpf(0.12, 0.22, clampf(nrm.normalized().x * 0.5 + 0.5, 0.0, 1.0))

## Point on a dome over a squircle footprint: g = footprint outline point, th = elevation 0..PI/2.
static func _dome_at(base: Vector2, g: Vector2, th: float, h: float) -> Vector2:
	var e := 2.0 / DOME_N
	return base + IsoGrid.project(g * pow(cos(th), e)) - Vector2(0, h * pow(sin(th), e))

## Translucent dome: faint back net arcs, the shell (and a paler upper layer), a highlight arc, then the front arcs
## and a WOOD footing ring. Wrecked: a torn flap open towards `gap`, the nearest arc snapped and sagging.
func _dome(base: Vector2, half: Vector2, h: float, c: Color, k: float, gap: float) -> void:
	var foot := Squircle.points(Vector2.ZERO, half, 4.0, 48)
	var pts := PackedVector2Array()
	for t in 9:
		for g in foot:
			pts.append(_dome_at(base, g, PI / 2 * t / 8.0, h))
	var hull := Geometry2D.convex_hull(pts)
	var upper := PackedVector2Array()
	for g in foot:
		upper.append(_dome_at(base + Vector2(-3, 0), g * 0.8, PI / 2 * 0.62, h))
	upper = Geometry2D.convex_hull(upper + PackedVector2Array([_dome_at(base, foot[0], PI / 2, h)]))
	var wood := _tint(Palette.WOOD)
	var net_back: Array = []
	var net_front: Array = []
	var snap := roundi(clampf(gap / (PI / 4) - 0.5, 0.0, 3.0))  # the arc nearest the tear
	for m in 4:
		var a := PI / 8 + m * PI / 4
		var line: Array = []  # [point, depth sign]
		for w in 33:  # up one side (w < 16) and down the other
			var th := PI / 2 * (w / 16.0 if w <= 16 else (32 - w) / 16.0)
			var az := a + PI if w < 16 else a
			var g := Vector2(half.x * signf(cos(az)) * sqrt(absf(cos(az))), half.y * signf(sin(az)) * sqrt(absf(sin(az))))
			var hh := h
			if m == snap and k > 0.0:
				var d := absf(w - 23.0) / 16.0
				if d < 0.2 * k:
					line.append(null)  # the snapped gap
					continue
				hh *= 1.0 - k * 0.5 * (1.0 - smoothstep(0.0, 0.5, d))
			line.append([_dome_at(base, g, th, hh), (g.x + g.y) * cos(th) >= 0.0])
		var run := PackedVector2Array()
		var front := false
		for q in line + [null]:
			if q == null or (run.size() > 0 and q[1] != front):
				if run.size() > 1:
					(net_front if front else net_back).append(run)
				run = PackedVector2Array([run[-1]]) if q != null and run.size() > 0 else PackedVector2Array()
			if q != null:
				run.append(q[0])
				front = q[1]
	for r: PackedVector2Array in net_back:
		draw_polyline(r, Color(wood, 0.45), 1.5, true)
	var shell := [hull]
	if k > 0.0:  # a jagged flap torn open from the footing up towards the top
		var g := Vector2(half.x * sqrt(cos(gap)), half.y * sqrt(sin(gap)))
		var tip := _dome_at(base, g, 1.05, h)
		var low := _dome_at(base, g, 0.0, h) + Vector2(0, 8)
		var w := 26.0 * k
		var tear := PackedVector2Array([low + Vector2(-w, 0), tip.lerp(low, 0.5) + Vector2(-w * 0.7, 0), tip + Vector2(-w * 0.3, 5),
			tip + Vector2(0, -3), tip + Vector2(w * 0.35, 7), tip.lerp(low, 0.45) + Vector2(w * 0.6, 0), low + Vector2(w, 0)])
		shell = Geometry2D.clip_polygons(hull, tear)
	for s: PackedVector2Array in shell:
		if not Geometry2D.is_polygon_clockwise(s) == Geometry2D.is_polygon_clockwise(hull):
			continue
		draw_colored_polygon(s, Color(c, DOME_ALPHA))
		draw_polyline(s + PackedVector2Array([s[0]]), Color(Palette.shade(c, 0.2), 0.5), 1.5, true)  # soft outline
	draw_colored_polygon(upper, Color(Palette.CLOUD, 0.14))
	var r := Rect2(hull[0], Vector2.ZERO)
	for q in hull:
		r = r.expand(q)
	var arc := PackedVector2Array()
	for i in 13:
		var t := deg_to_rad(195.0 + 55.0 * i / 12.0)
		arc.append(r.get_center() + Vector2(cos(t) * r.size.x, sin(t) * r.size.y) * 0.5 * 0.8)
	draw_polyline(arc, Color(Palette.CLOUD, 0.7), 3.0, true)
	var ring := PackedVector2Array()
	for g in foot:
		ring.append(base + IsoGrid.project(g))
	ring.append(ring[0])
	draw_polyline(ring, wood, 2.5, true)
	for run: PackedVector2Array in net_front:
		draw_polyline(run, wood, 2.0, true)

## `foot` with `cut` taken out of it (the outline that keeps foot's winding, so block() still finds its front sides).
static func _chipped(foot: PackedVector2Array, cut: PackedVector2Array) -> PackedVector2Array:
	var cw := Geometry2D.is_polygon_clockwise(foot)
	for poly: PackedVector2Array in Geometry2D.clip_polygons(foot, cut):
		if Geometry2D.is_polygon_clockwise(poly) == cw:
			return poly
	return foot

## Wrecked colours: a bit darker and less saturated, still pastel.
func _tint(c: Color) -> Color:
	var k := clampf(broken, 0.0, 1.0)
	var d := Palette.shade(c, DAMAGE_SHADE * k)
	d.s *= 1.0 - DAMAGE_DESAT * k
	return d

## A thin pole with a small rounded BUTTER pennant at its top, pennant scaled by k. Wrecked: it lies tipped over.
func _flag(base: Vector2, h: float, k := 1.0) -> void:
	var tip_over := clampf(broken, 0.0, 1.0) * (1.25 if posmod(int(base.x), 2) == 0 else -1.25)
	draw_set_transform_matrix(Transform2D(tip_over, base) * Transform2D(0.0, -base))
	block(self, Squircle.iso_points(base, Vector2(0.03, 0.03), 4.0, 16), h, 0.0, _tint(Palette.WOOD))
	var tip := base + Vector2(0, -h)
	draw_colored_polygon(Squircle.points(tip + Vector2(6, 4) * k, Vector2(6, 3.6) * k), _tint(Palette.BUTTER))
	draw_set_transform_matrix(Transform2D.IDENTITY)

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
