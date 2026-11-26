extends SceneTree
# ./gd shot shots/picker.png 1 res://tests/show_raid_picker.gd: the main scene with the raid picker open.

func _init() -> void:
	var main: Node = load("res://main.tscn").instantiate()
	main.debug_raid = "picker"
	root.add_child.call_deferred(main)
