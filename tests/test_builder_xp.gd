extends SceneTree
# Builder XP: finished jobs feed each specialty the builder has; levels 1–3 make it ×1.5 / ×2 / ×3 on its buildings.

var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _init() -> void:
	# thresholds and progress
	ok(Specialties.level(0) == 1 and Specialties.level(9) == 1 and Specialties.level(10) == 2, "Lv 2 at 10 XP")
	ok(Specialties.level(29) == 2 and Specialties.level(30) == 3 and Specialties.level(999) == 3, "Lv 3 at 30 XP, no Lv 4")
	ok(Specialties.progress(0) == 0.0 and Specialties.progress(20) == 0.5 and Specialties.progress(40) == 1.0, "XP bar fill")

	# speed per level, on the specialty's buildings only
	ok(Specialties.speed(["water"], "fountain", {"water": 0}) == 1.5, "Lv 1: ×1.5")
	ok(Specialties.speed(["water"], "fountain", {"water": 10}) == 2.0, "Lv 2: ×2")
	ok(Specialties.speed(["water"], "fountain", {"water": 30}) == 3.0, "Lv 3: ×3")
	ok(Specialties.speed(["water"], "snack_stand", {"water": 30}) == 1.0, "other buildings stay 1×")

	# XP per job: more in the specialty; the second specialty levels separately
	var xp := {}
	ok(Specialties.award(xp, ["water", "carpenter"], "fountain").is_empty(), "first job: no level-up yet")
	ok(xp == {"water": Specialties.XP_SPEC, "carpenter": Specialties.XP_JOB}, "own specialty gets more XP")
	Specialties.award(xp, ["water", "carpenter"], "path")
	ok(xp["water"] == 4 and xp["carpenter"] == 2, "a plain job: a little XP to each")
	var up := []
	for i in 2:
		up = Specialties.award(xp, ["water", "carpenter"], "fountain")
	ok(up == ["water"] and xp["water"] == 10 and Specialties.level(xp["carpenter"]) == 1, "Water hits Lv 2, Carpenter doesn't")
	ok(Specialties.award({}, [], "fountain").is_empty(), "a generalist earns nothing to level")

	# in the sim: a finished job awards XP and reports the level-up
	var m := ParkMap.new()
	m.money = 1 << 20
	m.place("zoo_gate", Vector2i(0, 7))
	for x in range(1, 10):
		m.place("path", Vector2i(x, 7))
	var shed := Vector2i(1, 8)
	m.place("builder_shed", shed)
	m.toggle_specialty(shed, "carpenter")
	m.spec_xp[shed] = {"carpenter": 8}
	var sim := ParkSim.new(m, 5)
	sim.build("snack_stand", Vector2i(5, 8))
	for i in 1000:
		if sim.jobs.is_empty():
			break
		sim.step()
	ok(sim.jobs.is_empty() and m.spec_xp[shed]["carpenter"] == 8 + Specialties.XP_SPEC, "the stand gives Carpenter XP")
	ok(sim.leveled.size() == 1 and sim.leveled[0]["spec"] == "carpenter" and sim.leveled[0]["level"] == 2
		and sim.leveled[0]["shed"] == shed, "the level-up is reported")
	ok(InfoCard.spec_line(m, shed, "carpenter") == "Carpenter Lv 2 · ×2 · 11/30 XP", "the card line")

	# saved; old saves load at Lv 1, 0 XP
	var d := SaveGame.from_text(SaveGame.to_text(SaveGame.pack(m, sim, 1, [])))
	var m2 := ParkMap.new()
	SaveGame.restore(d, m2)
	ok(m2.spec_xp == m.spec_xp, "XP survives a save")
	d["map"].erase("spec_xp")
	var m3 := ParkMap.new()
	SaveGame.restore(d, m3)
	ok(m3.spec_xp.is_empty() and InfoCard.spec_line(m3, shed, "carpenter").begins_with("Carpenter Lv 1"), "old save: Lv 1")
	m.remove_at(shed)
	ok(not m.spec_xp.has(shed), "demolished shed forgets its XP")
	done()
