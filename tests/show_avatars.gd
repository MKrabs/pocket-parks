extends SceneTree
# ./gd shot shots/SOC2.png 4 res://tests/show_avatars.gd: your character and a visiting friend's, with name tags.

func _initialize() -> void:
	var main: Node2D = load("res://main.gd").new()
	main.bots = false
	root.add_child.call_deferred(main)
	await main.ready
	var sim: ParkSim = main.sim
	sim.join_avatar("Mia", Palette.CLAY)
	sim.move_avatar("Mia", Vector2i(12, 11))
	main.walk_to(Vector2i(8, 11))
	main.cam.zoom = Vector2.ONE * 2.2
	main.follow = false
	main.cam.position = IsoGrid.project(Vector2(8, 10))
