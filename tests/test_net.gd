extends SceneTree
# NET0: one process, two Nets. Discovery over loopback UDP, then a live visit over ENet on 127.0.0.1.
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

## Poll both nets until `cond` holds (or ~3 s pass).
func pump(a: Net, b: Net, cond: Callable) -> bool:
	for i in 300:
		a.poll(0.01)
		b.poll(0.01)
		if cond.call():
			return true
		OS.delay_msec(10)
	return false

func _init() -> void:
	var map := BotPark.generate("zoo", 5)
	var sim := ParkSim.new(map, 5)
	sim.send("guest", "Mia")
	var host := Net.new()
	host.park_name = "Host Park"
	host.sim = sim
	host.map = map
	var guest := Net.new()
	guest.sim = ParkSim.new(ParkMap.new(), 1)
	guest.map = ParkMap.new()
	host.start()
	guest.start()
	ok(host.port > 0 and guest.port > 0 and host.port != guest.port, "both host: %d %d" % [host.port, guest.port])
	ok(host.udp_port > 0 and guest.udp_port > 0 and host.udp_port != guest.udp_port, "two listeners: %d %d" % [host.udp_port, guest.udp_port])

	host.announce()
	ok(pump(host, guest, func() -> bool: return guest.offers().any(func(o: Dictionary) -> bool: return o["name"] == "Host Park")),
		"a broadcast on one port is heard on another")
	ok(not host.offers().any(func(o: Dictionary) -> bool: return o["name"] == "Host Park"), "a game doesn't list itself")
	var offer: Dictionary = guest.offers().filter(func(o: Dictionary) -> bool: return o["name"] == "Host Park")[0]
	ok(offer["port"] == host.port and offer["live"], "offer carries the host port")

	var changed := [0]
	guest.map_changed.connect(func() -> void: changed[0] += 1)
	ok(guest.join(offer["ip"], offer["port"]), "client socket opens")
	ok(pump(host, guest, func() -> bool: return changed[0] > 0), "map arrives")
	ok(guest.visit_map.buildings == map.buildings, "client has the host's buildings")

	for i in 30:
		sim.step()  # the sent guest enters at the gate and starts walking
	var same := func() -> bool:
		return sim.guests.size() > 0 and guest.visit_sim.guests.size() == sim.guests.size() and guest.visit_sim.guests[0]["pos"] == sim.guests[0]["pos"]
	ok(pump(host, guest, same), "client sees the host's guest")
	var before: Vector2 = guest.visit_sim.guests[0]["pos"]
	for i in 10:
		sim.step()
	ok(pump(host, guest, func() -> bool: return guest.visit_sim.guests[0]["pos"] != before), "client sees the guest move")

	var free := Vector2i(-1, -1)
	for x in IsoGrid.SIZE.x:
		if not map.occupied.has(Vector2i(x, 0)):
			free = Vector2i(x, 0)
	ok(map.place("tree", free), "host plants a tree")
	ok(pump(host, guest, func() -> bool: return guest.visit_map.buildings.has(free)), "a layout change is resent")

	var lost := [false]
	guest.lost.connect(func() -> void: lost[0] = true)
	host._host.close()
	host.port = 0
	ok(pump(host, guest, func() -> bool: return lost[0]), "host going away is noticed")
	ok(guest.visit_sim == null, "mirror dropped")
	guest._exit_tree()
	host._exit_tree()
	host.free()
	guest.free()
	done()
