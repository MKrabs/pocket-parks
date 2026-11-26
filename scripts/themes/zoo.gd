class_name ZooTheme
# Zoo theme pack: the first theme.

static func catalog() -> Dictionary:
	var B := Buildings  # short alias for the part helpers
	return {
		"zoo_gate": {"name": "Zoo Gate", "role": "entrance", "footprint": Vector2i(1, 1), "cost": 100,
			"parts": B.arch(Palette.WOOD, Palette.CLAY)},
		"path": {"name": "Path", "role": "path", "footprint": Vector2i(1, 1), "cost": 5,
			"parts": [B.part(Vector2.ZERO, Vector2(0.46, 0.46), 3, Palette.SAND)]},
		"tree": {"name": "Tree", "role": "decor", "appeal": 2, "footprint": Vector2i(1, 1), "cost": 20,
			"specialty": "landscaper", "mode": "faster", "parts": B.tree(Vector2.ZERO)},
		"fountain": {"name": "Fountain", "role": "decor", "appeal": 8, "footprint": Vector2i(1, 1), "cost": 70,
			"specialty": "water", "mode": "only",
			"parts": [
				B.part(Vector2.ZERO, Vector2(0.42, 0.42), 6, Palette.STONE),
				B.part(Vector2.ZERO, Vector2(0.33, 0.33), 0, Palette.WATER, 6),
				B.part(Vector2.ZERO, Vector2(0.07, 0.07), 12, Palette.STONE, 6),
				B.part(Vector2.ZERO, Vector2(0.2, 0.2), 3, Palette.STONE, 18),
				B.part(Vector2.ZERO, Vector2(0.14, 0.14), 0, Palette.WATER, 21),
				B.part(Vector2.ZERO, Vector2(0.04, 0.04), 9, Palette.WATER, 21),
			]},
		"snack_stand": {"name": "Snack Stand", "role": "shop", "price": 5, "footprint": Vector2i(1, 1), "cost": 60,
			"specialty": "carpenter", "mode": "faster",
			"parts": [
				B.part(Vector2.ZERO, Vector2(0.3, 0.3), 20, Palette.WOOD),
				B.part(Vector2.ZERO, Vector2(0.42, 0.42), 7, Palette.CLAY, 20),
				B.part(Vector2.ZERO, Vector2(0.24, 0.24), 5, Palette.CLAY, 27),
			]},
		"pond": {"name": "Pond", "role": "attraction", "appeal": 5, "capacity": 6, "footprint": Vector2i(2, 2), "cost": 80,
			"specialty": "water", "mode": "faster",
			"parts": [
				B.part(Vector2.ZERO, Vector2(0.92, 0.92), 7, Palette.STONE),
				B.part(Vector2.ZERO, Vector2(0.7, 0.7), 0, Palette.WATER, 7),
			]},
		"enclosure": {"name": "Enclosure", "role": "attraction", "appeal": 10, "capacity": 10, "footprint": Vector2i(3, 3), "cost": 150,
			"specialty": "carpenter", "mode": "faster", "parts": enclosure()},
		"water_tank": {"name": "Water Tank", "role": "attraction", "appeal": 14, "capacity": 12, "footprint": Vector2i(3, 3), "cost": 240,
			"specialty": "water", "mode": "only", "parts": water_tank()},
		"aviary": {"name": "Aviary", "role": "attraction", "appeal": 14, "capacity": 12, "footprint": Vector2i(3, 3), "cost": 240,
			"specialty": "aviary", "mode": "only", "parts": aviary()},
		"reinforced": {"name": "Reinforced Enclosure", "role": "attraction", "appeal": 15, "capacity": 12, "footprint": Vector2i(3, 3), "cost": 260,
			"specialty": "heavy", "mode": "only", "parts": enclosure(Palette.STONE, Vector2(0.13, 0.13), 16, 7.0)},
		"builder_shed": {"name": "Builder Shed", "role": "staff", "footprint": Vector2i(1, 1), "cost": 80,
			"specialty": "carpenter", "mode": "faster", "parts": B.shed(Palette.CLAY)},
	}

## Glass tank of WATER on a STONE plinth, framed by STONE corner posts and a rim on top.
static func water_tank() -> Array:
	var P := Buildings.part
	var out: Array = [P.call(Vector2.ZERO, Vector2(1.42, 1.42), 6, Palette.STONE)]
	var c := 1.18
	out.append(P.call(Vector2(-c, -c), Vector2(0.1, 0.1), 26, Palette.STONE, 6))
	out.append(P.call(Vector2.ZERO, Vector2(1.22, 1.22), 24, Palette.WATER, 6))
	out.append(P.call(Vector2(0.3, -0.35), Vector2(0.3, 0.22), 3, Palette.STONE, 30))  # rock breaking the surface
	out.append(P.call(Vector2(-0.4, 0.3), Vector2(0.14, 0.12), 2, Palette.MOSS, 30))   # weed patch
	for at in [Vector2(c, -c), Vector2(-c, c), Vector2(c, c)]:
		out.append(P.call(at, Vector2(0.1, 0.1), 26, Palette.STONE, 6))
	return out

## Netted dome: thin WOOD arcs (meridians) over a grass floor with a tree and a perch inside.
static func aviary() -> Array:
	var P := Buildings.part
	var out: Array = [P.call(Vector2.ZERO, Vector2(1.42, 1.42), 3, Palette.GRASS_DARK)]
	out.append_array(Buildings.tree(Vector2(-0.3, -0.3)))
	out.append(P.call(Vector2(0.45, 0.35), Vector2(0.05, 0.05), 18, Palette.WOOD, 3))
	out.append(P.call(Vector2(0.45, 0.35), Vector2(0.22, 0.04), 3, Palette.WOOD, 21))
	var r := 1.3
	var top := 58.0
	var beads: Array = []  # [depth, part]
	for k in 3:
		var a := PI * k / 3.0 + PI / 12.0
		for i in 33:
			var t := PI * i / 32.0
			var at := Vector2(cos(a), sin(a)) * r * cos(t)
			beads.append([at.x + at.y, P.call(at, Vector2(0.05, 0.05), 5, Palette.WOOD, 3 + top * sin(t))])
	beads.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	for b in beads:
		out.append(b[1])
	return out

static func enclosure(post_color := Palette.WOOD, post := Vector2(0.07, 0.07), h := 12.0, spacing := 13.0) -> Array:
	# Fence posts (or wall blocks) on a squircle ring, plus rock and tree inside, depth-sorted by u+v.
	var items: Array = []  # [depth, parts]
	# Sample the ring densely, then drop a post every `gap` of arc length so they don't bunch at corners.
	var ring := Squircle.points(Vector2.ZERO, Vector2(1.32, 1.32), 4.0, 2000)
	var seg := PackedFloat32Array()
	var total := 0.0
	for i in ring.size():
		seg.append(IsoGrid.project(ring[i]).distance_to(IsoGrid.project(ring[i - 1])))
		total += seg[i]
	var gap := total / roundf(total / spacing)  # ~spacing screen px between posts, evenly divided
	var walked := gap
	for i in ring.size():
		walked += seg[i]
		if walked >= gap:
			walked -= gap
			var p := ring[i]
			items.append([p.x + p.y, [Buildings.part(p, post, h, post_color)]])
	var rock := Vector2(0.45, -0.45)
	items.append([0.0, [Buildings.part(rock, Vector2(0.26, 0.2), 9, Palette.STONE)]])
	items.append([0.01, Buildings.tree(Vector2(-0.4, 0.4))])
	items.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var out: Array = [Buildings.part(Vector2.ZERO, Vector2(1.42, 1.42), 3, Palette.GRASS_DARK)]
	for it in items:
		out.append_array(it[1])
	return out
