extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

## The test_park_sim park, with no walk-in crowd so only sent people are inside.
func quiet(seed_value: int, guards := 0) -> ParkSim:
	var m := ParkMap.new()
	m.money = 1 << 30
	m.place("zoo_gate", Vector2i(0, 7))
	for x in range(1, 14):
		m.place("path", Vector2i(x, 7))
	m.place("pond", Vector2i(9, 5))
	m.place("snack_stand", Vector2i(6, 8))
	m.place("enclosure", Vector2i(2, 4))
	m.money = 500
	var sim := ParkSim.new(m, seed_value)
	sim._appeal = 0.0
	for i in guards:
		sim.hire("guard")
	return sim

func find(sim: ParkSim, kind: String) -> Dictionary:
	for g in sim.guests:
		if g["kind"] == kind:
			return g
	return {}

## Steps until cond(sim) holds or the day ends; true if it held.
func until(sim: ParkSim, cond: Callable) -> bool:
	while sim.tick < ParkSim.DAY_TICKS:
		if cond.call(sim):
			return true
		sim.step()
	return cond.call(sim)

func _init() -> void:
	# Hidden until the first strike, exposed exactly while striking.
	var sim := quiet(1)
	sim.send("hooligan", "a")
	var hid := true
	var seen := false
	while sim.tick < ParkSim.DAY_TICKS and sim.events.is_empty():
		sim.step()
		var h := find(sim, "hooligan")
		if not h.is_empty() and sim.events.is_empty():
			seen = true
			hid = hid and h["state"] != "strike" and not h["wanted"]
	ok(seen and hid, "actor looks like a guest before its first strike")
	ok(sim.events.size() == 1 and find(sim, "hooligan")["state"] == "strike", "strike is exposed")

	# A wrecked building reopens after 45 s.
	var e: Dictionary = sim.events[0]
	ok(e["kind"] == "wrecked" and sim.closed.has(e["origin"]), "hooligan wrecks")
	ok("wrecked" in sim.building_status(e["origin"]), "wrecked pin")
	until(sim, func(s: ParkSim) -> bool: return s.tick == e["tick"] + ParkSim.WRECK_TICKS - 1)
	ok(sim.closed.has(e["origin"]), "still closed just before 45 s")
	sim.step()
	ok(not sim.closed.has(e["origin"]), "reopens after 45 s")

	# repair reopens now and costs a quarter of the building.
	sim = quiet(1)
	sim.send("hooligan", "a")
	until(sim, func(s: ParkSim) -> bool: return not s.events.is_empty())
	e = sim.events[0]
	var before := sim.money
	var id: String = sim._targets.filter(func(t: Dictionary) -> bool: return t["origin"] == e["origin"])[0]["id"]
	ok(sim.repair(e["origin"]), "repair a wrecked building")
	ok(not sim.closed.has(e["origin"]) and sim.money == before - int(Buildings.get_def(id)["cost"] * 0.25), "repair reopens now for 25%")
	ok(not sim.repair(e["origin"]), "nothing to repair")

	# Loot reaches the ledger only on leaving.
	sim = quiet(2)
	sim.send("thief", "a")
	var robbed := until(sim, func(s: ParkSim) -> bool: return not s.events.is_empty())
	ok(robbed and sim.events[0]["kind"] == "robbed" and sim.events[0]["amount"] > 0, "thief robs a shop")
	ok("robbed" in sim.building_status(sim.events[0]["origin"]), "robbed pin")
	var early := true
	while sim.tick < ParkSim.DAY_TICKS and not find(sim, "thief").is_empty():
		early = early and sim.ledger.get("a", 0) == 0
		sim.step()
	var loot := 0
	for ev: Dictionary in sim.events:
		loot += ev["amount"]
	ok(early, "no loot in the ledger while the thief is inside")
	ok(find(sim, "thief").is_empty() and sim.ledger["a"] == loot, "loot delivered on leaving (%d)" % loot)

	# Litterbug drops litter next to the building.
	sim = quiet(3)
	sim.send("litterbug", "a")
	until(sim, func(s: ParkSim) -> bool: return not s.events.is_empty())
	ok(sim.events[0]["kind"] == "littered" and sim.events[0]["amount"] >= 2, "litterbug litters")
	ok("littered" in sim.building_status(sim.events[0]["origin"]), "littered pin")

	# Honest guests pay their sender 20% of what they spent.
	var shared := 0
	for s in 20:
		sim = quiet(40 + s)
		for i in 5:
			sim.send("guest", "g")
		until(sim, func(p: ParkSim) -> bool: return p.spawned == 5 and p.guests.is_empty())
		var total := sim.income  # everything these 5 spent
		var owed: int = sim.ledger.get("g", 0)
		ok(sim.money == 500 + total - owed, "the share comes out of the host's takings")
		# each guest's share is floored, so up to 5 short of 20% of the total
		ok(owed <= int(total * 0.2) and owed > int(total * 0.2) - 5, "guests pay their sender 20%% (%s of %s)" % [owed, total])
		shared += owed
	ok(shared > 0, "some guest share paid")

	# Stay or leave follows the chance table: spies bring home one blueprint per crime.
	var reached := [0, 0, 0, 0, 0, 0]  # spies with at least n crimes
	for s in 400:
		sim = quiet(100 + s)
		sim.send("spy", "a")
		until(sim, func(p: ParkSim) -> bool: return p.blueprints.has("a"))
		var n: int = sim.blueprints.get("a", []).size()
		for k in mini(n, 5) + 1:
			reached[k] += 1
	var rates := []
	for k in 4:
		rates.append(reached[k + 2] / float(maxi(reached[k + 1], 1)))
	print("spies reaching n crimes ", reached, " stay rates ", rates)
	for k in 4:
		ok(absf(rates[k] - ParkSim.STAY[k]) < 0.12, "stay chance after %d crimes ~%.2f (%.2f)" % [k + 1, ParkSim.STAY[k], rates[k]])
	ok(reached[1] > 380, "spies strike and get home")

	# Guards catch only witnessed (wanted) actors, never an honest guest.
	var caught := 0
	var bad := 0
	for s in 30:
		sim = quiet(500 + s, 2)
		for k in ["guest", "guest", "guest", "guest"]:
			sim.send(k, "g")
		for k in ["hooligan", "thief", "spy", "litterbug"]:
			sim.send(k, "a")
		var last := {}
		while sim.tick < ParkSim.DAY_TICKS:
			sim.step()
			var now := {}
			for p in sim.guests:
				now[p["id"]] = p
			for pid: int in last:
				var p: Dictionary = last[pid]
				if now.has(pid) or (p["state"] == "leave" and p["path"].is_empty()):
					continue
				caught += 1
				if p["kind"] == "guest" or not p["wanted"] or not p["event"]["witnessed"]:
					bad += 1
			last = now
		ok(sim.ledger.get("g", 0) >= 0, "honest senders never fined")
	print("guard catches %d, bad %d" % [caught, bad])
	ok(caught > 0 and bad == 0, "guards catch only witnessed actors")

	# accuse: a 0-crime actor and an honest guest are wrongful arrests the host pays for.
	for kind in ["thief", "guest"]:
		sim = quiet(6)
		sim.send(kind, "a")
		until(sim, func(p: ParkSim) -> bool: return not find(p, kind).is_empty())
		before = sim.money
		var r := sim.accuse(find(sim, kind)["id"])
		ok(r["wrongful"] and sim.money == before - ParkSim.WRONGFUL_FINE and sim.ledger["a"] == ParkSim.WRONGFUL_FINE, "wrongful arrest of a %s: host pays" % kind)
		ok(find(sim, kind)["state"] == "leave", "the wrongly accused %s leaves" % kind)
	ok(quiet(6).accuse(99).is_empty(), "unknown id")

	# accuse after 2 crimes: base × 2 plus the loot back.
	var fined := false
	for s in 40:
		sim = quiet(700 + s)
		sim.send("thief", "a")
		if not until(sim, func(p: ParkSim) -> bool: return not find(p, "thief").is_empty() and find(p, "thief")["crimes"] == 2):
			continue
		var t := find(sim, "thief")
		before = sim.money
		var r := sim.accuse(t["id"])
		var fine: int = ParkSim.BASE_FINE["thief"] * 2
		ok(not r["wrongful"] and r["fine"] == fine and r["loot"] == t["loot"] and t["loot"] > 0, "fine is base x 2")
		ok(sim.money == before + fine + t["loot"] and sim.ledger["a"] == -fine, "fine and loot go to the host")
		ok(find(sim, "thief").is_empty(), "arrested thief is gone")
		fined = true
		break
	ok(fined, "some thief got to 2 crimes")

	# Events say what and where, never who.
	for ev: Dictionary in sim.events + quiet(1).events:
		var keys := ev.keys()
		keys.sort()
		ok(keys == ["amount", "kind", "origin", "tick", "witnessed"], "event has no actor id")
	done()
