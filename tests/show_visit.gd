extends SceneTree
# ./gd shot shots/N2.png 20 res://tests/show_visit.gd: the main scene, visiting a festival park with people
# sent in, zoomed in so the markers above your people read.

func _init() -> void:
	var main: Node = load("res://main.tscn").instantiate()
	main.debug_visit = true
	root.add_child.call_deferred(main)
	await process_frame
	for c in main.get_children():
		if c is IsoCamera:
			c.zoom = Vector2.ONE * 1.8
