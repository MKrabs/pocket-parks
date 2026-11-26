class_name GridView
extends Node2D
# Draws the ground island and reports hover/clicks in cell coordinates.

signal cell_hovered(cell: Vector2i)
signal cell_clicked(cell: Vector2i, button: MouseButton)

const SLAB := 18.0  # depth of the ground slab in px
const NONE := Vector2i(-1, -1)

var hovered := NONE

func _process(_delta: float) -> void:
	var c := IsoGrid.to_cell(get_local_mouse_position())
	if not IsoGrid.in_bounds(c):
		c = NONE
	if c != hovered:
		hovered = c
		if c != NONE:
			cell_hovered.emit(c)
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and hovered != NONE:
		cell_clicked.emit(hovered, mb.button_index)

## Squircle (n=6) centred at cell-space point c with half-size r, projected to screen.
func _squircle(c: Vector2, r: Vector2, n: float = 6.0, steps: int = 48) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps:
		var t := TAU * i / steps
		var u := signf(cos(t)) * pow(absf(cos(t)), 2.0 / n)
		var v := signf(sin(t)) * pow(absf(sin(t)), 2.0 / n)
		pts.append(IsoGrid.project(c + Vector2(u * r.x, v * r.y)))
	return pts

func _draw() -> void:
	var half := Vector2(IsoGrid.SIZE) / 2.0
	var mid := half - Vector2(0.5, 0.5)
	# Slab: extrude every outline segment downward; the top face drawn last hides the back ones.
	var top := _squircle(mid, half + Vector2(0.12, 0.12), 60.0, 240)
	var down := Vector2(0, SLAB)
	for i in top.size():
		var a := top[i]
		var b := top[(i + 1) % top.size()]
		var amount := 0.12 if a.x + b.x < 0 else 0.22
		draw_colored_polygon(PackedVector2Array([a, b, b + down, a + down]), Palette.shade(Palette.GRASS_DARK, amount))
	draw_colored_polygon(top, Palette.shade(Palette.GRASS_DARK, 0.05))
	for x in IsoGrid.SIZE.x:
		for y in IsoGrid.SIZE.y:
			var cell := Vector2i(x, y)
			var col := Palette.GRASS if (x + y) % 2 == 0 else Palette.GRASS_DARK
			if cell == hovered:
				col = Palette.SKY
			draw_colored_polygon(_squircle(Vector2(cell), Vector2(0.47, 0.47)), col)
