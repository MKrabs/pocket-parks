extends SceneTree
# Showcase: Select mode info cards. A wrecked building's card (tests/show_person_card.gd: a guest's card).
# ./gd shot shots/X1-card.png 2 res://tests/show_select.gd

var main: Node2D
var person := false
var _done := false

func _initialize() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	main = load("res://main.gd").new()
	main.bots = false
	root.add_child.call_deferred(main)

func _process(_delta: float) -> bool:
	if _done or not main.is_node_ready():
		return false
	_done = true
	main.hud.speed = 0
	var sim: ParkSim = main.sim
	main.send_group("Theo", ["hooligan", "thief", "guest", "guest", "guest"])
	while sim.tick < ParkSim.DAY_TICKS - 1 and sim.closed.is_empty():
		main.advance(1)
	if person:
		for g in sim.guests:
			if g["state"] != "visit":
				main.card.show_person(g["id"])
				main.walkers.hovered = g["id"]
				break
	else:
		main.card.show_building(sim.closed.keys()[0])
	return false
