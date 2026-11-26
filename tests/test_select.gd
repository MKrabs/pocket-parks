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
	main.hud.speed = 0
	var zoo: ZooView = main.zoo
	var bar: BuildBar = main.bar
	var card: InfoCard = main.card
	var L := MOUSE_BUTTON_LEFT

	ok(zoo.selected == "" and zoo.ghost == null, "starts in Select mode")
	bar.pick("snack_stand")
	ok(zoo.selected == "snack_stand", "picking an item turns on place mode")
	main.escape()
	ok(zoo.selected == "", "Esc returns to Select")
	bar.pick("snack_stand")
	bar.pick("snack_stand")  # same item again: pick() presses an already pressed button, no change
	(bar.row.get_children().filter(func(b: Button) -> bool: return b.get_meta("id") == "snack_stand")[0] as Button).button_pressed = false
	ok(zoo.selected == "", "unpressing the same item returns to Select")

	bar.pick("path")
	main._on_cell_clicked(Vector2i(4, 13), L)
	ok(zoo.map.buildings.get(Vector2i(4, 13)) == "path" and zoo.selected == "path", "path stays active after placing")
	bar.pick("snack_stand")
	main._on_cell_clicked(Vector2i(9, 13), L)
	ok(zoo.map.buildings.get(Vector2i(9, 13)) == "snack_stand" and zoo.selected == "", "a snack stand goes back to Select")
	bar.pick("snack_stand")
	main._on_cell_clicked(Vector2i(10, 13), L, true)
	ok(zoo.map.buildings.get(Vector2i(10, 13)) == "snack_stand" and zoo.selected == "snack_stand", "Shift keeps placing")
	main.escape()

	# Building card: name, level, upgrade from the card.
	var o := Vector2i(8, 8)
	main.select_at(o, Vector2(-9999, -9999))
	ok(card.is_open() and card.origin == o, "clicking a building opens its card")
	ok(card.title.text == "Snack Stand · Lv 1", "card title %s" % card.title.text)
	ok(card.body.text.contains("Shop · sells at $5"), "role line: %s" % card.body.text)
	await process_frame
	await process_frame
	ok(card.upgrade.disabled and card.upgrade.text == "Lv 2 unlocks at park level 2", "park level gates upgrade: %s" % card.upgrade.text)
	main.sim.xp = ParkLevel.THRESHOLDS[-1]
	await process_frame
	await process_frame
	var money: int = main.sim.money
	card.upgrade.pressed.emit()
	await process_frame
	await process_frame  # process_frame fires before the nodes' _process
	ok(zoo.map.level(o) == 2 and main.sim.money == money - 60, "Upgrade upgrades and charges")
	ok(card.title.text == "Snack Stand · Lv 2", "card updates live: %s" % card.title.text)
	main.escape()
	ok(not card.is_open(), "Esc closes the card")
	main.select_at(Vector2i(10, 10), Vector2(-9999, -9999))
	ok(not card.is_open(), "empty ground opens nothing")
	main.select_at(o, Vector2(-9999, -9999))
	main.select_at(Vector2i(10, 10), Vector2(-9999, -9999))
	ok(not card.is_open(), "a click on empty ground closes the card")

	# Demolish refunds.
	main.select_at(Vector2i(9, 13), Vector2(-9999, -9999))
	money = main.sim.money
	card.demolish.pressed.emit()
	ok(not zoo.map.buildings.has(Vector2i(9, 13)) and main.sim.money == money + 30 and not card.is_open(), "Demolish refunds half")

	# Person card: accuse works like the old tool.
	main.send_group("Mia", ["thief"])
	var thief: Dictionary = {}
	while main.sim.tick < ParkSim.DAY_TICKS and (thief.is_empty() or thief["crimes"] == 0 or thief["state"] == "visit"):
		main.advance(1)
		for g in main.sim.guests:
			if g["kind"] == "thief":
				thief = g
	var at: Vector2 = IsoGrid.project(WalkerView.spot(thief)) - Vector2(0, WalkerView.LIFT + 5)
	main.select_at(Vector2i(-1, -1), at)
	ok(card.is_open() and card.person == thief["id"], "clicking a person opens their card")
	ok(card.title.text == "Guest" and card.accuse.visible and card.warning.text.contains("$40"), "a hidden actor looks like a guest")
	money = main.sim.money
	card.accuse.pressed.emit()
	ok(main.sim.money > money and main.toasts.items[0]["panel"].get_child(0).get_child(1).get_child(0).text.begins_with("Caught a thief"), "Accuse catches the thief")
	done()
