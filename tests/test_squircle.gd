extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _init() -> void:
	var half := Vector2(20, 10)
	var pts := Squircle.points(Vector2.ZERO, half, 4.0, 32)
	ok(pts.size() == 32, "step count")
	for i in pts.size():
		var p := pts[i]
		ok(absf(p.x) <= half.x + 0.001 and absf(p.y) <= half.y + 0.001, "within half_size")
		# point at angle t mirrors point at angle PI - t across the y axis
		var m := pts[(16 - i + 32) % 32]
		ok(p.is_equal_approx(Vector2(-m.x, m.y)), "symmetric %d" % i)
	# n=2 is an ellipse: (x/a)^2 + (y/b)^2 == 1
	for p in Squircle.points(Vector2.ZERO, half, 2.0, 16):
		ok(is_equal_approx(pow(p.x / half.x, 2) + pow(p.y / half.y, 2), 1.0), "n=2 ellipse")
	# n=4 bulges past the ellipse at the diagonal
	var d := Squircle.points(Vector2.ZERO, Vector2.ONE, 4.0, 8)[1]
	ok(d.x > cos(PI / 4) + 0.05, "n=4 is squarer than a circle")
	ok(Squircle.iso_points(Vector2.ZERO, Vector2.ONE, 4.0, 4)[0].is_equal_approx(Vector2(32, 16)), "iso 2:1 projection")
	ok(Buildings.ids().size() == 6, "6 zoo buildings")
	for id in Buildings.ids():
		var b: Dictionary = Buildings.get_def(id)
		ok(b["cost"] > 0 and b["footprint"].x > 0 and b["footprint"].y > 0, "cost/footprint: " + id)
	done()
