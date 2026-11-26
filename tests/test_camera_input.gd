extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func wheel(b: MouseButton, f: float, ctrl := false) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = b
	e.factor = f
	e.pressed = true
	e.ctrl_pressed = ctrl
	return e

func _init() -> void:
	var a := IsoCamera.input_action(wheel(MOUSE_BUTTON_WHEEL_DOWN, 0.3), 1.0)
	ok(a.pan.y > 0.0 and a.pan.x == 0.0 and a.zoom == 1.0, "fractional vertical wheel pans, no zoom")
	a = IsoCamera.input_action(wheel(MOUSE_BUTTON_WHEEL_UP, 1.0), 1.0)
	ok(a.zoom > 1.0 and a.pan == Vector2.ZERO, "factor-1 wheel zooms")
	a = IsoCamera.input_action(wheel(MOUSE_BUTTON_WHEEL_UP, 0.0), 1.0)
	ok(a.zoom > 1.0 and a.pan == Vector2.ZERO, "factor-0 wheel zooms")
	a = IsoCamera.input_action(wheel(MOUSE_BUTTON_WHEEL_RIGHT, 1.0), 1.0)
	ok(a.pan.x > 0.0 and a.zoom == 1.0, "horizontal wheel pans")
	a = IsoCamera.input_action(wheel(MOUSE_BUTTON_WHEEL_DOWN, 0.3, true), 1.0)
	ok(a.zoom < 1.0 and a.pan == Vector2.ZERO, "ctrl+fractional wheel zooms")
	var pg := InputEventPanGesture.new()
	pg.delta = Vector2(1, -2)
	a = IsoCamera.input_action(pg, 1.0)
	ok(a.pan.x > 0.0 and a.pan.y < 0.0 and a.zoom == 1.0, "pan gesture pans")
	var near := IsoCamera.input_action(pg, 2.0)
	ok(near.pan.length() < a.pan.length(), "panning smaller when zoomed in")
	var mg := InputEventMagnifyGesture.new()
	mg.factor = 1.2
	ok(is_equal_approx(IsoCamera.input_action(mg, 1.0).zoom, 1.2), "pinch zooms by its factor")
	done()
