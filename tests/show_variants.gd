extends SceneTree
# Showcase: the shop size variants of every theme (a row each), plus the build bar on its Shops tab.
# ./gd shot shots/variants.png 1 res://tests/show_variants.gd

func _init() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	var stage := Node2D.new()
	stage.scale = Vector2(1.6, 1.6)
	root.add_child.call_deferred(stage)
	var y := 70.0
	for base: String in ["snack_stand", "fest_truck", "cin_popcorn"]:
		var x := 120.0
		for id: String in Buildings.family(base):
			var v := BuildingView.new(id)
			var fp: Vector2i = Buildings.get_def(id)["footprint"]
			v.position = Vector2(x + (fp.y - 1) * 32, y - (fp.y - 1) * 16)
			stage.add_child(v)
			x += 60 + (fp.x + fp.y) * 32
		y += 100
	var bar := BuildBar.new()
	root.add_child.call_deferred(bar)
	bar.ready.connect(func() -> void:
		bar.show_tab("Shops")
		bar.step_variant(bar.row.get_children().filter(func(b: Button) -> bool: return b.visible)[0], 1))
