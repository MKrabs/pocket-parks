extends SceneTree
# Showcase: L-shaped habitats in each fence style (fence, glass, net, wall), and a live paint preview being dragged.
# ./gd shot shots/HAB1.png 1 res://tests/show_shapes.gd

func _init() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	var zoo := ZooView.new()
	zoo.map.money = 1 << 20
	var m := zoo.map
	m.xp = ParkLevel.THRESHOLDS[-1]  # every fence style unlocked
	for x in 20:
		m.place("path", Vector2i(x, 9))
	var fences := ["habitat", "habitat_glass", "habitat_net", "habitat_wall"]
	for i in fences.size():
		var at := Vector2i(1 + (i % 2) * 6, 3 + (i / 2) * 7)
		m.paint(fences[i], Rect2i(at, Vector2i(4, 2)))
		m.paint(fences[i], Rect2i(at + Vector2i(0, 2), Vector2i(2, 2)))  # added: an L
	m.place("tree", Vector2i(13, 4))
	zoo.selected = "habitat"
	zoo.hovered = Vector2i(14, 4)
	zoo.drag_from = Vector2i(16, 6)
	var cam := Camera2D.new()
	cam.position = IsoGrid.project(Vector2(9, 9))
	cam.zoom = Vector2.ONE * 0.95
	root.add_child.call_deferred(zoo)
	root.add_child.call_deferred(cam)
