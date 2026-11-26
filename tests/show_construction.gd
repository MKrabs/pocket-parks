extends SceneTree
# Showcase: a new pond site with Bo working on it, and a snack stand waiting for its upgrade.
# ./gd shot shots/B1.png 2 res://tests/show_construction.gd

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
	main.zoo.selected = "pond"
	main.zoo.on_click(Vector2i(8, 10))
	main.zoo.selected = ""
	main.zoo.upgrade(Vector2i(5, 8))
	main.advance(200)
	main.card.show_building(Vector2i(5, 8))
	return false
