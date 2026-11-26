extends SceneTree
# Showcase: Bo's shed card with the specialty picker, and the Attractions tab with the specialist glyphs.
# ./gd shot shots/B2-card.png 2 res://tests/show_specialty_card.gd

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
	main.sim.money = 2000
	main.zoo.map.money = 2000
	main.zoo.selected = "aviary"
	main.zoo.on_click(Vector2i(8, 10))
	main.zoo.selected = ""
	main.advance(100)
	main.bar.show_tab("Attractions")
	main.card.show_building(Vector2i(2, 8))
	return false
