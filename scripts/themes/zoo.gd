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
			"parts": B.tree(Vector2.ZERO)},
		"snack_stand": {"name": "Snack Stand", "role": "shop", "price": 5, "footprint": Vector2i(1, 1), "cost": 60,
			"parts": [
				B.part(Vector2.ZERO, Vector2(0.3, 0.3), 20, Palette.WOOD),
				B.part(Vector2.ZERO, Vector2(0.42, 0.42), 7, Palette.CLAY, 20),
				B.part(Vector2.ZERO, Vector2(0.24, 0.24), 5, Palette.CLAY, 27),
			]},
		"pond": {"name": "Pond", "role": "attraction", "appeal": 5, "capacity": 6, "footprint": Vector2i(2, 2), "cost": 80,
			"parts": [
				B.part(Vector2.ZERO, Vector2(0.92, 0.92), 7, Palette.STONE),
				B.part(Vector2.ZERO, Vector2(0.7, 0.7), 0, Palette.WATER, 7),
			]},
		"enclosure": {"name": "Enclosure", "role": "attraction", "appeal": 10, "capacity": 10, "footprint": Vector2i(3, 3), "cost": 150,
			"parts": enclosure()},
		"builder_shed": {"name": "Builder Shed", "role": "staff", "footprint": Vector2i(1, 1), "cost": 80,
			"parts": B.shed(Palette.CLAY)},
	}

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
			items.append([p.x + p.y, [Buildings.part(p, Vector2(0.07, 0.07), 12, Palette.WOOD)]])
	var rock := Vector2(0.45, -0.45)
	items.append([0.0, [Buildings.part(rock, Vector2(0.26, 0.2), 9, Palette.STONE)]])
	items.append([0.01, Buildings.tree(Vector2(-0.4, 0.4))])
	items.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var out: Array = [Buildings.part(Vector2.ZERO, Vector2(1.42, 1.42), 3, Palette.GRASS_DARK)]
	for it in items:
		out.append_array(it[1])
	return out
