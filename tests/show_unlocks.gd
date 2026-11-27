extends SceneTree
# Showcase: the build bar at park level 1, Attractions tab, the habitat item stepped to Glass (locked, greyed).
# ./gd shot shots/unlocks.png 1 res://tests/show_unlocks.gd

func _init() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	var bar := BuildBar.new()
	bar.map = ParkMap.new()
	root.add_child.call_deferred(bar)
	bar.ready.connect(func() -> void:
		bar.show_tab("Attractions")
		for b: Button in bar.row.get_children():
			if b.get_meta("id") == "habitat":
				bar.step_variant(b, 1))
