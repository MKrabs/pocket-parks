class_name BotPark
# Pure generator for parks to visit: entrance on the west edge, a path spine with branches,
# attractions and shops touching the paths, decor on free cells. Same seed -> same park.

const SIZES := {
	"small": {"attractions": 3, "shops": 2, "decor": 8, "branches": 2},
	"large": {"attractions": 6, "shops": 3, "decor": 16, "branches": 3},
}
const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

static func generate(theme_id: String, seed: int, size := "small") -> ParkMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var cfg: Dictionary = SIZES[size]
	var map := ParkMap.new()
	map.money = 1 << 30  # bots build for free; can_place still checks every cell
	map.xp = ParkLevel.THRESHOLDS[-1]  # and have everything unlocked
	var y0 := rng.randi_range(4, IsoGrid.SIZE.y - 5)
	map.place(_pick(rng, theme_id, "entrance"), Vector2i(0, y0))
	var path: String = _pick(rng, theme_id, "path")
	var spine_end := rng.randi_range(IsoGrid.SIZE.x - 5, IsoGrid.SIZE.x - 2)
	for x in range(1, spine_end + 1):
		map.place(path, Vector2i(x, y0))
	# Branches: vertical runs off the spine, spaced apart so they don't merge into blobs.
	var xs: Array = _shuffled(rng, range(3, spine_end + 1, 3))
	for i in mini(cfg["branches"], xs.size()):
		var dir := 1 if rng.randf() < 0.5 else -1
		for k in range(1, rng.randi_range(3, 6) + 1):
			map.place(path, Vector2i(xs[i], y0 + dir * k))  # stops at the edge (place fails)
	var cells: Array = []
	for x in IsoGrid.SIZE.x:
		for y in IsoGrid.SIZE.y:
			cells.append(Vector2i(x, y))
	for role: String in ["attraction", "shop"]:
		for n in cfg[role + "s"]:
			var id := _pick(rng, theme_id, role)
			for c: Vector2i in _shuffled(rng, cells):
				if map.can_place(id, c) and touches_path(map, ParkMap.footprint(id, c)):
					map.place(id, c)
					break
	var fences: Array = Buildings.themes()[theme_id].keys().filter(func(id: String) -> bool:
		return Buildings.get_def(id).has("habitat"))
	for n in (rng.randi_range(1, 2) if not fences.is_empty() else 0):  # a habitat or two, painted beside a path
		var id: String = fences[rng.randi() % fences.size()]
		var r := Rect2i(Vector2i.ZERO, Vector2i(rng.randi_range(2, 4), rng.randi_range(2, 3)))
		for c: Vector2i in _shuffled(rng, cells):
			r.position = c
			if map.paint_target(id, r).x == -1 and map.can_paint(id, r) and touches_path(map, ParkMap.rect_cells(r)):
				var o := map.paint(id, r)
				var offer := Animals.picker(map.habitats[o]["fence"])
				var k := absi(hash(o))  # not from rng: the rest of the layout stays as it was
				if not offer.is_empty():  # animal-free areas (the festival's picnic lawn) stay empty
					map.habitats[o]["animal"] = offer[k % offer.size()]
					map.habitats[o]["count"] = 2 + k % (Animals.MAX - 1)
				break
	var placed := 0
	for c: Vector2i in _shuffled(rng, cells):
		if placed == cfg["decor"]:
			break
		if map.place(_pick(rng, theme_id, "decor"), c):
			placed += 1
	map.money = ParkMap.START_MONEY
	return map

## True if any of `cells` has a path tile as a 4-neighbour.
static func touches_path(map: ParkMap, cells: Array) -> bool:
	for c: Vector2i in cells:
		for d in DIRS:
			var o: Variant = map.occupied.get(c + d)
			if o != null and Buildings.get_def(map.buildings[o])["role"] == "path":
				return true
	return false

static func _pick(rng: RandomNumberGenerator, theme_id: String, role: String) -> String:
	var cat: Dictionary = Buildings.themes()[theme_id]
	var ids: Array = cat.keys().filter(func(id: String) -> bool: return cat[id]["role"] == role and not cat[id].has("habitat"))
	return ids[rng.randi() % ids.size()]

## Fisher-Yates with our rng (Array.shuffle uses the global one, which breaks determinism).
static func _shuffled(rng: RandomNumberGenerator, a: Array) -> Array:
	var out := a.duplicate()
	for i in range(out.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = out[i]
		out[i] = out[j]
		out[j] = t
	return out
