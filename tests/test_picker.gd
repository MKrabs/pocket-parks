extends SceneTree
# The Visit picker must not grow when opened again (it used to stack old rows until it overflowed).
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)

func _init() -> void:
	var main: Node = load("res://main.tscn").instantiate()
	root.add_child.call_deferred(main)
	await process_frame
	main.open_picker()
	await process_frame
	var h: float = main.visit_panel._picker.size.y
	var rows: int = main.visit_panel._list.get_child_count()
	for i in 4:
		main.open_picker()
		await process_frame
	ok(main.visit_panel._picker.size.y == h, "same height after reopening: %s vs %s" % [main.visit_panel._picker.size.y, h])
	ok(main.visit_panel._list.get_child_count() == rows and rows == 3, "three parks, no duplicates: %d" % main.visit_panel._list.get_child_count())
	main.free()
	quit(1 if failed else 0)
