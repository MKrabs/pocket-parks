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
		"snack_stand": {"name": "Snack Cart", "role": "shop", "price": 5, "capacity": 2, "footprint": Vector2i(1, 1), "cost": 60,
			"specialty": "carpenter", "mode": "faster", "variants": ["snack_stand", "hotdog_stand", "burger_diner"],
			"parts": [
				B.part(Vector2.ZERO, Vector2(0.3, 0.3), 20, Palette.WOOD),
				B.part(Vector2.ZERO, Vector2(0.42, 0.42), 7, Palette.CLAY, 20),
				B.part(Vector2.ZERO, Vector2(0.24, 0.24), 5, Palette.CLAY, 27),
			]},
		"hotdog_stand": {"name": "Hot-dog Stand", "role": "shop", "price": 8, "capacity": 4, "footprint": Vector2i(2, 1), "cost": 110,
			"specialty": "carpenter", "mode": "faster",
			"parts": [
				B.part(Vector2.ZERO, Vector2(0.8, 0.32), 16, Palette.WOOD),
				B.part(Vector2(0, 0.34), Vector2(0.62, 0.05), 3, Palette.STONE, 9),  # counter
				B.part(Vector2.ZERO, Vector2(0.92, 0.44), 5, Palette.CLAY, 16),  # awning
				B.part(Vector2.ZERO, Vector2(0.44, 0.16), 6, Palette.BUTTER, 21),  # bun
				B.part(Vector2.ZERO, Vector2(0.54, 0.09), 6, Palette.CORAL, 26),  # sausage
			]},
		"burger_diner": {"name": "Burger Diner", "role": "shop", "price": 12, "capacity": 7, "footprint": Vector2i(2, 2), "cost": 190,
			"specialty": "carpenter", "mode": "faster",
			"parts": [
				# a long low diner at the back, a terrace table out front, a giant burger on a pole
				B.part(Vector2(0, -0.32), Vector2(0.82, 0.5), 15, Palette.CLOUD),
				B.part(Vector2(0.83, -0.32), Vector2(0.03, 0.34), 6, Palette.SKY, 5),  # windows
				B.part(Vector2(0, 0.19), Vector2(0.6, 0.03), 6, Palette.SKY, 5),
				B.part(Vector2(0, -0.32), Vector2(0.9, 0.58), 4, Palette.CLAY, 15),  # flat roof
				B.part(Vector2(-0.5, 0.5), Vector2(0.04, 0.04), 30, Palette.WOOD),  # the burger sign
				B.part(Vector2(-0.5, 0.5), Vector2(0.3, 0.3), 5, Palette.BUTTER, 30),
				B.part(Vector2(-0.5, 0.5), Vector2(0.33, 0.33), 3, Palette.WOOD, 35),
				B.part(Vector2(-0.5, 0.5), Vector2(0.28, 0.28), 7, Palette.BUTTER, 38),
				B.part(Vector2(0.45, 0.5), Vector2(0.15, 0.15), 6, Palette.CLOUD),  # terrace table
				B.part(Vector2(0.45, 0.5), Vector2(0.03, 0.03), 12, Palette.WOOD, 6),
				B.part(Vector2(0.45, 0.5), Vector2(0.27, 0.27), 3, Palette.CORAL, 18),  # parasol
			]},
		"pond": {"name": "Pond", "role": "attraction", "appeal": 5, "capacity": 6, "footprint": Vector2i(2, 2), "cost": 80,
			"specialty": "water", "mode": "faster",
			"parts": [
				B.part(Vector2.ZERO, Vector2(0.92, 0.92), 7, Palette.STONE),
				B.part(Vector2.ZERO, Vector2(0.7, 0.7), 0, Palette.WATER, 7),
			]},
		# Habitats are painted, not placed (ParkMap.paint): cost, appeal and capacity are per cell; "habitat" = fence style.
		"habitat": {"name": "Habitat · Fence", "role": "attraction", "habitat": "fence", "appeal": 1, "capacity": 1,
			"footprint": Vector2i(1, 1), "cost": 16, "specialty": "carpenter", "mode": "faster", "parts": [],
			"variants": ["habitat", "habitat_glass", "habitat_net", "habitat_wall"]},
		"habitat_glass": {"name": "Habitat · Glass", "role": "attraction", "habitat": "glass", "appeal": 1, "capacity": 1,
			"footprint": Vector2i(1, 1), "cost": 26, "specialty": "water", "mode": "only", "parts": []},
		"habitat_net": {"name": "Habitat · Net", "role": "attraction", "habitat": "net", "appeal": 1, "capacity": 1,
			"footprint": Vector2i(1, 1), "cost": 26, "specialty": "aviary", "mode": "only", "parts": []},
		"habitat_wall": {"name": "Habitat · Wall", "role": "attraction", "habitat": "wall", "appeal": 1, "capacity": 1,
			"footprint": Vector2i(1, 1), "cost": 28, "specialty": "heavy", "mode": "only", "parts": []},
		"builder_shed": {"name": "Builder Shed", "role": "staff", "footprint": Vector2i(1, 1), "cost": 80,
			"specialty": "carpenter", "mode": "faster", "parts": B.shed(Palette.CLAY)},
	}
