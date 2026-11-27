class_name FestivalTheme
# Food festival theme pack: arch, boardwalk, stage, bandstand, the Big Grill (Grill specialists only), a painted
# Picnic Lawn, three stall families in three sizes each, lantern trees and string lights.

static func catalog() -> Dictionary:
	var P := Buildings.part
	return {
		"fest_arch": {"name": "Festival Arch", "role": "entrance", "footprint": Vector2i(1, 1), "cost": 100,
			"parts": Buildings.arch(Palette.CLAY, Palette.BUTTER)},
		"fest_boardwalk": {"name": "Boardwalk", "role": "path", "footprint": Vector2i(1, 1), "cost": 6,
			"parts": [
				P.call(Vector2(0, -0.3), Vector2(0.46, 0.13), 3, Palette.WOOD),
				P.call(Vector2(0, 0), Vector2(0.46, 0.13), 3, Palette.WOOD),
				P.call(Vector2(0, 0.3), Vector2(0.46, 0.13), 3, Palette.WOOD),
			]},
		"fest_stage": {"name": "Stage", "role": "attraction", "appeal": 12, "capacity": 12, "footprint": Vector2i(3, 2), "cost": 180,
			"specialty": "carpenter", "mode": "faster",
			"parts": [
				P.call(Vector2.ZERO, Vector2(1.4, 0.9), 8, Palette.WOOD),
				P.call(Vector2(0, -0.72), Vector2(1.3, 0.12), 26, Palette.CLAY, 8),
				P.call(Vector2(0, -0.72), Vector2(1.36, 0.16), 5, Palette.BUTTER, 34),
				P.call(Vector2(-1.05, 0.55), Vector2(0.18, 0.18), 14, Palette.STONE, 8),
				P.call(Vector2(1.05, 0.55), Vector2(0.18, 0.18), 14, Palette.STONE, 8),
			]},
		"fest_band": {"name": "Bandstand", "role": "attraction", "appeal": 9, "capacity": 10, "footprint": Vector2i(2, 2), "cost": 150,
			"specialty": "carpenter", "mode": "faster",
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.9, 0.9), 5, Palette.STONE),
				P.call(Vector2.ZERO, Vector2(0.8, 0.8), 2, Palette.WOOD, 5),  # deck
				P.call(Vector2(-0.62, -0.62), Vector2(0.05, 0.05), 22, Palette.CLOUD, 7),  # posts
				P.call(Vector2(0.62, -0.62), Vector2(0.05, 0.05), 22, Palette.CLOUD, 7),
				P.call(Vector2(-0.62, 0.62), Vector2(0.05, 0.05), 22, Palette.CLOUD, 7),
				P.call(Vector2(0.62, 0.62), Vector2(0.05, 0.05), 22, Palette.CLOUD, 7),
				P.call(Vector2.ZERO, Vector2(0.92, 0.92), 4, Palette.CORAL, 29),  # stepped roof
				P.call(Vector2.ZERO, Vector2(0.64, 0.64), 4, Palette.CORAL, 33),
				P.call(Vector2.ZERO, Vector2(0.36, 0.36), 4, Palette.BUTTER, 37),
				P.call(Vector2.ZERO, Vector2(0.04, 0.04), 8, Palette.WOOD, 41),
			]},
		"fest_grill": {"name": "Big Grill", "role": "attraction", "appeal": 6, "capacity": 6, "footprint": Vector2i(2, 2), "cost": 90,
			"specialty": "grill", "mode": "only",
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.92, 0.92), 3, Palette.SAND),
				P.call(Vector2(-0.35, -0.35), Vector2(0.1, 0.1), 30, Palette.STONE),
				P.call(Vector2(0.05, 0.05), Vector2(0.5, 0.5), 14, Palette.STONE, 3),
				P.call(Vector2(0.05, 0.05), Vector2(0.56, 0.56), 4, Palette.CORAL, 17),
				P.call(Vector2(0.75, -0.55), Vector2(0.14, 0.3), 6, Palette.WOOD, 3),
				P.call(Vector2(-0.55, 0.75), Vector2(0.3, 0.14), 6, Palette.WOOD, 3),
			]},
		# Painted like a habitat (ParkMap.paint), with a low hedge instead of a fence; cost, appeal, capacity per cell.
		"fest_lawn": {"name": "Picnic Lawn", "role": "attraction", "habitat": "hedge", "appeal": 1, "capacity": 1,
			"footprint": Vector2i(1, 1), "cost": 12, "specialty": "landscaper", "mode": "faster", "parts": []},
		"fest_truck": {"name": "Food Truck", "role": "shop", "price": 6, "capacity": 2, "footprint": Vector2i(1, 1), "cost": 70,
			"specialty": "carpenter", "mode": "faster", "variants": ["fest_truck", "fest_taco", "fest_hall"],
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.34, 0.42), 18, Palette.SKY, 3),
				P.call(Vector2.ZERO, Vector2(0.38, 0.46), 3, Palette.CLAY, 21),
				P.call(Vector2(0.36, 0), Vector2(0.06, 0.3), 3, Palette.BUTTER, 12),
			]},
		"fest_taco": {"name": "Taco Truck", "role": "shop", "price": 9, "capacity": 4, "footprint": Vector2i(2, 1), "cost": 120,
			"specialty": "carpenter", "mode": "faster",
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.82, 0.36), 18, Palette.BUTTER, 3),
				P.call(Vector2(0, 0.37), Vector2(0.4, 0.04), 7, Palette.STONE, 10),  # hatch
				P.call(Vector2(0, 0.46), Vector2(0.46, 0.1), 2, Palette.CORAL, 18),  # flap
				P.call(Vector2.ZERO, Vector2(0.86, 0.4), 3, Palette.CORAL, 21),
				P.call(Vector2(-0.4, 0), Vector2(0.2, 0.14), 6, Palette.MOSS, 24),  # sign
			]},
		"fest_hall": {"name": "Food Hall", "role": "shop", "price": 13, "capacity": 7, "footprint": Vector2i(2, 2), "cost": 200,
			"specialty": "carpenter", "mode": "faster",
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.92, 0.92), 3, Palette.WOOD),
				P.call(Vector2.ZERO, Vector2(0.78, 0.78), 18, Palette.CLOUD, 3),
				P.call(Vector2(0.8, 0), Vector2(0.03, 0.4), 9, Palette.CLAY, 3),  # doors
				P.call(Vector2(0, 0.8), Vector2(0.4, 0.03), 9, Palette.CLAY, 3),
				P.call(Vector2.ZERO, Vector2(0.9, 0.9), 4, Palette.CORAL, 21),  # stepped tent roof
				P.call(Vector2.ZERO, Vector2(0.6, 0.6), 4, Palette.CORAL, 25),
				P.call(Vector2.ZERO, Vector2(0.3, 0.3), 4, Palette.BUTTER, 29),
				P.call(Vector2.ZERO, Vector2(0.04, 0.04), 12, Palette.WOOD, 33),
				P.call(Vector2(0.1, 0), Vector2(0.1, 0.03), 6, Palette.BUTTER, 39),  # flag
			]},
		"fest_lemon": {"name": "Lemonade Stand", "role": "shop", "price": 4, "capacity": 2, "footprint": Vector2i(1, 1), "cost": 55,
			"specialty": "carpenter", "mode": "faster", "variants": ["fest_lemon", "fest_juice", "fest_tea"],
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.3, 0.3), 14, Palette.WOOD),
				P.call(Vector2.ZERO, Vector2(0.38, 0.38), 4, Palette.BUTTER, 14),
				P.call(Vector2.ZERO, Vector2(0.14, 0.14), 9, Palette.BUTTER, 18),  # the lemon
				P.call(Vector2(-0.06, -0.06), Vector2(0.06, 0.04), 2, Palette.MOSS, 27),  # leaf
			]},
		"fest_juice": {"name": "Juice Bar", "role": "shop", "price": 7, "capacity": 4, "footprint": Vector2i(2, 1), "cost": 100,
			"specialty": "carpenter", "mode": "faster",
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.82, 0.32), 14, Palette.WOOD),
				P.call(Vector2(0, 0.34), Vector2(0.6, 0.05), 3, Palette.STONE, 8),  # counter
				P.call(Vector2.ZERO, Vector2(0.88, 0.4), 4, Palette.MOSS, 14),
				P.call(Vector2(-0.45, 0), Vector2(0.11, 0.11), 9, Palette.CORAL, 18),  # cups
				P.call(Vector2(0, 0), Vector2(0.11, 0.11), 9, Palette.BUTTER, 18),
				P.call(Vector2(0.45, 0), Vector2(0.11, 0.11), 9, Palette.WATER, 18),
			]},
		"fest_tea": {"name": "Tea Tent", "role": "shop", "price": 11, "capacity": 7, "footprint": Vector2i(2, 2), "cost": 170,
			"specialty": "carpenter", "mode": "faster",
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.92, 0.92), 3, Palette.STONE),
				P.call(Vector2.ZERO, Vector2(0.78, 0.78), 16, Palette.CLOUD, 3),
				P.call(Vector2(0.8, 0), Vector2(0.03, 0.36), 9, Palette.SKY, 3),  # doors
				P.call(Vector2(0, 0.8), Vector2(0.36, 0.03), 9, Palette.SKY, 3),
				P.call(Vector2.ZERO, Vector2(0.9, 0.9), 4, Palette.SKY, 19),  # stepped tent roof
				P.call(Vector2.ZERO, Vector2(0.6, 0.6), 4, Palette.SKY, 23),
				P.call(Vector2.ZERO, Vector2(0.3, 0.3), 4, Palette.CLOUD, 27),
				P.call(Vector2.ZERO, Vector2(0.12, 0.12), 7, Palette.CLAY, 31),  # teapot
			]},
		"fest_floss": {"name": "Candy-floss Cart", "role": "shop", "price": 5, "capacity": 2, "footprint": Vector2i(1, 1), "cost": 60,
			"specialty": "carpenter", "mode": "faster", "variants": ["fest_floss", "fest_waffle", "fest_cake"],
			"parts": [
				P.call(Vector2(0.3, 0), Vector2(0.06, 0.3), 6, Palette.STONE),  # wheels
				P.call(Vector2(-0.3, 0), Vector2(0.06, 0.3), 6, Palette.STONE),
				P.call(Vector2.ZERO, Vector2(0.32, 0.36), 12, Palette.SKY, 3),
				P.call(Vector2.ZERO, Vector2(0.03, 0.03), 8, Palette.CLOUD, 15),  # stick
				P.call(Vector2.ZERO, Vector2(0.2, 0.2), 6, Palette.CORAL, 21),  # the floss
				P.call(Vector2.ZERO, Vector2(0.13, 0.13), 4, Palette.CORAL, 27),
			]},
		"fest_waffle": {"name": "Waffle Stand", "role": "shop", "price": 8, "capacity": 4, "footprint": Vector2i(2, 1), "cost": 110,
			"specialty": "carpenter", "mode": "faster",
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.8, 0.32), 16, Palette.BUTTER),
				P.call(Vector2(0, 0.34), Vector2(0.6, 0.05), 3, Palette.WOOD, 9),  # counter
				P.call(Vector2.ZERO, Vector2(0.9, 0.42), 4, Palette.CLAY, 16),
				P.call(Vector2.ZERO, Vector2(0.26, 0.26), 4, Palette.WOOD, 20),  # the waffle sign
				P.call(Vector2.ZERO, Vector2(0.18, 0.18), 2, Palette.BUTTER, 24),
			]},
		"fest_cake": {"name": "Cake Pavilion", "role": "shop", "price": 12, "capacity": 7, "footprint": Vector2i(2, 2), "cost": 190,
			"specialty": "carpenter", "mode": "faster",
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.86, 0.86), 14, Palette.CLOUD),
				P.call(Vector2(0.88, 0), Vector2(0.03, 0.34), 9, Palette.CLAY, 2),  # doors
				P.call(Vector2(0, 0.88), Vector2(0.34, 0.03), 9, Palette.CLAY, 2),
				P.call(Vector2.ZERO, Vector2(0.9, 0.9), 3, Palette.CORAL, 14),  # icing
				P.call(Vector2.ZERO, Vector2(0.58, 0.58), 9, Palette.CLOUD, 17),
				P.call(Vector2.ZERO, Vector2(0.62, 0.62), 3, Palette.CORAL, 26),
				P.call(Vector2.ZERO, Vector2(0.04, 0.04), 9, Palette.BUTTER, 29),  # candle
			]},
		"fest_lantern": {"name": "Lantern Tree", "role": "decor", "appeal": 3, "footprint": Vector2i(1, 1), "cost": 30,
			"specialty": "landscaper", "mode": "faster",
			"parts": Buildings.tree(Vector2.ZERO) + [
				P.call(Vector2(0.34, -0.1), Vector2(0.07, 0.07), 6, Palette.BUTTER, 8),
				P.call(Vector2(-0.1, 0.34), Vector2(0.07, 0.07), 6, Palette.BUTTER, 8),
				P.call(Vector2(0.26, 0.26), Vector2(0.07, 0.07), 6, Palette.BUTTER, 18),
			]},
		"fest_lights": {"name": "String Lights", "role": "decor", "appeal": 3, "footprint": Vector2i(1, 1), "cost": 25,
			"parts": [Buildings.shaped("lights", Vector2(0.36, 0.36), 24, Palette.BUTTER)]},
		"fest_shed": {"name": "Builder Shed", "role": "staff", "footprint": Vector2i(1, 1), "cost": 80,
			"specialty": "carpenter", "mode": "faster", "parts": Buildings.shed(Palette.SKY)},
	}
