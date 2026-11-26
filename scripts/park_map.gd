class_name ParkMap
extends RefCounted
# Pure placement rules: which building covers which cell, and the money counter.

const START_MONEY := 500

var money: int = START_MONEY
var buildings: Dictionary = {}  # origin cell (Vector2i) -> building id
var occupied: Dictionary = {}   # every covered cell -> origin cell
var levels: Dictionary = {}     # origin cell -> level 2..3 (absent = 1)

static func footprint(id: String, origin: Vector2i) -> Array[Vector2i]:
	var fp: Vector2i = Buildings.get_def(id)["footprint"]
	var out: Array[Vector2i] = []
	for x in fp.x:
		for y in fp.y:
			out.append(origin + Vector2i(x, y))
	return out

func fits(id: String, cell: Vector2i) -> bool:
	for c in footprint(id, cell):
		if not IsoGrid.in_bounds(c) or occupied.has(c):
			return false
	return true

func can_place(id: String, cell: Vector2i) -> bool:
	return fits(id, cell) and money >= Buildings.get_def(id)["cost"]

func place(id: String, cell: Vector2i) -> bool:
	if not can_place(id, cell):
		return false
	money -= Buildings.get_def(id)["cost"]
	buildings[cell] = id
	for c in footprint(id, cell):
		occupied[c] = cell
	return true

## Removes the whole building covering `cell`, refunds half of all it cost (upgrades too). False if the cell is empty.
func remove_at(cell: Vector2i) -> bool:
	if not occupied.has(cell):
		return false
	var origin: Vector2i = occupied[cell]
	var id: String = buildings[origin]
	for c in footprint(id, origin):
		occupied.erase(c)
	var cost: int = Buildings.get_def(id)["cost"]
	var paid := cost * (1 + (level(origin) - 1) * level(origin) / 2)  # 1×, +1×, +2×
	buildings.erase(origin)
	levels.erase(origin)
	money += paid / 2
	return true

func level(origin: Vector2i) -> int:
	return levels.get(origin, 1)

## Price of the next level (level 2 = 1× cost, level 3 = 2×), or -1 if this can't be upgraded.
func upgrade_cost(origin: Vector2i) -> int:
	if not buildings.has(origin) or not Buildings.upgradable(buildings[origin]) or level(origin) >= Buildings.MAX_LEVEL:
		return -1
	return Buildings.get_def(buildings[origin])["cost"] * level(origin)

func can_upgrade(origin: Vector2i) -> bool:
	var c := upgrade_cost(origin)
	return c >= 0 and money >= c

func upgrade(origin: Vector2i) -> bool:
	if not can_upgrade(origin):
		return false
	money -= upgrade_cost(origin)
	levels[origin] = level(origin) + 1
	return true

## Draw order key: x+y of the footprint's front (largest) corner.
static func depth(id: String, origin: Vector2i) -> int:
	var fp: Vector2i = Buildings.get_def(id)["footprint"]
	return origin.x + origin.y + fp.x + fp.y - 2
