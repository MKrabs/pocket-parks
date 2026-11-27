extends SceneTree
# SOC3: presence. Host + two clients in one process over ENet on 127.0.0.1: each sees who else is in the park.
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

func names(list: Array) -> Array:
	var out := list.map(func(p: Array) -> String: return p[0])
	out.sort()
	return out

func _initialize() -> void:
	var map := BotPark.generate("zoo", 5)
	var host := Net.new()
	host.sim = ParkSim.new(map, 5)
	host.map = map
	host.nick = "Hana"
	host.start()
	var nets: Array = [host]
	for p: Array in [["Sam", "CLAY"], ["Mia", "MOSS"]]:
		var n := Net.new()
		n.sim = ParkSim.new(ParkMap.new(), 1)
		n.map = ParkMap.new()
		n.nick = p[0]
		n.colour = p[1]
		n.start()
		nets.append(n)
	var a: Net = nets[1]
	var b: Net = nets[2]
	ok(a.join("127.0.0.1", host.port) and b.join("127.0.0.1", host.port), "both clients connect")
	var seen := func(n: Net) -> Array: return names(Net.others(n.visit_sim, n.shown()))
	ok(pump(nets, func() -> bool: return seen.call(a) == ["Mia"] and seen.call(b) == ["Sam"]), "each client sees the other")
	ok(names(Net.others(host.sim, host.shown())) == ["Mia", "Sam"], "the host sees both")
	ok(Net.others(a.visit_sim, a.shown())[0][1] == IdentityCard.colour_of("MOSS"), "with their colour")

	host.sim.join_avatar(host.shown(), host.color)  # the host's character walks into its own park
	ok(pump(nets, func() -> bool: return seen.call(a) == ["Hana", "Mia"]), "the host shows while its character is there")

	b.leave()
	ok(pump(nets, func() -> bool: return seen.call(a) == ["Hana"] and names(Net.others(host.sim, host.shown())) == ["Sam"]),
		"a leave updates everyone: %s" % [seen.call(a)])

	# at home: the chip under the money counts visitors and lists their names on hover / click
	var hud := Hud.new()
	hud.sim = host.sim
	root.add_child(hud)
	await process_frame
	hud.set_visitors(Net.others(host.sim, host.shown()))
	ok(hud._here_chip.visible and hud._here_label.text == "1 visiting", "chip: %s" % hud._here_label.text)
	hud._open_names(true)
	ok(hud._here_label.text == "Sam", "names open: %s" % hud._here_label.text)
	hud.set_visitors([])
	ok(not hud._here_chip.visible, "nobody visiting: no chip")
	hud.free()

	for n: Net in nets:
		n._exit_tree()
		n.free()
	done()
