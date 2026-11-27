extends SceneTree
# SOC4: chat. Host + two clients in one process over ENet on 127.0.0.1; the host relays every line said in its park.
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func pump(nets: Array, cond: Callable) -> bool:
	for i in 500:
		for n: Net in nets:
			n.poll(0.01)
		if cond.call():
			return true
		OS.delay_msec(10)
	return false

func _initialize() -> void:
	var map := BotPark.generate("zoo", 5)
	var host := Net.new()
	host.sim = ParkSim.new(map, 5)
	host.map = map
	host.start()
	var heard := {}  # net -> [[name, text, home], ...]
	var nets: Array = [host]
	for c: Color in [Palette.CLAY, Palette.MOSS]:
		var n := Net.new()
		n.sim = ParkSim.new(ParkMap.new(), 1)
		n.map = ParkMap.new()
		n.color = c
		n.start()
		nets.append(n)
	for n: Net in nets:
		heard[n] = []
		n.said.connect(func(name: String, _c: Color, text: String, home: bool) -> void: heard[n].append([name, text, home]))
	var a: Net = nets[1]
	var b: Net = nets[2]
	ok(a.join("127.0.0.1", host.port) and b.join("127.0.0.1", host.port), "both clients connect")
	ok(not a.say("too early"), "no line before the host heard our hello")
	ok(pump(nets, func() -> bool: return host.sim.avatars.size() == 2), "both visitors said hello")

	ok(not a.say("   "), "an empty line isn't sent")
	ok(a.say("hello there " + "x".repeat(100)), "client says a line")
	var line := "hello there " + "x".repeat(Net.SAY_MAX - 12)
	var got := func() -> bool: return heard[host].size() == 1 and heard[a].size() == 1 and heard[b].size() == 1
	ok(pump(nets, got), "the line reaches the host and both clients")
	ok(heard[host][0] == [a.player, line, true], "host shows it in its own park, cut to %d chars" % Net.SAY_MAX)
	ok(heard[b][0] == [a.player, line, false], "the other client hears it, under the speaker's name")
	ok(heard[a][0] == [a.player, line, false], "the speaker gets its own line back")

	ok(host.say("welcome"), "the host says a line at home")
	ok(pump(nets, func() -> bool: return heard[b].size() == 2), "its visitors hear it")
	ok(heard[host][1] == [host.player, "welcome", true] and heard[b][1] == [host.player, "welcome", false], "host line")

	# the log keeps the last 6, and typing doesn't fire hotkeys
	var main: Node2D = load("res://main.gd").new()
	main.bots = false
	root.add_child(main)
	await process_frame
	for i in 8:
		main.say("line %d" % i)
	var texts: Array = main.chat.lines.map(func(l: Dictionary) -> String: return l["text"])
	ok(texts == ["line 2", "line 3", "line 4", "line 5", "line 6", "line 7"], "log keeps the last 6: %s" % [texts])
	ok(main.chat.lines[0]["name"] == main.net.player, "at home it's our own name")
	var theme := Buildings.active
	var key := func(code: Key) -> void:
		var e := InputEventKey.new()
		e.pressed = true
		e.physical_keycode = code
		e.keycode = code
		e.unicode = code + 32 if code >= KEY_A and code <= KEY_Z else 0
		root.push_input(e)
		var up: InputEventKey = e.duplicate()
		up.pressed = false
		root.push_input(up)
	key.call(KEY_ENTER)
	ok(main.chat.typing(), "Enter opens the line")
	for c: Key in [KEY_T, KEY_F, KEY_ENTER]:
		key.call(c)
	ok(Buildings.active == theme and main.follow, "T and F went into the line, not the hotkeys")
	ok(not main.chat.typing() and main.chat.lines[-1]["text"] == "tf", "Enter sends: %s" % main.chat.lines[-1]["text"])

	main.free()
	for n: Net in nets:
		n._exit_tree()
		n.free()
	done()
