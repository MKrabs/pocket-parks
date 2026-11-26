class_name CloudTransition
extends CanvasLayer
# Travel between parks: the camera zooms out, layers of puffs roll in, the destination's name holds on the
# clouds while `swap` runs, then the clouds part as the camera zooms back. A click or key skips to the end;
# world input is blocked while it runs. Timing lives in Motion's const block.

var tween: Tween
var _clouds := Node2D.new()
var _title := Label.new()

func _ready() -> void:
	layer = 100
	add_child(_clouds)
	var font := SystemFont.new()
	font.font_names = ["Nunito", "Quicksand", "Varela Round", "Comfortaa", "Arial Rounded MT Bold", "sans-serif"]
	font.font_weight = 800
	_title.add_theme_font_override("font", font)
	_title.add_theme_font_size_override("font_size", Motion.TITLE_SIZE)
	_title.add_theme_color_override("font_color", Palette.INK)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	visible = false

func running() -> bool:
	return tween != null and tween.is_running()

## Play the transition to `title`; `swap` runs once at full cover. Rightward when leaving home.
func play(cam: Camera2D, title: String, swap: Callable, rightward := true) -> Tween:
	skip()
	var view := get_viewport().get_visible_rect().size
	var dir := 1.0 if rightward else -1.0
	var z0 := cam.zoom
	var covered := Motion.COVER_AT + Motion.COVER_TIME
	var part_at := covered + Motion.HOLD_TIME
	_title.text = title
	_title.modulate.a = 0.0
	visible = true
	tween = create_tween().set_parallel()
	tween.tween_property(cam, "zoom", z0 * Motion.TRAVEL_ZOOM, Motion.TRAVEL_ZOOM_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	for i in Motion.CLOUD_LAYERS:  # back to front
		var travel: float = view.x * Motion.LAYER_TRAVEL[i]
		for side in [-1.0, 1.0]:  # left and right half of the cover, so the clouds can part
			var half := _half(view, side, i)
			half.position.x = -dir * travel
			tween.tween_property(half, "position:x", 0.0, Motion.COVER_TIME).set_delay(Motion.COVER_AT) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(half, "position:x", side * travel * 0.7, Motion.PART_TIME).set_delay(part_at) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_title, "modulate:a", 1.0, Motion.TITLE_FADE).set_delay(covered - Motion.TITLE_FADE)
	tween.tween_property(_title, "modulate:a", 0.0, Motion.TITLE_FADE).set_delay(part_at)
	tween.tween_callback(swap).set_delay(covered + Motion.HOLD_TIME / 2.0)
	tween.tween_property(cam, "zoom", z0, Motion.PART_TIME).set_delay(part_at).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_end).set_delay(part_at + Motion.PART_TIME)
	return tween

## Jump to the end: the swap (if not yet done) and the final camera zoom still happen, once.
func skip() -> void:
	if running():
		tween.custom_step(60.0)

func _end() -> void:
	visible = false
	for c in _clouds.get_children():
		c.queue_free()

## Half the cover (side -1 left, 1 right) for layer `depth` (0 = back): a jittered grid of big puffs.
func _half(view: Vector2, side: float, depth: int) -> Node2D:
	var half := Node2D.new()
	_clouds.add_child(half)
	var rng := RandomNumberGenerator.new()
	rng.seed = depth * 2 + int(side > 0)
	var size := view.y * (0.5 + 0.08 * depth)
	var step := size * (0.42 + 0.14 * depth)  # back layer dense (the cover), front layers sparser (the bumps)
	var x0 := view.x * 0.5 - step * 0.5 if side > 0 else -size * 0.4
	var x1 := view.x + size * 0.4 if side > 0 else view.x * 0.5 + step * 0.5
	var y := -size * 0.1
	var row := 0
	while y < view.y + size * 0.25:
		var x := x0 + (step * 0.5 if row % 2 else 0.0)
		while x < x1:
			var p := Puff.new()
			p.size = size * rng.randf_range(0.85, 1.15)
			p.seed = rng.randi()
			p.dark = Motion.LAYER_DARK * (Motion.CLOUD_LAYERS - 1 - depth)  # back layers a touch darker
			p.position = Vector2(x, y) + Vector2(rng.randf_range(-0.1, 0.1), rng.randf_range(-0.1, 0.1)) * size
			half.add_child(p)
			x += step
		y += step * 0.7
		row += 1
	return half

func _input(event: InputEvent) -> void:
	if not running():
		return
	get_viewport().set_input_as_handled()
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed() and not event.is_echo():
		skip()
