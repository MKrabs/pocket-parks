extends SceneTree
# Showcase: every zoo and festival building intact (top row of each pair) above its wrecked variant.
# ./gd shot shots/DMG.png 1 res://tests/show_wrecked.gd

func _init() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	var stage := Node2D.new()
	stage.scale = Vector2(0.85, 0.85)
	root.add_child.call_deferred(stage)
	var y := 120.0
	for theme: String in ["zoo", "festival"]:
		for wrecked in [false, true]:
			var x := 40.0
			for id: String in Buildings.themes()[theme].keys():
				var v := BuildingView.new(id)
				var fp: Vector2i = Buildings.get_def(id)["footprint"]
				v.origin = Vector2i(roundi(x), 0)  # varied seeds
				v.position = Vector2(x + (fp.y - 1) * 32, y - (fp.y - 1) * 16)
				v.wrecked = wrecked
				stage.add_child(v)
				x += 30 + (fp.x + fp.y) * 32
			y += 205.0
