class_name ZooView
extends Node2D
# Draws the map's buildings in iso depth order, plus the ghost preview of the selected building.

signal money_changed(money: int)

var map := ParkMap.new()
const LIFT := 4.0  # px a hovered building rises in Select mode

var selected := ""  # catalog id being placed, or "" in Select mode
var turn := 0  # quarter turns of the placement ghost (R / Shift+R)
var hovered := GridView.NONE
var lifted := GridView.NONE  # origin of the hovered building in Select mode
var ghost: BuildingView
var fx: Node2D  # where place/remove puffs go (main's Feedback); none in a visited park
var charm := false  # charm view (C): paths tinted by charm, other buildings faded
var drag_from := GridView.NONE  # painting a habitat: the cell the drag started on
var erasing := false  # that drag is a right-drag (removes cells)
var sim: ParkSim  # your park: placing and upgrading open construction sites; none in a visited park (instant)

func _ready() -> void:
	rebuild()

## Sites show their scaffold and progress; finished ones pop. Charm view tints paths and fades the rest.
func _process(_delta: float) -> void:
	if not sim:
		return
	for v: BuildingView in get_children():
		if v == ghost:
			continue
		var path: bool = Buildings.get_def(v.id)["role"] == "path"
		v.tint = CharmView.tint(sim.charm(v.origin)) if charm and path else Color(Palette.INK, 0.0)
		v.modulate.a = CharmView.FADE if charm and not path else 1.0
		var j := sim.job_at(v.origin)
		v.site_upgrade = not j.is_empty() and j["level"] > 1
		v.site = -1.0 if j.is_empty() else 1.0 - float(j["left"]) / j["total"]
	for o in sim.finished:
		var v := view_at(o)
		if v:
			if v.level != map.level(o):
				v.level = map.level(o)
				v.fresh = 0.0
				v.create_tween().tween_property(v, "fresh", 1.0, Motion.POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			Motion.pop(v)
	sim.finished.clear()

## Re-create one BuildingView per building, sorted back to front.
func rebuild() -> void:
	for c in get_children():
		c.queue_free()
	var origins: Array = map.buildings.keys()
	origins.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := ParkMap.depth(map.buildings[a], a, map.rotation(a))
		var db := ParkMap.depth(map.buildings[b], b, map.rotation(b))
		return da < db if da != db else a.x < b.x)
	for o: Vector2i in map.habitats:  # floors first: under every building and walker
		add_child(HabitatView.of(map.buildings[o], map.habitats[o]["cells"], o, "floor"))
	for o: Vector2i in origins:
		if map.habitats.has(o):
			var cs: Array = map.habitats[o]["cells"]
			var front := 0
			for c: Vector2i in cs:
				var f := HabitatView.of(map.buildings[o], cs, o, "fence")
				f.cell = c
				f.z_index = 2 * (c.x + c.y)
				add_child(f)
				front = maxi(front, c.x + c.y)
			var dome := HabitatView.of(map.buildings[o], cs, o, "dome")
			dome.z_index = 2 * front
			add_child(dome)
			continue
		var v := BuildingView.new(map.buildings[o])
		v.origin = o
		v.level = map.level(o)
		v.turn = map.rotation(o)
		v.position = IsoGrid.to_screen(o)
		v.z_index = 2 * ParkMap.depth(map.buildings[o], o, v.turn)  # WalkerView rows sit at the odd values
		add_child(v)
	ghost = null
	highlight(lifted)
	update_ghost()
	money_changed.emit(map.money)

## Show the buildings the sim has closed (wrecked by a hooligan) as their damaged variant.
func show_wrecked(closed: Dictionary) -> void:
	for v: BuildingView in get_children():
		if v != ghost and v.wrecked != closed.has(v.origin):
			v.wrecked = not v.wrecked

func update_ghost() -> void:
	if ghost:
		ghost.queue_free()
		ghost = null
	if selected == "" or hovered == GridView.NONE:
		return
	if painting():
		var r := drag_rect()
		var cs: Array = ParkMap.rect_cells(r)
		ghost = HabitatView.of(selected, cs, r.position, "all")
		var cost: int = Buildings.get_def(selected)["cost"]
		var ok: bool
		if drag_from == GridView.NONE:
			ok = true
			ghost.label = "$%d / cell · drag to paint" % cost
		elif erasing:
			ok = not map.unpaint_plan(r).is_empty()
			ghost.label = "Remove %d cells" % cs.size() if ok else "Habitats stay in one piece, 4+ cells"
		else:
			var n := map.paint_cells(selected, r).size()
			ok = map.can_paint(selected, r)
			ghost.label = "%d cells · $%d ($%d / cell)" % [n, n * cost, cost] if n > 0 else "Can't paint here"
		ghost.z_index = 1000
		ghost.position = IsoGrid.to_screen(r.position)
		ghost.modulate = Color(Palette.CORAL if not ok or erasing else Palette.CREAM, 0.7)
		add_child(ghost)
		return
	ghost = BuildingView.new(selected)
	ghost.turn = turn
	ghost.z_index = 1000  # above every building and walker
	ghost.position = IsoGrid.to_screen(hovered)
	ghost.modulate = Color(Palette.CREAM if map.can_place(selected, hovered, turn) else Palette.CORAL, 0.6)
	ghost.label = "Buy this land first" if map.on_unowned(selected, hovered, turn) else BuildBar.shed_text(map.shed_needs(selected))
	add_child(ghost)

## A habitat fence is picked: the grid paints rectangles by dragging instead of placing.
func painting() -> bool:
	return Buildings.get_def(selected).has("habitat")

## The dragged rectangle (corner where the drag started to the hovered cell), or just the hovered cell.
func drag_rect() -> Rect2i:
	var a := hovered if drag_from == GridView.NONE else drag_from
	var b := hovered if hovered != GridView.NONE else a
	return Rect2i(Vector2i(mini(a.x, b.x), mini(a.y, b.y)), (a - b).abs() + Vector2i.ONE)

## Mouse down on `cell` while painting: left paints, right (erase) removes.
func drag_start(cell: Vector2i, erase: bool) -> void:
	drag_from = cell
	erasing = erase
	update_ghost()

## Mouse up: paint or remove the dragged rectangle. True if the map changed.
func drag_end() -> bool:
	if drag_from == GridView.NONE:
		return false
	var r := drag_rect()
	drag_from = GridView.NONE
	var done: bool
	if erasing:
		done = sim.unpaint(r) if sim else not map.unpaint(r).is_empty()
	else:
		done = sim.paint(selected, r) if sim else map.paint(selected, r).x >= 0
	if done:
		rebuild()
		if fx:
			Motion.puff_at(fx, IsoGrid.project(Vector2(r.position) + Vector2(r.size - Vector2i.ONE) * 0.5), Motion.DUST_SIZE)
	else:
		update_ghost()
	return done

## Turn the placement ghost a quarter turn (dir 1 = clockwise, -1 = back).
func rotate_ghost(dir: int) -> void:
	turn = posmod(turn + dir, 4)
	update_ghost()

func select(id: String) -> void:
	selected = id
	drag_from = GridView.NONE
	update_ghost()

func on_hover(cell: Vector2i) -> void:
	hovered = cell
	update_ghost()

## Lift the building at `origin` a little (Select-mode hover); NONE drops it back.
func highlight(origin: Vector2i) -> void:
	lifted = origin
	for v: BuildingView in get_children():
		if v != ghost:
			v.position = IsoGrid.to_screen(v.origin) - Vector2(0, LIFT if v.origin == origin else 0.0)

## Place the selected building at `cell`. True if it was placed.
func on_click(cell: Vector2i) -> bool:
	if selected == "" or not (sim.build(selected, cell, turn) if sim else map.place(selected, cell, turn)):
		return false
	rebuild()
	Motion.squish(view_at(cell))
	if fx:
		Motion.puff_at(fx, Feedback.base_of(selected, cell, turn), Motion.DUST_SIZE)
	return true

func upgrade(origin: Vector2i) -> bool:
	if sim:
		if not sim.upgrade(origin):
			return false
		rebuild()
		Motion.bounce(view_at(origin))  # the scaffold goes up; the new level pops in when it's done
		return true
	if not map.upgrade(origin):
		return false
	rebuild()
	var v := view_at(origin)
	Motion.bounce(v)
	v.fresh = 0.0
	v.create_tween().tween_property(v, "fresh", 1.0, Motion.POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return true

## Remove the building at `origin` for its refund; a copy shrinks into a puff.
func demolish(origin: Vector2i) -> bool:
	var gone := view_at(origin)
	if not (sim.demolish(origin) if sim else map.remove_at(origin)):
		return false
	rebuild()
	if fx and gone:
		var v := BuildingView.new(gone.id)
		v.level = gone.level
		v.turn = gone.turn
		v.position = gone.position
		fx.add_child(v)
		Motion.vanish(v)
		Motion.puff_at(fx, Feedback.base_of(v.id, origin, v.turn), Motion.DUST_SIZE)
	return true

## The building view at a building origin, or null.
func view_at(origin: Vector2i) -> BuildingView:
	for v: BuildingView in get_children():
		if v != ghost and v.origin == origin and not v.is_queued_for_deletion():
			return v
	return null
