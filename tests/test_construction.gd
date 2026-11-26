extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

## Gate at (0,7), path along y=7, `sheds` builder sheds below the path (placed instantly, as the start park is).
func sim_with(sheds: int) -> ParkSim:
	var m := ParkMap.new()
	m.money = 1 << 20
	m.xp = ParkLevel.THRESHOLDS[2]  # park level 3: room for 2 sheds
	m.place("zoo_gate", Vector2i(0, 7))
	for x in range(1, 14):
		m.place("path", Vector2i(x, 7))
	for i in sheds:
		m.place("builder_shed", Vector2i(1 + i, 8))
	return ParkSim.new(m, 5)

## Steps until no site is left (or `limit` ticks); returns the ticks it took.
func run(sim: ParkSim, limit := 5000) -> int:
	var n := 0
	while not sim.jobs.is_empty() and n < limit:
		sim.step()
		n += 1
	return n

func targeted(sim: ParkSim, o: Vector2i) -> bool:
	return sim._targets.any(func(t: Dictionary) -> bool: return t["origin"] == o)

func _init() -> void:
	# the table
	ok(ParkSim.build_ticks("path") == 0, "paths are instant")
	ok(ParkSim.build_ticks("tree") == 50, "tree 5 s")
	ok(ParkSim.build_ticks("snack_stand") == 200, "shop 20 s")
	ok(ParkSim.build_ticks("pond") == 400 and ParkSim.build_ticks("enclosure") == 600, "pond 40 s, enclosure 60 s")
	ok(ParkSim.build_ticks("fest_stage") > ParkSim.build_ticks("fest_grill"), "others by size")
	ok(ParkSim.build_ticks("pond", 2) == 600 and ParkSim.build_ticks("pond", 3) == 1000, "upgrades x1.5 / x2.5")

	# no shed: the job waits, money is gone already
	var sim := sim_with(0)
	var before := sim.money
	ok(sim.build("snack_stand", Vector2i(5, 8)), "placed")
	ok(sim.money == before - 60, "paid up front")
	ok(sim.build("path", Vector2i(5, 6)) and sim.job_at(Vector2i(5, 6)).is_empty(), "a path needs no builder")
	for i in 300:
		sim.step()
	ok(sim.job_at(Vector2i(5, 8))["left"] == 200 and sim.job_at(Vector2i(5, 8))["builder"] == "", "waits without a builder")
	ok(not targeted(sim, Vector2i(5, 8)), "site gets no guests")

	# one shed: the builder walks, works exactly the table time, the shop opens
	sim = sim_with(1)
	ok(sim.builders.size() == 1 and sim.builders[0]["name"] == "Bo", "the shed houses Bo")
	sim.build("snack_stand", Vector2i(5, 8))
	var worked := 0
	var walked := 0
	while not sim.jobs.is_empty() and worked + walked < 5000:
		sim.step()
		if sim.builders[0]["state"] == "work" or sim.jobs.is_empty():
			worked += 1
		else:
			walked += 1
	ok(worked == 200, "worked the table time (%d)" % worked)
	ok(walked > 0, "walked to the site first")
	ok(targeted(sim, Vector2i(5, 8)) and Vector2i(5, 8) in sim.finished, "open when done")
	for i in 3 * ParkSim.TPS:
		sim.step()
	ok(sim.builders[0]["state"] == "home", "walks home after")

	# two jobs, one builder: one after the other; two sheds: in parallel
	var one := sim_with(1)
	one.build("snack_stand", Vector2i(5, 8))
	one.build("snack_stand", Vector2i(8, 8))
	var two := sim_with(2)
	two.build("snack_stand", Vector2i(5, 8))
	two.build("snack_stand", Vector2i(8, 8))
	ok(two.builders[1]["name"] != two.builders[0]["name"], "builders have their own names")
	var t1 := run(one)
	var t2 := run(two)
	ok(t1 > 400 and t2 < 300, "two sheds run two jobs in parallel (%d vs %d ticks)" % [t1, t2])

	# a new shed under construction has no builder yet
	sim = sim_with(1)
	sim.build("builder_shed", Vector2i(4, 8))
	ok(sim.builders.size() == 1, "shed site houses nobody")
	run(sim)
	ok(sim.builders.size() == 2, "finished shed brings a builder")

	# sheds are capped by park level
	ok(not sim.build("builder_shed", Vector2i(6, 8)), "a third shed waits for park level 5")
	ok(sim._map.shed_needs("builder_shed") == 5 and BuildBar.shed_text(5) == "More sheds at park level 5", "says which level")
	ok(sim._map.shed_needs("snack_stand") == 0, "other buildings aren't capped")
	sim.xp = ParkLevel.THRESHOLDS[4]
	ok(sim.build("builder_shed", Vector2i(6, 8)), "park level 5 allows a third")
	var fresh := ParkMap.new()
	ok(fresh.place("builder_shed", Vector2i(1, 1)) and not fresh.can_place("builder_shed", Vector2i(3, 3)), "level 1: one shed")

	# upgrade closes and reopens; level only goes up when done
	sim = sim_with(1)
	sim.build("snack_stand", Vector2i(5, 8))
	run(sim)
	var shop := Vector2i(5, 8)
	before = sim.money
	ok(sim.upgrade(shop) and sim.money == before - 60, "upgrade paid up front")
	ok(not sim.upgrade(shop), "one job per building")
	ok(not targeted(sim, shop) and sim._map.level(shop) == 1, "closed while upgrading")
	ok(sim.job_at(shop)["total"] == 300, "upgrade time x1.5")
	run(sim)
	ok(targeted(sim, shop) and sim._map.level(shop) == 2, "reopens at level 2")

	# the site gets no guests during a full day
	sim = sim_with(0)
	sim.build("pond", Vector2i(9, 5))
	sim.build("snack_stand", Vector2i(5, 8))
	for i in ParkSim.DAY_TICKS:
		sim.step()
	ok(not sim.today.has(Vector2i(9, 5)) and not sim.today.has(shop), "no visits to sites")

	# demolish a site: everything back
	sim = sim_with(1)
	before = sim.money
	sim.build("pond", Vector2i(9, 5))
	for i in 20:
		sim.step()
	ok(sim.demolish_refund(Vector2i(9, 5)) == 80, "refund shown is the full price")
	ok(sim.demolish(Vector2i(9, 5)) and sim.money == before and sim.jobs.is_empty(), "demolish refunds everything")
	ok(not sim._map.buildings.has(Vector2i(9, 5)), "site gone")
	done()
