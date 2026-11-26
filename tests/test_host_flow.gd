extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func find(sim: ParkSim, kind: String, sender: String) -> Dictionary:
	for g in sim.guests:
		if g["kind"] == kind and g["sender"] == sender:
			return g
	return {}

func _initialize() -> void:
	var main: Node2D = load("res://main.gd").new()
	root.add_child.call_deferred(main)
	await main.ready
	main.hud.speed = 0  # the test drives the clock
	var sim: ParkSim = main.sim
	main.send_group("Mia", ["thief"])
	while sim.tick < ParkSim.DAY_TICKS and not sim.events.any(func(e: Dictionary) -> bool: return e["kind"] == "robbed"):
		main.advance(1)
	var rob: Array = sim.events.filter(func(e: Dictionary) -> bool: return e["kind"] == "robbed")
	ok(not rob.is_empty(), "the thief robs")
	var o: Vector2i = rob[0]["origin"]
	ok(main.toasts.items.size() >= 1, "a toast for the crime")
	var texts: Array = main.toasts.items.map(func(t: Dictionary) -> String: return t["panel"].get_child(0).get_child(1).get_child(0).text)
	ok(texts.any(func(s: String) -> bool: return s.begins_with("Snack Stand was robbed: −$")), "robbed toast text %s" % [texts])
	main.pins._process(0.0)
	ok(main.pins.pins.any(func(p: Dictionary) -> bool: return p["origin"] == o and p["kind"] == "robbed"), "robbed pin")

	var thief := find(sim, "thief", "Mia")
	ok(not thief.is_empty(), "thief still inside")
	var before: int = sim.money
	var r: Dictionary = main.accuse(thief["id"])
	ok(not r["wrongful"] and r["fine"] > 0 and sim.money == before + r["fine"] + r["loot"], "fine raises money")
	ok(main.zoo.map.money == sim.money, "build money follows")
	ok(main.toasts.items[0]["panel"].get_child(0).get_child(1).get_child(0).text.begins_with("Caught a thief: +$"), "caught toast")

	var guest := find(sim, "guest", "")
	while guest.is_empty() or guest["state"] == "visit":
		main.advance(1)
		guest = find(sim, "guest", "")
	before = sim.money
	r = main.accuse(guest["id"])
	ok(r["wrongful"] and sim.money == before - ParkSim.WRONGFUL_FINE, "wrongful arrest costs money")

	# Bot friends send groups on schedule.
	main.advance(main.SEND_EVERY * 2)
	ok(sim.guests.any(func(g: Dictionary) -> bool: return g["sender"] in main.BOTS) or sim.ledger.keys().any(func(k: String) -> bool: return k in main.BOTS), "bots send people")

	# Pick a person by where they are drawn.
	var g: Dictionary = sim.guests.filter(func(p: Dictionary) -> bool: return p["state"] != "visit")[0]
	ok(main.person_at(IsoGrid.project(WalkerView.spot(g)) - Vector2(0, 8)) >= 0, "person_at finds someone")
	ok(main.person_at(Vector2(-5000, -5000)) == -1, "nobody far away")
	done()
