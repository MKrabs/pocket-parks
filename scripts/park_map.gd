class_name ParkMap
extends RefCounted
# Pure placement rules: which building covers which cell, and the money counter.

const START_MONEY := 500
const PLOT := 4  # plot side in cells: the 20×20 world is 5×5 plots
const PLOT_PRICE := 200  # the first plot; each one bought adds this again
const START_PLOTS := Rect2i(1, 1, 3, 3)  # in plot coords: the 12×12 centre you start with

var money: int = START_MONEY
var buildings: Dictionary = {}  # origin cell (Vector2i) -> building id
var occupied: Dictionary = {}   # every covered cell -> origin cell
var levels: Dictionary = {}     # origin cell -> level 2..3 (absent = 1)
var rotations: Dictionary = {}  # origin cell -> quarter turns 1..3 (absent = 0)
var xp := 0                     # park XP (ParkLevel); the sim owns it while the day runs, like money
var specialties: Dictionary = {}  # builder shed origin -> Array of Specialties ids its builder picked
var owned: Dictionary = {}  # plot coord -> true. Empty = no plots, every cell is yours (bot parks)
var bought := 0  # plots bought beyond the start area

## Your park: own only the start area; the rest is for sale.
func start_small() -> void:
	for x in range(START_PLOTS.position.x, START_PLOTS.end.x):
		for y in range(START_PLOTS.position.y, START_PLOTS.end.y):
			owned[Vector2i(x, y)] = true

static func plot_of(cell: Vector2i) -> Vector2i:
	return Vector2i(floori(cell.x / float(PLOT)), floori(cell.y / float(PLOT)))  # -1 is plot -1, not 0

func owns(cell: Vector2i) -> bool:
	return owned.is_empty() or owned.has(plot_of(cell))

## Not yet owned, inside the world, and sharing an edge with land you own.
func buyable(plot: Vector2i) -> bool:
	if owned.is_empty() or owned.has(plot) or not IsoGrid.in_bounds(plot * PLOT):
		return false
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if owned.has(plot + d):
			return true
	return false

func plot_price() -> int:
	return PLOT_PRICE * (bought + 1)

## Park level another plot waits for, or 0 if you may buy one now (-1: no more ever).
func plot_needs() -> int:
	return 0 if bought < ParkLevel.cap("plots", park_level()) else ParkLevel.needed("plots", bought + 1)

func can_buy(plot: Vector2i) -> bool:
	return buyable(plot) and money >= plot_price() and plot_needs() == 0

func buy(plot: Vector2i) -> bool:
	if not can_buy(plot):
		return false
	money -= plot_price()
	owned[plot] = true
	bought += 1
	return true

func park_level() -> int:
	return ParkLevel.of(xp)

## Park level a new building `id` waits for (more builder sheds), or 0 if it may be placed.
func shed_needs(id: String) -> int:
	if Buildings.get_def(id)["role"] != "staff":
		return 0
	var n := buildings.values().filter(func(b: String) -> bool: return Buildings.get_def(b)["role"] == "staff").size()
	return 0 if n < ParkLevel.cap("sheds", park_level()) else ParkLevel.needed("sheds", n + 1)

func specs(shed: Vector2i) -> Array:
	return specialties.get(shed, [])

## Specialties the builder at `shed` may show: the ones it has, plus all others while a slot is free. Never locked ones.
func spec_choices(shed: Vector2i) -> Array:
	var free := specs(shed).size() < ParkLevel.cap("specialties", park_level())
	return Specialties.ALL.keys().filter(func(s: String) -> bool: return free or s in specs(shed))

## Pick `s` for the builder at `shed`, or drop it if it already has it. False if no slot is free.
func toggle_specialty(shed: Vector2i, s: String) -> bool:
	var have: Array = specialties.get_or_add(shed, [])
	if s in have:
		have.erase(s)
		return true
	if not s in spec_choices(shed):
		return false
	have.append(s)
	return true

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
		if not IsoGrid.in_bounds(c) or occupied.has(c) or not owns(c):
			return false
	return true

## True if some in-bounds footprint cell is land you don't own (the ghost says so).
func on_unowned(id: String, cell: Vector2i, rot := 0) -> bool:
	return footprint(id, cell, rot).any(func(c: Vector2i) -> bool: return IsoGrid.in_bounds(c) and not owns(c))

func can_place(id: String, cell: Vector2i, rot := 0) -> bool:
	return fits(id, cell, rot) and money >= Buildings.get_def(id)["cost"] and shed_needs(id) == 0

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
	specialties.erase(origin)
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

## Park level the next upgrade waits for, or 0 if the park level already allows it.
func upgrade_needs(origin: Vector2i) -> int:
	if level(origin) < ParkLevel.cap("building_level", park_level()):
		return 0
	return ParkLevel.needed("building_level", level(origin) + 1)

func can_upgrade(origin: Vector2i) -> bool:
	var c := upgrade_cost(origin)
	return c >= 0 and money >= c and upgrade_needs(origin) == 0

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
