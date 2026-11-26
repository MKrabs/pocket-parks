extends SceneTree
# Staff levels: upgrade costs and wages, guard sight, janitor cleaning speed, no arrests without a crime.
# quiet/find/until copied from tests/test_actors.gd (extending it would run its _init too).

var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

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

func until(sim: ParkSim, cond: Callable) -> bool:
	while sim.tick < ParkSim.DAY_TICKS:
		if cond.call(sim):
			return true
		sim.step()
	return cond.call(sim)

func _init() -> void:
	# Costs and wages.
	var sim := quiet(1, 1)
	sim.hire("janitor")
	var j: Dictionary = sim.staff[0]
	ok(j["level"] == 1 and sim.staff_upgrade_cost(0) == 60, "hired at Lv 1, Lv 2 costs $60")
	var money := sim.money
	ok(sim.upgrade_staff(0) and j["level"] == 2 and sim.money == money - 60, "upgrade pays and levels up")
	ok(sim.upgrade_staff(0) and j["level"] == 3 and sim.staff_upgrade_cost(0) == -1, "Lv 3 is the top")
	ok(not sim.upgrade_staff(0), "no Lv 4")
	sim.money = 10
	ok(not sim.upgrade_staff(1) and sim.staff[1]["level"] == 1 and sim.money == 10, "too poor: nothing happens")
	var wages: Array = ParkSim.STAFF["guard"]["levels"].map(func(l: Dictionary) -> int: return l["wage"])
	ok(wages[0] < wages[1] and wages[1] < wages[2], "wages rise with level")
	while sim.tick < ParkSim.DAY_TICKS:
		sim.step()
	ok(sim.day_report()["wages"] == wages[2] + ParkSim.STAFF["janitor"]["levels"][0]["wage"], "day wages follow each level")
	sim.new_day()
	ok(sim.staff[0]["level"] == 3, "level kept overnight")

	# Sight: a striker 4.5 tiles away is seen by a Lv 3 guard, not a Lv 1 one (same seed).
	for lv in [1, 3]:
		var s := quiet(4)
		s.send("hooligan", "Theo")
		ok(until(s, func(x: ParkSim) -> bool: return not find(x, "hooligan").is_empty() and find(x, "hooligan")["state"] == "strike"), "hooligan strikes")
		var h := find(s, "hooligan")
		s.hire("guard")  # after the strike, so it can't catch it first
		s.staff[0]["level"] = lv
		s.staff[0]["pos"] = h["pos"] + Vector2(4.5, 0)
		s.staff[0]["path"] = []
		s._step_guard(s.staff[0])
		ok(h["wanted"] == (lv == 3), "Lv %d guard at 4.5 tiles: wanted %s" % [lv, h["wanted"]])

	# Spotting: a hidden actor with a past crime, guard kept next to it. Lv 3 notices it, Lv 2 never does.
	for lv in [2, 3]:
		var s := quiet(5, 1)
		s.staff[0]["level"] = lv
		s.send("spy", "Theo")
		until(s, func(x: ParkSim) -> bool: return not find(x, "spy").is_empty())
		var spy := find(s, "spy")
		spy["crimes"] = 1  # struck earlier, now walking in the crowd
		for i in 60 * ParkSim.TPS:  # only the guard acts, so the spy can't strike again in sight
			if spy["wanted"] or not s.arrests.is_empty():
				break
			s.staff[0]["pos"] = spy["pos"] + Vector2(2, 0)
			s.staff[0]["path"] = []
			s._step_guard(s.staff[0])
		ok((spy["wanted"] or not s.arrests.is_empty()) == (lv == 3), "Lv %d guard spots a hidden actor: %s" % [lv, lv == 3])

	# Cleaning: same litter, same seed, the Lv 3 janitor clears more in the same time.
	var left := []
	for lv in [1, 3]:
		var s := quiet(2)
		s.hire("janitor")
		s.staff[0]["level"] = lv
		for x in range(1, 14):
			s.litter[Vector2i(x, 7)] = true
		for i in 100:
			s.step()
		left.append(s.litter.size())
	ok(left[1] < left[0], "Lv 3 janitor cleans faster (%d vs %d spots left)" % [left[1], left[0]])

	# Lv 3 guards kept on top of honest guests and actors all day: only actors with crimes are ever wanted or caught.
	var s := quiet(6, 2)
	for st in s.staff:
		st["level"] = 3
	for k in ["guest", "guest", "guest", "spy", "thief", "hooligan", "guest", "litterbug"]:
		s.send(k, "Theo")
	var bad := 0
	while s.tick < ParkSim.DAY_TICKS:
		for i in s.staff.size():  # stand right on someone
			if s.guests.size() > i:
				s.staff[i]["pos"] = s.guests[i]["pos"]
		s.step()
		for g in s.guests:
			if g["wanted"] and g["crimes"] == 0:
				bad += 1
	for a: Dictionary in s.arrests:
		bad += 1 if a["wrongful"] or a["amount"] <= 0 else 0
	ok(not s.arrests.is_empty() and bad == 0, "guards catch only actors with crimes (%d caught)" % s.arrests.size())
	done()
