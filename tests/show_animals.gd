extends SceneTree
# Showcase: the 9 animals, big, by category (rows: water, highlands, birds), each walking, resting, swimming, hiding.
# ./gd shot shots/HAB2-animals.png 1 res://tests/show_animals.gd

func _initialize() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	var n := Node2D.new()
	n.draw.connect(func() -> void:
		var i := 0
		for a: String in Animals.ALL:
			var at := Vector2(110 + (i % 3) * 400, 170 + (i / 3) * 210)
			n.draw_string(Palette.FONT_BOLD, at + Vector2(-60, 40), Animals.ALL[a]["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Palette.INK)
			Animals.draw(n, a, at, 1.0, "walk", 0.2, 4.0)
			var p := 0
			for pose: String in ["rest", "swim", "hide"]:
				Animals.draw(n, a, at + Vector2(150 + p * 70, 0), -1.0, pose, 0.0, 2.0)
				p += 1
			i += 1)
	root.add_child.call_deferred(n)
