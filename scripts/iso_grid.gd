class_name IsoGrid
# Pure isometric grid math (2:1 tiles). Cell (0,0) centre sits at screen (0,0).

const TILE := Vector2(64, 32)
const SIZE := Vector2i(16, 16)

## Screen position of a cell's centre.
static func to_screen(cell: Vector2i) -> Vector2:
	return project(Vector2(cell))

## Same mapping for fractional cell coordinates (tile corners, shapes).
static func project(p: Vector2) -> Vector2:
	return Vector2((p.x - p.y) * TILE.x / 2, (p.x + p.y) * TILE.y / 2)

static func to_cell(screen: Vector2) -> Vector2i:
	var a := screen.x / (TILE.x / 2)
	var b := screen.y / (TILE.y / 2)
	return Vector2i(floori((a + b) / 2 + 0.5), floori((b - a) / 2 + 0.5))

static func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < SIZE.x and cell.y < SIZE.y
