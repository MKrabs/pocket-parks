extends SceneTree
# Showcase: all catalog buildings on cream. ./gd shot shots/Z2.png 1 res://tests/show_buildings.gd

func _init() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	var stage := Node2D.new()
	stage.scale = Vector2(2, 2)  # 2x so the shapes are easy to judge
	root.add_child.call_deferred(stage)
	var x := 40.0
	for id in Buildings.CATALOG:
		var v := BuildingView.new(id)
		var fp: Vector2i = Buildings.CATALOG[id]["footprint"]
		v.position = Vector2(x, 180 - (fp.y - 1) * 16)
		stage.add_child(v)
		x += 30 + fp.x * 64
