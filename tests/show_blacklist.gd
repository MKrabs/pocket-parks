extends SceneTree
# SOC5 shots. ./gd shot shots/SOC5.png 4 res://tests/show_blacklist.gd: home, Mia's character on the card with the
# ban days, the Blacklist unfolded. SOC5_VISIT=1: visiting a bot park, our character beside a shop, the action row up.

func _initialize() -> void:
	var main: Node2D = load("res://main.gd").new()
	main.bots = false
	main.debug_visit = OS.get_environment("SOC5_VISIT") == "1"
	root.add_child.call_deferred(main)
	await main.ready
	main.follow = false
	if main.debug_visit:
		var vs: ParkSim = main.visits[0]["sim"]
		var door := Vector2i(-1, -1)
		for t in vs._targets:
			if t["role"] == "shop":
				door = t["door"]
		var me := vs.avatar(main.net.player)
		me["cell"] = door
		me["pos"] = Vector2(door)
		main.cam.zoom = Vector2.ONE * 1.6
		main.cam.position = IsoGrid.project(Vector2(door))
		vs.join_avatar("Theo", Palette.CLAY)
		var theo := vs.avatar("Theo")
		theo["cell"] = door + Vector2i(1, 0)
		theo["pos"] = Vector2(door + Vector2i(1, 0))
		theo["strike"] = 1 << 20  # a friend mid-crime: coral tag
		return
	var sim: ParkSim = main.sim
	sim.join_avatar("Mia", Palette.CLAY)
	sim.move_avatar("Mia", Vector2i(10, 11))
	sim.blacklist = {"Theo": 3, "Juno": 1}
	main.hud.blacklist_open = true
	main.card.show_visitor("Mia")
	main.card.days = 5
	main.cam.zoom = Vector2.ONE * 1.4
	main.cam.position = IsoGrid.project(Vector2(9, 10))
