extends SceneTree
# Test pattern: extend SceneTree, call ok(cond, msg), finish with done(). ./gd check runs every tests/test_*.gd.
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _init() -> void:
	ok(Palette.shade(Palette.GRASS, 0.2).v < Palette.GRASS.v, "shade darkens")
	for c in [Palette.GRASS, Palette.SAND, Palette.WATER, Palette.CLAY]:
		ok(c.s < 0.45 and c.v > 0.6, "palette stays pastel: %s" % c.to_html())
	done()
