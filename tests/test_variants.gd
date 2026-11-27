extends SceneTree
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

const FAMILIES := [["snack_stand", "hotdog_stand", "burger_diner"], ["fest_truck", "fest_taco", "fest_hall"],
	["cin_popcorn", "cin_candy", "cin_cafe"]]

func key(code: Key) -> InputEventKey:
	var k := InputEventKey.new()
	k.pressed = true
	k.physical_keycode = code
	return k

func _initialize() -> void:
	for fam: Array in FAMILIES:
		var sizes := [Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)]
		for i in 3:
			var d := Buildings.get_def(fam[i])
			ok(Buildings.family(fam[i]) == fam, "%s resolves to its family" % fam[i])
			ok(d["role"] == "shop", "%s is a shop" % fam[i])
			ok(d["footprint"] == sizes[i], "%s is %s" % [fam[i], sizes[i]])
			if i > 0:
				var e := Buildings.get_def(fam[i - 1])
				ok(d["price"] > e["price"] and d["cost"] > e["cost"] and d["capacity"] > e["capacity"],
					"%s costs, charges and holds more than %s" % [fam[i], fam[i - 1]])
	ok(Buildings.family("tree") == ["tree"], "no variants: a family of one")

	# Charm: a hot-dog stand next to a snack cart is "the same building again".
	var cell := Vector2i(5, 7)
	var charms := []
	for other in ["hotdog_stand", "fest_taco"]:
		var m := ParkMap.new()
		m.money = 1 << 30
		m.xp = ParkLevel.THRESHOLDS[-1]  # everything unlocked (test_unlocks covers the gates)
		m.place("zoo_gate", Vector2i(0, 7))
		for x in range(1, 11):
			m.place("path", Vector2i(x, 7))
		m.place("snack_stand", Vector2i(4, 8))
		m.place(other, Vector2i(6, 8))
		charms.append(ParkSim.new(m, 1).charm(cell))
	ok(charms[0] < charms[1], "variants repeat for charm (%.2f < %.2f)" % charms)

	# The build bar: one button per family, the arrows and 1/2/3 switch it, the ghost stays.
	var main: Node2D = load("res://main.gd").new()
	main.bots = false
	root.add_child.call_deferred(main)
	await main.ready
	await process_frame
	var bar: BuildBar = main.bar
	bar.show_tab("Shops")
	ok(bar.visible_ids() == ["snack_stand"], "one shop button for the snack family: %s" % [bar.visible_ids()])
	var b: Button = bar.row.get_children().filter(func(x: Button) -> bool: return x.visible)[0]
	bar.step_variant(b, 1)
	ok(b.get_meta("id") == "hotdog_stand" and b.text.begins_with("Hot-dog Stand") and "$110" in b.text,
		"› shows the next variant's name and price: %s" % b.text)
	ok(not bar.placing, "an arrow on an idle button doesn't start placing")
	bar.step_variant(b, -1)
	bar.step_variant(b, -1)
	ok(b.get_meta("id") == "burger_diner", "‹ wraps to the biggest")
	main.zoo.on_hover(Vector2i(8, 8))
	b.button_pressed = true
	ok(main.zoo.selected == "burger_diner" and main.zoo.ghost != null, "placing the shown variant")
	main.zoo.rotate_ghost(1)
	main._unhandled_key_input(key(KEY_2))
	ok(main.zoo.selected == "hotdog_stand" and bar.placing, "2 switches the variant while placing")
	var g: BuildingView = main.zoo.ghost
	ok(g != null and g.id == "hotdog_stand" and g.turn == 1 and g.position == IsoGrid.to_screen(Vector2i(8, 8)),
		"the ghost stays where it was, turned the same way")
	main._unhandled_key_input(key(KEY_1))
	ok(main.zoo.ghost.id == "snack_stand" and b.get_meta("id") == "snack_stand", "1 goes back to the cart")
	bar.clear()
	main._unhandled_key_input(key(KEY_3))
	ok(main.zoo.selected == "" and b.get_meta("id") == "snack_stand", "number keys do nothing in Select mode")
	bar.pick("burger_diner")
	ok(main.zoo.selected == "burger_diner" and b.get_meta("id") == "burger_diner", "pick() finds a variant's button")
	done()
