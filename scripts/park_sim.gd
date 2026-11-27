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
# Staff levels: hire price, then per level (index 0 = Lv 1) the upgrade cost to reach it and the day's wage.
# Janitor: speed (tiles/tick), clean (ticks per litter spot), reach (grid tiles it looks for litter in).
# Guard: speed, sight (tiles it witnesses crimes in), catch (tiles), spot (chance per second to notice a hidden
# actor with crimes within sight and mark it wanted).
const STAFF := {
	"janitor": {"hire": 50, "levels": [
		{"cost": 0, "wage": 20, "speed": 0.15, "clean": 15, "reach": 5},
		{"cost": 60, "wage": 28, "speed": 0.2, "clean": 9, "reach": 8},
		{"cost": 120, "wage": 36, "speed": 0.25, "clean": 5, "reach": 12}]},
	"guard": {"hire": 40, "levels": [
		{"cost": 0, "wage": 25, "speed": 0.3, "sight": 3.0, "catch": 1.0, "spot": 0.0},
		{"cost": 60, "wage": 35, "speed": 0.36, "sight": 4.0, "catch": 1.3, "spot": 0.0},
		{"cost": 120, "wage": 45, "speed": 0.42, "sight": 5.0, "catch": 1.6, "spot": 0.1}]},
}
const SHOP_APPEAL := 3  # shops have no appeal in the packs; this weights them as a target
const SHOP_CAPACITY := 2
const VISIT_TICKS := {"attraction": 40, "shop": 15}
const LITTER_CHANCE := 0.3
const QUEUE_GIVE_UP := 100  # ticks
const UNHAPPY := 20.0
# Sending people (docs/design/game.md → Sending people). Bad actors are guests with a kind other than "guest".
const CATCH_PAUSE := 2 * TPS
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
const SEND_BASE := 3  # send limit = SEND_BASE + the sender's park level
# In person (docs/design/game.md → Visiting in person): a character's crimes, by the actor kind whose effect it has.
const CRIMES := {"hooligan": "Wreck", "litterbug": "Litter", "thief": "Steal", "spy": "Spy"}
const BAN_DAYS := 3     # guard catches blacklist for the host's default (ban_days), starting here
const BAN_MAX := 7
# Construction (docs/design/game.md → Building). Seconds by building id, else by role, else 20 s per footprint side.
const BUILD_SECONDS := {"path": 0.0, "entrance": 0.0, "decor": 5.0, "shop": 20.0, "pond": 40.0, "enclosure": 60.0}
const LEVEL_TIME := [1.0, 1.5, 2.5]  # × build time for building level 1 / upgrading to 2 / to 3
const BUILDER_SPEED := 0.15
const AVATAR_SPEED := 0.25  # tiles per tick
const BUILDER_NAMES := ["Bo", "Ada", "Kit", "Nell", "Rio", "Pip", "Sol", "June"]
# Park charm (docs/design/game.md → Park charm): each path tile scores the cells within CHARM_REACH, about -1..1.
const CHARM_REACH := 2
const CHARM_DECOR := 0.04        # + per decor appeal point in view (tree 2, fountain 8) ...
const CHARM_DECOR_MAX := 0.5     #   ... capped
const CHARM_WATER := 0.2         # + any water in view (a building built by the water specialty: fountain, pond, tank)
const CHARM_VARIETY := 0.08      # + per distinct building id in view beyond the first ...
const CHARM_VARIETY_MAX := 0.32  #   ... capped
const CHARM_REPEAT := 0.15       # − per extra copy of the same non-decor id in view ("seen it", anti-spam)
const CHARM_GRASS := 0.2         # + open grass (free cells), full at CHARM_GRASS_FULL of them
const CHARM_GRASS_FULL := 8
const CHARM_PACKED := 0.25       # − packed clutter: fewer than CHARM_PACKED_BELOW free cells in view
const CHARM_PACKED_BELOW := 3
const CHARM_LITTER := 0.12       # − per littered tile in view
const CHARM_WRECKED := 0.3       # − per wrecked building in view
# Strolls: the walk since the last stop, judged on arrival. Spending scales with mood (spend_factor).
const STROLL_MIN := 6            # tiles; shorter walks are neutral
const LOVELY := 0.35             # average charm at or above: a lovely stroll
const DULL := -0.1               # at or below: a dull walk
const STROLL_MOOD := 6.0
const STROLL_SPEND := 0.3        # ± on the purchase at that stop
const SKIP_BELOW := 30.0         # mood under this: often skip buying (always after a dull walk)
const SKIP_CHANCE := 0.5
const FULL_FROM := 70.0          # mood from this: full price; 30..70 ramps from MIN_SPEND to 1
const MIN_SPEND := 0.7

var money: int
var tick := 0
var guests: Array[Dictionary] = []  # walker + mood (0-100), state: walk|queue|visit|strike|leave; sender, spent, crimes, loot, wanted
var staff: Array[Dictionary] = []   # walker + kind, level (1-3); janitors: work (ticks left on a spot)
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
var charged: Dictionary = {}        # sender -> send prices it paid through send_paid (already inside ledger)
var sender_levels: Dictionary = {}  # sender -> its park level, as told in hello and each send
var cash_events: Array = []         # guest payments: {tick, origin (gate or shop), amount}; for the money floats
var arrests: Array = []             # {tick, pos (cell), guard (staff index, -1 = accused), amount, wrongful}
var _gate: Array = []               # [kind, sender] waiting to enter
var jobs: Array[Dictionary] = []     # sites: {origin, id, level (being built), left, total (work ticks), paid, builder ("" = waiting)}
var builders: Array[Dictionary] = [] # one per finished shed: {name, shed (origin), pos (fractional cell), state: home|walk|work}
var finished: Array[Vector2i] = []   # sites done; the view pops them and clears this
var avatars: Array[Dictionary] = []  # player characters, not guests (no spending, mood): {name, color, cell, pos, path}
                                     # + like an actor: sender (= name), kind (worst crime so far), crimes, loot, spied, event, strike (ticks)
var blacklist: Dictionary = {}       # player name -> in-game days left (counts down in new_day)
var ban_days := BAN_DAYS             # the host's default ban for guard catches
var _map: ParkMap

var _rng := RandomNumberGenerator.new()
var _astar := AStarGrid2D.new()
var _entrance := Vector2i(-1, -1)
var _paths: Array[Vector2i] = []
var _targets: Array[Dictionary] = []  # reachable attractions/shops: origin, role, appeal, capacity, price, door, inside
var _decor: Dictionary = {}           # cell -> mood per tick from nearby decor
var _charm: Dictionary = {}           # path cell -> charm; cleared on map change, rebuilt when litter/wrecks change
var _charm_key := 0
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
	for w in guests + staff + avatars:
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
	for n: String in blacklist.keys():
		blacklist[n] -= 1
		if blacklist[n] <= 0:
			blacklist.erase(n)
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
	_charm.clear()
	_appeal = 0.0
	_map = map
	_sync_builders()
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
		if not job_at(origin).is_empty():
			continue  # a site: closed until the builder is done
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

## Charm of path tile `cell` (about -1..1; 0 for anything that isn't a path).
func charm(cell: Vector2i) -> float:
	var key := hash([litter.keys(), closed.keys()])
	if _charm.is_empty() or key != _charm_key:
		_charm_key = key
		for p in _paths:
			_charm[p] = _charm_of(p)
	return _charm.get(cell, 0.0)

func _charm_of(cell: Vector2i) -> float:
	var free := 0
	var seen := {}  # origin -> true, each building in view once
	var c := 0.0
	for dx in range(-CHARM_REACH, CHARM_REACH + 1):
		for dy in range(-CHARM_REACH, CHARM_REACH + 1):
			var k := cell + Vector2i(dx, dy)
			if not IsoGrid.in_bounds(k):
				continue
			if litter.has(k):
				c -= CHARM_LITTER
			if not _map.occupied.has(k):
				free += 1
			else:
				seen[_map.occupied[k]] = true
	var decor := 0.0
	var water := false
	var ids := {}  # building id -> copies in view
	for o: Vector2i in seen:
		var id: String = _map.buildings[o]
		var d := Buildings.leveled(id, _map.level(o))
		if d["role"] == "path" or d["role"] == "entrance":
			continue
		if closed.has(o):
			c -= CHARM_WRECKED
		water = water or d.get("specialty", "") == "water"
		if d["role"] == "decor":
			decor += d["appeal"]
		elif ids.has(id):
			c -= CHARM_REPEAT
		ids[id] = true
	c += minf(decor * CHARM_DECOR, CHARM_DECOR_MAX)
	c += CHARM_WATER if water else 0.0
	c += minf(maxi(ids.size() - 1, 0) * CHARM_VARIETY, CHARM_VARIETY_MAX)
	c += CHARM_GRASS * minf(float(free) / CHARM_GRASS_FULL, 1.0)
	c -= CHARM_PACKED if free < CHARM_PACKED_BELOW else 0.0
	return clampf(c, -1.0, 1.0)

## What share of a price `g` pays at a shop: 0 = skipped. Mood curve, then the stroll bonus.
func spend_factor(g: Dictionary) -> float:
	var stroll: String = g.get("stroll", "")
	if g["mood"] < SKIP_BELOW and (stroll == "dull" or _rng.randf() < SKIP_CHANCE):
		return 0.0
	var f := lerpf(MIN_SPEND, 1.0, clampf((g["mood"] - SKIP_BELOW) / (FULL_FROM - SKIP_BELOW), 0.0, 1.0))
	return f * (1.0 + STROLL_SPEND if stroll == "lovely" else 1.0 - STROLL_SPEND if stroll == "dull" else 1.0)

## The walk since the last stop is over: judge it, then start counting the next one.
func _judge_stroll(g: Dictionary) -> void:
	var avg: float = g["walk_charm"] / g["walk_tiles"] if g["walk_tiles"] > 0 else 0.0
	g["stroll"] = "" if g["walk_tiles"] < STROLL_MIN else "lovely" if avg >= LOVELY else "dull" if avg <= DULL else ""
	g["mood"] += STROLL_MOOD if g["stroll"] == "lovely" else -STROLL_MOOD if g["stroll"] == "dull" else 0.0
	g["walk_tiles"] = 0
	g["walk_charm"] = 0.0

func step() -> void:
	if tick >= DAY_TICKS:
		return
	tick += 1
	for o: Vector2i in closed.keys():
		if closed[o] <= tick:
			closed.erase(o)
	_step_builders()
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
			_wages += stat(s, "wage")
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
	staff[-1]["level"] = 1
	return true

## A staff member's number for its level (see STAFF).
static func stat(s: Dictionary, key: String) -> Variant:
	return STAFF[s["kind"]]["levels"][s["level"] - 1][key]

## Price of staff member i's next level, or -1 at the top.
func staff_upgrade_cost(i: int) -> int:
	var lv: Array = STAFF[staff[i]["kind"]]["levels"]
	return lv[staff[i]["level"]]["cost"] if staff[i]["level"] < lv.size() else -1

## Pay for staff member i's next level. False at the top or too poor.
func upgrade_staff(i: int) -> bool:
	var cost := staff_upgrade_cost(i)
	if cost < 0 or money < cost:
		return false
	money -= cost
	staff[i]["level"] += 1
	return true

func _walker(kind: String) -> Dictionary:
	return {"kind": kind, "cell": _entrance, "pos": Vector2(_entrance), "path": []}

## A person sent by `sender` joins the gate queue and enters like a guest. kind: one of KINDS.
func send(kind: String, sender: String) -> void:
	assert(kind in KINDS, "unknown kind " + kind)
	_gate.append([kind, sender])

## Most people of `sender` inside at once (docs/design/game.md → Send limit), halved while blacklisted here.
func send_limit(sender: String) -> int:
	var n: int = SEND_BASE + sender_levels.get(sender, 1)
	return n / 2 if blacklist.has(sender) else n

## What one `kind` costs `sender`: double while blacklisted here.
func send_cost(sender: String, kind: String) -> int:
	return Visit.PRICES[kind] * (2 if blacklist.has(sender) else 1)

## A send from a remote park at `level`: refused (false, nothing charged) at its limit; otherwise queued and
## charged through the ledger, so the price reaches the sender with its next ledger message.
func send_paid(kind: String, sender: String, level: int) -> bool:
	sender_levels[sender] = level
	var t := sent_by(sender)
	if t["guests"] + t["hidden"] + t["wanted"] >= send_limit(sender):
		return false
	var cost := send_cost(sender, kind)
	ledger[sender] = ledger.get(sender, 0) - cost
	charged[sender] = charged.get(sender, 0) + cost
	send(kind, sender)
	return true

## What `sender` has in this park: guests / hidden (actors not wanted) / wanted, counting the gate queue,
## plus earned (guest share, loot, wrongful-arrest pay, not counting send prices), fines paid and its send limit.
func sent_by(sender: String) -> Dictionary:
	var out := {"guests": 0, "hidden": 0, "wanted": 0, "fines": fined.get(sender, 0), "limit": send_limit(sender),
		"banned": blacklist.get(sender, 0)}
	out["earned"] = ledger.get(sender, 0) + out["fines"] + charged.get(sender, 0)
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
		"sender": sender, "spent": ENTRY_FEE, "crimes": 0, "loot": 0, "spied": [], "wanted": false, "event": {},
		"stroll": "", "walk_tiles": 0, "walk_charm": 0.0})  # stroll: last walk's verdict, "lovely" | "dull" | ""
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

## A player's character enters at the gate (back to the gate if already here). False (and not here) while blacklisted.
func join_avatar(name: String, color: Color, label := "") -> bool:
	leave_avatar(name)
	if blacklist.has(name):
		return false
	avatars.append({"name": name, "label": label if label != "" else name, "color": color, "cell": _entrance, "pos": Vector2(_entrance), "path": [],
		"sender": name, "kind": "", "crimes": 0, "loot": 0, "spied": [], "event": {}, "strike": 0})
	return true

## The character leaves the park (Back home, disconnect); what it carries is delivered.
func leave_avatar(name: String) -> void:
	var a := avatar(name)
	if not a.is_empty():
		_settle_avatar(a)
		avatars.erase(a)

func avatar(name: String) -> Dictionary:
	for a in avatars:
		if a["name"] == name:
			return a
	return {}

## Walk `name`'s character along the paths to `cell`. False if it isn't here, is striking, or the cell isn't walkable.
func move_avatar(name: String, cell: Vector2i) -> bool:
	var a := avatar(name)
	if a.is_empty() or a.get("strike", 0) > 0 or not _astar.is_in_boundsv(cell) or _astar.is_point_solid(cell):
		return false
	_go(a, cell)
	return true

## One tick of every character's walk. Separate from step() so they walk while the day is paused or over.
## A character at the gate hands over what it carries (loot is delivered when you leave through the gate).
func step_avatars() -> void:
	for a in avatars:
		_walk(a, AVATAR_SPEED)
		a["strike"] = maxi(a.get("strike", 0) - 1, 0)
		if a["cell"] == _entrance:
			_settle_avatar(a)

func _settle_avatar(a: Dictionary) -> void:
	if a.get("loot", 0) > 0 or not a.get("spied", []).is_empty():
		_settle(a)
		a["loot"] = 0
		a["spied"] = []

## The open attraction or shop right beside `cell`, or {}.
func _beside(cell: Vector2i) -> Dictionary:
	for t in _targets:
		if closed.has(t["origin"]):
			continue
		for c: Vector2i in t["cells"]:
			if absi(c.x - cell.x) + absi(c.y - cell.y) == 1:
				return t
	return {}

## Crimes (CRIMES keys) `name`'s character can do where it stands; [] while walking or striking, or nowhere near.
func crimes_for(name: String) -> Array:
	var a := avatar(name)
	if a.is_empty() or not a["path"].is_empty() or a.get("strike", 0) > 0:
		return []
	var t := _beside(a["cell"])
	if t.is_empty():
		return []
	return CRIMES.keys().filter(func(k: String) -> bool: return k != "thief" or t["role"] == "shop")

## `name`'s character does `kind` at the building beside it, exposed for STRIKE_TICKS. False if it can't here.
func avatar_strike(name: String, kind: String) -> bool:
	if not kind in crimes_for(name):
		return false
	var a := avatar(name)
	a["strike"] = STRIKE_TICKS
	_crime(a, kind, _beside(a["cell"]))
	return true

## The host accuses a visitor's character: after a crime it's caught, fined and blacklisted for `days` (1–BAN_MAX);
## with no crime it's a wrongful accusation the host pays for, and nobody is banned. {} if it isn't here.
func accuse_avatar(name: String, days: int) -> Dictionary:
	var a := avatar(name)
	if a.is_empty():
		return {}
	return _ban(a, days) if a["crimes"] > 0 else _wrongful(a)

## Caught fair and square: fined like an actor, loot back, out of the park and blacklisted.
func _ban(a: Dictionary, days: int, guard := -1) -> Dictionary:
	var r := _arrest(a, guard)
	blacklist[a["name"]] = clampi(days, 1, BAN_MAX)
	r["days"] = blacklist[a["name"]]
	return r

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
			var from: Vector2i = g["cell"]
			var there := _walk(g, GUEST_SPEED)
			if g["cell"] != from:  # GUEST_SPEED < 1: at most one new tile per tick
				g["walk_tiles"] += 1
				g["walk_charm"] += charm(g["cell"])
			if there:
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
	_judge_stroll(g)
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
	var paid := 0
	if t["role"] == "shop":
		paid = roundi(t["price"] * spend_factor(g))
	if paid > 0:
		money += paid
		income += paid
		cash_events.append({"tick": tick, "origin": t["origin"], "amount": paid})
		g["spent"] += paid
		g["mood"] += 5
		if _rng.randf() < LITTER_CHANCE:
			g["litter_in"] = _rng.randi_range(5, 40)  # dropped a few steps down the path
	elif t["role"] != "shop":
		g["mood"] += t["appeal"] * 1.5
	var d: Dictionary = today.get_or_add(t["origin"], {"guests": 0, "income": 0})
	d["guests"] += 1
	d["income"] += paid
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
	_crime(g, g["kind"], t)

## `who` (an actor or a character) does the crime of actor kind `kind` at target `t`: the effect, the report, the loot.
func _crime(g: Dictionary, kind: String, t: Dictionary) -> void:
	g["crimes"] += 1
	if BASE_FINE[kind] > BASE_FINE.get(g["kind"], 0):
		g["kind"] = kind  # a character is fined at its worst crime's base
	var origin: Vector2i = t["origin"]
	var e := {"tick": tick, "kind": "", "origin": origin, "amount": 0, "witnessed": false}
	match kind:
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
		if g["state"] == "visit":
			_targets[g["target"]]["inside"] -= 1
		_leave(g)
		return _wrongful(g)
	return {}

## The host pays for accusing `g` (a guest or a character) without evidence; its sender gets the money.
func _wrongful(g: Dictionary) -> Dictionary:
	money -= WRONGFUL_FINE
	arrests.append({"tick": tick, "pos": g["pos"], "guard": -1, "amount": -WRONGFUL_FINE, "wrongful": true})
	if g["sender"] != "":
		ledger[g["sender"]] = ledger.get(g["sender"], 0) + WRONGFUL_FINE
	return {"wrongful": true, "fine": WRONGFUL_FINE, "loot": 0}

## Caught with evidence: the sender is fined BASE_FINE × crimes, the loot goes back to the host.
func _arrest(g: Dictionary, guard := -1) -> Dictionary:
	var fine: int = BASE_FINE[g["kind"]] * g["crimes"]
	money += fine + g["loot"]
	arrests.append({"tick": tick, "pos": g["pos"], "guard": guard, "amount": fine + g["loot"], "wrongful": false})
	if g["sender"] != "":
		ledger[g["sender"]] = ledger.get(g["sender"], 0) - fine
		fined[g["sender"]] = fined.get(g["sender"], 0) + fine
	if g.get("state") == "visit":
		_targets[g["target"]]["inside"] -= 1
	guests.erase(g)
	avatars.erase(g)
	return {"wrongful": false, "fine": fine, "loot": g["loot"], "kind": g["kind"]}

## Guards mark strikers within sight as wanted (from Lv 3 they may also notice a hidden actor with crimes),
## chase the nearest wanted actor and catch it within their catch radius. Nobody without a crime is ever wanted.
func _step_guard(s: Dictionary) -> void:
	if s.get("pause", 0) > 0:
		s["pause"] -= 1
		return
	var sight: float = stat(s, "sight")
	var spot: float = stat(s, "spot") / TPS
	var best: Dictionary = {}
	var best_d := INF
	for g in guests:
		var d: float = s["pos"].distance_to(g["pos"])
		if g["state"] == "strike" and d <= sight:
			g["wanted"] = true
			g["event"]["witnessed"] = true
		elif spot > 0.0 and g["crimes"] > 0 and not g["wanted"] and d <= sight and _rng.randf() < spot:
			g["wanted"] = true
		if g["wanted"] and d < best_d:
			best = g
			best_d = d
	for a in avatars:  # a character seen striking is caught on the spot and blacklisted for the default days
		if a.get("strike", 0) > 0 and s["pos"].distance_to(a["pos"]) <= sight:
			a["event"]["witnessed"] = true
			_ban(a, ban_days, staff.find(s))
			break
	if not best.is_empty() and (s["path"].is_empty() or tick % 5 == 0):
		_go(s, best["cell"])
	if _walk(s, stat(s, "speed")) and best.is_empty() and not _paths.is_empty():
		_go(s, _paths[_rng.randi() % _paths.size()])
	if not best.is_empty() and s["pos"].distance_to(best["pos"]) <= stat(s, "catch"):
		_arrest(best, staff.find(s))
		s["pause"] = CATCH_PAUSE
		s["path"] = []

## Janitors spend `clean` ticks on a littered spot, then head for the nearest litter within `reach`, else wander.
func _step_staff(s: Dictionary) -> void:
	if s["kind"] == "guard":
		_step_guard(s)
		return
	if s.get("work", 0) > 0:
		s["work"] -= 1
		if s["work"] == 0:
			litter.erase(s["cell"])
		return
	if not _walk(s, stat(s, "speed")):
		return
	if litter.has(s["cell"]):
		s["work"] = stat(s, "clean")
		return
	# ponytail: nearest by grid distance, not walk distance; fine on a 16x16 park
	var best := Vector2i(-1, -1)
	var best_d: int = stat(s, "reach") + 1
	for c: Vector2i in litter:
		var d := absi(c.x - s["cell"].x) + absi(c.y - s["cell"].y)
		if d < best_d:
			best = c
			best_d = d
	if best.x >= 0:
		_go(s, best)
	elif not litter.is_empty() and not _paths.is_empty():
		_go(s, _paths[_rng.randi() % _paths.size()])  # litter somewhere, out of reach: wander to find it

## Work ticks to build `id` (level 1) or to upgrade it to `level`.
static func build_ticks(id: String, level := 1) -> int:
	var d := Buildings.get_def(id)
	var fp: Vector2i = d["footprint"]
	var s: float = BUILD_SECONDS.get(id, BUILD_SECONDS.get(d["role"], 20.0 * sqrt(fp.x * fp.y)))
	return roundi(s * LEVEL_TIME[level - 1] * TPS)

## Place `id` and open a site for it (paid now). Paths and gates are instant. False if it doesn't fit or is too dear.
func build(id: String, cell: Vector2i, rot := 0) -> bool:
	_map.money = money
	_map.xp = xp
	if not _map.place(id, cell, rot):
		return false
	money = _map.money
	var t := build_ticks(id)
	if t > 0:
		jobs.append({"origin": cell, "id": id, "level": 1, "left": t, "total": t, "paid": Buildings.get_def(id)["cost"], "builder": ""})
	load_map(_map)
	return true

## Pay for the next level and close the building until a builder has done it. False if not possible or already a site.
func upgrade(origin: Vector2i) -> bool:
	var cost := _map.upgrade_cost(origin)
	if cost < 0 or money < cost or not job_at(origin).is_empty():
		return false
	money -= cost
	_map.money = money
	var id: String = _map.buildings[origin]
	var lv := _map.level(origin) + 1
	var t := build_ticks(id, lv)
	jobs.append({"origin": origin, "id": id, "level": lv, "left": t, "total": t, "paid": cost, "builder": ""})
	load_map(_map)
	return true

## What demolishing gives back: a site refunds everything it was paid (plus the usual half for a building being upgraded).
func demolish_refund(origin: Vector2i) -> int:
	var j := job_at(origin)
	if j.is_empty():
		return _map.refund(origin)
	return j["paid"] + (_map.refund(origin) if j["level"] > 1 else 0)

func demolish(origin: Vector2i) -> bool:
	if not _map.buildings.has(origin):
		return false
	var back := demolish_refund(origin)
	jobs.erase(job_at(origin))
	_map.money = money
	_map.remove_at(origin, back)
	money = _map.money
	load_map(_map)
	return true

## The site at `origin`, or {}.
func job_at(origin: Vector2i) -> Dictionary:
	for j in jobs:
		if j["origin"] == origin:
			return j
	return {}

## The site `builder` works on, or {}.
func job_of(builder: Dictionary) -> Dictionary:
	for j in jobs:
		if j["builder"] == builder["name"]:
			return j
	return {}

## The builder living in the shed at `origin`, or {}.
func builder_of(shed: Vector2i) -> Dictionary:
	for b in builders:
		if b["shed"] == shed:
			return b
	return {}

## One builder per finished shed: gone sheds take theirs away (its site waits again), new ones get a name.
func _sync_builders() -> void:
	var sheds: Array = _map.buildings.keys().filter(func(o: Vector2i) -> bool:
		return Buildings.get_def(_map.buildings[o])["role"] == "staff" and job_at(o).is_empty())
	builders = builders.filter(func(b: Dictionary) -> bool: return b["shed"] in sheds)
	for o: Vector2i in sheds:
		if builder_of(o).is_empty():
			var used := builders.map(func(b: Dictionary) -> String: return b["name"])
			var free: Array = BUILDER_NAMES.filter(func(n: String) -> bool: return not n in used)
			builders.append({"name": free[0] if not free.is_empty() else "Bo", "shed": o, "pos": _home(o), "state": "home"})
	for j in jobs:
		if j["builder"] != "" and not builders.any(func(b: Dictionary) -> bool: return b["name"] == j["builder"]):
			j["builder"] = ""

func _home(shed: Vector2i) -> Vector2:
	return Vector2(shed) + Vector2(0.55, 0.1)  # just in front of the shed's door side

func _site(j: Dictionary) -> Vector2:
	return Vector2(j["origin"]) + Vector2(_map.size(j["id"], _map.rotation(j["origin"]))) - Vector2(0.4, 0.4)  # front corner

## Work per tick `b` puts into site `j` (Specialties.speed: 0 = not its specialty, 1, or 2).
func speed_on(b: Dictionary, j: Dictionary) -> int:
	return Specialties.speed(_map.specs(b["shed"]), j["id"])

## Waiting sites (oldest first) get the fastest free builder that can build them; builders walk there in a
## straight line, work, then walk home. Specialist-only sites wait for a matching builder.
## ponytail: straight line across grass and buildings; path-finding if builders should look like they use paths.
func _step_builders() -> void:
	for j in jobs:
		if j["builder"] != "" and builders.any(func(b: Dictionary) -> bool: return b["name"] == j["builder"] and speed_on(b, j) == 0):
			j["builder"] = ""  # its builder dropped the specialty this site needs
		if j["builder"] != "":
			continue
		var best := 0
		for b in builders:
			if job_of(b).is_empty() and speed_on(b, j) > best:
				best = speed_on(b, j)
				j["builder"] = b["name"]
	for b in builders:
		var j := job_of(b)
		var to: Vector2 = _home(b["shed"]) if j.is_empty() else _site(j)
		var d: float = b["pos"].distance_to(to)
		if d > BUILDER_SPEED:
			b["pos"] += (to - b["pos"]) / d * BUILDER_SPEED
			b["state"] = "walk"
			continue
		b["pos"] = to
		b["state"] = "home" if j.is_empty() else "work"
		if j.is_empty():
			continue
		j["left"] -= speed_on(b, j)
		if j["left"] <= 0:
			jobs.erase(j)
			if j["level"] > 1:
				_map.levels[j["origin"]] = j["level"]
			finished.append(j["origin"])
			load_map(_map)
