extends SceneTree
# ./gd shot shots/NET0.png 3 res://tests/show_net.gd: the main scene plus a second "game" (a Net hosting a bot
# festival park) in the same process; the Visit picker lists it under Nearby.
# NET_VISIT=1 ./gd shot shots/NET0-visit.png 6 res://tests/show_net.gd: travels there and watches it live.

func _init() -> void:
	var map := BotPark.generate("festival", 9, "large")
	var sim := ParkSim.new(map, 9)
	sim.hire("guard")
	for i in 12:
		sim.send("guest", "Mia")
	for i in 200:
		sim.step()
	var friend := Net.new()
	friend.park_name = "Otter Lane"
	friend.player = "sam42"
	friend.theme = "festival"
	friend.sim = sim
	friend.map = map
	root.add_child.call_deferred(friend)
	process_frame.connect(sim.step)

	var main: Node = load("res://main.tscn").instantiate()
	main.bots = false
	root.add_child.call_deferred(main)
	await create_timer(1.0).timeout
	main.visit_panel.open(main.offers, main.net.offers())
	if OS.get_environment("NET_VISIT") == "1":
		await create_timer(0.5).timeout
		var o: Dictionary = main.net.offers().filter(func(x: Dictionary) -> bool: return x["player"] == "sam42")[0]
		main.visit_panel._picker.hide()
		main.travel_to(o)
