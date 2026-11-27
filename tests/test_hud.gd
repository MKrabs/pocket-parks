extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _initialize() -> void:
	var main: Node2D = load("res://main.gd").new()
	main.bots = false
	root.add_child.call_deferred(main)
	await main.ready
	var hud: Hud = main.hud
	var bar: BuildBar = main.bar
	var sim: ParkSim = main.sim

	# tabs filter the build items by role
	for t: String in BuildBar.TABS:
		bar.show_tab(t)
		var ids := bar.visible_ids()
		if t == "Staff":
			ok(ids.count("") == ParkSim.STAFF.size() and ids.filter(func(i: String) -> bool: return i != "").all(
				func(i: String) -> bool: return Buildings.get_def(i)["role"] == "staff"), "Staff tab holds hiring and the builder shed")
		else:
			ok(not ids.is_empty(), "%s tab has items" % t)
			ok(ids.all(func(i: String) -> bool: return Buildings.get_def(i)["role"] in BuildBar.TABS[t]), "%s tab filters by role: %s" % [t, ids])
	var all: Array = []
	for t: String in BuildBar.TABS:
		bar.show_tab(t)
		all += bar.visible_ids().filter(func(i: String) -> bool: return i != "")
	var families := Buildings.ids().filter(func(i: String) -> bool: return Buildings.family(i)[0] == i)
	ok(all.size() == families.size() and families.all(func(i: String) -> bool: return i in all),"every catalog family sits in some tab, once")
	bar.pick("snack_stand")
	ok(bar.tab == "Shops" and main.zoo.selected == "snack_stand", "pick opens the item's tab")
	bar.show_tab("Decor")
	ok(main.zoo.selected == "", "switching tabs lets go of the picked item")

	# the Staff tab hires
	bar.show_tab("Staff")
	var money := sim.money
	var staff := sim.staff.size()
	var b: Button = bar.row.get_children().filter(func(x: Button) -> bool: return x.visible and x.get_meta("id") == "")[0]
	b.pressed.emit()
	ok(sim.staff.size() == staff + 1 and sim.money < money, "hire button hires")

	# speed buttons
	hud.speed_buttons[0].pressed.emit()
	ok(hud.speed == 0, "pause")
	hud.speed_buttons[2].pressed.emit()
	ok(hud.speed == 3, "fast")
	hud.speed_buttons[1].pressed.emit()
	ok(hud.speed == 1, "play")

	# labels follow the sim
	sim.money = 1234
	await create_timer(Motion.COUNT_TIME + 0.2).timeout
	ok(hud.money.text == "$ 1234", "money label: %s" % hud.money.text)
	hud.speed = 0
	sim.send("guest", "test")
	await process_frame
	ok(hud.guests.text == str(sim.guests.size()) and sim.guests.size() > 0, "guest label: %s" % hud.guests.text)
	ok(Hud.face_for(90) == 1 and Hud.face_for(50) == 0 and Hud.face_for(10) == -1, "mood faces")
	hud.set_level(2, 0.5)
	ok(hud.level == 2 and hud.progress == 0.5, "level setter")
	ok(hud.park_name.text == "Pocket Zoo", "park name")
	done()
