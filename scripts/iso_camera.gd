class_name IsoCamera
extends Camera2D
# Pan with right/middle drag or WASD/arrows, zoom with the wheel.

const PAN_SPEED := 600.0  # screen px per second
const ZOOM_MIN := 0.5
const ZOOM_MAX := 2.5
const ZOOM_STEP := 1.1

var dragging := false

func _process(delta: float) -> void:
	var dir := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)))
	position += dir * PAN_SPEED * delta / zoom.x

func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb:
		if mb.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			dragging = mb.pressed
		elif mb.pressed and mb.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var f := ZOOM_STEP if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / ZOOM_STEP
			zoom = Vector2.ONE * clampf(zoom.x * f, ZOOM_MIN, ZOOM_MAX)
	var mm := event as InputEventMouseMotion
	if mm and dragging:
		position -= mm.relative / zoom.x
