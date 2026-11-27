extends SceneTree
# Showcase: the shaped buildings (fence, glass, dome, wall) intact, wrecked, and turned a quarter.
# ./gd shot shots/SH1.png 1 res://tests/show_shapes.gd

func _init() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	var stage := Node2D.new()
	stage.scale = Vector2(1.3, 1.3)
	root.add_child.call_deferred(stage)
	for row in 3:
		var ids := ["enclosure", "water_tank", "aviary", "reinforced"]
		for i in ids.size():
			var v := BuildingView.new(ids[i])
			v.origin = Vector2i(i * 3, 0)
			v.position = Vector2(130 + i * 230, 130 + row * 175)
			v.turn = 1 if row == 2 else 0
			v.wrecked = row == 1
			stage.add_child(v)
