extends SceneTree
# SOC6: send limit = 3 + the sender's park level, people of yours inside one park at once. The host refuses past it
# and charges nothing for a refused send; people leaving free a slot.
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func park() -> ParkSim:
	var m := ParkMap.new()
	m.money = 1 << 30
	m.place("zoo_gate", Vector2i(0, 7))
	for x in range(1, 14):
		m.place("path", Vector2i(x, 7))
	m.place("snack_stand", Vector2i(6, 8))
	var sim := ParkSim.new(m, 3)
	sim._appeal = 0.0
	return sim

func _init() -> void:
	var sim := park()
	ok(sim.send_limit("Carl") == 4, "unknown sender: level 1, limit 4")
	sim.sender_levels["Carl"] = 4
	ok(sim.send_limit("Carl") == 7, "level 4: limit 7")
	sim.sender_levels["Carl"] = 10
	ok(sim.send_limit("Carl") == 13, "level 10: limit 13")

	# The host path: Carl (level 4) said hello, then sends 8 over the wire.
	sim = park()
	var host := Net.new()
	host.sim = sim
	host._names[7] = "Carl"
	host._hear(7, {"t": "hello", "player": "Carl", "level": 4})
	ok(sim.send_limit("Carl") == 7, "hello tells the host Carl's level")
	for i in 8:
		host._hear(7, {"t": "send", "kind": "guest" if i % 2 == 0 else "thief", "level": 4})
	var t := sim.sent_by("Carl")
	ok(VisitPanel.inside(t) == 7 and t["limit"] == 7, "the 8th is refused: %s" % t)
	var cost := 4 * Visit.PRICES["guest"] + 3 * Visit.PRICES["thief"]
	ok(sim.ledger["Carl"] == -cost and sim.charged["Carl"] == cost, "only the 7 are charged: %d" % sim.ledger["Carl"])
	ok(t["earned"] == 0, "prices don't count as earnings")
	ok(not VisitPanel.can_send(t), "the Send panel is full")

	# Someone leaves: a slot opens.
	while sim.tick < ParkSim.DAY_TICKS and VisitPanel.inside(sim.sent_by("Carl")) == 7:
		sim.step()
	ok(VisitPanel.inside(sim.sent_by("Carl")) < 7, "someone left")
	ok(VisitPanel.can_send(sim.sent_by("Carl")), "panel can send again")
	ok(sim.send_paid("guest", "Carl", 4), "a freed slot takes a new send")

	# A level-up (told in the next send) raises the limit.
	while VisitPanel.inside(sim.sent_by("Carl")) < 7:
		sim.send_paid("guest", "Carl", 4)
	ok(not sim.send_paid("guest", "Carl", 4), "full again at level 4")
	ok(sim.send_paid("guest", "Carl", 5), "level 5: an 8th fits")

	# Senders are counted apart.
	ok(sim.send_paid("guest", "Mia", 1), "another sender has its own limit")
	host.free()
	done()
