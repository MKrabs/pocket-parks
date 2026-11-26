extends SceneTree
# Showcase: the HUD with four crime toasts and a building card open at once (nothing may overlap).
# ./gd shot shots/X3-card.png 2 res://tests/show_hud.gd

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
	for k: String in ["robbed", "littered", "spied", "wrecked"]:
		main.toasts.add(k, "Snack Stand: " + k)
	main.card.show_building(Vector2i(8, 8))
	main.bar.show_tab("Staff")
	return false
