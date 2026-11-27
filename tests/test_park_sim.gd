extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

## Gate at (0,7), path along y=7, buildings touching the path. `with_path` false leaves the gate cut off.
func park(enclosure: bool, with_path := true) -> ParkMap:
	var m := ParkMap.new()
	m.money = 1 << 30
	m.place("zoo_gate", Vector2i(0, 7))
	for x in range(1 if with_path else 2, 14):
		m.place("path", Vector2i(x, 7))
	m.place("pond", Vector2i(9, 5))
	m.place("snack_stand", Vector2i(6, 8))
	m.place("tree", Vector2i(12, 8))
	if enclosure:
		m.paint("habitat", Rect2i(2, 4, 3, 3))
	m.money = 500
	return m

func run(sim: ParkSim) -> Dictionary:
	var walkable := {}
	for o: Vector2i in sim._paths:
		walkable[o] = true
	walkable[sim._entrance] = true
	var off := 0
	for i in ParkSim.DAY_TICKS:
		sim.step()
		for g in sim.guests:
			if not walkable.has(g["cell"]) or not walkable.has(Vector2i(g["pos"].round())):
				off += 1
	ok(off == 0, "guests stay on path tiles (%d off)" % off)
	return sim.day_report()

func _init() -> void:
	var t0 := Time.get_ticks_usec()
	var big := ParkSim.new(park(true), 7)
	var a := run(big)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	print("park day: %.0f ms, report %s, litter %d" % [ms, a, big.litter.size()])
	ok(ms < 1000.0, "day simulates in under 1 s")
	ok(a["guests"] >= 40, "a decent crowd turns up")
	ok(a["served"] > 0 and a["income"] > a["guests"] * ParkSim.ENTRY_FEE, "guests visit and pay at shops")
	ok(a["happiness"] > 0.0 and a["happiness"] <= 100.0, "happiness in range")
	var paid := 0
	var at_gate := 0
	for c: Dictionary in big.cash_events:
		paid += c["amount"]
		at_gate += 1 if c["origin"] == big._entrance else 0
	ok(paid == a["income"] and at_gate == a["guests"], "cash_events add up to income, one entry fee per guest at the gate")
	ok(big.day_time() == 120.0, "day ends at 120 s")

	ok(run(ParkSim.new(park(true), 7)) == a, "same seed, same report")
	ok(run(ParkSim.new(park(false), 7))["guests"] < a["guests"], "more appeal, more guests")
	var cut := ParkSim.new(park(true, false), 7)
	ok(run(cut)["guests"] == 0, "no path to the entrance, no guests")

	var dirty := ParkSim.new(park(true), 3)
	run(dirty)
	var clean := ParkSim.new(park(true), 3)
	ok(clean.hire("janitor"), "hire janitor")
	ok(clean.money == 500 - ParkSim.STAFF["janitor"]["hire"], "hire cost up front")
	ok(clean.hire("guard"), "hire guard")
	ok(not clean.hire("clown"), "unknown staff refused")
	var r := run(clean)
	print("litter without janitor %d, with %d" % [dirty.litter.size(), clean.litter.size()])
	ok(dirty.litter.size() >= 3 and clean.litter.size() < dirty.litter.size(), "janitor reduces litter")
	ok(r["wages"] == 45, "wages taken at day end")
	ok(clean.closed.is_empty(), "nothing closed yet")

	# Building mid-day: the sim picks up the new map.
	var m := park(false)
	var live := ParkSim.new(m, 5)
	for i in 300:
		live.step()
	var before := live.guests.size()
	m.money = 1 << 30
	m.paint("habitat", Rect2i(2, 4, 3, 3))
	m.remove_at(Vector2i(9, 5))  # the pond goes
	m.remove_at(Vector2i(12, 7))  # path under someone's feet maybe
	live.load_map(m)
	ok(live.guests.size() == before, "guests survive a map change")
	ok(live._targets.size() == 2, "new enclosure is a target, pond is gone (%d)" % live._targets.size())
	var cells := {}
	for o: Vector2i in live._paths:
		cells[o] = true
	cells[live._entrance] = true
	var stuck := 0
	for g in live.guests:
		if not cells.has(g["cell"]):
			stuck += 1
	ok(stuck == 0, "nobody left standing off the path")
	var r2 := run(live)
	ok(r2["served"] > 0, "day goes on after the change")
	live.new_day()
	ok(live.tick == 0 and live.guests.is_empty() and live.litter.is_empty(), "new day resets")
	done()
