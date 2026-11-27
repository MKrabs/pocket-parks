extends SceneTree
# SOC2: characters. In-process host + client over ENet on 127.0.0.1; the host's sim owns and walks every avatar.
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

## Poll both nets (and walk the host's avatars) until `cond` holds (or ~5 s pass).
func pump(a: Net, b: Net, cond: Callable) -> bool:
	for i in 500:
		a.sim.step_avatars()
		a.poll(0.01)
		b.poll(0.01)
		if cond.call():
			return true
		OS.delay_msec(10)
	return false

func find(s: ParkSim, name: String) -> Dictionary:
	for a in s.avatars:
		if a["name"] == name:
			return a
	return {}

func _init() -> void:
	var map := BotPark.generate("zoo", 5)
	var sim := ParkSim.new(map, 5)
	var gate: Vector2i = sim._entrance
	var far := gate  # the path tile furthest from the gate
	for c: Vector2i in sim._paths:
		if sim._astar.get_id_path(gate, c).size() > sim._astar.get_id_path(gate, far).size():
			far = c

	# pure sim: enter at the gate, walk on paths only, never a guest
	sim.join_avatar("Ana", Palette.SKY)
	ok(find(sim, "Ana")["cell"] == gate, "a character enters at the gate")
	ok(sim._astar.is_point_solid(Vector2i(0, 0)) and not sim.move_avatar("Ana", Vector2i(0, 0)), "can't walk onto grass")
	ok(not sim.move_avatar("Nobody", far), "no character, no walk")
	ok(sim.move_avatar("Ana", far), "walk to a path tile")
	var off_path := false
	for i in 400:
		sim.step_avatars()
		off_path = off_path or sim._astar.is_point_solid(find(sim, "Ana")["cell"])
	ok(find(sim, "Ana")["cell"] == far and not off_path, "arrives, along paths")
	ok(sim.guests.is_empty() and sim.accuse(0).is_empty(), "a character is no guest")
	sim.join_avatar("Ana", Palette.SKY)
	ok(sim.avatars.size() == 1 and find(sim, "Ana")["cell"] == gate, "joining again: one character, back at the gate")

	# network: the host is the authority
	var host := Net.new()
	host.sim = sim
	host.map = map
	host.start()
	sim.leave_avatar("Ana")
	sim.join_avatar(host.player, Palette.SKY)
	var guest := Net.new()
	guest.sim = ParkSim.new(ParkMap.new(), 1)
	guest.map = ParkMap.new()
	guest.colour = "CLAY"
	guest.start()
	ok(guest.join("127.0.0.1", host.port), "client socket opens")
	ok(pump(host, guest, func() -> bool: return guest.visit_sim != null and guest.visit_sim.avatars.size() == 2),
		"both avatars appear in the client's live state")
	var mine := find(sim, guest.player)
	ok(not mine.is_empty() and mine["cell"] == gate and mine["color"] == Palette.CLAY, "host added the visitor at its gate, in its colour")
	ok(not find(guest.visit_sim, host.player).is_empty(), "the client sees the host's own character")

	ok(guest.move_avatar(far), "client sends a move")
	var seen_walk := [false]
	var arrived := func() -> bool:
		var a := find(guest.visit_sim, guest.player)
		seen_walk[0] = seen_walk[0] or (not a.is_empty() and not a["path"].is_empty())
		off_path = off_path or sim._astar.is_point_solid(find(sim, guest.player)["cell"])
		return not a.is_empty() and a["cell"] == far and a["path"].is_empty()
	ok(pump(host, guest, arrived), "the client sees its avatar arrive")
	ok(seen_walk[0] and not off_path, "it walked there along paths on the host")
	ok(find(sim, host.player)["cell"] == gate, "the host's character stayed put")

	guest.leave()
	ok(pump(host, guest, func() -> bool: return sim.avatars.size() == 1), "disconnect removes the visitor's avatar")
	ok(sim.avatars[0]["name"] == host.player, "the host's character stays")
	guest._exit_tree()
	host._exit_tree()
	host.free()
	guest.free()
	done()
