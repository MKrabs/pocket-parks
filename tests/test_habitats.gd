extends SceneTree
# Habitats: painted rectangles with a fence (docs/design/game.md → Habitats and animals, steps 1-2).

var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

## Gate at (0,7), a path along y = 7, one builder shed per entry of `specs` at (1+i, 8).
func park(specs: Array) -> ParkMap:
	var m := ParkMap.new()
	m.money = 1 << 20
	m.xp = ParkLevel.THRESHOLDS[-1]  # room for two sheds and their specialties
	m.place("zoo_gate", Vector2i(0, 7))
	for x in range(1, 16):
		m.place("path", Vector2i(x, 7))
	for i in specs.size():
		m.place("builder_shed", Vector2i(1 + i, 8))
		for s: String in specs[i]:
			m.toggle_specialty(Vector2i(1 + i, 8), s)
	return m

func _init() -> void:
	var m := park([])
	m.money = 1000
	# paint
	var o := m.paint("habitat", Rect2i(4, 3, 3, 3))
	ok(o == Vector2i(4, 3) and m.habitats[o]["cells"].size() == 9, "paint a 3×3")
	ok(m.money == 1000 - 9 * 16, "paid per cell")
	ok(m.habitats[o]["fence"] == "fence" and m.habitats[o]["animal"] == "" and m.habitats[o]["items"].is_empty(), "fence, no animal, no items")
	ok(m.occupied[Vector2i(6, 5)] == o and m.buildings[o] == "habitat", "every cell is covered by it")
	ok(not m.can_place("tree", Vector2i(5, 4)), "no building on a habitat")
	# add: an L shape, from inside and from touching the edge
	ok(m.paint("habitat", Rect2i(6, 0, 1, 4)) == o, "drag from inside adds (L shape)")
	ok(m.paint("habitat", Rect2i(7, 5, 2, 1)) == o, "drag touching the edge adds")
	ok(m.habitats[o]["cells"].size() == 9 + 3 + 2 and m.habitats.size() == 1, "one habitat of 14 cells")
	ok(m.paint_target("habitat_wall", Rect2i(7, 1, 2, 2)) == Vector2i(-2, -2), "another fence can't add to it")
	ok(m.paint("habitat", Rect2i(9, 0, 1, 3)).x < 0, "a new one needs 4+ cells")
	ok(m.paint("habitat", Rect2i(10, 4, 2, 2)) != o and m.habitats.size() == 2, "a separate one")
	ok(m.paint_target("habitat", Rect2i(7, 4, 3, 1)) == Vector2i(-2, -2), "can't bridge two habitats")
	ok(m.paint("habitat", Rect2i(3, 6, 4, 2)).x < 0, "the path isn't free land")
	# remove
	var before := m.money
	ok(not m.unpaint(Rect2i(7, 5, 2, 1)).is_empty() and m.habitats[o]["cells"].size() == 12, "right-drag removes cells")
	ok(m.money == before + 2 * 16 / 2, "half back per cell")
	ok(m.unpaint(Rect2i(4, 4, 3, 1)).is_empty(), "can't cut it in two")
	ok(m.unpaint(Rect2i(10, 4, 1, 1)).is_empty(), "can't drop below 4 cells")
	var moved := m.unpaint(Rect2i(10, 4, 2, 2))
	ok(moved.has(Vector2i(10, 4)) and moved[Vector2i(10, 4)] == Vector2i(-1, -1) and m.habitats.size() == 1, "removing all of it removes it")
	moved = m.unpaint(Rect2i(4, 3, 2, 3))
	ok(moved[o] == Vector2i(6, 0) and m.habitats.has(Vector2i(6, 0)) and m.occupied[Vector2i(6, 5)] == Vector2i(6, 0), "origin moves to the smallest cell")
	ok(ParkMap.connected([Vector2i(0, 0), Vector2i(1, 0)]) and not ParkMap.connected([Vector2i(0, 0), Vector2i(1, 1)]), "diagonal doesn't connect")
	ok(ParkMap.outline(ParkMap.rect_cells(Rect2i(0, 0, 3, 3))).size() == 12, "3×3 outline: 12 sides")
	# ownership
	var mine := ParkMap.new()
	mine.start_small()
	mine.money = 1000
	ok(mine.paint("habitat", Rect2i(3, 4, 2, 2)).x < 0, "not on land you don't own")
	ok(mine.paint("habitat", Rect2i(4, 4, 2, 2)).x >= 0, "on your own land")
	mine.money = 10
	ok(mine.paint("habitat", Rect2i(8, 8, 2, 2)).x < 0, "too poor")

	# a fence job per specialty
	for fence: String in ["habitat", "habitat_glass", "habitat_net", "habitat_wall"]:
		var need := Specialties.required(fence)
		var sim := ParkSim.new(park([[]] if need == "" else [[], [need]]), 3)
		ok(sim.paint(fence, Rect2i(5, 3, 3, 4)), fence + ": painted")
		var j := sim.job_at(Vector2i(5, 3))
		ok(j["total"] == roundi(14 * ParkSim.FENCE_SECONDS * ParkSim.TPS), fence + ": time by outline length")
		sim.step()
		var who := sim.builder_of(Vector2i(2 if need != "" else 1, 8))
		ok(j["builder"] == who["name"], fence + ": the right builder takes it")
		ok(sim._targets.is_empty(), fence + ": closed while fenced")
		for i in 2000:
			if sim.jobs.is_empty():
				break
			sim.step()
		ok(sim.jobs.is_empty(), fence + ": fenced")
	var waits := ParkSim.new(park([[]]), 3)
	waits.paint("habitat_net", Rect2i(5, 3, 2, 2))
	for i in 100:
		waits.step()
	ok(waits.jobs[0]["builder"] == "", "net waits for an Aviary builder")
	waits.paint("habitat_net", Rect2i(7, 3, 1, 2))
	ok(waits.jobs.size() == 1 and waits.jobs[0]["total"] == roundi(10 * ParkSim.FENCE_SECONDS * ParkSim.TPS), "adding extends its site")
	ok(waits.unpaint(Rect2i(5, 3, 3, 2)) and waits.jobs.is_empty(), "removing it drops its site")

	# guests visit from a path tile touching it; appeal from size
	var pm := park([])
	pm.paint("habitat", Rect2i(4, 4, 3, 3))
	var sim := ParkSim.new(pm, 9)
	ok(sim._targets.size() == 1 and sim._targets[0]["appeal"] == 9 and sim._targets[0]["door"].y == 7, "an attraction, appeal by size, door on the path")
	for i in ParkSim.DAY_TICKS / 2:
		sim.step()
	ok(sim.today.get(Vector2i(4, 4), {"guests": 0})["guests"] > 0, "guests visit it")

	# save round trip
	var saved := SaveGame.pack(pm, sim, 2, [])
	var m2 := ParkMap.new()
	var sim2 := SaveGame.restore(SaveGame.from_text(SaveGame.to_text(saved)), m2)
	ok(m2.habitats == pm.habitats and m2.occupied == pm.occupied, "habitats survive the round trip")
	ok(SaveGame.pack(m2, sim2, 2, []) == saved, "and pack the same")
	ok(m2.paint("habitat", Rect2i(7, 4, 1, 3)) == Vector2i(4, 4), "a loaded habitat can grow")
	done()
