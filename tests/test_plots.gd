extends SceneTree
# Land plots: the start area is yours, the rest is bought plot by plot, next to your land, capped by park level.
var failed := false
func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed = true
		printerr("FAIL: ", msg)
func done() -> void:
	quit(1 if failed else 0)

func _init() -> void:
	var bot := ParkMap.new()
	ok(bot.owns(Vector2i(0, 0)) and bot.can_place("tree", Vector2i(19, 19)), "no plots: all land is yours (bot parks)")

	var m := ParkMap.new()
	m.money = 1 << 20
	m.start_small()
	ok(m.owned.size() == 9 and m.owns(Vector2i(4, 4)) and m.owns(Vector2i(15, 15)), "start area is the 12×12 centre")
	ok(not m.owns(Vector2i(3, 4)) and not m.owns(Vector2i(16, 10)), "outside it is for sale")
	ok(not m.can_place("tree", Vector2i(2, 8)) and not m.place("tree", Vector2i(2, 8)), "can't place on unowned land")
	ok(not m.can_place("pond", Vector2i(15, 8)) and m.on_unowned("pond", Vector2i(15, 8)), "a footprint reaching over the line is refused")
	ok(not m.on_unowned("pond", Vector2i(14, 8)) and m.can_place("pond", Vector2i(14, 8)), "inside it places")
	ok(ParkMap.plot_of(Vector2i(-1, -1)) == Vector2i(-1, -1), "plot_of floors negatives")

	# adjacency
	ok(m.buyable(Vector2i(0, 2)) and m.buyable(Vector2i(2, 4)), "edge plots next to your land are buyable")
	ok(not m.buyable(Vector2i(0, 0)), "a corner plot (diagonal only) isn't")
	ok(not m.buyable(Vector2i(2, 2)) and not m.buyable(Vector2i(5, 2)) and not m.buyable(Vector2i(-1, 2)), "owned or off-world plots aren't")

	# level cap
	ok(m.plot_needs() == 2 and not m.buy(Vector2i(0, 2)), "park level 1: no plots yet")
	m.xp = ParkLevel.THRESHOLDS[1]  # level 2
	var before := m.money
	ok(m.plot_price() == ParkMap.PLOT_PRICE and m.buy(Vector2i(0, 2)), "level 2 buys one")
	ok(m.money == before - ParkMap.PLOT_PRICE and m.owns(Vector2i(1, 9)) and m.can_place("tree", Vector2i(1, 9)), "paid and now buildable")
	ok(m.buyable(Vector2i(0, 1)) and not m.buyable(Vector2i(0, 0)), "plots next to a bought plot open up")
	ok(m.plot_needs() == 4 and not m.buy(Vector2i(0, 1)), "the cap follows the park level")
	m.xp = ParkLevel.THRESHOLDS[3]  # level 4
	ok(m.plot_price() == 2 * ParkMap.PLOT_PRICE, "the price rises with each plot")
	var cash := m.money
	m.money = m.plot_price() - 1
	ok(not m.buy(Vector2i(0, 1)), "can't buy without the money")
	m.money = cash
	ok(m.buy(Vector2i(0, 1)) and m.buyable(Vector2i(0, 0)), "corner opens once a neighbour is yours")
	m.xp = ParkLevel.THRESHOLDS[-1]  # level 10
	for p: Vector2i in [Vector2i(0, 0), Vector2i(0, 3), Vector2i(4, 2)]:
		ok(m.buy(p), "buy %s at level 10" % p)
	ok(m.bought == 5 and m.plot_needs() == -1 and not m.buy(Vector2i(4, 1)), "five plots at most")
	done()
