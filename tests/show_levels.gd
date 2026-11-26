extends SceneTree
# Showcase: every upgradable building at levels 1, 2, 3. ./gd shot shots/U1.png 1 res://tests/show_levels.gd
# Zoo on the left, festival on the right, one building per row.

func _init() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	var stage := Node2D.new()
	root.add_child.call_deferred(stage)
	var col := 0
	for theme: String in ["zoo", "festival"]:
		Buildings.use(theme)
		var y := 40.0
		for id: String in Buildings.ids():
			if not Buildings.upgradable(id):
				continue
			var fp: Vector2i = Buildings.get_def(id)["footprint"]
			y += 40 + (fp.x + fp.y) * 15
			for lv in range(1, 4):
				var v := BuildingView.new(id)
				v.level = lv
				v.position = Vector2(110 + col * 640 + (lv - 1) * 200 - (fp.x - fp.y) * 16, y - (fp.x + fp.y - 2) * 16)
				stage.add_child(v)
			y += (fp.x + fp.y) * 15
		col += 1
	var ghost := BuildingView.new("snack_stand")  # the upgrade tool's hover: next level + price
	ghost.level = 2
	ghost.label = "$60"
	ghost.modulate = Color(Palette.CREAM, 0.6)
	ghost.position = Vector2(110, 660)
	stage.add_child(ghost)
