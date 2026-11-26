extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _init() -> void:
	var main: Node = load("res://main.tscn").instantiate()
	root.add_child.call_deferred(main)
	await process_frame
	main.bots = false
	var tr: CloudTransition = main.transition
	var cam: Camera2D = main.cam
	var z0: float = cam.zoom.x

	# Full run, stepped by hand (no frames pass inside the loop): one swap, at full cover.
	var swaps := [0]
	var swap_at := [-1.0]
	var t := [0.0]
	var tw := tr.play(cam, "Somewhere", func() -> void:
		swaps[0] += 1
		swap_at[0] = t[0])
	var min_zoom := z0
	while tr.running() and t[0] < 5.0:
		t[0] += 0.02
		tw.custom_step(0.02)
		min_zoom = minf(min_zoom, cam.zoom.x)
	var covered := Motion.COVER_AT + Motion.COVER_TIME
	ok(swaps[0] == 1, "swap called once: %d" % swaps[0])
	ok(swap_at[0] >= covered and swap_at[0] <= covered + Motion.HOLD_TIME + 0.02, "swap at the hold: %.2f" % swap_at[0])
	ok(absf(min_zoom - z0 * Motion.TRAVEL_ZOOM) < 0.01, "zoomed out to %.3f" % min_zoom)
	ok(absf(cam.zoom.x - z0) < 0.001 and not tr.visible, "ends at normal zoom, hidden")
	ok(t[0] < 1.6, "about 1.2 s: %.2f" % t[0])

	# Skip partway: still exactly one swap, camera back to normal.
	swaps[0] = 0
	tw = tr.play(cam, "Somewhere", func() -> void: swaps[0] += 1)
	tw.custom_step(0.2)
	ok(swaps[0] == 0, "no swap before cover")
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_SPACE
	tr._input(key)
	ok(swaps[0] == 1 and not tr.running(), "skip swaps once and ends")
	ok(absf(cam.zoom.x - z0) < 0.001, "skip ends at normal zoom: %.3f" % cam.zoom.x)

	# travel_to then travel_home straight away: the second skips the first, we end up home.
	main.travel_to({"name": "Clover Fields", "theme": "festival", "seed": 7, "size": "small", "guards": 1})
	ok(not main.visiting, "visit waits for the clouds")
	main.travel_home()
	ok(main.visiting, "starting the trip home finished the trip out")
	tr.skip()
	ok(not main.visiting and main.hud.visible, "back home")

	# Kit helpers end where they should.
	var n := Node2D.new()
	root.add_child(n)
	Motion.pop(n).custom_step(1.0)
	ok(n.scale.is_equal_approx(Vector2.ONE), "pop ends at scale 1")
	Motion.squish(n).custom_step(1.0)
	ok(n.scale.is_equal_approx(Vector2.ONE), "squish returns to scale 1")
	n.position = Vector2(5, 5)
	Motion.shake(n, 8.0).custom_step(1.0)
	ok(n.position.is_equal_approx(Vector2(5, 5)), "shake returns home")
	var flew := [false]
	Motion.fly_to(n, Vector2(50, 0), func() -> void: flew[0] = true).custom_step(1.0)
	ok(flew[0] and n.position.is_equal_approx(Vector2(50, 0)), "fly_to lands and calls back")
	Motion.puff_at(root, Vector2.ZERO, 40.0).custom_step(2.0)
	Motion.vanish(n).custom_step(1.0)
	ok(n.is_queued_for_deletion(), "vanish frees")
	main.free()
	done()
