extends SceneTree
# Showcase: charm view on the start park with a paved, stand-lined dull corner (left) and a leafy lovely stretch (right),
# a guest's ♥ and ~ stroll marks, and the card of a dull-path stand. ./gd shot shots/CH2.png 3 res://tests/show_charm.gd

var main: Node2D
var _t := 0.0
var _set := false
var _marked := false

func _initialize() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	main = load("res://main.gd").new()
	main.bots = false
	root.add_child.call_deferred(main)

func _process(delta: float) -> bool:
	_t += delta
	if not _set and _t > 0.2:
		_set = true
		var m: ParkMap = main.zoo.map
		m.money = 1 << 30
		for x in range(4, 11):
			for y in [12, 13, 14]:
				m.place("path", Vector2i(x, y))
			m.place("snack_stand", Vector2i(x, 15))
		for c in [Vector2i(13, 10), Vector2i(15, 10), Vector2i(13, 12), Vector2i(14, 13)]:
			m.place("tree", c)
		m.place("fountain", Vector2i(15, 12))
		m.money = ParkMap.START_MONEY
		main.zoo.rebuild()
		main.follow = false
		main.cam.zoom = Vector2(1.7, 1.7)
		main.cam.position = IsoGrid.project(Vector2(10.5, 11.5))
		main.charm.toggle()
		main.card.show_building(Vector2i(8, 15))
	if _set and not _marked and _t > 2.5:
		_marked = true
		main.fx.stroll_mark(Vector2(14, 11), true)
		main.fx.stroll_mark(Vector2(7, 13), false)
	return false
