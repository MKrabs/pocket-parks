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
		var p := BuildingView.wreck_plan("pond", 1, Vector2i(x, 2))
		ok(p["rubble"].size() >= 3 and p["rubble"].size() <= 5, "3-5 rubble blocks")
		differs = differs or p["rubble"] != BuildingView.wreck_plan("pond", 1, Vector2i(0, 2))["rubble"]
	ok(differs, "other origins break differently")
	ok(BuildingView.wreck_plan("pond", 0, Vector2i.ZERO)["fallen"].is_empty(), "a flat pond has nothing to fall off")
	ok(BuildingView.wreck_plan("pond", 1, Vector2i(5, 1))["gap"] > 0.0, "breaks on a side facing the viewer")
	var v := HabitatView.of("habitat_net", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], Vector2i.ZERO, "all")
	v.wrecked = true
	root.add_child(v)
	await process_frame  # draws the torn dome without errors
	v.free()
	done()
