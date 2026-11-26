class_name Motion
# The game's motion language: small Tween helpers on drawn nodes. Every helper returns its Tween.

# --- Tuning (owner tunes these by feel) ---
const POP_TIME := 0.25
const VANISH_TIME := 0.15
const VANISH_SCALE := 0.4  # shrinks to this while fading
const SQUISH_TIME := 0.25
const SQUISH := Vector2(1.18, 0.82)  # squash, then the inverse stretch
const SHAKE_TIME := 0.3
const SHAKE_STEPS := 6
const FLY_TIME := 0.5
const PUFF_TIME := 0.6  # puff_at: pop, then grow and fade
const PUFF_GROW := 1.25
const BOUNCE := 1.08  # bounce: grow by this, then settle back
const BOUNCE_TIME := 0.3
# Gameplay feedback (scripts/feedback.gd and the views it pokes):
const CRIME_SHAKE := 3.0  # px
const TILT_TIME := 0.5  # wrecked: grey tilt eases in
const DEBRIS := 3  # wrecked: small puffs around the base
const DEBRIS_SIZE := 18.0
const LITTER_PUFF := 14.0
const LOOT_FLY := Vector2(40, -48)  # robbed: the coin flies this far from the shop top
const GLINT_HOLD := 0.2  # spied: glint stays this long after popping in
const MONEY_EVERY := 1.0  # at most one floating "+$" per building per this many seconds (amounts summed)
const MONEY_RISE := 26.0
const MONEY_TIME := 1.3
const COUNT_TIME := 0.4  # HUD money chip counts to the new value
const ARREST_PUFF := 26.0
const HOP := 7.0  # guard hop height, px
const HOP_TIME := 0.3
const DUST_SIZE := 34.0  # placing / removing a building
# Cloud transition (scripts/cloud_transition.gd), seconds from its start:
const TRAVEL_ZOOM := 0.75 / 0.92  # zoom factor at the widest point (0.92 → 0.75 at the default zoom)
const TRAVEL_ZOOM_TIME := 0.4  # zoom out, ease in
const COVER_AT := 0.2  # clouds start rolling in
const COVER_TIME := 0.5
const HOLD_TIME := 0.3  # full cover with the name; the park swap happens halfway
const PART_TIME := 0.6  # clouds part while the camera zooms back with a slight overshoot
const CLOUD_LAYERS := 3
const LAYER_TRAVEL := [1.6, 1.9, 2.2]  # screen widths each layer travels on the way in, back → front (parallax)
const LAYER_DARK := 0.05  # each layer further back is shaded this much more
const TITLE_SIZE := 72
const TITLE_FADE := 0.1

static func pop(node: CanvasItem) -> Tween:
	node.scale = Vector2.ZERO
	var t := node.create_tween()
	t.tween_property(node, "scale", Vector2.ONE, POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return t

static func vanish(node: CanvasItem, free := true) -> Tween:
	var t := node.create_tween().set_parallel()
	t.tween_property(node, "scale", node.scale * VANISH_SCALE, VANISH_TIME).set_ease(Tween.EASE_IN)
	t.tween_property(node, "modulate:a", 0.0, VANISH_TIME)
	if free:
		t.chain().tween_callback(node.queue_free)
	return t

static func squish(node: CanvasItem) -> Tween:
	var s: Vector2 = node.scale
	var t := node.create_tween().set_trans(Tween.TRANS_SINE)
	t.tween_property(node, "scale", s * SQUISH, SQUISH_TIME * 0.3)
	t.tween_property(node, "scale", s * Vector2(SQUISH.y, SQUISH.x), SQUISH_TIME * 0.3)
	t.tween_property(node, "scale", s, SQUISH_TIME * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return t

static func bounce(node: CanvasItem) -> Tween:
	var s: Vector2 = node.scale
	var t := node.create_tween().set_trans(Tween.TRANS_SINE)
	t.tween_property(node, "scale", s * BOUNCE, BOUNCE_TIME * 0.35).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "scale", s, BOUNCE_TIME * 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return t

## Decaying jitter around the current position, ending back on it.
static func shake(node: CanvasItem, strength: float) -> Tween:
	var p: Vector2 = node.position
	var t := node.create_tween()
	for i in SHAKE_STEPS:
		var k := strength * (1.0 - float(i) / SHAKE_STEPS)
		t.tween_property(node, "position", p + Vector2(randf_range(-k, k), randf_range(-k, k)), SHAKE_TIME / (SHAKE_STEPS + 1))
	t.tween_property(node, "position", p, SHAKE_TIME / (SHAKE_STEPS + 1))
	return t

static func fly_to(node: CanvasItem, to_pos: Vector2, then := Callable()) -> Tween:
	var t := node.create_tween()
	t.tween_property(node, "position", to_pos, FLY_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if then.is_valid():
		t.tween_callback(then)
	return t

## A one-off puff at `pos` in `parent` that pops, swells and fades away.
static func puff_at(parent: Node, pos: Vector2, size: float) -> Tween:
	var p := Puff.new()
	p.size = size
	p.seed = randi()
	p.position = pos
	parent.add_child(p)
	var t := pop(p)
	t.tween_property(p, "scale", Vector2.ONE * PUFF_GROW, PUFF_TIME - POP_TIME)
	t.parallel().tween_property(p, "modulate:a", 0.0, PUFF_TIME - POP_TIME).set_ease(Tween.EASE_IN)
	t.tween_callback(p.queue_free)
	return t
