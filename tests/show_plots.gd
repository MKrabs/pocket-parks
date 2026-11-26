extends SceneTree
# Showcase: owned start area, muted for-sale land with signs, and the card of a plot to buy.
# ./gd shot shots/MAP.png 2 res://tests/show_plots.gd

var main: Node2D
var _done := false

func _initialize() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	main = load("res://main.gd").new()
	main.bots = false
	main.zoo.map.xp = ParkLevel.THRESHOLDS[1]  # level 2 from the start: one plot may be bought, no level-up card
	root.add_child.call_deferred(main)

func _process(_delta: float) -> bool:
	if _done or not main.is_node_ready():
		return false
	_done = true
	main.hud.speed = 0
	main.select_at(Vector2i(17, 9), Vector2(-9999, -9999))
	return false
