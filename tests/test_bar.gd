extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

const H := 720.0
const AWAY := Vector2(640, 200)
const EDGE := Vector2(640, H - 10)

func wait(bar: BuildBar, mouse: Vector2, secs: float) -> void:
	for i in int(secs * 60):
		bar.step(1.0 / 60, mouse, H)

func _initialize() -> void:
	var main: Node2D = load("res://main.gd").new()
	main.bots = false
	root.add_child.call_deferred(main)
	await main.ready
	var bar: BuildBar = main.bar
	bar.set_process(false)  # the test moves the mouse
	await process_frame

	wait(bar, AWAY, BuildBar.HIDE_AFTER * 0.5)
	ok(bar.shown, "stays up before the delay")
	wait(bar, AWAY, BuildBar.HIDE_AFTER * 0.6)
	ok(not bar.shown, "hides after the delay with the mouse away")
	await create_timer(Motion.BAR_TIME + 0.1).timeout
	ok(is_equal_approx(bar.offset.y, bar.panel.size.y + BuildBar.MARGIN), "slid down to the handle: %s" % bar.offset.y)

	wait(bar, EDGE, 0.1)
	ok(bar.shown, "shows near the bottom edge")
	wait(bar, EDGE, BuildBar.HIDE_AFTER * 2)
	ok(bar.shown, "stays up while the mouse is near")
	wait(bar, AWAY, BuildBar.HIDE_AFTER * 1.1)
	ok(not bar.shown, "hides again once the mouse leaves")

	var b := InputEventKey.new()
	b.pressed = true
	b.physical_keycode = KEY_B
	main._unhandled_key_input(b)
	ok(bar.shown, "B shows")
	wait(bar, AWAY, BuildBar.HIDE_AFTER * 2)
	ok(bar.shown, "a bar opened with B waits for the mouse")
	main._unhandled_key_input(b)
	ok(not bar.shown, "B hides")

	main._unhandled_key_input(b)
	bar.pin.button_pressed = true
	ok(bar.pinned, "pin button pins")
	wait(bar, EDGE, 0.1)
	wait(bar, AWAY, BuildBar.HIDE_AFTER * 3)
	main._unhandled_key_input(b)
	ok(bar.shown, "pinned never hides")
	bar.pin.button_pressed = false

	bar.pick("snack_stand")
	ok(bar.placing, "picking an item is placing")
	wait(bar, EDGE, 0.1)
	wait(bar, AWAY, BuildBar.HIDE_AFTER * 3)
	main._unhandled_key_input(b)
	ok(bar.shown, "placing never hides")
	bar.clear()
	ok(not bar.placing, "back to Select")
	wait(bar, AWAY, BuildBar.HIDE_AFTER * 1.1)
	ok(not bar.shown, "hides once placing ends")

	var d: Dictionary = {}
	bar.pinned = true
	main.save_path = "user://test_bar_%d.json" % OS.get_process_id()
	main.save()
	d = SaveGame.read(main.save_path)
	DirAccess.remove_absolute(main.save_path)
	main.save_path = ""
	ok(d.get("bar_pinned") == true, "pin state is saved")
	done()
