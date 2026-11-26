class_name ZooMap
extends RefCounted
# Pure placement rules: which building covers which cell, and the money counter.

const START_MONEY := 500

var money: int = START_MONEY
var buildings: Dictionary = {}  # origin cell (Vector2i) -> building id
var occupied: Dictionary = {}   # every covered cell -> origin cell

static func footprint(id: String, origin: Vector2i) -> Array[Vector2i]:
	var fp: Vector2i = Buildings.CATALOG[id]["footprint"]
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
	return fits(id, cell) and money >= Buildings.CATALOG[id]["cost"]

func place(id: String, cell: Vector2i) -> bool:
	if not can_place(id, cell):
		return false
	money -= Buildings.CATALOG[id]["cost"]
	buildings[cell] = id
	for c in footprint(id, cell):
		occupied[c] = cell
	return true

## Removes the whole building covering `cell`, refunds half its cost. False if the cell is empty.
func remove_at(cell: Vector2i) -> bool:
	if not occupied.has(cell):
		return false
	var origin: Vector2i = occupied[cell]
	var id: String = buildings[origin]
	for c in footprint(id, origin):
		occupied.erase(c)
	buildings.erase(origin)
	money += Buildings.CATALOG[id]["cost"] / 2
	return true

## Draw order key: x+y of the footprint's front (largest) corner.
static func depth(id: String, origin: Vector2i) -> int:
	var fp: Vector2i = Buildings.CATALOG[id]["footprint"]
	return origin.x + origin.y + fp.x + fp.y - 2
