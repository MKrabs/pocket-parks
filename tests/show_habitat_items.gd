extends SceneTree
# Showcase: the start habitat decorated (trees, rocks, a shelter, a waterfall) with happy red pandas; its card is open
# on the clicked shelter, offering the decor items and the shelter's removal.
# ./gd shot shots/HAB3.png 3 res://tests/show_habitat_items.gd

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
	var o := Vector2i(6, 8)
	var map: ParkMap = main.zoo.map
	map.money = 5000
	for it: Array in [["tree", Vector2i(6, 8), 0], ["tree", Vector2i(6, 9), 0], ["tree", Vector2i(6, 10), 0],
			["tree", Vector2i(7, 8), 0], ["shelter", Vector2i(8, 8), 0], ["rocks", Vector2i(8, 9), 0],["waterfall", Vector2i(7, 10), 0]]:
		map.place_item(o, it[0], it[1], it[2])
	map.buy_animal(o, "red_panda")
	main.zoo.rebuild()
	main.advance(100)
	main.card.show_building(o)
	main.cam.zoom = Vector2.ONE * 2.4
	main.cam.position = IsoGrid.project(Vector2(8.5, 9))
	return false
