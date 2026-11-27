extends SceneTree
# Habitat decor items: placing is limited to the habitat's free cells, items move the needs shares (comfort),
# removing refunds half, they charm nearby paths, and they survive a save.
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _init() -> void:
	var map := ParkMap.new()
	map.money = 10000
	var o := map.paint("habitat_glass", Rect2i(2, 2, 3, 3))
	ok(o == Vector2i(2, 2), "a 3×3 glass habitat")

	# Limited to the habitat: inside yes, outside or overlapping its edge no, nor on another item.
	ok(map.item_block(o, "pool", Vector2i(2, 2)) == "", "a pool fits inside")
	ok(map.item_block(o, "pool", Vector2i(5, 2)) == "Inside the habitat only", "not outside")
	ok(map.item_block(o, "pool_big", Vector2i(4, 4)) == "Inside the habitat only", "a 2×2 can't hang over the edge")
	ok(map.item_block(o, "rocks_long", Vector2i(4, 2), 1) == "", "turned, the 2×1 ridge fits along the edge")
	ok(map.item_block(o, "rocks_long", Vector2i(4, 2)) != "", "unturned it doesn't")
	ok(map.item_block(Vector2i(9, 9), "tree", Vector2i(9, 9)) != "", "no habitat there")

	# Shares update comfort: an otter (40% water, 10% rocks, a shelter) gets happier with each item.
	map.buy_animal(o, "otter")
	var h: Dictionary = map.habitats[o]
	var c0 := Animals.comfort("otter", h)
	var money := map.money
	ok(map.place_item(o, "pool_big", Vector2i(2, 2)), "place a big pool")
	ok(map.money == money - Animals.ITEMS["pool_big"]["cost"], "it's paid for")
	ok(not map.place_item(o, "tree", Vector2i(3, 3)), "not on the pool")
	ok(is_equal_approx(Animals.terrain(h)["water"], 4.0 / 9.0), "4 of 9 cells are water")
	var c1 := Animals.comfort("otter", h)
	ok(c1 > c0, "water raises comfort (%d → %d)" % [c0, c1])
	ok(map.place_item(o, "waterfall", Vector2i(2, 4)), "a waterfall on the front row")
	ok(map.place_item(o, "shelter", Vector2i(4, 2)), "and a shelter")
	var c2 := Animals.comfort("otter", h)
	ok(c2 == 100 and c2 > c1, "rocks and a shelter: fully comfortable (%d)" % c2)
	ok(Animals.appeal_factor(h) == 2.0, "full comfort, full appeal")

	# Remove refunds half; comfort follows.
	var i := map.item_at(o, Vector2i(4, 2))
	ok(i >= 0 and h["items"][i]["id"] == "shelter", "the shelter is at its cell")
	money = map.money
	ok(map.remove_item(o, i), "remove the shelter")
	ok(map.money == money + Animals.ITEMS["shelter"]["cost"] / 2, "half back")
	ok(map.item_at(o, Vector2i(4, 2)) == -1, "its cell is free again")
	ok(Animals.comfort("otter", h) < c2, "no shelter: less comfort")
	ok(not map.remove_item(o, 9), "no such item")

	# Unpainting cells drops the items on them.
	var big := map.paint("habitat_glass", Rect2i(5, 2, 1, 3))
	ok(big == o, "grow it by a column")
	ok(map.place_item(o, "tree", Vector2i(5, 3)), "a tree in the new column")
	map.unpaint(Rect2i(5, 2, 1, 3))
	ok(map.item_at(o, Vector2i(5, 3)) == -1 and h["items"].size() == 2, "its tree went with the column")

	# Charm: decor items count for nearby paths, and pools count as water.
	map.place("zoo_gate", Vector2i(0, 6))
	for x in range(1, 7):
		map.place("path", Vector2i(x, 6))
	var sim := ParkSim.new(map, 1)
	var with := sim.charm(Vector2i(3, 6))
	h["items"] = []
	sim.load_map(map)
	ok(sim.charm(Vector2i(3, 6)) < with, "items charm nearby paths (%.2f vs %.2f)" % [with, sim.charm(Vector2i(3, 6))])

	# Saved: items come back with their cells.
	map.place_item(o, "pool", Vector2i(3, 3), 0)
	var back := ParkMap.new()
	SaveGame.restore(SaveGame.from_text(SaveGame.to_text(SaveGame.pack(map, ParkSim.new(map, 1), 1, []))), back)
	ok(back.item_at(o, Vector2i(3, 3)) == 0, "items survive a save")
	done()
