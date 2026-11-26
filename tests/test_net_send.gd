extends SceneTree
# NET1: an in-process host and client. The client sends people over ENet, the host's sim judges them, and the
# ledger comes back: guest share, a thief's loot, a fine; replays and reconnects never pay twice.
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

## The test_actors park: one gate, a path, a pond, a snack stand, an enclosure; no walk-in crowd.
func quiet(seed_value: int) -> Array:
	var m := ParkMap.new()
	m.money = 1 << 30
	m.place("zoo_gate", Vector2i(0, 7))
	for x in range(1, 14):
		m.place("path", Vector2i(x, 7))
	m.place("pond", Vector2i(9, 5))
	m.place("snack_stand", Vector2i(6, 8))
	m.place("enclosure", Vector2i(2, 4))
	m.money = 500
	var sim := ParkSim.new(m, seed_value)
	sim._appeal = 0.0
	return [m, sim]

func mine(sim: ParkSim, who: String) -> Array:
	return sim.guests.filter(func(g: Dictionary) -> bool: return g["sender"] == who)

## Step the host park until nobody `who` sent is inside or queued.
func empty_of(sim: ParkSim, who: String) -> void:
	while sim.tick < ParkSim.DAY_TICKS:
		sim.step()
		var t := sim.sent_by(who)
		if t["guests"] + t["hidden"] + t["wanted"] == 0:
			return

func _init() -> void:
	var park := quiet(2)
	var hsim: ParkSim = park[1]
	var host := Net.new()
	host.player = "Hana"
	host.sim = hsim
	host.map = park[0]
	var client := Net.new()
	client.player = "Carl"
	client.sim = ParkSim.new(ParkMap.new(), 1)
	client.map = ParkMap.new()
	host.start()
	client.start()
	var m0 := client.sim.money

	ok(not client.send_person("guest"), "no sending before connecting")
	ok(client.join("127.0.0.1", host.port), "client socket opens")
	ok(pump(host, client, func() -> bool: return host._names.values() == ["Carl"]), "host learns the visitor's name")

	# Guests: the host's sim runs it under the visitor's name, and its share comes back.
	for i in 4:  # some only see the free attractions; a share needs a snack
		ok(client.send_person("guest"), "send accepted once connected")
	ok(pump(host, client, func() -> bool: return hsim.sent_by("Carl")["guests"] == 4), "host queues Carl's guests")
	ok(pump(host, client, func() -> bool: return client.visit_ledger["guests"] == 4), "client sees its guests inside")
	empty_of(hsim, "Carl")
	var share: int = hsim.ledger.get("Carl", 0)
	ok(share > 0, "guests earned a share (%d)" % share)
	ok(pump(host, client, func() -> bool: return client.sim.money == m0 + share), "share paid: %d vs %d" % [client.sim.money - m0, share])

	# A thief that escapes: its loot reaches the client.
	client.send_person("thief")
	ok(pump(host, client, func() -> bool: return hsim.sent_by("Carl")["hidden"] == 1), "host queues the thief")
	var robbed := hsim.events.size()
	empty_of(hsim, "Carl")
	var loot: int = hsim.ledger["Carl"] - share
	ok(hsim.events.size() > robbed and loot > 0, "thief robbed and left (%d)" % loot)
	ok(pump(host, client, func() -> bool: return client.sim.money == m0 + share + loot), "loot paid")

	# Caught with evidence: the fine comes off the client's money.
	client.send_person("thief")
	ok(pump(host, client, func() -> bool: return hsim.sent_by("Carl")["hidden"] == 1), "second thief queued")
	var t: Dictionary = {}
	while hsim.tick < ParkSim.DAY_TICKS and (t.is_empty() or t["crimes"] == 0):
		hsim.step()
		var ts := mine(hsim, "Carl")
		t = ts[0] if not ts.is_empty() else {}
	ok(not t.is_empty(), "second thief struck")
	var r := hsim.accuse(t["id"])
	ok(not r["wrongful"] and r["fine"] > 0, "host catches it")
	var owed: int = hsim.ledger["Carl"]
	ok(owed == share + loot - r["fine"], "ledger fined")
	ok(pump(host, client, func() -> bool: return client.sim.money == m0 + owed), "fine deducted: %d" % (client.sim.money - m0))

	# Replays never pay twice: the same seq, or an older one, is ignored.
	var last: Dictionary = client.got["Hana"]
	var money := client.sim.money
	client._apply({"t": "ledger", "from": "Hana", "seq": last["seq"], "owed": owed + 500, "blueprints": [], "inside": {}})
	client._apply({"t": "ledger", "from": "Hana", "seq": last["seq"] - 1, "owed": 0, "blueprints": [], "inside": {}})
	ok(client.sim.money == money, "replayed messages ignored")
	client._apply({"t": "ledger", "from": "Hana", "seq": last["seq"] + 1, "owed": owed, "blueprints": [], "inside": client.visit_ledger})
	ok(client.sim.money == money, "a newer message with the same total pays nothing")

	# The visitor leaves; its guest settles in the host park, and is paid on the next visit.
	client.send_person("guest")
	ok(pump(host, client, func() -> bool: return hsim.sent_by("Carl")["guests"] == 1), "third guest queued")
	client.leave()
	ok(pump(host, client, func() -> bool: return host._names.is_empty()), "host notices the visitor left")
	empty_of(hsim, "Carl")
	owed = hsim.ledger["Carl"]
	ok(owed > share + loot - r["fine"], "the guest settled while Carl was away")
	ok(client.sim.money == money, "nothing paid while away")
	client.join("127.0.0.1", host.port)
	ok(pump(host, client, func() -> bool: return client.sim.money == m0 + owed), "paid on reconnect, once")
	for i in 20:
		host.poll(0.01)
		client.poll(0.01)
	ok(client.sim.money == m0 + owed, "and only once")

	# The host keeps the ledger on disk; the visitor keeps its seq and what it got.
	var back := SaveGame.from_text(SaveGame.to_text(SaveGame.pack(park[0], hsim, 1, [], host.state())))
	ok(SaveGame.restore(back, ParkMap.new()).ledger == hsim.ledger and back["net"]["seq"] == host.seq, "host ledger and seq saved")
	var c := Net.new()
	c.load_state(SaveGame.from_text(SaveGame.to_text(SaveGame.pack(client.map, client.sim, 1, [], client.state())))["net"])
	ok(c.player == "Carl" and c.got == client.got, "visitor name and payments saved")
	c.free()

	client._exit_tree()
	host._exit_tree()
	host.free()
	client.free()
	done()
