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
# Sending people (docs/design/game.md → Sending people). Bad actors are guests with a kind other than "guest".
const GUARD_SPEED := 0.3
const CATCH_PAUSE := 2 * TPS
const GUARD_SIGHT := 3.0
const SEND_GAP := 5            # ticks between sent people entering at the gate
const GUEST_SHARE := 0.2       # sent guests pay their sender this share of what they spend
const STRIKE_TICKS := 3 * TPS
const STAY := [0.8, 0.55, 0.3, 0.1]  # stay chance after 1, 2, 3, 4 crimes; then 0
const WRECK_TICKS := 45 * TPS
const REPAIR_SHARE := 0.25
const THEFT_SHARE := 0.15
const THEFT_CAP := 60
const BASE_FINE := {"hooligan": 40, "litterbug": 30, "thief": 50, "spy": 60}
const WRONGFUL_FINE := 40
const ROBBED_TICKS := 20 * TPS
const KINDS := ["guest", "hooligan", "litterbug", "thief", "spy"]

var money: int
var tick := 0
var guests: Array[Dictionary] = []  # walker + mood (0-100), state: walk|queue|visit|strike|leave; sender, spent, crimes, loot, wanted
var staff: Array[Dictionary] = []   # walker + kind
var litter: Dictionary = {}         # path cell -> true
var closed: Dictionary = {}         # wrecked building origin -> tick it reopens
var today: Dictionary = {}          # attraction/shop origin -> {guests, income} finished visits today (info card)
var income := 0
var served := 0   # guests who finished at least one visit
var xp: int       # park XP (ParkLevel), carried across days
var spawned := 0
var events: Array = []              # crimes: {tick, kind, origin, amount, witnessed}; never who
var ledger: Dictionary = {}         # sender -> money owed to it (negative: it owes the host)
var blueprints: Dictionary = {}     # sender -> Array of building ids its spies brought home
var fined: Dictionary = {}          # sender -> fines it paid so far (already inside ledger)
var cash_events: Array = []         # guest payments: {tick, origin (gate or shop), amount}; for the money floats
var arrests: Array = []             # {tick, pos (cell), guard (staff index, -1 = accused), amount, wrongful}
var _gate: Array = []               # [kind, sender] waiting to enter

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
	xp = map.xp
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
	today.clear()
	served = 0
	spawned = 0
	_gone = 0
	_gone_mood = 0.0
	_wages = 0
	guests.clear()
	litter.clear()
	closed.clear()  # reopen ticks count from the old day's clock
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
		var d: Dictionary = Buildings.leveled(id, map.level(origin))
		if d["role"] == "decor":
			decor_appeal += d["appeal"]
			for c in map.cells(origin):
				for dx in range(-2, 3):
					for dy in range(-2, 3):
						var k := c + Vector2i(dx, dy)
						_decor[k] = _decor.get(k, 0.0) + d["appeal"] * 0.01
		elif d["role"] == "attraction" or d["role"] == "shop":
			var cells := map.cells(origin)
			var door := _door(cells)
			if door.x < 0:
				continue
			var shop: bool = d["role"] == "shop"
			_targets.append({"id": id, "origin": origin, "cells": cells, "role": d["role"], "door": door, "inside": 0,
				"appeal": SHOP_APPEAL if shop else d["appeal"], "capacity": SHOP_CAPACITY if shop else d["capacity"],
				"price": d.get("price", 0)})
			_appeal += _targets[-1]["appeal"]
	if not _targets.is_empty():
		_appeal += decor_appeal

## The path tile next to the footprint with the shortest walk from the entrance, or (-1,-1).
func _door(fp: Array[Vector2i]) -> Vector2i:
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
	for o: Vector2i in closed.keys():
		if closed[o] <= tick:
			closed.erase(o)
	if not _gate.is_empty() and tick % SEND_GAP == 0 and _entrance.x >= 0:
		var p: Array = _gate.pop_front()
		_spawn(p[0], p[1])
	if guests.size() < MAX_GUESTS and _rng.randf() < _appeal * SPAWN_PER_APPEAL:
		_spawn()
	var stay: Array[Dictionary] = []
	for g in guests:
		if _step_guest(g):
			_gone_mood += g["mood"]
			_gone += 1
			if g["kind"] == "guest" and g["visits"] > 0 and g["mood"] >= ParkLevel.HAPPY:
				xp += ParkLevel.XP_HAPPY
			_settle(g)
		else:
			stay.append(g)
	guests = stay
	for s in staff:
		_step_staff(s)
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

## A person sent by `sender` joins the gate queue and enters like a guest. kind: one of KINDS.
func send(kind: String, sender: String) -> void:
	assert(kind in KINDS, "unknown kind " + kind)
	_gate.append([kind, sender])

## What `sender` has in this park: guests / hidden (actors not wanted) / wanted, counting the gate queue,
## plus earned (guest share, loot, wrongful-arrest pay) and fines paid.
func sent_by(sender: String) -> Dictionary:
	var out := {"guests": 0, "hidden": 0, "wanted": 0, "fines": fined.get(sender, 0)}
	out["earned"] = ledger.get(sender, 0) + out["fines"]
	var people: Array = _gate.map(func(p: Array) -> Dictionary: return {"kind": p[0], "sender": p[1], "wanted": false})
	for g in people + guests:
		if g["sender"] == sender:
			out["guests" if g["kind"] == "guest" else "wanted" if g["wanted"] else "hidden"] += 1
	return out

func _spawn(kind := "guest", sender := "") -> void:
	var g := _walker(kind)
	# ponytail: actors never stop for "wants"; they leave by the stay table (or by mood)
	g.merge({"id": spawned, "mood": 50.0, "state": "walk", "target": -1, "visits": 0, "wait": 0, "litter_in": 0,
		"wants": _rng.randi_range(2, 4) if kind == "guest" else 1 << 20,
		"sender": sender, "spent": ENTRY_FEE, "crimes": 0, "loot": 0, "spied": [], "wanted": false, "event": {}})
	guests.append(g)
	spawned += 1
	money += ENTRY_FEE
	income += ENTRY_FEE
	cash_events.append({"tick": tick, "origin": _entrance, "amount": ENTRY_FEE})
	_pick(g)

## Left through the gate: the sender gets its guest share, or the actor's loot and blueprints.
## ponytail: people still inside at new_day() are dropped without settling.
func _settle(g: Dictionary) -> void:
	var sender: String = g["sender"]
	if sender == "":
		return
	var owed: int = int(g["spent"] * GUEST_SHARE) if g["kind"] == "guest" else g["loot"]
	money -= owed if g["kind"] == "guest" else 0  # loot already left the host's money at the theft
	ledger[sender] = ledger.get(sender, 0) + owed
	if not g["spied"].is_empty():
		blueprints[sender] = blueprints.get(sender, []) + g["spied"]

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
		"strike":
			g["wait"] -= 1
			if g["wait"] <= 0:
				_hide(g)
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
		xp += ParkLevel.XP_SERVED
	if t["role"] == "shop":
		money += t["price"]
		income += t["price"]
		cash_events.append({"tick": tick, "origin": t["origin"], "amount": t["price"]})
		g["spent"] += t["price"]
		g["mood"] += 5
		if _rng.randf() < LITTER_CHANCE:
			g["litter_in"] = _rng.randi_range(5, 40)  # dropped a few steps down the path
	else:
		g["mood"] += t["appeal"] * 1.5
	var d: Dictionary = today.get_or_add(t["origin"], {"guests": 0, "income": 0})
	d["guests"] += 1
	d["income"] += t["price"] if t["role"] == "shop" else 0
	g["mood"] = minf(g["mood"], 100.0)
	if g["kind"] != "guest" and (g["kind"] != "thief" or t["role"] == "shop"):
		_strike(g, t)
	elif g["visits"] >= g["wants"] or g["mood"] < UNHAPPY:
		_leave(g)
	else:
		_pick(g)

func _leave(g: Dictionary) -> void:
	g["state"] = "leave"
	_go(g, _entrance)

## The actor does its crime at the building it just visited, exposed for STRIKE_TICKS.
func _strike(g: Dictionary, t: Dictionary) -> void:
	g["state"] = "strike"
	g["wait"] = STRIKE_TICKS
	g["crimes"] += 1
	var origin: Vector2i = t["origin"]
	var e := {"tick": tick, "kind": "", "origin": origin, "amount": 0, "witnessed": false}
	match g["kind"]:
		"hooligan":
			e["kind"] = "wrecked"
			closed[origin] = tick + WRECK_TICKS
		"litterbug":
			e["kind"] = "littered"
			var spots: Array[Vector2i] = []
			for c: Vector2i in t["cells"]:
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						var n := c + Vector2i(dx, dy)
						if n in _paths and not litter.has(n) and not n in spots:
							spots.append(n)
			for i in mini(_rng.randi_range(2, 4), spots.size()):
				litter[spots.pop_at(_rng.randi() % spots.size())] = true
				e["amount"] += 1
		"thief":
			e["kind"] = "robbed"
			e["amount"] = mini(int(money * THEFT_SHARE), THEFT_CAP)
			money -= e["amount"]
			g["loot"] += e["amount"]
		"spy":
			e["kind"] = "spied"
			g["spied"].append(t["id"])
	g["event"] = e
	events.append(e)

## Back in the crowd; press its luck for another round, or head for the gate.
func _hide(g: Dictionary) -> void:
	var c: int = g["crimes"]
	if c <= STAY.size() and _rng.randf() < STAY[c - 1]:
		_pick(g)
	else:
		_leave(g)

## Repair a wrecked building now for REPAIR_SHARE of its cost. False if not wrecked or too poor.
func repair(origin: Vector2i) -> bool:
	if not closed.has(origin):
		return false
	var cost := repair_cost(origin)
	if money < cost:
		return false
	money -= cost
	closed.erase(origin)
	return true

func repair_cost(origin: Vector2i) -> int:
	for t in _targets:
		if t["origin"] == origin:
			return int(Buildings.get_def(t["id"])["cost"] * REPAIR_SHARE)
	return 0

## Pin states for a building: wrecked, littered (litter within 1 tile of the footprint), robbed (last 20 s).
func building_status(origin: Vector2i) -> Array[String]:
	var out: Array[String] = []
	if closed.has(origin):
		out.append("wrecked")
	for t in _targets:
		if t["origin"] != origin:
			continue
		for c: Vector2i in t["cells"]:
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					if litter.has(c + Vector2i(dx, dy)) and not "littered" in out:
						out.append("littered")
	for e: Dictionary in events:
		if e["kind"] == "robbed" and e["origin"] == origin and tick - e["tick"] < ROBBED_TICKS:
			out.append("robbed")
			break
	return out

## The host's manual arrest. An actor with crimes is fined; anyone else is a wrongful arrest the host pays for.
## Returns {} for an unknown id, else {wrongful, fine, loot} (plus kind when it was a real catch).
func accuse(person_id: int) -> Dictionary:
	for g in guests:
		if g["id"] != person_id:
			continue
		if g["crimes"] > 0:
			return _arrest(g)
		money -= WRONGFUL_FINE
		arrests.append({"tick": tick, "pos": g["pos"], "guard": -1, "amount": -WRONGFUL_FINE, "wrongful": true})
		if g["sender"] != "":
			ledger[g["sender"]] = ledger.get(g["sender"], 0) + WRONGFUL_FINE
		if g["state"] == "visit":
			_targets[g["target"]]["inside"] -= 1
		_leave(g)
		return {"wrongful": true, "fine": WRONGFUL_FINE, "loot": 0}
	return {}

## Caught with evidence: the sender is fined BASE_FINE × crimes, the loot goes back to the host.
func _arrest(g: Dictionary, guard := -1) -> Dictionary:
	var fine: int = BASE_FINE[g["kind"]] * g["crimes"]
	money += fine + g["loot"]
	arrests.append({"tick": tick, "pos": g["pos"], "guard": guard, "amount": fine + g["loot"], "wrongful": false})
	if g["sender"] != "":
		ledger[g["sender"]] = ledger.get(g["sender"], 0) - fine
		fined[g["sender"]] = fined.get(g["sender"], 0) + fine
	if g["state"] == "visit":
		_targets[g["target"]]["inside"] -= 1
	guests.erase(g)
	return {"wrongful": false, "fine": fine, "loot": g["loot"], "kind": g["kind"]}

## Guards mark strikers within sight as wanted, chase the nearest wanted actor and catch it within 1 tile.
func _step_guard(s: Dictionary) -> void:
	if s.get("pause", 0) > 0:
		s["pause"] -= 1
		return
	var best: Dictionary = {}
	var best_d := INF
	for g in guests:
		var d: float = s["pos"].distance_to(g["pos"])
		if g["state"] == "strike" and d <= GUARD_SIGHT:
			g["wanted"] = true
			g["event"]["witnessed"] = true
		if g["wanted"] and d < best_d:
			best = g
			best_d = d
	if not best.is_empty() and (s["path"].is_empty() or tick % 5 == 0):
		_go(s, best["cell"])
	if _walk(s, GUARD_SPEED) and best.is_empty() and not _paths.is_empty():
		_go(s, _paths[_rng.randi() % _paths.size()])
	if not best.is_empty() and s["pos"].distance_to(best["pos"]) <= 1.0:
		_arrest(best, staff.find(s))
		s["pause"] = CATCH_PAUSE
		s["path"] = []

func _step_staff(s: Dictionary) -> void:
	if s["kind"] == "guard":
		_step_guard(s)
		return
	if not _walk(s, STAFF_SPEED):
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
