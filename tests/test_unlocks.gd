extends SceneTree
# Park-level gates (ParkLevel.UNLOCKS): fence styles, animals, size variants open at their level, closed before.
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func at(map: ParkMap, lv: int) -> ParkMap:
	map.xp = ParkLevel.THRESHOLDS[lv - 1]
	return map

func _init() -> void:
	Buildings.active = "zoo"
	var map := ParkMap.new()
	map.money = 1 << 20
	var gates := {"habitat": 1, "habitat_glass": 2, "habitat_wall": 3, "habitat_net": 4,
		"snack_stand": 1, "hotdog_stand": 2, "burger_diner": 4, "pond": 1}
	for id: String in gates:
		var lv: int = gates[id]
		ok(ParkLevel.building_opens(id) == lv, "%s opens at %d" % [id, lv])
		if lv > 1:
			ok(at(map, lv - 1).opens_at(id) == lv and not map.can_place(id, Vector2i(5, 5)), "%s closed below %d" % [id, lv])
		ok(at(map, lv).opens_at(id) == 0, "%s open at %d" % [id, lv])
	ok(not at(map, 1).can_paint("habitat_glass", Rect2i(5, 5, 2, 2)) and at(map, 2).can_paint("habitat_glass", Rect2i(5, 5, 2, 2)),
		"glass paints from level 2")
	ok(at(map, 1).can_place("snack_stand", Vector2i(5, 5)) and not map.can_place("hotdog_stand", Vector2i(5, 5))
		and at(map, 2).can_place("hotdog_stand", Vector2i(5, 5)), "2×1 places from level 2")

	# animals: one per category from the start, the rest over levels 2–8
	var start := Animals.ALL.keys().filter(func(a: String) -> bool: return ParkLevel.opens("animals", a) == 1)
	var cats := start.map(func(a: String) -> String: return Animals.ALL[a]["category"])
	cats.sort()
	ok(cats == ["birds", "highlands", "water"], "one per category at start")
	for a: String in Animals.ALL:
		var lv := ParkLevel.opens("animals", a)
		ok(lv >= 1 and lv <= 8, "%s opens by level 8" % a)
	var o := at(map, 8).paint("habitat_glass", Rect2i(10, 10, 3, 3))
	ok(at(map, 1).animal_block(o, "capybara") == "Unlocks at park level 2", "capybara locked at 1")
	ok(map.animal_block(o, "otter") == "", "otter open at 1")
	ok(at(map, 2).animal_block(o, "capybara") == "", "capybara open at 2")

	# the level-up card lists them
	ok("Glass habitats" in ParkLevel.describe(2) and "New animal: Capybara" in ParkLevel.describe(2)
		and "Bigger buildings: the 2×1 size" in ParkLevel.describe(2), "level 2 card lines")
	ok("Net habitats" in ParkLevel.describe(4) and "Bigger buildings: the 2×2 size" in ParkLevel.describe(4), "level 4 card lines")
	done()
