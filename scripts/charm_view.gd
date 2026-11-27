class_name CharmView
extends CanvasLayer
# C toggles the charm view: ZooView tints every path tile by its charm (STONE dull → GRASS → BUTTER lovely) and fades
# the other buildings. This layer is the small legend chip shown while it's on.

const FADE := 0.4  # alpha of non-path buildings in charm view

var zoo: ZooView

## Tint for a charm value: STONE at or below DULL, GRASS halfway, BUTTER at or above LOVELY.
static func tint(c: float) -> Color:
	var t := clampf(inverse_lerp(ParkSim.DULL, ParkSim.LOVELY, c), 0.0, 1.0)
	return Palette.STONE.lerp(Palette.GRASS, t * 2.0) if t < 0.5 else Palette.GRASS.lerp(Palette.BUTTER, t * 2.0 - 1.0)

func _ready() -> void:
	visible = false
	var dots: Array = [ParkSim.DULL, (ParkSim.DULL + ParkSim.LOVELY) * 0.5, ParkSim.LOVELY].map(func(c: float) -> Control: return Hud.dot(tint(c)))
	var label := Hud._label(14)
	label.text = "Charm view · C"
	var chip := Hud._chip_of(Palette.CREAM, dots + [label])
	chip.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, Hud.MARGIN)
	add_child(chip)

func toggle() -> void:
	visible = not visible
	zoo.charm = visible
