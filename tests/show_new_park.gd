extends SceneTree
# Showcase: F9's "start a new park?" card.
# ./gd shot shots/SAVE.png 1 res://tests/show_new_park.gd

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
	main.hud.confirm_new_park()
	return false
