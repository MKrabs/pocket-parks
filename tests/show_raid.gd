extends SceneTree
# ./gd shot shots/R2.png 30 res://tests/show_raid.gd: the main scene, straight inside a raid on a festival park.

func _init() -> void:
	var main: Node = load("res://main.tscn").instantiate()
	main.debug_raid = "raid"
	root.add_child.call_deferred(main)
