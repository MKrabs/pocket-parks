class_name ParkMap
extends RefCounted
# Pure placement rules: which building covers which cell, and the money counter.

const START_MONEY := 500

var money: int = START_MONEY
var buildings: Dictionary = {}  # origin cell (Vector2i) -> building id
var occupied: Dictionary = {}   # every covered cell -> origin cell
var levels: Dictionary = {}     # origin cell -> level 2..3 (absent = 1)
var rotations: Dictionary = {}  # origin cell -> quarter turns 1..3 (absent = 0)

## Footprint size after `rot` quarter turns (3x2 turned once is 2x3).
static func size(id: String, rot := 0) -> Vector2i:
	var fp: Vector2i = Buildings.get_def(id)["footprint"]
	return Vector2i(fp.y, fp.x) if rot % 2 == 1 else fp

## Cells covered by `id` turned `rot` times; `origin` stays the min corner.
static func footprint(id: String, origin: Vector2i, rot := 0) -> Array[Vector2i]:
	var fp := size(id, rot)
	var out: Array[Vector2i] = []
	for x in fp.x:
		for y in fp.y:
			out.append(origin + Vector2i(x, y))
	return out

func rotation(origin: Vector2i) -> int:
	return rotations.get(origin, 0)

## Cells covered by the building at `origin`.
func cells(origin: Vector2i) -> Array[Vector2i]:
	return footprint(buildings[origin], origin, rotation(origin))

func fits(id: String, cell: Vector2i, rot := 0) -> bool:
	for c in footprint(id, cell, rot):
		if not IsoGrid.in_bounds(c) or occupied.has(c):
			return false
	return true

func can_place(id: String, cell: Vector2i, rot := 0) -> bool:
	return fits(id, cell, rot) and money >= Buildings.get_def(id)["cost"]

func place(id: String, cell: Vector2i, rot := 0) -> bool:
	if not can_place(id, cell, rot):
		return false
	money -= Buildings.get_def(id)["cost"]
	buildings[cell] = id
	if rot % 4 != 0:
		rotations[cell] = rot % 4
	for c in footprint(id, cell, rot):
		occupied[c] = cell
	return true

## Removes the whole building covering `cell`, refunds half of all it cost (upgrades too), or `back` if given.
## False if the cell is empty.
func remove_at(cell: Vector2i, back := -1) -> bool:
	if not occupied.has(cell):
		return false
	var origin: Vector2i = occupied[cell]
	for c in cells(origin):
		occupied.erase(c)
	money += refund(origin) if back < 0 else back
	buildings.erase(origin)
	levels.erase(origin)
	rotations.erase(origin)
	return true

## What removing the building at `origin` gives back: half of all it cost (1×, +1×, +2× per level).
func refund(origin: Vector2i) -> int:
	var cost: int = Buildings.get_def(buildings[origin])["cost"]
	return cost * (1 + (level(origin) - 1) * level(origin) / 2) / 2

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
static func depth(id: String, origin: Vector2i, rot := 0) -> int:
	var fp := size(id, rot)
	return origin.x + origin.y + fp.x + fp.y - 2
