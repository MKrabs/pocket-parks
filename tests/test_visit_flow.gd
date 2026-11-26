extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var offers := Visit.offers(rng)
	ok(offers.size() == 3, "three parks on offer")
	ok(offers[0]["theme"] != offers[1]["theme"] and offers[0]["name"] != offers[1]["name"], "themes mix, names differ")
	for o in offers:
		ok(o["guards"] >= 0 and o["guards"] <= 3, "0-3 guards")
	ok(Visit.open(offers[0])[1].staff.size() == offers[0]["guards"], "guards hired in the visited park")

	var main: Node = load("res://main.tscn").instantiate()
	root.add_child.call_deferred(main)
	await process_frame  # main._ready has run
	main.bots = false  # N3's bot senders would move our money too
	var home: ParkSim = main.sim
	home._appeal = 0.0  # no walk-in crowd at home, so only the visit moves our money
	home.guests.clear()
	var m0: int = home.money

	main.visit({"name": "Test Park", "theme": "zoo", "seed": 11, "size": "small", "guards": 0})
	ok(main.visiting and not main.hud.visible, "visiting swaps the view")
	ok(main.send("guest") and main.send("thief"), "sends accepted")
	ok(home.money == m0 - Visit.PRICES["guest"] - Visit.PRICES["thief"], "paid now: %d" % (m0 - home.money))
	var park: ParkSim = main.visits[0]["sim"]
	var t := park.sent_by(Visit.ME)
	ok(t["guests"] == 1 and t["hidden"] == 1, "gate queue counts: %s" % t)

	for i in 60:
		main.step_world()
	var mine := park.guests.filter(func(g: Dictionary) -> bool: return g["sender"] == Visit.ME)
	ok(mine.size() == 2, "both inside")
	main.go_home()
	ok(not main.visiting and main.hud.visible, "back home")
	var n := 0
	while main.visits.size() > 0 and n < ParkSim.DAY_TICKS:
		main.step_world()
		n += 1
	ok(main.visits.is_empty(), "left park dropped once our people are out")
	var guest: Dictionary = mine.filter(func(g: Dictionary) -> bool: return g["kind"] == "guest")[0]
	var thief: Dictionary = mine.filter(func(g: Dictionary) -> bool: return g["kind"] == "thief")[0]
	var share := int(guest["spent"] * ParkSim.GUEST_SHARE)
	ok(thief["loot"] > 0, "thief stole something")
	ok(park.ledger[Visit.ME] == share + thief["loot"], "ledger = share + loot")
	ok(home.money == m0 - 53 + share + thief["loot"], "money: %d vs %d" % [home.money, m0 - 53 + share + thief["loot"]])
	main.free()
	done()
