class_name SaveGame
extends RefCounted
# Your park on disk (docs/design/game.md → networking: no server). One canonical Dictionary, written as JSON via
# JSON.from_native so Vector2i keys and typed arrays survive. Guests, litter, wrecks and visits are not kept.

const VERSION := 1
const PATH := "user://park.json"
# Top-level keys and their types; a file missing one or with another version is treated as no file.
const KEYS := {"version": TYPE_INT, "theme": TYPE_STRING, "day": TYPE_INT, "stolen": TYPE_ARRAY, "map": TYPE_DICTIONARY,
	"money": TYPE_INT, "xp": TYPE_INT, "tick": TYPE_INT, "staff": TYPE_ARRAY, "jobs": TYPE_ARRAY, "builders": TYPE_ARRAY}

## Everything needed to resume, as plain values (deep copies, so the park can keep running).
## `net` is Net.state(). The sim's ledger is kept so people sent in by visitors settle after a restart.
static func pack(map: ParkMap, sim: ParkSim, day: int, stolen: Array, net := {}) -> Dictionary:
	return {"version": VERSION, "theme": Buildings.active, "day": day, "stolen": stolen.duplicate(), "net": net.duplicate(true),
		"ledger": sim.ledger.duplicate(true), "blueprints": sim.blueprints.duplicate(true), "fined": sim.fined.duplicate(true),
		"charged": sim.charged.duplicate(true), "blacklist": sim.blacklist.duplicate(), "ban_days": sim.ban_days,
		"map": {"buildings": map.buildings, "levels": map.levels, "rotations": map.rotations, "owned": map.owned,
			"bought": map.bought, "specialties": map.specialties, "habitats": map.habitats, "spec_xp": map.spec_xp}.duplicate(true),
		"money": sim.money, "xp": sim.xp, "tick": sim.tick,
		"staff": sim.staff.map(func(s: Dictionary) -> Dictionary: return {"kind": s["kind"], "level": s["level"]}),
		"jobs": sim.jobs.duplicate(true), "builders": sim.builders.duplicate(true)}

## Fill `map` from a packed park and return its sim. Staff start at the gate, builders where they were.
static func restore(d: Dictionary, map: ParkMap) -> ParkSim:
	var m: Dictionary = d["map"]
	map.buildings.clear()
	map.occupied.clear()
	map.levels = m["levels"]
	map.rotations = m["rotations"]
	map.owned = m["owned"]
	map.bought = m["bought"]
	map.specialties = m["specialties"]
	map.habitats = m.get("habitats", {})  # optional: saves from before HAB1 have none
	map.spec_xp = m.get("spec_xp", {})  # saves from before PRG1: every specialty at Lv 1, 0 XP
	for o: Vector2i in m["buildings"]:
		if not Buildings.get_def(m["buildings"][o]).is_empty():  # a building this copy doesn't know is dropped
			map.buildings[o] = m["buildings"][o]
			for c in map.cells(o):
				map.occupied[c] = o
	map.money = d["money"]
	map.xp = d["xp"]
	var sim := ParkSim.new(map, 1)
	sim.tick = d["tick"]
	sim.jobs.assign(d["jobs"])
	sim.builders.assign(d["builders"])
	sim.ledger = d.get("ledger", {})  # optional keys: saves from before NET1 load without them
	sim.blueprints = d.get("blueprints", {})
	sim.fined = d.get("fined", {})
	sim.charged = d.get("charged", {})
	sim.blacklist = d.get("blacklist", {})
	sim.ban_days = int(d.get("ban_days", ParkSim.BAN_DAYS))
	sim.load_map(map)  # sites stay closed, saved builders keep their sheds
	for s: Dictionary in d["staff"]:
		sim.staff.append(sim._walker(s["kind"]))
		sim.staff[-1]["level"] = s["level"]
	return sim

static func to_text(d: Dictionary) -> String:
	return JSON.stringify(JSON.from_native(d))

## The packed park in `text`, or {} if it isn't one of this version (corrupt, old, unknown).
static func from_text(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary or json.data.get("type") != "Dictionary":
		return {}
	var d: Variant = JSON.to_native(json.data)
	if not d is Dictionary:
		return {}
	for k: String in KEYS:
		if typeof(d.get(k)) != KEYS[k]:
			return {}
	if d["version"] != VERSION or not Buildings.themes().has(d["theme"]):
		return {}
	return d

static func write(path: String, d: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(to_text(d))

## The park saved at `path`, or {} (no file, or not a park we can load).
static func read(path: String) -> Dictionary:
	return from_text(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
