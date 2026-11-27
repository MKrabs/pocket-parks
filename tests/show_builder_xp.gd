extends SceneTree
# Showcase: Bo's shed card with a Lv 2 Carpenter (XP bar) after a level-up toast.
# ./gd shot shots/PRG1.png 2 res://tests/show_builder_xp.gd

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
	var shed := Vector2i(6, 12)
	main.hud.speed = 0
	main.sim.money = 2000
	main.zoo.map.money = 2000
	main.zoo.map.toggle_specialty(shed, "carpenter")
	main.zoo.map.spec_xp[shed] = {"carpenter": 9}
	main.zoo.selected = "snack_stand"
	main.zoo.on_click(Vector2i(9, 13))
	main.zoo.selected = ""
	main.advance(400)
	main.card.show_building(shed)
	return false
