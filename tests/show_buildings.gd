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
	for id: String in ids():
		var v := BuildingView.new(id)
		var fp: Vector2i = Buildings.get_def(id)["footprint"]
		v.position = Vector2(x + (fp.y - 1) * 32, 220 - (fp.y - 1) * 16)  # footprint reaches (fp.y - 1) * 32 px left
		stage.add_child(v)
		x += 20 + (fp.x + fp.y) * 32
