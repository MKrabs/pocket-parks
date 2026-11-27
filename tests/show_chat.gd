extends SceneTree
# ./gd shot shots/SOC4.png 2 res://tests/show_chat.gd: two characters talking (bubbles) and the chat log.

func _initialize() -> void:
	var main: Node2D = load("res://main.gd").new()
	main.bots = false
	root.add_child.call_deferred(main)
	await main.ready
	var sim: ParkSim = main.sim
	sim.join_avatar("Mia", Palette.CLAY)
	sim.move_avatar("Mia", Vector2i(12, 11))
	main.walk_to(Vector2i(7, 11))
	main.cam.zoom = Vector2.ONE * 2.2
	main.follow = false
	main.cam.position = IsoGrid.project(Vector2(9.5, 10))
	await create_timer(1.5).timeout  # both walk apart first
	main._hear("Mia", Palette.CLAY, "hi! love the pond")
	main.say("thanks, the snack stand is new")
	main._hear("Mia", Palette.CLAY, "I'm sending a friend over, watch your wallet")
	main.say("ha, my guards are ready")
