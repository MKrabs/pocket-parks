extends SceneTree
# Showcase: gate, stage, food truck, grill and enclosure in all 4 turns (columns 0-3).
# ./gd shot shots/X4.png 1 res://tests/show_rotation.gd

func _init() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	var stage := Node2D.new()
	stage.scale = Vector2(1.2, 1.2)
	root.add_child.call_deferred(stage)
	var rows := {"zoo_gate": 60.0, "fest_stage": 160.0, "fest_truck": 260.0, "fest_grill": 360.0}
	for id: String in rows:
		for t in 4:
			var v := BuildingView.new(id)
			v.turn = t
			var fp := ParkMap.size(id, t)
			# Centre each footprint on its column slot.
			v.position = Vector2(130 + t * 260, rows[id]) - IsoGrid.project(Vector2(fp - Vector2i.ONE) * 0.5)
			stage.add_child(v)
