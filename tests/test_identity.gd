extends SceneTree
# SOC1: name validation, the identity surviving a save, and announcements carrying name, park and colour.
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _init() -> void:
	ok(IdentityCard.valid("Mo") and IdentityCard.valid("  Sixteen chars!! ") and IdentityCard.valid("Sixteen chars!!!"), "2..16 chars, trimmed")
	ok(not IdentityCard.valid("M") and not IdentityCard.valid("   ") and not IdentityCard.valid("Seventeen chars!!"), "too short or long")
	ok(IdentityCard.valid("A rather long park name", IdentityCard.PARK_MAX), "park names may be longer")
	ok(IdentityCard.colour_of("MOSS") == Palette.MOSS and IdentityCard.colour_of("nope") == Palette.SKY, "colour lookup")
	ok(IdentityCard.COLOURS.size() == 6, "six swatches")

	var net := Net.new()
	net.player = "marc42"
	net.nick = "Marc"
	net.park_name = "Otter Bay"
	net.colour = "CORAL"
	var m := ParkMap.new()
	m.start_small()
	var path := "user://test_identity_%d.json" % OS.get_process_id()
	SaveGame.write(path, SaveGame.pack(m, ParkSim.new(m, 1), 1, [], net.state()))
	var d := SaveGame.read(path)
	DirAccess.remove_absolute(path)
	var back := Net.new()
	back.load_state(d.get("net", {}))
	ok([back.player, back.nick, back.park_name, back.colour] == ["marc42", "Marc", "Otter Bay", "CORAL"], "identity round trip")
	var old := Net.new()
	old.load_state({"player": "x11", "seq": 0, "got": {}})
	ok(old.nick == "" and old.park_name == "Pocket Zoo" and old.colour == "SKY" and old.shown() == "x11", "old save: defaults")
	back.free()
	old.free()

	var map := BotPark.generate("zoo", 5)
	net.sim = ParkSim.new(map, 5)
	net.map = map
	var guest := Net.new()
	net.start()
	guest.start()
	ok(net.player == "marc42", "start keeps a chosen player id")
	net.announce()
	var heard := false
	for i in 300:
		net.poll(0.01)
		guest.poll(0.01)
		if guest.offers().any(func(o: Dictionary) -> bool: return o["name"] == "Otter Bay"):
			heard = true
			break
		OS.delay_msec(10)
	ok(heard, "announce heard")
	if heard:
		var o: Dictionary = guest.offers().filter(func(o: Dictionary) -> bool: return o["name"] == "Otter Bay")[0]
		ok(o["player"] == "Marc" and o["colour"] == "CORAL", "offer carries nick and colour: %s" % o)
	net.free()
	guest.free()
	done()
