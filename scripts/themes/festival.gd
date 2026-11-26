class_name FestivalTheme
# Food festival theme pack: tiny, only here to prove themes swap.

static func catalog() -> Dictionary:
	return {
		"fest_arch": {"name": "Festival Arch", "role": "entrance", "footprint": Vector2i(1, 1), "cost": 100,
			"parts": Buildings.arch(Palette.CLAY, Palette.BUTTER)},
		"fest_boardwalk": {"name": "Boardwalk", "role": "path", "footprint": Vector2i(1, 1), "cost": 6,
			"parts": [
				Buildings.part(Vector2(0, -0.3), Vector2(0.46, 0.13), 3, Palette.WOOD),
				Buildings.part(Vector2(0, 0), Vector2(0.46, 0.13), 3, Palette.WOOD),
				Buildings.part(Vector2(0, 0.3), Vector2(0.46, 0.13), 3, Palette.WOOD),
			]},
		"fest_stage": {"name": "Stage", "role": "attraction", "appeal": 12, "capacity": 12, "footprint": Vector2i(3, 2), "cost": 180,
			"parts": [
				Buildings.part(Vector2.ZERO, Vector2(1.4, 0.9), 8, Palette.WOOD),
				Buildings.part(Vector2(0, -0.72), Vector2(1.3, 0.12), 26, Palette.CLAY, 8),
				Buildings.part(Vector2(0, -0.72), Vector2(1.36, 0.16), 5, Palette.BUTTER, 34),
				Buildings.part(Vector2(-1.05, 0.55), Vector2(0.18, 0.18), 14, Palette.STONE, 8),
				Buildings.part(Vector2(1.05, 0.55), Vector2(0.18, 0.18), 14, Palette.STONE, 8),
			]},
		"fest_grill": {"name": "Big Grill", "role": "attraction", "appeal": 6, "capacity": 6, "footprint": Vector2i(2, 2), "cost": 90,
			"parts": [
				Buildings.part(Vector2.ZERO, Vector2(0.92, 0.92), 3, Palette.SAND),
				Buildings.part(Vector2(-0.35, -0.35), Vector2(0.1, 0.1), 30, Palette.STONE),
				Buildings.part(Vector2(0.05, 0.05), Vector2(0.5, 0.5), 14, Palette.STONE, 3),
				Buildings.part(Vector2(0.05, 0.05), Vector2(0.56, 0.56), 4, Palette.CORAL, 17),
				Buildings.part(Vector2(0.75, -0.55), Vector2(0.14, 0.3), 6, Palette.WOOD, 3),
				Buildings.part(Vector2(-0.55, 0.75), Vector2(0.3, 0.14), 6, Palette.WOOD, 3),
			]},
		"fest_truck": {"name": "Food Truck", "role": "shop", "price": 6, "footprint": Vector2i(1, 1), "cost": 70,
			"parts": [
				Buildings.part(Vector2.ZERO, Vector2(0.34, 0.42), 18, Palette.SKY, 3),
				Buildings.part(Vector2.ZERO, Vector2(0.38, 0.46), 3, Palette.CLAY, 21),
				Buildings.part(Vector2(0.36, 0), Vector2(0.06, 0.3), 3, Palette.BUTTER, 12),
			]},
		"fest_lantern": {"name": "Lantern Tree", "role": "decor", "appeal": 3, "footprint": Vector2i(1, 1), "cost": 30,
			"parts": Buildings.tree(Vector2.ZERO) + [
				Buildings.part(Vector2(0.34, -0.1), Vector2(0.07, 0.07), 6, Palette.BUTTER, 8),
				Buildings.part(Vector2(-0.1, 0.34), Vector2(0.07, 0.07), 6, Palette.BUTTER, 8),
				Buildings.part(Vector2(0.26, 0.26), Vector2(0.07, 0.07), 6, Palette.BUTTER, 18),
			]},
	}
