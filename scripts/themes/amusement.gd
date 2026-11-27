class_name AmusementTheme
# Amusement park theme pack: ticket arch, coaster, teacups, Ferris wheel, churros, balloons and bunting.

static func catalog() -> Dictionary:
	var P := Buildings.part
	return {
		"amu_arch": {"name": "Ticket Arch", "role": "entrance", "footprint": Vector2i(1, 1), "cost": 100,
			"parts": Buildings.arch(Palette.CORAL, Palette.BUTTER) + [
				P.call(Vector2(0.12, 0), Vector2(0.04, 0.22), 9, Palette.CLOUD, 22),  # ticket sign
			]},
		"amu_path": {"name": "Midway", "role": "path", "footprint": Vector2i(1, 1), "cost": 6,
			"parts": [P.call(Vector2.ZERO, Vector2(0.46, 0.46), 3, Palette.CLAY)]},
		"amu_coaster": {"name": "Coaster", "role": "attraction", "appeal": 16, "capacity": 12, "footprint": Vector2i(3, 3), "cost": 280,
			"specialty": "rides", "mode": "only", "parts": coaster()},
		"amu_teacups": {"name": "Teacups", "role": "attraction", "appeal": 7, "capacity": 8, "footprint": Vector2i(2, 2), "cost": 120,
			"specialty": "rides", "mode": "faster", "parts": teacups()},
		"amu_wheel": {"name": "Ferris Wheel", "role": "attraction", "appeal": 10, "capacity": 8, "footprint": Vector2i(2, 2), "cost": 180,
			"specialty": "rides", "mode": "faster",
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.86, 0.86), 3, Palette.STONE),
				Buildings.shaped("wheel", Vector2(0.12, 0.8), 62, Palette.SKY, 6),
			]},
		"amu_churro": {"name": "Churro Cart", "role": "shop", "price": 5, "capacity": 2, "footprint": Vector2i(1, 1), "cost": 60,
			"specialty": "carpenter", "mode": "faster", "variants": ["amu_churro", "amu_sweets", "amu_parlour"],
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.3, 0.22), 14, Palette.BUTTER, 3),
				P.call(Vector2(0.18, 0.24), Vector2(0.08, 0.04), 6, Palette.WOOD),  # wheels
				P.call(Vector2(-0.18, 0.24), Vector2(0.08, 0.04), 6, Palette.WOOD),
				P.call(Vector2.ZERO, Vector2(0.04, 0.04), 12, Palette.WOOD, 17),  # parasol pole
				P.call(Vector2.ZERO, Vector2(0.38, 0.38), 3, Palette.CORAL, 29),
				P.call(Vector2.ZERO, Vector2(0.18, 0.18), 3, Palette.CLOUD, 32),
			]},
		"amu_sweets": {"name": "Sweet Stall", "role": "shop", "price": 8, "capacity": 4, "footprint": Vector2i(2, 1), "cost": 110,
			"specialty": "carpenter", "mode": "faster",
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.8, 0.32), 15, Palette.CLOUD),
				P.call(Vector2(0, 0.34), Vector2(0.62, 0.05), 3, Palette.WOOD, 9),  # counter
				P.call(Vector2.ZERO, Vector2(0.9, 0.42), 4, Palette.CORAL, 15),  # awning
				P.call(Vector2(-0.4, 0), Vector2(0.12, 0.12), 8, Palette.BUTTER, 19),  # churro bundle
				P.call(Vector2(0.4, 0), Vector2(0.14, 0.14), 8, Palette.CLOUD, 19),  # candy floss
				P.call(Vector2(0.4, 0), Vector2(0.1, 0.1), 4, Palette.CORAL, 27),
			]},
		"amu_parlour": {"name": "Churro Parlour", "role": "shop", "price": 12, "capacity": 7, "footprint": Vector2i(2, 2), "cost": 190,
			"specialty": "carpenter", "mode": "faster",
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.82, 0.82), 20, Palette.BUTTER),
				P.call(Vector2(0.84, 0), Vector2(0.03, 0.5), 8, Palette.SKY, 7),  # windows
				P.call(Vector2(0, 0.84), Vector2(0.5, 0.03), 8, Palette.SKY, 7),
				P.call(Vector2.ZERO, Vector2(0.92, 0.92), 4, Palette.CORAL, 20),  # striped roof
				P.call(Vector2.ZERO, Vector2(0.64, 0.64), 4, Palette.CLOUD, 24),
				P.call(Vector2.ZERO, Vector2(0.36, 0.36), 4, Palette.CORAL, 28),
				P.call(Vector2.ZERO, Vector2(0.06, 0.06), 10, Palette.WOOD, 32),  # churro sign
				P.call(Vector2.ZERO, Vector2(0.18, 0.06), 5, Palette.BUTTER, 42),
			]},
		"amu_balloons": {"name": "Balloons", "role": "decor", "appeal": 3, "footprint": Vector2i(1, 1), "cost": 30,
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.12, 0.12), 5, Palette.WOOD),  # the weight they're tied to
				Buildings.shaped("balloons", Vector2(0.12, 0.12), 38, Palette.CORAL, 5),
			]},
		"amu_bunting": {"name": "Bunting", "role": "decor", "appeal": 2, "footprint": Vector2i(1, 1), "cost": 20,
			"parts": bunting()},
		"amu_shed": {"name": "Builder Shed", "role": "staff", "footprint": Vector2i(1, 1), "cost": 80,
			"specialty": "carpenter", "mode": "faster", "parts": Buildings.shed(Palette.BUTTER)},
	}

## A raised loop of thin rails round the 3×3 footprint, a station in the middle, a car on the front straight.
static func coaster() -> Array:
	var P := Buildings.part
	var back := Buildings.shaped("rails", Vector2(1.3, 1.3), 22, Palette.CORAL)
	back["side"] = -1
	var front := back.duplicate()
	front["side"] = 1
	return [
		P.call(Vector2.ZERO, Vector2(1.42, 1.42), 2, Palette.STONE),
		back,
		P.call(Vector2.ZERO, Vector2(0.4, 0.4), 12, Palette.WOOD, 2),  # station
		P.call(Vector2.ZERO, Vector2(0.48, 0.48), 4, Palette.CLAY, 14),
		front,
		P.call(Vector2(1.3, 0.1), Vector2(0.14, 0.26), 7, Palette.BUTTER, 22),  # car
		P.call(Vector2(1.3, -0.08), Vector2(0.1, 0.06), 4, Palette.SKY, 29),  # its riders
		P.call(Vector2(1.3, 0.22), Vector2(0.1, 0.06), 4, Palette.SKY, 29),
	]

## A round deck with four cups round a teapot hub.
static func teacups() -> Array:
	var P := Buildings.part
	var out: Array = [
		P.call(Vector2.ZERO, Vector2(0.9, 0.9), 4, Palette.STONE),
		P.call(Vector2.ZERO, Vector2(0.16, 0.16), 14, Palette.CLAY, 4),  # teapot hub
		P.call(Vector2.ZERO, Vector2(0.1, 0.1), 4, Palette.CLAY, 18),
	]
	var cups := [[Vector2(-0.48, -0.48), Palette.CORAL], [Vector2(0.48, -0.48), Palette.SKY],
		[Vector2(-0.48, 0.48), Palette.BUTTER], [Vector2(0.48, 0.48), Palette.MOSS]]
	for cup: Array in cups:
		out.append(P.call(cup[0], Vector2(0.26, 0.26), 9, cup[1], 4))
		out.append(P.call(cup[0], Vector2(0.18, 0.18), 1, Palette.shade(cup[1], 0.22), 13))  # inside
	return out

## Two poles with a line of little flags between them.
static func bunting() -> Array:
	var P := Buildings.part
	var out: Array = [
		P.call(Vector2(0, -0.38), Vector2(0.04, 0.04), 26, Palette.WOOD),
		P.call(Vector2(0, 0.38), Vector2(0.04, 0.04), 26, Palette.WOOD),
		P.call(Vector2.ZERO, Vector2(0.015, 0.38), 1.5, Palette.STONE, 24),
	]
	var flags := [Palette.CORAL, Palette.BUTTER, Palette.SKY, Palette.MOSS]
	for i in flags.size():
		out.append(P.call(Vector2(0, -0.24 + i * 0.16), Vector2(0.02, 0.05), 6, flags[i], 18))
	return out
