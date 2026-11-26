extends SceneTree
# ./gd shot shots/A1-puffs.png 1 res://tests/show_puffs.gd: standalone puffs at different sizes on cream.

func _init() -> void:
	var bg := Node2D.new()
	bg.draw.connect(func() -> void: bg.draw_rect(Rect2(0, 0, 1280, 720), Palette.CREAM))
	root.add_child.call_deferred(bg)
	var x := 60.0
	for s in [70.0, 120.0, 190.0, 270.0, 350.0]:
		var p := Puff.new()
		p.size = s
		p.seed = int(s)
		p.position = Vector2(x + s / 2.0, 380)
		x += s + 40.0
		bg.add_child(p)
