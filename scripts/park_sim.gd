class_name ParkSim
extends RefCounted
# The park day (docs/design/game.md → "A park day"): fixed ticks, seeded RNG, no nodes.
# Walkers (guests, staff) are Dictionaries: cell (Vector2i), pos (Vector2, fractional cell for smooth drawing), path.

const TPS := 10
const DAY_TICKS := 120 * TPS
const ENTRY_FEE := 3
const SPAWN_PER_APPEAL := 0.0025 # spawn chance per tick per point of park appeal
const MAX_GUESTS := 80
const GUEST_SPEED := 0.2  # tiles per tick
const STAFF_SPEED := 0.15
const STAFF := {"janitor": {"hire": 50, "wage": 20}, "guard": {"hire": 40, "wage": 25}}
const SHOP_APPEAL := 3  # shops have no appeal in the packs; this weights them as a target
const SHOP_CAPACITY := 2
const VISIT_TICKS := {"attraction": 40, "shop": 15}
const LITTER_CHANCE := 0.3
const QUEUE_GIVE_UP := 100  # ticks
const UNHAPPY := 20.0
# Raids (docs/design/game.md → Raids). Speeds: guest < raider < guard.
const RAID_TICKS := 60 * TPS
const RAIDER_SPEED := 0.25
const GUARD_SPEED := 0.3
const RAIDER_GAP := 5          # ticks between raiders entering
const CATCH_PAUSE := 2 * TPS
const RAIDER_WORK := {"hooligan": 3 * TPS, "thief": 4 * TPS, "spy": 5 * TPS}
const LITTER_EVERY := TPS
const THEFT_SHARE := 0.2       # thieves take this share of the target's money

var money: int
var tick := 0
var guests: Array[Dictionary] = []  # walker + mood (0-100), state: walk|queue|visit|leave
var staff: Array[Dictionary] = []   # walker + kind
var litter: Dictionary = {}         # path cell -> true
var closed: Dictionary = {}         # building origin -> true (R1: wrecked by raiders)
var income := 0
var served := 0   # guests who finished at least one visit
var spawned := 0
var raiders: Array[Dictionary] = []  # walker + state: go|work|roam|escape, wait, loot, target
var raiding := false
var _raid_queue: Array[String] = []
var _raid_end := 0
var _raid_litter: Dictionary = {}
var _raid := {}

var _rng := RandomNumberGenerator.new()
var _astar := AStarGrid2D.new()
var _entrance := Vector2i(-1, -1)
var _paths: Array[Vector2i] = []
var _targets: Array[Dictionary] = []  # reachable attractions/shops: origin, role, appeal, capacity, price, door, inside
var _decor: Dictionary = {}           # cell -> mood per tick from nearby decor
var _appeal := 0.0
var _gone_mood := 0.0
var _gone := 0
var _wages := 0

func _init(map: ParkMap, seed_value: int) -> void:
	_rng.seed = seed_value
	money = map.money
	_astar.region = Rect2i(Vector2i.ZERO, IsoGrid.SIZE)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.update()
	_load(map)

## Pick up map changes mid-day: rebuild the path graph and targets, re-route everyone already walking.
func load_map(map: ParkMap) -> void:
	var old_origins: Array = _targets.map(func(t: Dictionary) -> Vector2i: return t["origin"])
	_load(map)
	if _entrance.x < 0:
		guests.clear()  # ponytail: gate removed mid-day, guests just vanish
		return
	var index := {}
	for i in _targets.size():
		index[_targets[i]["origin"]] = i
	for w in guests + staff:
		w["path"] = []
		if _astar.is_point_solid(w["cell"]):  # path under them was erased
			w["cell"] = _entrance
			w["pos"] = Vector2(_entrance)
	for g in guests:
		var t: int = index.get(old_origins[g["target"]], -1) if g["target"] >= 0 else -1
		g["target"] = t
		if g["state"] == "leave":
			_go(g, _entrance)
		elif t < 0:
			_pick(g)  # its building is gone
		elif g["state"] == "visit":
			_targets[t]["inside"] += 1
		elif g["state"] == "walk":
			_go(g, _targets[t]["door"])

## Morning: clock, counters, guests and litter reset; staff stay on the payroll and start at the gate.
func new_day() -> void:
	tick = 0
	income = 0
	served = 0
	spawned = 0
	_gone = 0
	_gone_mood = 0.0
	_wages = 0
	guests.clear()
	litter.clear()
	for t in _targets:
		t["inside"] = 0
	if _entrance.x >= 0:
		for s in staff:
			s.merge(_walker(s["kind"]), true)

func _load(map: ParkMap) -> void:
	_entrance = Vector2i(-1, -1)
	_paths.clear()
	_targets.clear()
	_decor.clear()
	_appeal = 0.0
	_astar.fill_solid_region(_astar.region)
	for origin: Vector2i in map.buildings:
		var role: String = Buildings.get_def(map.buildings[origin])["role"]
		if role == "path":
			_paths.append(origin)
		elif role == "entrance":
			_entrance = origin
		if role == "path" or role == "entrance":
			_astar.set_point_solid(origin, false)
	if _entrance.x < 0:
		return
	var decor_appeal := 0.0
	for origin: Vector2i in map.buildings:
		var id: String = map.buildings[origin]
		var d: Dictionary = Buildings.get_def(id)
		if d["role"] == "decor":
			decor_appeal += d["appeal"]
			for c in ParkMap.footprint(id, origin):
				for dx in range(-2, 3):
					for dy in range(-2, 3):
						var k := c + Vector2i(dx, dy)
						_decor[k] = _decor.get(k, 0.0) + d["appeal"] * 0.01
		elif d["role"] == "attraction" or d["role"] == "shop":
			var door := _door(id, origin)
			if door.x < 0:
				continue
			var shop: bool = d["role"] == "shop"
			_targets.append({"id": id, "origin": origin, "role": d["role"], "door": door, "inside": 0,
				"appeal": SHOP_APPEAL if shop else d["appeal"], "capacity": SHOP_CAPACITY if shop else d["capacity"],
				"price": d.get("price", 0)})
			_appeal += _targets[-1]["appeal"]
	if not _targets.is_empty():
		_appeal += decor_appeal

## The path tile next to the footprint with the shortest walk from the entrance, or (-1,-1).
func _door(id: String, origin: Vector2i) -> Vector2i:
	var fp := ParkMap.footprint(id, origin)
	var best := Vector2i(-1, -1)
	var best_len := 1 << 30
	for c in fp:
		for n: Vector2i in [c + Vector2i.LEFT, c + Vector2i.RIGHT, c + Vector2i.UP, c + Vector2i.DOWN]:
			if n in fp or not n in _paths:
				continue
			var p := _astar.get_id_path(_entrance, n)
			if not p.is_empty() and p.size() < best_len:
				best = n
				best_len = p.size()
	return best

func step() -> void:
	if tick >= DAY_TICKS:
		return
	tick += 1
	if guests.size() < MAX_GUESTS and _rng.randf() < _appeal * SPAWN_PER_APPEAL:
		_spawn()
	var stay: Array[Dictionary] = []
	for g in guests:
		if _step_guest(g):
			_gone_mood += g["mood"]
			_gone += 1
		else:
			stay.append(g)
	guests = stay
	for s in staff:
		_step_staff(s)
	if raiding:
		_step_raid()
	if tick == DAY_TICKS:
		for s in staff:
			_wages += STAFF[s["kind"]]["wage"]
		money -= _wages

func day_time() -> float:
	return float(tick) / TPS

func day_report() -> Dictionary:
	var mood := _gone_mood
	for g in guests:
		mood += g["mood"]
	var n := _gone + guests.size()
	return {"income": income, "served": served, "guests": spawned, "wages": _wages,
		"happiness": mood / n if n > 0 else 0.0}

## Hire staff up front; they start at the entrance. False if unknown kind, too poor, or no entrance.
func hire(kind: String) -> bool:
	if not STAFF.has(kind) or money < STAFF[kind]["hire"] or _entrance.x < 0:
		return false
	money -= STAFF[kind]["hire"]
	staff.append(_walker(kind))
	return true

func _walker(kind: String) -> Dictionary:
	return {"kind": kind, "cell": _entrance, "pos": Vector2(_entrance), "path": []}

func _spawn() -> void:
	var g := _walker("guest")
	g.merge({"id": spawned, "mood": 50.0, "state": "walk", "target": -1, "visits": 0, "wants": _rng.randi_range(2, 4), "wait": 0, "litter_in": 0})
	guests.append(g)
	spawned += 1
	money += ENTRY_FEE
	income += ENTRY_FEE
	_pick(g)

func _go(w: Dictionary, to: Vector2i) -> void:
	var p := _astar.get_id_path(w["cell"], to)
	w["path"] = Array(p.slice(1))

## Moves along the path; true once at its end.
func _walk(w: Dictionary, speed: float) -> bool:
	var path: Array = w["path"]
	var left := speed
	while not path.is_empty():
		var next := Vector2(path[0])
		var d: float = w["pos"].distance_to(next)
		if d > left:
			w["pos"] += (next - w["pos"]) / d * left
			return false
		w["pos"] = next
		w["cell"] = path.pop_front()
		left -= d
	return true

## True when the guest has left the park.
func _step_guest(g: Dictionary) -> bool:
	match g["state"]:
		"walk":
			if _walk(g, GUEST_SPEED):
				_arrive(g)
		"queue":
			g["wait"] += 1
			g["mood"] -= 0.05  # crowding
			var t: Dictionary = _targets[g["target"]]
			if closed.has(t["origin"]):
				g["mood"] -= 10
				_pick(g)
			elif t["inside"] < t["capacity"]:
				_enter(g, t)
			elif g["wait"] > QUEUE_GIVE_UP:
				g["mood"] -= 10
				_pick(g)
		"visit":
			g["wait"] -= 1
			if g["wait"] <= 0:
				_finish(g)
		"leave":
			if _walk(g, GUEST_SPEED):
				return true
	var c: Vector2i = g["cell"]
	if g["litter_in"] > 0:
		g["litter_in"] -= 1
		if g["litter_in"] == 0 and c != _entrance:
			litter[c] = true
	g["mood"] += _decor.get(c, 0.0)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if litter.has(c + Vector2i(dx, dy)):
				g["mood"] -= 0.03
	g["mood"] = clampf(g["mood"], 0.0, 100.0)
	if g["mood"] < UNHAPPY and (g["state"] == "walk" or g["state"] == "queue"):
		_leave(g)
	return false

## Next target, weighted by appeal, never the one just visited. Leaves if nothing is open.
func _pick(g: Dictionary) -> void:
	var total := 0.0
	for i in _targets.size():
		if i != g["target"] and not closed.has(_targets[i]["origin"]):
			total += _targets[i]["appeal"]
	var r := _rng.randf() * total
	for i in _targets.size():
		if i == g["target"] or closed.has(_targets[i]["origin"]):
			continue
		r -= _targets[i]["appeal"]
		if r <= 0.0:
			g["target"] = i
			g["state"] = "walk"
			_go(g, _targets[i]["door"])
			return
	_leave(g)

func _arrive(g: Dictionary) -> void:
	var t: Dictionary = _targets[g["target"]]
	if closed.has(t["origin"]):
		g["mood"] -= 10
		_pick(g)
	elif t["inside"] < t["capacity"]:
		_enter(g, t)
	else:
		g["state"] = "queue"
		g["wait"] = 0

func _enter(g: Dictionary, t: Dictionary) -> void:
	t["inside"] += 1
	g["state"] = "visit"
	g["wait"] = VISIT_TICKS[t["role"]]

func _finish(g: Dictionary) -> void:
	var t: Dictionary = _targets[g["target"]]
	t["inside"] -= 1
	g["visits"] += 1
	if g["visits"] == 1:
		served += 1
	if t["role"] == "shop":
		money += t["price"]
		income += t["price"]
		g["mood"] += 5
		if _rng.randf() < LITTER_CHANCE:
			g["litter_in"] = _rng.randi_range(5, 40)  # dropped a few steps down the path
	else:
		g["mood"] += t["appeal"] * 1.5
	g["mood"] = minf(g["mood"], 100.0)
	if g["visits"] >= g["wants"] or g["mood"] < UNHAPPY:
		_leave(g)
	else:
		_pick(g)

func _leave(g: Dictionary) -> void:
	g["state"] = "leave"
	_go(g, _entrance)

func _step_staff(s: Dictionary) -> void:
	if s["kind"] == "guard" and s.get("pause", 0) > 0:
		s["pause"] -= 1
		return
	if not _walk(s, GUARD_SPEED if s["kind"] == "guard" else STAFF_SPEED):
		return
	if s["kind"] == "guard":
		if not _paths.is_empty():
			_go(s, _paths[_rng.randi() % _paths.size()])
		return
	litter.erase(s["cell"])
	# ponytail: nearest by grid distance, not walk distance; fine on a 16x16 park
	var best := Vector2i(-1, -1)
	var best_d := 1 << 30
	for c: Vector2i in litter:
		var d := absi(c.x - s["cell"].x) + absi(c.y - s["cell"].y)
		if d < best_d:
			best = c
			best_d = d
	if best.x >= 0:
		_go(s, best)

## Raiders (hooligan, litterbug, thief, spy) enter at the entrance one by one. Ends after 60 s or when none are left.
func start_raid(squad: Array[String]) -> void:
	if _entrance.x < 0:
		return
	raiding = true
	raiders.clear()
	_raid_queue = squad.duplicate()
	_raid_end = tick + RAID_TICKS
	_raid = {"stolen_money": 0, "blueprints": [] as Array[String], "wrecked": 0, "end_happiness": -1.0}

func raid_result() -> Dictionary:
	var r := _raid.duplicate()
	if r["end_happiness"] < 0.0:
		r["end_happiness"] = _happiness_now()
	r["stars"] = [r["wrecked"] > 0, r["stolen_money"] > 0 or not r["blueprints"].is_empty(),
		r["end_happiness"] < 50.0] as Array[bool]
	return r

## Undo the temporary damage: wrecked buildings reopen, raid litter goes.
func end_raid() -> void:
	if raiding:
		_finish_raid()
	closed.clear()
	for c: Vector2i in _raid_litter:
		litter.erase(c)
	_raid_litter.clear()

func _happiness_now() -> float:
	if guests.is_empty():
		return day_report()["happiness"]
	var m := 0.0
	for g in guests:
		m += g["mood"]
	return m / guests.size()

func _finish_raid() -> void:
	raiding = false
	raiders.clear()
	_raid_queue.clear()
	_raid["end_happiness"] = _happiness_now()

func _step_raid() -> void:
	if not _raid_queue.is_empty() and (_raid_end - RAID_TICKS - tick) % RAIDER_GAP == 0:
		var r := _walker(_raid_queue.pop_front())
		r.merge({"state": "go", "wait": 0, "loot": 0, "target": -1})
		raiders.append(r)
		_raider_next(r)
	var out: Array[Dictionary] = []
	for r in raiders:
		if _step_raider(r):
			out.append(r)
	for s in staff:
		if s["kind"] != "guard" or s.get("pause", 0) > 0:
			continue
		for r in raiders:
			if not r in out and s["pos"].distance_to(r["pos"]) <= 1.0:
				out.append(r)
				s["pause"] = CATCH_PAUSE
				break
	raiders = raiders.filter(func(r: Dictionary) -> bool: return not r in out)
	if tick >= _raid_end or (raiders.is_empty() and _raid_queue.is_empty()):
		_finish_raid()

## Picks the raider's next job: hooligans any open attraction/shop, thieves a shop, spies the top-appeal building.
func _raider_next(r: Dictionary) -> void:
	var kind: String = r["kind"]
	if kind == "litterbug":
		r["state"] = "roam"
		if not _paths.is_empty():
			_go(r, _paths[_rng.randi() % _paths.size()])
		return
	var pick: Array[int] = []
	for i in _targets.size():
		var t := _targets[i]
		if kind == "hooligan" and not closed.has(t["origin"]) or kind == "thief" and t["role"] == "shop":
			pick.append(i)
		elif kind == "spy" and (pick.is_empty() or Buildings.get_def(t["id"]).get("appeal", 0) > Buildings.get_def(_targets[pick[0]]["id"]).get("appeal", 0)):
			pick = [i]
	if pick.is_empty():
		r["state"] = "escape"
		_go(r, _entrance)
		return
	r["target"] = pick[_rng.randi() % pick.size()]
	r["state"] = "go"
	_go(r, _targets[r["target"]]["door"])

## True when the raider leaves the park (escaped with loot or gave up).
func _step_raider(r: Dictionary) -> bool:
	match r["state"]:
		"go":
			if _walk(r, RAIDER_SPEED):
				r["state"] = "work"
				r["wait"] = RAIDER_WORK[r["kind"]]
		"work":
			r["wait"] -= 1
			if r["wait"] > 0:
				return false
			var t: Dictionary = _targets[r["target"]]
			if r["kind"] == "hooligan":
				if not closed.has(t["origin"]):
					closed[t["origin"]] = true
					_raid["wrecked"] += 1
				_raider_next(r)
			else:
				if r["kind"] == "thief":
					r["loot"] = int(money * THEFT_SHARE)
				r["state"] = "escape"
				_go(r, _entrance)
		"roam":
			if tick % LITTER_EVERY == 0 and r["cell"] != _entrance and not litter.has(r["cell"]):
				litter[r["cell"]] = true
				_raid_litter[r["cell"]] = true
			if _walk(r, RAIDER_SPEED):
				_raider_next(r)
		"escape":
			if _walk(r, RAIDER_SPEED):
				if r["kind"] == "thief":
					var m := mini(r["loot"], money)
					money -= m
					_raid["stolen_money"] += m
				elif r["kind"] == "spy" and r["target"] >= 0:
					_raid["blueprints"].append(_targets[r["target"]]["id"])
				return true
	return false
