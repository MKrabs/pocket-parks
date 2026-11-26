extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _init() -> void:
	var m := ZooMap.new()
	ok(m.money == 500, "start money")
	ok(m.place("enclosure", Vector2i(2, 2)), "place enclosure")
	ok(m.money == 350, "cost deducted")
	ok(not m.can_place("tree", Vector2i(4, 4)), "overlap refused (far corner)")
	ok(not m.place("pond", Vector2i(1, 1)), "partial overlap refused")
	ok(m.money == 350, "refused place costs nothing")
	ok(not m.can_place("pond", Vector2i(15, 3)), "out of bounds refused")
	ok(not m.can_place("tree", Vector2i(-1, 0)), "negative out of bounds refused")
	ok(m.can_place("pond", Vector2i(14, 14)), "fits in the last corner")
	ok(m.remove_at(Vector2i(4, 3)), "remove by any covered cell")
	ok(m.money == 350 + 75, "half refund")
	ok(m.occupied.is_empty() and m.buildings.is_empty(), "every tile freed")
	ok(not m.remove_at(Vector2i(4, 3)), "remove on empty cell")
	m.money = 10
	ok(not m.place("tree", Vector2i(0, 0)), "too poor refused")
	ok(m.money == 10 and m.occupied.is_empty(), "too poor leaves state alone")
	ok(ZooMap.depth("enclosure", Vector2i(0, 0)) == ZooMap.depth("tree", Vector2i(2, 2)), "depth uses front corner")
	done()
