class_name CinemaTheme
# Cinema theme pack: ticket booth, red carpet, screens, popcorn, posters and palms.

static func catalog() -> Dictionary:
	var P := Buildings.part
	return {
		"cin_booth": {"name": "Ticket Booth", "role": "entrance", "footprint": Vector2i(1, 1), "cost": 100,
			"parts": Buildings.arch(Palette.STONE, Palette.CLAY) + [
				P.call(Vector2(0.12, 0), Vector2(0.04, 0.3), 5, Palette.BUTTER, 27),  # marquee lights
			]},
		"cin_carpet": {"name": "Red Carpet", "role": "path", "footprint": Vector2i(1, 1), "cost": 6,
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.46, 0.46), 2, Palette.STONE),
				P.call(Vector2.ZERO, Vector2(0.46, 0.3), 1, Palette.CLAY, 2),
			]},
		"cin_room": {"name": "Screen Room", "role": "attraction", "appeal": 7, "capacity": 8, "footprint": Vector2i(2, 2), "cost": 110,
			"specialty": "projection", "mode": "faster", "parts": screen_room()},
		"cin_big": {"name": "Big Screen", "role": "attraction", "appeal": 14, "capacity": 14, "footprint": Vector2i(3, 3), "cost": 250,
			"specialty": "projection", "mode": "only", "parts": big_screen()},
		"cin_popcorn": {"name": "Popcorn Stand", "role": "shop", "price": 5, "capacity": 2, "footprint": Vector2i(1, 1), "cost": 60,
			"specialty": "carpenter", "mode": "faster", "variants": ["cin_popcorn", "cin_candy", "cin_cafe"],
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.32, 0.32), 16, Palette.CORAL),
				P.call(Vector2.ZERO, Vector2(0.36, 0.36), 3, Palette.CLOUD, 16),
				P.call(Vector2.ZERO, Vector2(0.14, 0.14), 10, Palette.CLOUD, 19),  # cup
				P.call(Vector2.ZERO, Vector2(0.17, 0.17), 4, Palette.BUTTER, 29),  # popcorn
				P.call(Vector2.ZERO, Vector2(0.11, 0.11), 3, Palette.BUTTER, 33),
			]},
		"cin_candy": {"name": "Candy Bar", "role": "shop", "price": 8, "capacity": 4, "footprint": Vector2i(2, 1), "cost": 110,
			"specialty": "carpenter", "mode": "faster",
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.82, 0.34), 14, Palette.CORAL),
				P.call(Vector2.ZERO, Vector2(0.86, 0.38), 3, Palette.CLOUD, 14),
				P.call(Vector2(-0.48, 0), Vector2(0.14, 0.14), 9, Palette.BUTTER, 17),  # candy jars
				P.call(Vector2(0, 0), Vector2(0.14, 0.14), 9, Palette.SKY, 17),
				P.call(Vector2(0.48, 0), Vector2(0.14, 0.14), 9, Palette.MOSS, 17),
				P.call(Vector2(-0.48, 0), Vector2(0.09, 0.09), 3, Palette.CLOUD, 26),
				P.call(Vector2(0, 0), Vector2(0.09, 0.09), 3, Palette.CLOUD, 26),
				P.call(Vector2(0.48, 0), Vector2(0.09, 0.09), 3, Palette.CLOUD, 26),
			]},
		"cin_cafe": {"name": "Lobby Café", "role": "shop", "price": 12, "capacity": 7, "footprint": Vector2i(2, 2), "cost": 180,
			"specialty": "carpenter", "mode": "faster",
			"parts": [
				# a stepped picture-palace front with a marquee canopy and a tall blade sign on the roof
				P.call(Vector2.ZERO, Vector2(0.76, 0.76), 18, Palette.CLAY),
				P.call(Vector2(0.77, 0), Vector2(0.03, 0.28), 9, Palette.WOOD),  # doors
				P.call(Vector2(0, 0.77), Vector2(0.28, 0.03), 9, Palette.WOOD),
				P.call(Vector2.ZERO, Vector2(0.88, 0.88), 3, Palette.BUTTER, 11),  # marquee canopy
				P.call(Vector2(-0.12, -0.12), Vector2(0.5, 0.5), 7, Palette.CLAY, 18),  # stepped top
				P.call(Vector2(0.45, -0.45), Vector2(0.05, 0.2), 32, Palette.CORAL, 18),  # blade sign
				P.call(Vector2(0.47, -0.45), Vector2(0.04, 0.13), 24, Palette.BUTTER, 22),
				P.call(Vector2(-0.12, -0.12), Vector2(0.17, 0.17), 9, Palette.CLOUD, 25),  # the cup
			]},
		"cin_poster": {"name": "Poster Wall", "role": "decor", "appeal": 3, "footprint": Vector2i(1, 1), "cost": 30,
			"parts": [
				P.call(Vector2(-0.2, 0), Vector2(0.06, 0.42), 24, Palette.STONE),
				P.call(Vector2(-0.12, -0.2), Vector2(0.02, 0.15), 16, Palette.SKY, 4),
				P.call(Vector2(-0.12, 0.2), Vector2(0.02, 0.15), 16, Palette.BUTTER, 4),
			]},
		"cin_palm": {"name": "Potted Palm", "role": "decor", "appeal": 2, "footprint": Vector2i(1, 1), "cost": 20,
			"specialty": "landscaper", "mode": "faster",
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.16, 0.16), 8, Palette.CLAY),
				P.call(Vector2.ZERO, Vector2(0.04, 0.04), 18, Palette.WOOD, 8),
				P.call(Vector2.ZERO, Vector2(0.3, 0.08), 3, Palette.MOSS, 25),
				P.call(Vector2.ZERO, Vector2(0.08, 0.3), 3, Palette.MOSS, 26),
				P.call(Vector2.ZERO, Vector2(0.1, 0.1), 4, Palette.MOSS, 28),
			]},
		"cin_shed": {"name": "Builder Shed", "role": "staff", "footprint": Vector2i(1, 1), "cost": 80,
			"specialty": "carpenter", "mode": "faster", "parts": Buildings.shed(Palette.CORAL)},
	}

## Rounded hall with a big pale screen on its +x face.
static func screen_room() -> Array:
	var P := Buildings.part
	return [
		P.call(Vector2.ZERO, Vector2(0.8, 0.8), 24, Palette.CLAY),
		P.call(Vector2.ZERO, Vector2(0.86, 0.86), 4, Palette.STONE, 24),
		P.call(Vector2(0.83, 0), Vector2(0.03, 0.56), 15, Palette.CLOUD, 4),
	]

## Open-air screen: a tall framed screen at the back (-x), rising rows of CLAY seats facing it, a projector at the front.
static func big_screen() -> Array:
	var P := Buildings.part
	var out: Array = [
		P.call(Vector2.ZERO, Vector2(1.42, 1.42), 3, Palette.STONE),
		P.call(Vector2(-1.15, 0), Vector2(0.12, 1.25), 52, Palette.STONE, 3),
		P.call(Vector2(-1.02, 0), Vector2(0.02, 1.08), 36, Palette.CLOUD, 12),
	]
	for i in 3:
		out.append(P.call(Vector2(-0.3 + i * 0.45, 0), Vector2(0.15, 1.0), 4 + i * 4, Palette.CORAL, 3))
	out.append(P.call(Vector2(1.15, 0), Vector2(0.14, 0.14), 14, Palette.STONE, 3))
	out.append(P.call(Vector2(1.02, 0), Vector2(0.04, 0.08), 6, Palette.BUTTER, 9))  # lens
	return out
