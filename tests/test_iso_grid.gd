extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _init() -> void:
	for x in IsoGrid.SIZE.x:
		for y in IsoGrid.SIZE.y:
			var c := Vector2i(x, y)
			ok(IsoGrid.to_cell(IsoGrid.to_screen(c)) == c, "round trip %s" % c)
	ok(IsoGrid.to_screen(Vector2i(1, 0)) == Vector2(32, 16), "x axis goes down-right")
	ok(IsoGrid.to_screen(Vector2i(0, 1)) == Vector2(-32, 16), "y axis goes down-left")
	# just inside the tile edges still maps to the tile
	var c := Vector2i(5, 9)
	var p := IsoGrid.to_screen(c)
	for d in [Vector2(30, 0), Vector2(-30, 0), Vector2(0, 15), Vector2(0, -15)]:
		ok(IsoGrid.to_cell(p + d) == c, "inside edge %s" % d)
	ok(IsoGrid.to_cell(p + Vector2(0, 17)) == Vector2i(6, 10), "past bottom corner")
	ok(IsoGrid.in_bounds(Vector2i(0, 0)) and IsoGrid.in_bounds(Vector2i(15, 15)), "corners in bounds")
	ok(not IsoGrid.in_bounds(Vector2i(16, 0)) and not IsoGrid.in_bounds(Vector2i(0, -1)), "out of bounds")
	ok(not IsoGrid.in_bounds(IsoGrid.to_cell(Vector2(0, -100))), "above board is out of bounds")
	done()
