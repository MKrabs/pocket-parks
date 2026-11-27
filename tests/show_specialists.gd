extends "res://tests/show_buildings.gd"
# Showcase: the specialist-only zoo buildings. ./gd shot shots/B2.png 1 res://tests/show_specialists.gd

func ids() -> Array:
	return ["fountain"]  # specialist-only habitats are painted: see show_shapes.gd
