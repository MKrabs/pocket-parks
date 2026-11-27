extends SceneTree
# Showcase: the start habitat's card, red pandas with a shelter and a little tree cover: a partly met checklist.
# ./gd shot shots/HAB2-card.png 3 res://tests/show_habitat_card.gd

var main: Node2D
var _done := false

func _initialize() -> void:
	RenderingServer.set_default_clear_color(Palette.CREAM)
	main = load("res://main.gd").new()
	main.bots = false
	root.add_child.call_deferred(main)

func _process(_delta: float) -> bool:
	if _done or not main.is_node_ready():
		return false
	_done = true
	var o := Vector2i(6, 8)
	main.zoo.map.habitats[o]["items"] = [{"id": "tree", "cells": [Vector2i(6, 8), Vector2i(7, 8)]},
		{"id": "shelter", "cells": [Vector2i(8, 8)]}]
	main.zoo.map.habitats[o]["count"] = 3
	main.zoo.rebuild()
	main.advance(100)
	main.card.show_building(o)
	return false
