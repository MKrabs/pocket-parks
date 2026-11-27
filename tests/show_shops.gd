extends "res://tests/show_buildings.gd"
# Showcase: the 2×2 shops of every theme side by side, to judge that their silhouettes differ.
# ./gd shot shots/shops.png 1 res://tests/show_shops.gd

func ids() -> Array:
	return ["burger_diner", "cin_cafe", "conf_pavilion", "fest_hall", "fest_cake", "fest_tea", "amu_parlour"]
