extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

## Gate at (0,7), path along y=7, one builder shed per entry in `specs` (its specialties), park level `lv`.
func sim_with(specs: Array, lv := 7) -> ParkSim:
	var m := ParkMap.new()
	m.money = 1 << 20
	m.xp = ParkLevel.THRESHOLDS[lv - 1]
	m.place("zoo_gate", Vector2i(0, 7))
	for x in range(1, 14):
		m.place("path", Vector2i(x, 7))
	for i in specs.size():
		m.place("builder_shed", Vector2i(1 + i, 8))
		for s: String in specs[i]:
			m.toggle_specialty(Vector2i(1 + i, 8), s)
	return ParkSim.new(m, 5)

## Builds `id` at `cell` and steps until it's done (or `limit`); returns the ticks spent working on it.
func work_ticks(sim: ParkSim, id: String, cell: Vector2i, limit := 3000) -> int:
	sim.build(id, cell)
	var worked := 0
	for i in limit:
		if sim.jobs.is_empty():
			break
		sim.step()
		if sim.builders.any(func(b: Dictionary) -> bool: return b["state"] == "work") or sim.jobs.is_empty():
			worked += 1
	return worked

func _init() -> void:
	# the generalist builds normal buildings at 1×, faster ones at 1× too
	ok(work_ticks(sim_with([[]]), "snack_stand", Vector2i(5, 8)) == 200, "generalist: snack stand at 1×")
	ok(work_ticks(sim_with([["water"]]), "snack_stand", Vector2i(5, 8)) == 200, "wrong specialist: 1×")
	ok(work_ticks(sim_with([[]]), "path", Vector2i(5, 6)) == 0, "paths stay instant")
	# faster: 2× with the specialist
	ok(work_ticks(sim_with([["carpenter"]]), "snack_stand", Vector2i(5, 8)) == 100, "carpenter: snack stand at 2×")
	ok(Specialties.speed([], "tree") == 1 and Specialties.speed(["landscaper"], "tree") == 2, "tree: landscaper faster")

	# specialist-only: waits for the specialist, and says so
	var sim := sim_with([[], ["heavy"]])
	sim.build("water_tank", Vector2i(5, 3))
	for i in 200:  # the day ends at DAY_TICKS, and with it the work
		sim.step()
	var j := sim.job_at(Vector2i(5, 3))
	ok(j["builder"] == "" and j["left"] == j["total"], "water tank waits without a Water builder")
	ok(InfoCard.site_line(sim, j).contains("Waiting for a Water specialist"), "the card says who it waits for")
	sim._map.toggle_specialty(Vector2i(1, 8), "water")
	sim.step()
	ok(sim.job_at(Vector2i(5, 3))["builder"] == sim.builder_of(Vector2i(1, 8))["name"], "the new Water specialist takes it")
	var t := 0
	while not sim.jobs.is_empty() and t < 3000:
		sim.step()
		t += 1
	ok(sim.jobs.is_empty(), "water tank gets built")
	for id: String in ["water_tank", "aviary", "fountain", "reinforced"]:
		ok(Specialties.required(id) != "", id + " is specialist-only")

	# the assigner picks the fastest free builder
	sim = sim_with([[], ["carpenter"]])
	sim.build("snack_stand", Vector2i(5, 8))
	sim.step()
	ok(sim.job_at(Vector2i(5, 8))["builder"] == sim.builder_of(Vector2i(2, 8))["name"], "the carpenter gets the stand")

	# slots: one below park level 6, two from 6; locked ones never show
	var m := ParkMap.new()
	m.xp = ParkLevel.THRESHOLDS[4]  # level 5
	var shed := Vector2i(1, 1)
	m.place("builder_shed", shed)
	ok(m.spec_choices(shed).size() == 5, "all five to choose from")
	ok(m.toggle_specialty(shed, "water") and m.spec_choices(shed) == ["water"], "one picked: only it shows")
	ok(not m.toggle_specialty(shed, "heavy") and m.specs(shed) == ["water"], "no second slot below level 6")
	m.xp = ParkLevel.THRESHOLDS[5]  # level 6
	ok(m.spec_choices(shed).size() == 5, "level 6: a second slot opens")
	ok(m.toggle_specialty(shed, "heavy") and m.specs(shed) == ["water", "heavy"], "second specialty picked")
	ok(not m.toggle_specialty(shed, "aviary") and m.spec_choices(shed) == ["water", "heavy"], "no third")
	ok(m.toggle_specialty(shed, "water") and m.specs(shed) == ["heavy"], "picking again drops it")
	m.remove_at(shed)
	ok(m.specs(shed).is_empty(), "demolished shed forgets its specialties")

	# themes bring their own specialties: Projection only in cinema
	m.place("builder_shed", shed)
	ok(not "projection" in m.spec_choices(shed), "zoo: no Projection")
	Buildings.use("cinema")
	ok(m.spec_choices(shed) == ["landscaper", "water", "carpenter", "projection"], "cinema: shared + Projection")
	ok(m.toggle_specialty(shed, "projection"), "pick Projection")
	ok(Specialties.required("cin_big") == "projection", "Big Screen needs Projection")
	ok(Specialties.speed([], "cin_big") == 0 and Specialties.speed(["projection"], "cin_big") == 1, "Big Screen: specialist-only")
	ok(Specialties.speed([], "cin_room") == 1 and Specialties.speed(["projection"], "cin_room") == 2, "Screen Room: faster")
	Buildings.use("festival")
	ok(m.spec_choices(shed).has("projection"), "a picked specialty still shows after a theme swap")
	ok(not m.toggle_specialty(shed, "aviary"), "festival: no Aviary to pick")
	Buildings.use("zoo")
	done()
