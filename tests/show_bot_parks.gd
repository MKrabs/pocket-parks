extends SceneTree
# Showcase: a small zoo bot park and a large festival bot park side by side.
# ./gd shot shots/B1.png 1 res://tests/show_bot_parks.gd

func _init() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	var parks := [["zoo", 7, "small"], ["festival", 7, "large"]]
	for i in parks.size():
		var stage := Node2D.new()
		stage.scale = Vector2(0.6, 0.6)
		stage.position = Vector2(320 + i * 640, 200)
		stage.add_child(GridView.new())
		var view := ZooView.new()
		view.map = BotPark.generate(parks[i][0], parks[i][1], parks[i][2])
		stage.add_child(view)
		root.add_child.call_deferred(stage)
