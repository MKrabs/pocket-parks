extends Node2D
# Entry point. Build child nodes in code here; keep main.tscn as the only scene file.

func _ready() -> void:
	add_child(GridView.new())
	var cam := IsoCamera.new()
	# centre of the board top, nudged down by half the slab depth
	cam.position = IsoGrid.project(Vector2(IsoGrid.SIZE) / 2.0 - Vector2(0.5, 0.5)) + Vector2(0, GridView.SLAB / 2)
	add_child(cam)
