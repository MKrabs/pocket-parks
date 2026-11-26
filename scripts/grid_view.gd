class_name GridView
extends Node2D
# Draws the ground island and reports hover/clicks in cell coordinates.

signal cell_hovered(cell: Vector2i)
signal cell_clicked(cell: Vector2i, button: MouseButton)

const SLAB := 18.0  # depth of the ground slab in px
const NONE := Vector2i(-1, -1)

var hovered := NONE
var tile_hover := false:  # tint the hovered tile (place mode only; Select mode lifts buildings instead)
	set(on):
		tile_hover = on
		queue_redraw()

func _process(_delta: float) -> void:
	var c := IsoGrid.to_cell(get_local_mouse_position())
	if not IsoGrid.in_bounds(c):
		c = NONE
	if c != hovered:
		hovered = c
		cell_hovered.emit(c)  # NONE when the mouse leaves the grid
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and hovered != NONE:
		cell_clicked.emit(hovered, mb.button_index)

func _draw() -> void:
	var half := Vector2(IsoGrid.SIZE) / 2.0
	var mid := half - Vector2(0.5, 0.5)
	# Slab: extrude every outline segment downward; the top face drawn last hides the back ones.
	var top := Squircle.iso_points(IsoGrid.project(mid), half + Vector2(0.12, 0.12), 60.0, 240)
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
			if cell == hovered and tile_hover:
				col = Palette.SKY
			draw_colored_polygon(Squircle.iso_points(IsoGrid.to_screen(cell), Vector2(0.47, 0.47), 6.0, 48), col)
