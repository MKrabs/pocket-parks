extends SceneTree
# SOC5: mischief in person and the blacklist. In-process host + client over ENet on 127.0.0.1; the host's sim judges.
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

## Poll both nets (walking the host's characters) until `cond` holds (or ~5 s pass).
func pump(a: Net, b: Net, cond: Callable) -> bool:
	for i in 500:
		a.sim.step_avatars()
		a.poll(0.01)
		b.poll(0.01)
		if cond.call():
			return true
		OS.delay_msec(10)
	return false

func shop_door(sim: ParkSim) -> Vector2i:
	for t in sim._targets:
		if t["role"] == "shop":
			return t["door"]
	return Vector2i(-1, -1)

## Put `name`'s character straight on `cell` (sim-only checks).
func place(sim: ParkSim, name: String, cell: Vector2i) -> void:
	var a := sim.avatar(name)
	a["cell"] = cell
	a["pos"] = Vector2(cell)
	a["path"] = []

func _init() -> void:
	var map := BotPark.generate("zoo", 5)
	var sim := ParkSim.new(map, 5)
	sim.money = 1000
	var door := shop_door(sim)
	ok(door.x >= 0, "the bot park has a shop with a door")

	# --- network: Ana steals next to a shop, a guard sees it ---
	var host := Net.new()
	host.sim = sim
	host.map = map
	host.start()
	var guest := Net.new()
	guest.sim = ParkSim.new(ParkMap.new(), 1)
	guest.map = ParkMap.new()
	guest.player = "Ana"
	guest.level = 4
	guest.start()
	ok(guest.join("127.0.0.1", host.port), "client socket opens")
	ok(pump(host, guest, func() -> bool: return guest.visit_sim != null and not guest.visit_sim.avatar("Ana").is_empty()),
		"Ana's character is in the park")
	sim._appeal = 0.0  # no park guests: the host's money only moves by our doing
	guest.move_avatar(door)
	ok(pump(host, guest, func() -> bool: return not guest.visit_sim.avatar("Ana")["path"].is_empty()), "Ana walks")
	ok(guest.visit_sim.crimes_for("Ana").is_empty(), "no crimes while walking")
	ok(pump(host, guest, func() -> bool:
		var a := guest.visit_sim.avatar("Ana")
		return a["cell"] == door and a["path"].is_empty()), "Ana walks to the shop")
	ok("thief" in guest.visit_sim.crimes_for("Ana") and "hooligan" in guest.visit_sim.crimes_for("Ana"),
		"the client sees Steal and Wreck offered beside the shop: %s" % [guest.visit_sim.crimes_for("Ana")])
	var money := sim.money
	guest.strike("thief")
	ok(pump(host, guest, func() -> bool: return guest.visit_sim.avatar("Ana").get("strike", 0) > 0), "the client sees itself striking")
	var loot: int = sim.avatar("Ana")["loot"]
	ok(loot > 0 and sim.money == money - loot, "the host's till was robbed: %d" % loot)
	ok(not sim.move_avatar("Ana", sim._entrance), "can't walk away mid-strike")
	ok(sim.hire("guard"), "hire a guard")
	money = sim.money
	sim.staff[-1]["pos"] = Vector2(door)
	sim.staff[-1]["cell"] = door
	sim.step()
	ok(sim.avatar("Ana").is_empty(), "the guard caught Ana: her character is out")
	ok(sim.blacklist.get("Ana") == ParkSim.BAN_DAYS, "witnessed strike: blacklisted for the default days")
	ok(sim.money == money + loot + ParkSim.BASE_FINE["thief"] and sim.ledger["Ana"] == -ParkSim.BASE_FINE["thief"],
		"fined base × 1 crime, the loot went back")
	ok(pump(host, guest, func() -> bool: return int(guest.visit_ledger.get("banned", 0)) == ParkSim.BAN_DAYS),
		"the client hears it's banned")
	ok(guest.visit_ledger["limit"] == (ParkSim.SEND_BASE + 4) / 2, "send limit halved: %s" % guest.visit_ledger)

	# rejoin while blacklisted: in-person entry refused, sending still works at double price
	guest.leave()
	ok(guest.join("127.0.0.1", host.port), "reconnect")
	var heard := func() -> bool: return guest._hello and int(guest.visit_ledger.get("banned", 0)) > 0 and guest.visit_sim.tick == sim.tick
	ok(pump(host, guest, heard), "the rejoin hears the ban")
	ok(sim.avatar("Ana").is_empty() and guest.visit_sim.avatar("Ana").is_empty(), "a blacklisted join gets no character")
	var before: int = sim.ledger["Ana"]
	guest.send_person("guest")
	ok(pump(host, guest, func() -> bool: return sim.ledger["Ana"] != before), "the send arrives")
	ok(sim.ledger["Ana"] == before - 2 * Visit.PRICES["guest"], "sending costs ×2")
	ok(sim.send_cost("Ana", "thief") == 2 * Visit.PRICES["thief"], "thief ×2 too")
	guest._exit_tree()
	host._exit_tree()
	host.free()
	guest.free()

	# --- host accusation with a chosen number of days ---
	sim.staff.clear()
	ok(sim.join_avatar("Bo", Palette.CLAY), "Bo walks in")
	place(sim, "Bo", door)
	ok(sim.avatar_strike("Bo", "spy"), "Bo spies on the shop")
	ok(not sim.avatar_strike("Bo", "litterbug"), "one strike at a time")
	var r := sim.accuse_avatar("Bo", 5)
	ok(not r["wrongful"] and r["days"] == 5 and sim.blacklist["Bo"] == 5, "accused after a crime: 5 days")
	ok(not sim.join_avatar("Bo", Palette.CLAY), "a blacklisted character can't walk in")
	ok(sim.accuse_avatar("Nobody", 3).is_empty(), "nobody to accuse")
	ok(sim.accuse_avatar("Bo", 3).is_empty(), "Bo is out of the park")

	# wrongful accusation: pays, never bans
	sim.join_avatar("Cy", Palette.SKY)
	money = sim.money
	r = sim.accuse_avatar("Cy", 7)
	ok(r["wrongful"] and not sim.blacklist.has("Cy"), "a wrongful accusation doesn't ban")
	ok(sim.money == money - ParkSim.WRONGFUL_FINE and sim.ledger["Cy"] == ParkSim.WRONGFUL_FINE, "the host pays Cy")
	ok(not sim.avatar("Cy").is_empty(), "Cy stays in the park")

	# loot is delivered at the gate
	place(sim, "Cy", door)
	ok(sim.avatar_strike("Cy", "thief"), "Cy steals")
	loot = sim.avatar("Cy")["loot"]
	for i in ParkSim.STRIKE_TICKS:
		sim.step_avatars()
	ok(sim.ledger["Cy"] == ParkSim.WRONGFUL_FINE, "loot not delivered while still inside")
	ok(sim.move_avatar("Cy", sim._entrance), "Cy heads for the gate")
	for i in 400:
		sim.step_avatars()
	ok(sim.ledger["Cy"] == ParkSim.WRONGFUL_FINE + loot and sim.avatar("Cy")["loot"] == 0, "loot delivered at the gate")

	# limit halved, cost doubled; the ban counts down in the host's days
	sim.sender_levels["Bo"] = 4
	ok(sim.send_limit("Bo") == 3 and sim.send_cost("Bo", "guest") == 2 * Visit.PRICES["guest"], "Bo: limit 7/2, price ×2")
	for d in 4:
		sim.new_day()
	ok(sim.blacklist.get("Bo") == 1 and sim.blacklist.get("Ana") == null, "after 4 days: Bo has 1 left, Ana's 3 are over")
	sim.new_day()
	ok(not sim.blacklist.has("Bo") and sim.send_limit("Bo") == 7, "the ban expires after 5 days")
	ok(sim.join_avatar("Bo", Palette.CLAY), "Bo may come back")

	# clamped, saved
	sim.join_avatar("Di", Palette.SKY)
	place(sim, "Di", door)
	sim.avatar_strike("Di", "spy")
	ok(sim.accuse_avatar("Di", 30)["days"] == ParkSim.BAN_MAX, "days clamp to 1–7")
	sim.ban_days = 6
	var back := SaveGame.restore(SaveGame.from_text(SaveGame.to_text(SaveGame.pack(map, sim, 1, []))), ParkMap.new())
	ok(back.blacklist.get("Di") == ParkSim.BAN_MAX and back.ban_days == 6, "the blacklist is saved: %s" % back.blacklist)
	done()
