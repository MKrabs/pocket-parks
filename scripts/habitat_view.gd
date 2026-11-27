class_name HabitatView
extends BuildingView
# Draws a painted habitat (ParkMap.habitats): a ground-coloured floor and its fence along the outline, in the fence's
# style: wood rails, glass panels, a stone wall, or a low net footing under one dome over the bounding area.
# ZooView splits a habitat into layers so walkers and buildings sort right: one "floor" under everything, one
# "fence" per cell (its outline sides, depth-sorted like a 1×1 building), one "dome". The preview draws "all".

var cells: Array = []  # every cell of the habitat (or of the painted rectangle)
var cell := GridView.NONE  # layer "fence": draw only this cell's sides
var layer := "all"  # "floor", "fence", "dome" or "all"
var fence := "fence"  # style: fence, glass, net, wall

# Tuning (px heights, tiles widths):
const RAIL_H := 12.0
const GLASS_H := 22.0
const WALL_H := 16.0
const WALL_THICK := 0.09
const NET_FOOT := 4.0
const GLASS_ALPHA_ := 0.35

static func of(id: String, cs: Array, origin_: Vector2i, layer_: String) -> HabitatView:
	var v := HabitatView.new(id)
	v.cells = cs
	v.origin = origin_
	v.layer = layer_
	v.fence = Buildings.get_def(id)["habitat"]
	return v

## Local screen point of grid point `p` (node sits on the origin cell's centre).
func _at(p: Vector2) -> Vector2:
	return IsoGrid.project(p - Vector2(origin))

func _draw() -> void:
	if layer in ["floor", "all"]:
		for c: Vector2i in cells:
			var k := 0.51  # a hair over half a tile, so neighbouring cells leave no seam
			draw_colored_polygon(PackedVector2Array([_at(Vector2(c) + Vector2(-k, -k)), _at(Vector2(c) + Vector2(k, -k)),
				_at(Vector2(c) + Vector2(k, k)), _at(Vector2(c) + Vector2(-k, k))]), Palette.HABITAT)
	if layer in ["fence", "all"]:
		var sides := ParkMap.outline(cells if cell == GridView.NONE else [cell]).filter(
			func(s: Array) -> bool: return not s[0] + s[1] in cells)
		sides.sort_custom(func(a: Array, b: Array) -> bool:  # back to front: by depth, back sides of a cell first
			var da: int = 2 * (a[0].x + a[0].y) + a[1].x + a[1].y
			var db: int = 2 * (b[0].x + b[0].y) + b[1].x + b[1].y
			return da < db)
		var grow := 1.0 if site < 0.0 else 0.25 + 0.75 * site  # a site's fence rises as the builder works
		for s: Array in sides:
			_side(s[0], s[1], grow)
		if site >= 0.0 and (cell == origin or cell == GridView.NONE):
			_ring(Vector2(0, -RAIL_H - 26))
	if layer in ["dome", "all"] and fence == "net":
		var r := Rect2(Vector2(cells[0]), Vector2.ZERO)
		for c: Vector2i in cells:
			r = r.expand(Vector2(c)).expand(Vector2(c) + Vector2.ONE)
		var half := r.size * 0.5 - Vector2(0.06, 0.06)
		var h := 26.0 + 12.0 * minf(r.size.x, r.size.y)
		_dome(_at(r.get_center() - Vector2(0.5, 0.5)), half, h * (1.0 if site < 0.0 else maxf(site, 0.05)), Palette.SKY, 0.0, 0.0)
	if label != "":
		_pill(_at(Vector2(cells[0])) + Vector2(0, -RAIL_H - 34))

## One outline side of cell `c` facing `d`, in the fence's style, `grow` of its full height.
func _side(c: Vector2i, d: Vector2i, grow: float) -> void:
	var along := Vector2(absi(d.y), absi(d.x)) * 0.5  # half the side, along it
	var mid := Vector2(c) + Vector2(d) * 0.5
	var a := _at(mid - along)
	var b := _at(mid + along)
	var amt := 0.22 if d.x != 0 else 0.12  # faces along x look right (darker), along y look left
	match fence:
		"fence":
			var h := RAIL_H * grow
			for y in [h * 0.4, h - 2.5]:
				_band(a, b, h, h, y, y + 2.5, Palette.shade(Palette.WOOD, amt))
			for p in [a, b]:
				block(self, Squircle.iso_points(p, Vector2(0.06, 0.06), 4.0, 16), h + 2.0, 0.0, Palette.WOOD)
		"glass":
			var h := GLASS_H * grow
			block(self, _strip(mid, along, 0.07), 4.0, 0.0, Palette.STONE)
			_band(a, b, h, h, 4.0, h - 3.0, Color(Palette.shade(Palette.WATER, amt), GLASS_ALPHA_))
			_band(a, b, h, h, h * 0.55, h * 0.66, Color(Palette.CLOUD, 0.4))
			_band(a, b, h, h, h - 3.0, h, Palette.shade(Palette.STONE, amt))
		"wall":
			block(self, _strip(mid - Vector2(d) * WALL_THICK, along, WALL_THICK), WALL_H * grow, 0.0, Palette.STONE)
		"net":
			_band(a, b, NET_FOOT, NET_FOOT, 0.0, NET_FOOT, Palette.shade(Palette.WOOD, amt))

## A rounded strip `thick` tiles wide along a side (half length `along`), as an iso footprint.
func _strip(mid: Vector2, along: Vector2, thick: float) -> PackedVector2Array:
	var half := along + Vector2(thick, thick)
	return Squircle.iso_points(_at(mid), half, 6.0, 32)
