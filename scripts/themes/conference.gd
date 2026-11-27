class_name ConferenceTheme
# Conference theme pack: registration desk, carpet, Main Stage, booths, coffee, plants and roll-up banners.

static func catalog() -> Dictionary:
	var P := Buildings.part
	return {
		"conf_desk": {"name": "Registration Desk", "role": "entrance", "footprint": Vector2i(1, 1), "cost": 100,
			"parts": [
				P.call(Vector2(0.2, -0.3), Vector2(0.14, 0.13), 11, Palette.WOOD),  # the two desks either side
				P.call(Vector2(0.2, 0.3), Vector2(0.14, 0.13), 11, Palette.WOOD),
				P.call(Vector2(0.2, -0.3), Vector2(0.06, 0.08), 3, Palette.CLOUD, 11),  # badges waiting
				P.call(Vector2(0.2, 0.3), Vector2(0.06, 0.08), 3, Palette.CLOUD, 11),
			] + Buildings.arch(Palette.STONE, Palette.SKY) + [
				P.call(Vector2(0.15, 0), Vector2(0.02, 0.22), 4, Palette.BUTTER, 27),  # welcome stripe
			]},
		"conf_carpet": {"name": "Carpet", "role": "path", "footprint": Vector2i(1, 1), "cost": 6,
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.46, 0.46), 2, Palette.STONE),
				P.call(Vector2.ZERO, Vector2(0.46, 0.3), 1, Palette.SKY, 2),
			]},
		"conf_stage": {"name": "Main Stage", "role": "attraction", "appeal": 14, "capacity": 14, "footprint": Vector2i(3, 2),
			"cost": 250, "specialty": "tech", "mode": "only", "parts": main_stage()},
		"conf_booth": {"name": "Booth", "role": "attraction", "appeal": 4, "capacity": 3, "footprint": Vector2i(1, 1), "cost": 70,
			"specialty": "carpenter", "mode": "faster", "variants": ["conf_booth", "conf_expo", "conf_pavilion"],
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.42, 0.42), 2, Palette.STONE),
				P.call(Vector2(-0.3, 0), Vector2(0.06, 0.36), 26, Palette.WOOD, 2),  # back panel
				P.call(Vector2(-0.24, 0), Vector2(0.01, 0.26), 14, Palette.SKY, 10),  # poster
				P.call(Vector2(0.18, 0), Vector2(0.12, 0.26), 10, Palette.CLAY, 2),  # counter
				P.call(Vector2(0.18, 0), Vector2(0.14, 0.28), 2, Palette.CLOUD, 12),
			]},
		"conf_expo": {"name": "Expo Stand", "role": "attraction", "appeal": 7, "capacity": 5, "footprint": Vector2i(2, 1), "cost": 120,
			"specialty": "carpenter", "mode": "faster",
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.9, 0.42), 2, Palette.STONE),
				P.call(Vector2(0, -0.3), Vector2(0.84, 0.06), 28, Palette.WOOD, 2),  # back wall along x
				P.call(Vector2(0, -0.24), Vector2(0.6, 0.01), 14, Palette.SKY, 11),  # long poster
				P.call(Vector2(-0.45, 0.16), Vector2(0.26, 0.12), 10, Palette.CLAY, 2),
				P.call(Vector2(0.45, 0.16), Vector2(0.26, 0.12), 10, Palette.CLAY, 2),
				P.call(Vector2(-0.45, 0.16), Vector2(0.28, 0.14), 2, Palette.CLOUD, 12),
				P.call(Vector2(0.45, 0.16), Vector2(0.28, 0.14), 2, Palette.CLOUD, 12),
			]},
		"conf_pavilion": {"name": "Pavilion", "role": "attraction", "appeal": 11, "capacity": 8, "footprint": Vector2i(2, 2), "cost": 190,
			"specialty": "carpenter", "mode": "faster",
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.8, 0.8), 22, Palette.CLOUD),
				P.call(Vector2.ZERO, Vector2(0.88, 0.88), 4, Palette.SKY, 22),  # roof
				P.call(Vector2(0.81, 0), Vector2(0.02, 0.4), 12, Palette.SKY, 5),  # open front, glowing screen
				P.call(Vector2(0, 0.81), Vector2(0.4, 0.02), 12, Palette.BUTTER, 5),
				P.call(Vector2.ZERO, Vector2(0.26, 0.26), 8, Palette.CLOUD, 26),  # sign on the roof
				P.call(Vector2.ZERO, Vector2(0.18, 0.18), 2, Palette.CLAY, 34),
			]},
		"conf_coffee": {"name": "Coffee Bar", "role": "shop", "price": 4, "capacity": 3, "footprint": Vector2i(1, 1), "cost": 60,
			"specialty": "carpenter", "mode": "faster",
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.32, 0.32), 14, Palette.WOOD),
				P.call(Vector2.ZERO, Vector2(0.36, 0.36), 2, Palette.CLOUD, 14),
				P.call(Vector2(-0.12, -0.12), Vector2(0.1, 0.1), 12, Palette.STONE, 16),  # espresso machine
				P.call(Vector2(0.14, 0.14), Vector2(0.07, 0.07), 7, Palette.CLOUD, 16),  # cup
				P.call(Vector2(0.14, 0.14), Vector2(0.05, 0.05), 1, Palette.CLAY, 23),
			]},
		"conf_plant": {"name": "Office Plant", "role": "decor", "appeal": 2, "footprint": Vector2i(1, 1), "cost": 20,
			"specialty": "landscaper", "mode": "faster",
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.17, 0.17), 10, Palette.CLOUD),
				P.call(Vector2.ZERO, Vector2(0.26, 0.26), 10, Palette.MOSS, 10),
				P.call(Vector2.ZERO, Vector2(0.17, 0.17), 8, Palette.MOSS, 20),
			]},
		"conf_banner": {"name": "Roll-up Banner", "role": "decor", "appeal": 3, "footprint": Vector2i(1, 1), "cost": 30,
			"parts": [
				P.call(Vector2.ZERO, Vector2(0.06, 0.24), 3, Palette.STONE),
				P.call(Vector2.ZERO, Vector2(0.02, 0.2), 34, Palette.SKY, 3),
				P.call(Vector2(0.02, 0), Vector2(0.01, 0.2), 6, Palette.BUTTER, 22),  # logo stripe
			]},
		"conf_shed": {"name": "Builder Shed", "role": "staff", "footprint": Vector2i(1, 1), "cost": 80,
			"specialty": "carpenter", "mode": "faster", "parts": Buildings.shed(Palette.SKY)},
	}

## 3x2 stage: wooden platform, a tall back wall at -x with a big screen, speaker stacks, a lectern up front.
static func main_stage() -> Array:
	var P := Buildings.part
	return [
		P.call(Vector2.ZERO, Vector2(1.42, 0.92), 8, Palette.WOOD),
		P.call(Vector2(-1.25, 0), Vector2(0.12, 0.9), 48, Palette.STONE, 8),
		P.call(Vector2(-1.12, 0), Vector2(0.02, 0.62), 28, Palette.SKY, 18),  # screen
		P.call(Vector2(-0.85, -0.72), Vector2(0.13, 0.13), 30, Palette.CLAY, 8),  # speakers
		P.call(Vector2(-0.85, 0.72), Vector2(0.13, 0.13), 30, Palette.CLAY, 8),
		P.call(Vector2(0.55, 0), Vector2(0.1, 0.14), 16, Palette.CLAY, 8),  # lectern
		P.call(Vector2(0.55, 0), Vector2(0.12, 0.16), 2, Palette.BUTTER, 24),
	]
