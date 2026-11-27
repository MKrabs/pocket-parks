extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

## Gate at (0,7), path along y=7 for x in 1..`length`, plus `extra` {cell: id}.
func park(length: int, extra := {}) -> ParkMap:
	var m := ParkMap.new()
	m.money = 1 << 30
	m.place("zoo_gate", Vector2i(0, 7))
	for x in range(1, length + 1):
		m.place("path", Vector2i(x, 7))
	for c: Vector2i in extra:
		m.place(extra[c], c)
	return m

## Every path cell in x 3..7, y 5..9 that isn't already taken (a packed paved square).
func paved() -> Dictionary:
	var out := {}
	for x in range(3, 8):
		for y in range(5, 10):
			if y != 7 and y != 8:
				out[Vector2i(x, y)] = "path"
	return out

## One seeded day: the stroll verdicts seen on arrival and what the stand earned per visit.
func day(m: ParkMap, stand: Vector2i) -> Dictionary:
	var sim := ParkSim.new(m, 3)
	var strolls := {}
	for i in ParkSim.DAY_TICKS:
		sim.step()
		for g in sim.guests:
			if g["state"] != "walk":
				strolls[g["stroll"]] = true
	var d: Dictionary = sim.today.get(stand, {"guests": 0, "income": 0})
	return {"strolls": strolls, "visits": d["guests"], "per_visit": float(d["income"]) / maxi(d["guests"], 1)}

func _init() -> void:
	var cell := Vector2i(5, 7)
	var sim := ParkSim.new(park(10), 1)
	var plain := sim.charm(cell)
	ok(sim.build("tree", Vector2i(5, 8)), "tree placed")
	ok(sim.charm(cell) > plain, "decor raises a tile's charm (%.2f -> %.2f)" % [plain, sim.charm(cell)])
	sim.litter[Vector2i(6, 7)] = true
	var tree := sim.charm(cell)
	sim.litter.clear()
	ok(tree < sim.charm(cell), "litter lowers charm, and the cache notices")
	ok(sim.charm(Vector2i(15, 15)) == 0.0, "no path, no charm")

	var row := {}
	var mix := {}
	var other := ["snack_stand", "fest_truck", "cin_popcorn", "builder_shed"]
	for i in 4:
		row[Vector2i(4 + i, 8)] = "snack_stand"
		mix[Vector2i(4 + i, 8)] = other[i]
	var same := ParkSim.new(park(10, row), 1).charm(cell)
	var varied := ParkSim.new(park(10, mix), 1).charm(cell)
	ok(same < varied, "4 identical stands score lower than 4 different buildings (%.2f < %.2f)" % [same, varied])

	var packed_map := mix.duplicate()
	packed_map.merge(paved())
	var packed := ParkSim.new(park(10, packed_map), 1).charm(cell)
	ok(packed < varied, "a packed area scores lower than one with open grass (%.2f < %.2f)" % [packed, varied])
	ok(packed >= -1.0 and varied <= 1.0, "charm stays in -1..1")

	# Same 12-tile walk to a stand at (13,7): lined with trees and grass, or through a paved square.
	var stand := Vector2i(13, 7)
	var trees := {stand: "snack_stand"}
	var paving := {stand: "snack_stand"}
	for x in range(1, 13):
		trees[Vector2i(x, 5)] = "tree"
		trees[Vector2i(x, 9)] = "tree"
		for y in [5, 6, 8, 9]:
			paving[Vector2i(x, y)] = "path"
	var lovely := day(park(12, trees), stand)
	var dull := day(park(12, paving), stand)
	print("lovely %s, dull %s" % [lovely, dull])
	ok(lovely["visits"] > 0 and dull["visits"] > 0, "guests reach the stand on both routes")
	ok(lovely["strolls"].has("lovely") and not lovely["strolls"].has("dull"), "a long charming route is a lovely stroll")
	ok(dull["strolls"].has("dull") and not dull["strolls"].has("lovely"), "a long paved route is a dull walk")
	ok(lovely["per_visit"] > dull["per_visit"], "a lovely stroll earns more per visit than a dull one")

	var short := day(park(3, {Vector2i(4, 7): "snack_stand", Vector2i(2, 6): "tree", Vector2i(2, 8): "fountain"}), Vector2i(4, 7))
	ok(short["visits"] > 0 and short["strolls"].keys() == [""], "short walks are neutral")

	var g := {"mood": 80.0, "stroll": ""}
	ok(is_equal_approx(sim.spend_factor(g), 1.0), "happy guests pay in full")
	g["stroll"] = "lovely"
	ok(is_equal_approx(sim.spend_factor(g), 1.0 + ParkSim.STROLL_SPEND), "plus the stroll bonus")
	g.merge({"mood": 25.0, "stroll": "dull"}, true)
	ok(sim.spend_factor(g) == 0.0, "unhappy after a dull walk: skips buying")
	done()
