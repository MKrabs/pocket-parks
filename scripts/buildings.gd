class_name Buildings
# Sample building catalog. Each entry: name, footprint (tiles), cost, parts.
# A part is one extruded squircle block: at/half in tiles (relative to the footprint centre),
# h = height px, z = lift px, color. Parts are drawn in list order (back to front).

static var CATALOG: Dictionary = {
	"path": {"name": "Path", "footprint": Vector2i(1, 1), "cost": 5,
		"parts": [part(Vector2.ZERO, Vector2(0.46, 0.46), 3, Palette.SAND)]},
	"tree": {"name": "Tree", "footprint": Vector2i(1, 1), "cost": 20,
		"parts": tree(Vector2.ZERO)},
	"snack_stand": {"name": "Snack Stand", "footprint": Vector2i(1, 1), "cost": 60,
		"parts": [
			part(Vector2.ZERO, Vector2(0.3, 0.3), 20, Palette.WOOD),
			part(Vector2.ZERO, Vector2(0.42, 0.42), 7, Palette.CLAY, 20),
			part(Vector2.ZERO, Vector2(0.24, 0.24), 5, Palette.CLAY, 27),
		]},
	"pond": {"name": "Pond", "footprint": Vector2i(2, 2), "cost": 80,
		"parts": [
			part(Vector2.ZERO, Vector2(0.92, 0.92), 7, Palette.STONE),
			part(Vector2.ZERO, Vector2(0.7, 0.7), 0, Palette.WATER, 7),
		]},
	"enclosure": {"name": "Enclosure", "footprint": Vector2i(3, 3), "cost": 150,
		"parts": enclosure()},
}

static func part(at: Vector2, half: Vector2, h: float, color: Color, z := 0.0) -> Dictionary:
	return {"at": at, "half": half, "h": h, "z": z, "color": color}

static func tree(at: Vector2) -> Array:
	return [
		part(at, Vector2(0.1, 0.1), 14, Palette.WOOD),
		part(at, Vector2(0.36, 0.36), 12, Palette.MOSS, 12),
		part(at, Vector2(0.24, 0.24), 10, Palette.MOSS, 24),
	]

static func enclosure() -> Array:
	# Fence posts on a squircle ring, plus rock and tree inside, depth-sorted by u+v.
	var items: Array = []  # [depth, parts]
	# Sample the ring densely, then drop a post every `gap` of arc length so they don't bunch at corners.
	var ring := Squircle.points(Vector2.ZERO, Vector2(1.32, 1.32), 4.0, 2000)
	var seg := PackedFloat32Array()
	var total := 0.0
	for i in ring.size():
		seg.append(IsoGrid.project(ring[i]).distance_to(IsoGrid.project(ring[i - 1])))
		total += seg[i]
	var gap := total / roundf(total / 13.0)  # ~13 screen px between posts, evenly divided
	var walked := gap
	for i in ring.size():
		walked += seg[i]
		if walked >= gap:
			walked -= gap
			var p := ring[i]
			items.append([p.x + p.y, [part(p, Vector2(0.07, 0.07), 12, Palette.WOOD)]])
	var rock := Vector2(0.45, -0.45)
	items.append([0.0, [part(rock, Vector2(0.26, 0.2), 9, Palette.STONE)]])
	items.append([0.01, tree(Vector2(-0.4, 0.4))])
	items.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var out: Array = [part(Vector2.ZERO, Vector2(1.42, 1.42), 3, Palette.GRASS_DARK)]
	for it in items:
		out.append_array(it[1])
	return out
