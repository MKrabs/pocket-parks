extends SceneTree
# Showcase: all amusement buildings in a row on top, a large amusement bot park below.
# ./gd shot shots/TH1.png 1 res://tests/show_amusement.gd

func _init() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	Buildings.use("amusement")
	var row := Node2D.new()
	row.scale = Vector2(1.05, 1.05)
	root.add_child.call_deferred(row)
	var x := 30.0
	for id: String in Buildings.ids():
		var v := BuildingView.new(id)
		var fp: Vector2i = Buildings.get_def(id)["footprint"]
		v.position = Vector2(x + (fp.y - 1) * 32, 130 - (fp.y - 1) * 16)
		row.add_child(v)
		x += 14 + (fp.x + fp.y) * 32
	var park := Node2D.new()
	park.scale = Vector2(0.55, 0.55)
	park.position = Vector2(640, 300)
	park.add_child(GridView.new())
	var view := ZooView.new()
	view.map = BotPark.generate("amusement", 7, "large")
	park.add_child(view)
	root.add_child.call_deferred(park)
