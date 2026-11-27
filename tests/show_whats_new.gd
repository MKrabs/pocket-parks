extends SceneTree
# Showcase: the What's new card over the park, with the version label bottom-left.
# ./gd shot shots/LOG1.png 1 res://tests/show_whats_new.gd

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
	main.hud.open_whats_new()
	return false
