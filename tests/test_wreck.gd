extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _init() -> void:
	var a := BuildingView.wreck_plan("snack_stand", 0, Vector2i(3, 4))
	ok(a == BuildingView.wreck_plan("snack_stand", 0, Vector2i(3, 4)), "same origin breaks the same way")
	ok(a["fallen"] == [1, 2], "the roof slides off, the body stays")
	ok(a["chips"].has(0), "the body is chipped")
	ok(a["drop"] == 20.0, "the roof drops to the ground")
	var differs := false
	for x in 8:
		var p := BuildingView.wreck_plan("enclosure", 1, Vector2i(x, 2))
		ok(p["rubble"].size() >= 3 and p["rubble"].size() <= 5, "3-5 rubble blocks")
		differs = differs or p["rubble"] != BuildingView.wreck_plan("enclosure", 1, Vector2i(0, 2))["rubble"]
	ok(differs, "other origins break differently")
	ok(BuildingView.wreck_plan("pond", 0, Vector2i.ZERO)["fallen"].is_empty(), "a flat pond has nothing to fall off")
	for id in ["aviary", "reinforced", "water_tank", "enclosure"]:
		for t in 4:
			var parts := BuildingView.turned(id, t)
			var plan := BuildingView.wreck_plan(id, t, Vector2i(5, 1))
			var shaped := range(parts.size()).filter(func(i: int) -> bool: return parts[i].has("kind"))
			ok(not shaped.is_empty(), "%s has shaped parts" % id)
			ok(shaped.all(func(i: int) -> bool: return i not in plan["fallen"] and not plan["chips"].has(i)), "%s turn %d: shaped parts break in place" % [id, t])
			ok(plan["gap"] > 0.0 and plan["gap"] < PI / 2, "%s breaks on a side facing the viewer" % id)
			var sides := parts.filter(func(p: Dictionary) -> bool: return p.has("side")).map(func(p: Dictionary) -> int: return p["side"])
			ok(sides.is_empty() or sides == [-1, 1], "%s turn %d: far ring half before the near one" % [id, t])
	var v := BuildingView.new("aviary")
	v.wrecked = true
	root.add_child(v)
	await process_frame  # draws the torn dome without errors
	v.free()
	done()
