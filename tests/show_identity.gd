extends SceneTree
# Showcase: the identity card (your name, park name, colour).
# ./gd shot shots/SOC1.png 1 res://tests/show_identity.gd

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
	main.net.colour = "CORAL"
	main.net.park_name = "Otter Bay"
	main.hud.set_identity("Otter Bay", Palette.CORAL)
	main.open_identity()
	return false
