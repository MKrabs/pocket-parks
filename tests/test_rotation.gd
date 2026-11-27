extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _init() -> void:
	# Footprint: the 3x2 stage turned once covers 2x3 cells from the same origin.
	ok(ParkMap.size("fest_stage", 1) == Vector2i(2, 3) and ParkMap.size("fest_stage", 2) == Vector2i(3, 2), "size swaps on odd turns")
	var m := ParkMap.new()
	m.money = 1 << 30
	ok(m.place("fest_stage", Vector2i(2, 2), 1), "place turned stage")
	ok(m.occupied.has(Vector2i(3, 4)) and not m.occupied.has(Vector2i(4, 2)), "turned stage covers 2x3, not 3x2")
	ok(m.occupied.size() == 6 and m.rotation(Vector2i(2, 2)) == 1, "6 cells, rotation stored")
	ok(ParkMap.depth("fest_stage", Vector2i(2, 2), 1) == 2 + 2 + 2 + 3 - 2, "depth uses turned front corner")
	# can_place: a 3x2 at the bottom edge only fits turned flat.
	var edge := Vector2i(0, IsoGrid.SIZE.y - 2)
	ok(m.can_place("fest_stage", edge, 0) and m.can_place("fest_stage", edge, 2), "flat fits at the edge")
	ok(not m.can_place("fest_stage", edge, 1) and not m.can_place("fest_stage", edge, 3), "upright pokes out of bounds")
	ok(not m.can_place("tree", Vector2i(3, 4)), "turned cells are blocked")
	ok(m.can_place("tree", Vector2i(4, 2)), "unturned cells stay free")
	ok(m.remove_at(Vector2i(3, 4)) and m.occupied.is_empty() and m.rotations.is_empty(), "remove frees turned cells")

	# Sim: gate (0,7), path along y=7. The stage at (5,4) only reaches the path turned upright (y 4..6).
	for turn in 4:
		var p := ParkMap.new()
		p.money = 1 << 30
		p.place("zoo_gate", Vector2i(0, 7))
		for x in range(1, 14):
			p.place("path", Vector2i(x, 7))
		ok(p.place("fest_stage", Vector2i(5, 4), turn), "place stage turn %d" % turn)
		p.money = 500
		var sim := ParkSim.new(p, 7)
		for i in ParkSim.DAY_TICKS:
			sim.step()
		var got: int = sim.today.get(Vector2i(5, 4), {"guests": 0})["guests"]
		ok((got > 0) == (turn % 2 == 1), "turn %d stage guests %d" % [turn, got])

	# Turned parts: every rotation keeps every part, and turn 4 is turn 0.
	for id in ["zoo_gate", "fest_stage", "fest_truck"]:
		var n: int = Buildings.get_def(id)["parts"].size()
		for t in 4:
			ok(BuildingView.turned(id, t).size() == n, "%s turn %d keeps parts" % [id, t])
	var hatch: Array = BuildingView.turned("fest_truck", 1).filter(func(p: Dictionary) -> bool: return p["h"] == 3 and p["z"] == 12)
	ok(hatch.size() == 1 and hatch[0]["at"].is_equal_approx(Vector2(0, 0.36)), "hatch turns clockwise")
	done()
