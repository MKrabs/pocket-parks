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
	ok(Net.broadcasts(PackedStringArray(["192.168.0.177", "127.0.0.1", "10.27.42.112", "172.17.0.1", "8.8.8.8", "fe80::1",
		"192.168.0.5"])) == (["192.168.0.255", "10.27.42.255", "172.17.0.255"] as Array[String]), "directed broadcasts: private only, deduped")
	var live := [{"name": "A", "live": true}, {"name": "B", "live": true}]
	var bots := [{"name": "x"}, {"name": "y"}, {"name": "z"}]
	ok(VisitPanel.merge([], bots).size() == 3, "no friends: three bot parks")
	ok(VisitPanel.merge(live, bots).map(func(o: Dictionary) -> String: return o["name"]) == ["A", "B", "x"], "friends first, bots top up to 3")
	ok(VisitPanel.merge(live + live, bots).size() == 4, "four friends: no bots")
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

	# IP: join by a typed address, no discovery involved
	ok(Net.parse_address("192.168.1.23") == {"ip": "192.168.1.23", "port": Net.GAME_PORT}, "bare ip gets the default port")
	ok(Net.parse_address(" 192.168.1.23:24611 ") == {"ip": "192.168.1.23", "port": 24611}, "ip:port")
	for bad: String in ["", "hello", "192.168.1", "192.168.1.300", "1.2.3.4:", "1.2.3.4:x", "1.2.3.4:70000", "1.2.3.4:1:2"]:
		ok(Net.parse_address(bad).is_empty(), "not an address: '%s'" % bad)
	ok(Net.local_address(PackedStringArray(["127.0.0.1", "172.40.0.2", "172.20.0.5", "10.0.0.7", "192.168.1.40"])) == "192.168.1.40", "prefers 192.168")
	ok(Net.local_address(PackedStringArray(["fe80::1", "172.40.0.2", "172.20.0.5", "10.0.0.7"])) == "10.0.0.7", "then 10.*")
	ok(Net.local_address(PackedStringArray(["172.40.0.2", "172.31.0.5"])) == "172.31.0.5", "then 172.16-31 only")
	ok(Net.local_address(PackedStringArray(["127.0.0.1"])) == "", "no private address")
	var friend := Net.new()
	friend.map = ParkMap.new()
	friend.start()
	var heard := [false]
	friend.joined.connect(func() -> void: heard[0] = true)
	var addr := Net.parse_address("127.0.0.1:%d" % host.port)
	ok(friend.join(addr["ip"], addr["port"]), "typed address opens a socket")
	ok(pump(host, friend, func() -> bool: return heard[0] and friend.visit_map.buildings == map.buildings), "typed address joins and gets the map")
	var gone := [false]
	friend.lost.connect(func() -> void: gone[0] = true)
	ok(friend.join("127.0.0.1", Net.GAME_PORT + 19), "socket opens even with nobody there")
	for i in 1000:  # ~10 s
		friend.poll(0.01)
		if gone[0]:
			break
		OS.delay_msec(10)
	ok(gone[0], "an address that never answers is given up within 10 s")
	friend._exit_tree()
	friend.free()

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
