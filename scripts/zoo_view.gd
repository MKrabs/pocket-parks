class_name ZooView
extends Node2D
# Draws the map's buildings in iso depth order, plus the ghost preview of the selected building.

signal money_changed(money: int)

var map := ZooMap.new()
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
		var da := ZooMap.depth(map.buildings[a], a)
		var db := ZooMap.depth(map.buildings[b], b)
		return da < db if da != db else a.x < b.x)
	for o: Vector2i in origins:
		var v := BuildingView.new(map.buildings[o])
		v.position = IsoGrid.to_screen(o)
		add_child(v)
	ghost = null
	update_ghost()
	money_changed.emit(map.money)

func update_ghost() -> void:
	if ghost and (ghost.id != selected or hovered == GridView.NONE):
		ghost.queue_free()
		ghost = null
	if selected == "" or hovered == GridView.NONE:
		return
	if not ghost:
		ghost = BuildingView.new(selected)
		add_child(ghost)  # last child = drawn on top
	ghost.position = IsoGrid.to_screen(hovered)
	var tint := Palette.CORAL if not map.can_place(selected, hovered) else Palette.CREAM
	ghost.modulate = Color(tint, 0.6)

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
	elif button == MOUSE_BUTTON_LEFT and map.place(selected, cell):
		rebuild()
