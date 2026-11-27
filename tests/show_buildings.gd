extends SceneTree
# Showcase: all buildings of one theme on cream. ./gd shot shots/zoo.png 1 res://tests/show_buildings.gd
# (show_festival.gd overrides theme()).

func theme() -> String:
	return "zoo"

func ids() -> Array:
	return Buildings.ids()

func _init() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	Buildings.use(theme())
	var stage := Node2D.new()
	stage.scale = Vector2(1.6, 1.6)  # enlarged so the shapes are easy to judge
	root.add_child.call_deferred(stage)
	var x := 40.0
	var y := 120.0
	for id: String in ids():
		var fp: Vector2i = Buildings.get_def(id)["footprint"]
		var cells: Array = []
		if Buildings.get_def(id).has("habitat"):  # painted: show a small 3×2 patch
			fp = Vector2i(3, 2)
			for c in 6:
				cells.append(Vector2i(c % 3, c / 3))
		if x + (fp.x + fp.y) * 32 > 780:  # wrap to the next row (the stage is 800 px wide at 1.6×)
			x = 40.0
			y += 130.0
		var v: BuildingView = HabitatView.of(id, cells, Vector2i.ZERO, "all") if cells else BuildingView.new(id)
		v.position = Vector2(x + (fp.y - 1) * 32, y - (fp.y - 1) * 16)  # footprint reaches (fp.y - 1) * 32 px left
		stage.add_child(v)
		x += 20 + (fp.x + fp.y) * 32
