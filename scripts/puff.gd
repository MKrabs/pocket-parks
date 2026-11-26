class_name Puff
extends Node2D
# The signature cloud puff: a flat-bottomed cluster of overlapping squircles with a darker underside.
# Drawn around (0, 0); `size` is the width in px, `seed` picks the bumps, `dark` shades the whole puff.

const ROUND := 2.8  # superellipse exponent: softer than the n=4 buildings, so puffs read as cloud, not boxes

var size := 120.0
var seed := 0
var dark := 0.0

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var w := size
	var shapes: Array[Rect2] = [Rect2(Vector2(0, w * 0.1), Vector2(w * 0.5, w * 0.15))]  # centre, half size
	var bumps := rng.randi_range(3, 4)
	for i in bumps:
		var t := (i + 0.5) / bumps - 0.5  # -0.5 .. 0.5 across the puff
		var r := w * rng.randf_range(0.2, 0.25) * (1.0 - absf(t) * 0.7)  # biggest in the middle
		shapes.append(Rect2(Vector2(t * w * 0.7 + rng.randf_range(-0.03, 0.03) * w, w * 0.1 - r * 0.75), Vector2(r, r * 0.9)))
	var under := Palette.shade(Palette.CLOUD_SHADOW, dark)
	var top := Palette.shade(Palette.CLOUD, dark)
	for s in shapes:
		draw_colored_polygon(Squircle.points(s.position + Vector2(0, w * 0.05), s.size, ROUND, 48), under)
	for s in shapes:
		draw_colored_polygon(Squircle.points(s.position, s.size, ROUND, 48), top)
