extends SceneTree
# Showcase: a Lv 2 guard's staff card, with Lv 1-3 staff on the paths showing their cap stripes.
# ./gd shot shots/STF.png 2 res://tests/show_staff_card.gd

var main: Node2D
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
	sim.money += 1000
	for k in ["guard", "janitor", "guard"]:
		sim.hire(k)
	sim.upgrade_staff(0)
	sim.upgrade_staff(1)
	sim.upgrade_staff(1)
	main.advance(60)
	main.card.show_staff(0)
	main.walkers.hovered_staff = 0
	main.cam.zoom = Vector2.ONE * IsoCamera.ZOOM_MAX  # close enough to read the cap stripes
	main.cam.position = IsoGrid.project(sim.staff[0]["pos"]) + Vector2(60, 0)
	return false
