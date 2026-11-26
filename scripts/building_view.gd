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

func _init(building_id: String) -> void:
	id = building_id

func _draw() -> void:
	var b: Dictionary = Buildings.get_def(id)
	var fp: Vector2i = b["footprint"]
	var mid := Vector2(fp.x - 1, fp.y - 1) * 0.5  # footprint centre in grid coords
	var top := 0.0
	for p in b["parts"]:
		top = maxf(top, p["z"] + p["h"])
	var grow := 1.0
	if Buildings.upgradable(id) and b["role"] != "decor" and level >= 2:
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
	for p in b["parts"]:
		var foot := Squircle.iso_points(IsoGrid.project(mid + p["at"] * grow), p["half"] * grow, 4.0, 48)
		block(self, foot, p["h"] * grow, p["z"] * grow, _tint(p["color"]))
	if label != "":
		var f := ThemeDB.fallback_font
		var at := IsoGrid.project(mid) + Vector2(0, -maxf(top, 10.0) * grow - 38)  # clear of the flags
		var w := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_colored_polygon(Squircle.points(at, Vector2(w * 0.5 + 9, 11), 4.0, 32), Palette.BUTTER)
		draw_string(f, at + Vector2(-w * 0.5, 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Palette.INK)

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
