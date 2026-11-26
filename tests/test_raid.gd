extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

## Gate at (0,7), path along y=7, an enclosure, a pond and a snack stand on it.
func park() -> ParkMap:
	var m := ParkMap.new()
	m.money = 1 << 30
	m.place("zoo_gate", Vector2i(0, 7))
	for x in range(1, 14):
		m.place("path", Vector2i(x, 7))
	m.place("pond", Vector2i(9, 5))
	m.place("snack_stand", Vector2i(6, 8))
	m.place("enclosure", Vector2i(2, 4))
	m.money = 500
	return m

## Warm the day up, raid with `squad`, run until the raid ends.
func raid(seed_value: int, squad: Array[String], guards := 0) -> ParkSim:
	var sim := ParkSim.new(park(), seed_value)
	for i in guards:
		sim.hire("guard")
	for i in 100:
		sim.step()
	sim.start_raid(squad)
	while sim.raiding:
		sim.step()
	return sim

func _init() -> void:
	var h := raid(1, ["hooligan"] as Array[String])
	var hr := h.raid_result()
	ok(hr["wrecked"] >= 1 and not h.closed.is_empty(), "hooligan wrecks something without guards")
	ok(hr["stars"][0], "wreck star")
	ok(h.day_time() <= 10.0 + 60.0 + 0.01, "raid ends by 60 s")
	h.end_raid()
	ok(h.closed.is_empty(), "end_raid reopens everything")

	var caught := 0
	for s in 20:
		if raid(s, ["thief"] as Array[String], 3).raid_result()["stolen_money"] == 0:
			caught += 1
	print("lone thief caught by 3 guards: %d/20" % caught)
	ok(caught > 10, "3 guards usually catch a lone thief")

	var free := raid(2, ["thief"] as Array[String])
	var fr := free.raid_result()
	ok(fr["stolen_money"] > 0 and fr["stars"][1], "unguarded thief escapes with money")

	var spy := raid(3, ["spy"] as Array[String])
	var bp: Array = spy.raid_result()["blueprints"]
	ok(bp.size() == 1 and not Buildings.get_def(bp[0]).is_empty(), "spy brings back a resolvable blueprint")
	ok(bp.size() == 1 and bp[0] == "enclosure", "spy watched the highest-appeal building")

	var lb := ParkSim.new(park(), 4)
	for i in 100:
		lb.step()
	var before := lb.litter.duplicate()
	lb.start_raid(["litterbug", "hooligan", "hooligan"] as Array[String])
	while lb.raiding:
		lb.step()
	var r := lb.raid_result()
	ok(lb.litter.size() > before.size(), "litterbug drops litter")
	ok(r["stars"] == [r["wrecked"] > 0, r["stolen_money"] > 0 or not r["blueprints"].is_empty(), r["end_happiness"] < 50.0], "stars match the result")
	var dropped := lb._raid_litter.keys()
	ok(not dropped.is_empty(), "raid litter tracked")
	lb.end_raid()
	ok(lb.closed.is_empty(), "end_raid reopens all wrecked buildings")
	ok(dropped.all(func(c: Vector2i) -> bool: return not lb.litter.has(c)), "raid litter removed")
	done()
