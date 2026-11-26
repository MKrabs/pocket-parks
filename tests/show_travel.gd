extends SceneTree
# ./gd shot shots/A1-in.png 1 res://tests/show_travel.gd: the cloud transition to the first offer, slowed so
# the shot length picks the moment: 1 s = clouds closing, 2 s = full cover with the name, 3 s = clouds parting.

const START := 0.0  # transition time at 0 s
const SLOW := 0.31  # transition seconds per shot second

func _init() -> void:
	var main: Node = load("res://main.tscn").instantiate()
	root.add_child.call_deferred(main)
	await process_frame
	var tw: Tween = main.travel_to(main.offers[0])
	tw.custom_step(START)
	tw.set_speed_scale(SLOW)
