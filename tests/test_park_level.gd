extends SceneTree
# Park level: XP accrues from guests, thresholds, and the unlock caps (building level, sheds, specialties).
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _init() -> void:
	# thresholds
	ok(ParkLevel.of(0) == 1 and ParkLevel.of(29) == 1 and ParkLevel.of(30) == 2, "level 2 at 30 xp")
	ok(ParkLevel.of(ParkLevel.THRESHOLDS[-1]) == 10 and ParkLevel.of(1 << 30) == 10, "level 10 is the top")
	ok(ParkLevel.THRESHOLDS.size() == ParkLevel.MAX, "one threshold per level")
	var t := ParkLevel.THRESHOLDS
	for i in range(2, t.size()):
		ok(t[i] - t[i - 1] > t[i - 1] - t[i - 2], "steps rise at level %d" % (i + 1))
	ok(is_equal_approx(ParkLevel.progress(15), 0.5) and ParkLevel.progress(1 << 30) == 1.0, "ring progress")

	# unlock caps
	ok(ParkLevel.cap("building_level", 1) == 1 and ParkLevel.cap("building_level", 2) == 2
		and ParkLevel.cap("building_level", 3) == 2 and ParkLevel.cap("building_level", 4) == 3, "building level caps")
	var sheds := [1, 1, 2, 2, 3, 3, 4, 4, 4, 4]
	for lv in range(1, 11):
		ok(ParkLevel.cap("sheds", lv) == sheds[lv - 1], "sheds at level %d" % lv)
	ok(ParkLevel.cap("specialties", 5) == 1 and ParkLevel.cap("specialties", 6) == 2, "second specialty at 6")
	ok(ParkLevel.needed("building_level", 3) == 4 and ParkLevel.needed("sheds", 5) == -1, "needed level")
	ok(ParkLevel.describe(4) == ["Buildings up to Lv 3", "Buy up to 2 land plots"] and ParkLevel.describe(9).is_empty(), "card lines")

	# upgrades refused beyond the park's max building level
	var m := ParkMap.new()
	m.money = 1 << 20
	m.place("zoo_gate", Vector2i(0, 7))
	for x in range(1, 14):
		m.place("path", Vector2i(x, 7))
	var pond := Vector2i(9, 5)
	m.place("pond", pond)
	ok(not m.upgrade(pond) and m.upgrade_needs(pond) == 2, "Lv 2 waits for park level 2")
	m.xp = 30
	ok(m.upgrade(pond) and not m.upgrade(pond) and m.upgrade_needs(pond) == 4, "Lv 3 waits for park level 4")
	m.xp = ParkLevel.THRESHOLDS[3]
	ok(m.upgrade(pond) and m.level(pond) == 3, "park level 4 allows Lv 3")

	# XP accrues as guests are served, and is carried by the sim from the map
	m.place("snack_stand", Vector2i(6, 8))
	var sim := ParkSim.new(m, 3)
	ok(sim.xp == m.xp, "sim starts from the map's xp")
	for i in ParkSim.DAY_TICKS:
		sim.step()
	var gained := sim.xp - m.xp
	ok(sim.served > 0 and gained >= sim.served * ParkLevel.XP_SERVED, "xp from served guests: %d for %d" % [gained, sim.served])
	ok(gained <= sim.served * (ParkLevel.XP_SERVED + ParkLevel.XP_HAPPY), "happy bonus at most once per guest")
	sim.new_day()
	ok(sim.xp - m.xp == gained, "xp survives the night")
	done()
