class_name IsoCamera
extends Camera2D
# Pan with middle drag, WASD/arrows or a two-finger trackpad swipe. Zoom with the mouse wheel,
# Ctrl+wheel or a pinch.

const PAN_SPEED := 600.0  # screen px per second
const ZOOM_MIN := 0.5
const ZOOM_MAX := 2.5
const ZOOM_STEP := 1.1
# Trackpad feel (owner tunes these):
const PAN_STEP := 12.0  # screen px per unit of wheel `factor` from a two-finger swipe (Linux sends bursts of small factors)
const GESTURE_PAN_SCALE := 8.0  # screen px per unit of InputEventPanGesture.delta (macOS etc.)
const TRACKPAD_FACTOR_MAX := 0.9  # wheel factors below this are a trackpad swipe, not a mouse notch

var dragging := false

func _process(delta: float) -> void:
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return  # typing a chat line or an address, not panning
	var dir := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)))
	position += dir * PAN_SPEED * delta / zoom.x

# Event → {"pan": world offset to add to position, "zoom": factor to multiply zoom by}. Pure, so tests reach it.
static func input_action(event: InputEvent, cur_zoom: float) -> Dictionary:
	var pan := Vector2.ZERO
	var z := 1.0
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		var b := mb.button_index
		var horiz := b in [MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]
		var vert := b in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]
		var swipe := not mb.ctrl_pressed and (horiz or (mb.factor > 0.0 and mb.factor < TRACKPAD_FACTOR_MAX))
		if (horiz or vert) and swipe:
			var amount := (mb.factor if mb.factor > 0.0 else 1.0) * PAN_STEP / cur_zoom
			var dirs := {MOUSE_BUTTON_WHEEL_UP: Vector2.UP, MOUSE_BUTTON_WHEEL_DOWN: Vector2.DOWN,
				MOUSE_BUTTON_WHEEL_LEFT: Vector2.LEFT, MOUSE_BUTTON_WHEEL_RIGHT: Vector2.RIGHT}
			pan = dirs[b] * amount
		elif vert:
			z = ZOOM_STEP if b == MOUSE_BUTTON_WHEEL_UP else 1.0 / ZOOM_STEP
	var pg := event as InputEventPanGesture
	if pg:
		pan = pg.delta * GESTURE_PAN_SCALE / cur_zoom
	var mg := event as InputEventMagnifyGesture
	if mg and mg.factor > 0.0:
		z = mg.factor
	return {"pan": pan, "zoom": z}

func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_MIDDLE:  # right click is the eraser
		dragging = mb.pressed
	var mm := event as InputEventMouseMotion
	if mm and dragging:
		position -= mm.relative / zoom.x
	var a := input_action(event, zoom.x)
	position += a.pan
	if a.zoom != 1.0:
		zoom = Vector2.ONE * clampf(zoom.x * a.zoom, ZOOM_MIN, ZOOM_MAX)
