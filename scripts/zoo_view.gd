class_name ZooView
extends Node2D
# Draws the map's buildings in iso depth order, plus the ghost preview of the selected building.

signal money_changed(money: int)

var map := ParkMap.new()
var selected := ""  # catalog id, or "" for the eraser
var hovered := GridView.NONE
var ghost: BuildingView

func _ready() -> void:
	rebuild()

## Re-create one BuildingView per building, sorted back to front.
func rebuild() -> void:
	for c in get_children():
		c.queue_free()
	var origins: Array = map.buildings.keys()
	origins.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := ParkMap.depth(map.buildings[a], a)
		var db := ParkMap.depth(map.buildings[b], b)
		return da < db if da != db else a.x < b.x)
	for o: Vector2i in origins:
		var v := BuildingView.new(map.buildings[o])
		v.origin = o
		v.level = map.level(o)
		v.position = IsoGrid.to_screen(o)
		v.z_index = 2 * ParkMap.depth(map.buildings[o], o)  # WalkerView rows sit at the odd values
		add_child(v)
	ghost = null
	update_ghost()
	money_changed.emit(map.money)

## Grey out the buildings the sim has closed (wrecked by a hooligan).
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
	var at := hovered
	var ok := false
	if selected == BuildBar.UPGRADE:  # ghost = the hovered building one level up, with its price
		if not map.occupied.has(hovered):
			return
		at = map.occupied[hovered]
		ghost = BuildingView.new(map.buildings[at])
		ghost.level = mini(map.level(at) + 1, Buildings.MAX_LEVEL)
		var cost := map.upgrade_cost(at)
		ghost.label = "$%d" % cost if cost >= 0 else "max"
		ok = map.can_upgrade(at)
	else:
		ghost = BuildingView.new(selected)
		ok = map.can_place(selected, hovered)
	ghost.z_index = 1000  # above every building and walker
	ghost.position = IsoGrid.to_screen(at)
	ghost.modulate = Color(Palette.CREAM if ok else Palette.CORAL, 0.6)
	add_child(ghost)

func select(id: String) -> void:
	selected = id
	update_ghost()

func on_hover(cell: Vector2i) -> void:
	hovered = cell
	update_ghost()

func on_click(cell: Vector2i, button: MouseButton) -> void:
	if button == MOUSE_BUTTON_RIGHT or (button == MOUSE_BUTTON_LEFT and selected == ""):
		if map.remove_at(cell):
			rebuild()
	elif button == MOUSE_BUTTON_LEFT and selected == BuildBar.UPGRADE:
		if map.occupied.has(cell) and map.upgrade(map.occupied[cell]):
			rebuild()
	elif button == MOUSE_BUTTON_LEFT and map.place(selected, cell):
		rebuild()
