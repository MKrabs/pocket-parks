extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _init() -> void:
	var rng := RandomNumberGenerator.new()
	for s in 20:
		rng.seed = s
		var offers := Raid.offers(rng)
		ok(offers.size() == 3, "three targets")
		ok(offers.any(func(o: Dictionary) -> bool: return o["theme"] == "festival"), "at least one festival")
		for o in offers:
			var g: Array = Raid.GUARDS[o["size"]]
			ok(o["guards"] >= g[0] and o["guards"] <= g[1], "guard count fits the size")

	var counts := {"hooligan": 2, "spy": 1}
	ok(Raid.cost(counts) == 140, "squad cost")
	ok(Raid.squad(counts) == (["hooligan", "hooligan", "spy"] as Array[String]), "squad list")

	var o := {"theme": "festival", "seed": 5, "size": "large", "guards": 2}
	var sim := Raid.start(Raid.target(o), o, counts)
	ok(sim.raiding and sim.tick == Raid.WARMUP, "target day warmed up, raid running")
	ok(sim.staff.filter(func(s: Dictionary) -> bool: return s["kind"] == "guard").size() == 2, "guards hired")
	ok(sim.tick + ParkSim.RAID_TICKS <= ParkSim.DAY_TICKS, "raid fits in the target's day")
	while sim.raiding:
		sim.step()
	ok(sim.tick < ParkSim.DAY_TICKS, "raid ended before the day did")

	# A stolen blueprint can be placed in a park of another theme.
	var m := ParkMap.new()
	m.money = 1 << 20
	ok(m.place(Buildings.themes()["festival"].keys()[2], Vector2i(3, 3)), "festival building placeable in the zoo")
	done()
