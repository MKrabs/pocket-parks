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
			"specialty": "heavy", "mode": "only", "parts": reinforced()},
		"builder_shed": {"name": "Builder Shed", "role": "staff", "footprint": Vector2i(1, 1), "cost": 80,
			"specialty": "carpenter", "mode": "faster", "parts": B.shed(Palette.CLAY)},
	}

## Glass tank on a STONE plinth: glass sides with a STONE rim, WATER inside below the rim.
static func water_tank() -> Array:
	var glass := Buildings.ring("glass", 26, Palette.WATER, 6)
	return [
		Buildings.part(Vector2.ZERO, Vector2(1.42, 1.42), 6, Palette.STONE),
		glass[0],
		Buildings.shaped("water", Vector2(1.26, 1.26), 18, Palette.WATER, 6),
		glass[1],
	]

## Aviary: a grass floor with a tree and a perch, under one translucent dome with thin net arcs.
static func aviary() -> Array:
	var P := Buildings.part
	var out: Array = [P.call(Vector2.ZERO, Vector2(1.42, 1.42), 3, Palette.GRASS_DARK)]
	out.append_array(Buildings.tree(Vector2(-0.3, -0.3)))
	out.append(P.call(Vector2(0.45, 0.35), Vector2(0.05, 0.05), 18, Palette.WOOD, 3))
	out.append(P.call(Vector2(0.45, 0.35), Vector2(0.22, 0.04), 3, Palette.WOOD, 21))
	out.append(Buildings.shaped("dome", Vector2(1.32, 1.32), 58, Palette.SKY, 3))
	return out

## Grass floor, rock and tree inside a continuous WOOD fence.
static func enclosure() -> Array:
	return _ringed(Buildings.ring("fence", 12, Palette.WOOD, 3), [], [])

## One continuous STONE wall with buttresses (two per side, outside the wall).
static func reinforced() -> Array:
	var back: Array = []
	var front: Array = []
	for s in [-1.0, 1.0]:
		for t in [-0.55, 0.55]:
			for at: Vector2 in [Vector2(1.4 * s, t), Vector2(t, 1.4 * s)]:
				var half := Vector2(0.1, 0.13) if absf(at.x) > 1.0 else Vector2(0.13, 0.1)
				var b := Buildings.part(at, half, 13, Palette.STONE, 3)
				(back if at.x + at.y < 0.0 else front).append(b)
	return _ringed(Buildings.ring("wall", 18, Palette.STONE, 3), back, front)

## Grass floor, then `behind` the ring, the ring's far half, a rock and a tree, its near half, `before` it.
static func _ringed(ring: Array, behind: Array, before: Array) -> Array:
	return [Buildings.part(Vector2.ZERO, Vector2(1.42, 1.42), 3, Palette.GRASS_DARK)] + behind + [
		ring[0],
		Buildings.part(Vector2(0.45, -0.45), Vector2(0.26, 0.2), 9, Palette.STONE, 3),
	] + Buildings.tree(Vector2(-0.4, 0.4)) + [ring[1]] + before
