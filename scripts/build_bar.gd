class_name BuildBar
extends CanvasLayer
# Bottom bar: one button per catalog building plus an eraser. Money lives in the Hud.

signal picked(id: String)  # "" = eraser, UPGRADE = upgrade tool

const RADIUS := 14
const UPGRADE := "@upgrade"

var row := HBoxContainer.new()
var stolen: Array[String] = []  # blueprints spies brought home, offered in every theme

static func box(c: Color, radius: int = RADIUS) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(radius)
	s.corner_detail = 12
	s.set_content_margin_all(10)
	s.border_color = Palette.shade(c, 0.12)
	s.set_border_width_all(2)
	return s

func _ready() -> void:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", box(Palette.STONE, 20))
	row.add_theme_constant_override("separation", 8)
	bar.add_child(row)
	add_child(bar)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	fill()

## (Re)build the buttons for the active theme and select the first one.
func fill() -> void:
	for c in row.get_children():
		row.remove_child(c)
		c.queue_free()
	var group := ButtonGroup.new()
	for id: String in Buildings.ids() + stolen.filter(func(s: String) -> bool: return not s in Buildings.ids()):
		var b: Dictionary = Buildings.get_def(id)
		row.add_child(button("%s\n$%d" % [b["name"], b["cost"]], id, group))
	row.add_child(button("Eraser\n ", "", group))
	row.add_child(button("Upgrade\n ", UPGRADE, group))
	var bar := row.get_parent() as Control
	bar.reset_size()
	bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 16)
	(row.get_child(0) as Button).button_pressed = true

func button(text: String, id: String, group: ButtonGroup) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.button_group = group
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(96, 0)
	b.add_theme_stylebox_override("normal", box(Palette.CREAM))
	b.add_theme_stylebox_override("hover", box(Palette.shade(Palette.CREAM, 0.04)))
	b.add_theme_stylebox_override("pressed", box(Palette.SKY))
	b.add_theme_stylebox_override("hover_pressed", box(Palette.SKY))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, Palette.INK)
	b.toggled.connect(func(on: bool) -> void:
		if on:
			picked.emit(id))
	return b
