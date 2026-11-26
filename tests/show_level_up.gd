extends SceneTree
# Showcase: the "Level up!" card after reaching park level 4.
# ./gd shot shots/L1.png 2 res://tests/show_level_up.gd

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
	main.sim.xp = ParkLevel.THRESHOLDS[3] + 20
	return false
