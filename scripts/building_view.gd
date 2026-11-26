class_name BuildingView
extends Node2D
# Draws one catalog building. Node origin = centre of the building's origin cell.

var id: String

func _init(building_id: String) -> void:
	id = building_id

func _draw() -> void:
	var b: Dictionary = Buildings.CATALOG[id]
	var fp: Vector2i = b["footprint"]
	var mid := Vector2(fp.x - 1, fp.y - 1) * 0.5  # footprint centre in grid coords
	for p in b["parts"]:
		var foot := Squircle.iso_points(Squircle.to_screen(mid + p["at"]), p["half"], 4.0, 48)
		block(self, foot, p["h"], p["z"], p["color"])

## Extruded squircle: sides for edges facing the viewer, then the top face lifted by z + h.
static func block(ci: CanvasItem, foot: PackedVector2Array, h: float, z: float, c: Color) -> void:
	var lift := Vector2(0, -z)
	var up := Vector2(0, -z - h)
	if h > 0.0:
		for i in foot.size():
			var a := foot[i]
			var b := foot[(i + 1) % foot.size()]
			var nrm := (b - a).orthogonal()  # outward normal for a clockwise-on-screen loop
			if nrm.y <= 0.0:
				continue  # faces away from the camera
			# Left-facing sides lighter, right-facing darker, blended for a soft round look.
			var amt := lerpf(0.12, 0.22, clampf(nrm.normalized().x * 0.5 + 0.5, 0.0, 1.0))
			ci.draw_colored_polygon(PackedVector2Array([a + lift, b + lift, b + up, a + up]), Palette.shade(c, amt))
	var top := PackedVector2Array()
	for p in foot:
		top.append(p + up)
	ci.draw_colored_polygon(top, c)
