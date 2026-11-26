class_name Squircle
# Superellipse |x/a|^n + |y/b|^n = 1. Pure, no nodes.

const TILE := Vector2(64, 32)  # iso 2:1, same as the grid

static func points(center: Vector2, half_size: Vector2, n := 4.0, steps := 32) -> PackedVector2Array:
	var out := PackedVector2Array()
	var e := 2.0 / n
	for i in steps:
		var t := TAU * i / steps
		var c := cos(t)
		var s := sin(t)
		out.append(center + Vector2(half_size.x * signf(c) * pow(absf(c), e), half_size.y * signf(s) * pow(absf(s), e)))
	return out

## Grid coords (tiles, fractional ok) -> screen offset on the 2:1 ground plane.
static func to_screen(g: Vector2) -> Vector2:
	return Vector2((g.x - g.y) * TILE.x * 0.5, (g.x + g.y) * TILE.y * 0.5)

## Squircle footprint in grid space (half_tiles = half extent in tiles), projected onto the iso plane.
static func iso_points(center: Vector2, half_tiles: Vector2, n := 4.0, steps := 32) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points(Vector2.ZERO, half_tiles, n, steps):
		out.append(center + to_screen(p))
	return out
