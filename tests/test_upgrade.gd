extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

## Gate at (0,7), path along y=7, a pond, a snack stand and a tree touching it.
func park() -> ParkMap:
	var m := ParkMap.new()
	m.money = 1 << 30
	m.xp = ParkLevel.THRESHOLDS[-1]  # every building level unlocked (tests/test_park_level.gd covers the caps)
	m.place("zoo_gate", Vector2i(0, 7))
	for x in range(1, 14):
		m.place("path", Vector2i(x, 7))
	m.place("pond", Vector2i(9, 5))
	m.place("snack_stand", Vector2i(6, 8))
	m.place("tree", Vector2i(12, 8))
	return m

func guests(m: ParkMap) -> int:
	var sim := ParkSim.new(m, 3)
	for i in ParkSim.DAY_TICKS:
		sim.step()
	return sim.day_report()["guests"]

func _init() -> void:
	var m := park()
	var pond := Vector2i(9, 5)
	m.money = 80 + 160 + 5
	ok(m.level(pond) == 1, "placed at level 1")
	ok(m.upgrade(pond) and m.money == 165 and m.level(pond) == 2, "level 2 costs 1x")
	ok(m.upgrade(pond) and m.money == 5 and m.level(pond) == 3, "level 3 costs 2x")
	m.money = 10000
	ok(not m.upgrade(pond) and m.money == 10000 and m.level(pond) == 3, "max level 3")
	ok(m.upgrade_cost(pond) == -1, "no price at max")
	m.money = 59
	ok(not m.upgrade(Vector2i(6, 8)), "too poor is refused")
	ok(m.money == 59 and m.level(Vector2i(6, 8)) == 1, "refusal changes nothing")
	m.money = 0
	ok(m.remove_at(Vector2i(10, 6)), "remove the pond from any of its cells")
	ok(m.money == (80 + 80 + 160) / 2, "refund is half of everything paid")
	ok(m.level(pond) == 1, "level gone with the building")
	m.money = 1000
	ok(not m.upgrade(Vector2i(3, 7)) and not m.upgrade(Vector2i(0, 7)) and m.money == 1000, "path/entrance refuse")
	ok(not m.upgrade(Vector2i(5, 5)), "empty cell refuses")

	ok(Buildings.leveled("pond", 3)["appeal"] == 10 and Buildings.leveled("pond", 2)["capacity"] == 9, "attraction +50%/level")
	ok(Buildings.leveled("snack_stand", 3)["price"] == 10, "shop price +50%/level")
	ok(Buildings.leveled("tree", 2)["appeal"] == 3, "decor appeal +50%/level")

	var base := park()
	var up := park()
	for o in [Vector2i(9, 5), Vector2i(6, 8), Vector2i(12, 8)]:
		up.upgrade(o)
		up.upgrade(o)
	var g1 := guests(base)
	var g3 := guests(up)
	print("guests level 1: %d, level 3: %d" % [g1, g3])
	ok(g3 > g1, "leveled appeal draws more guests")
	done()
