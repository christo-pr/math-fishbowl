class_name TankLayout
## Pure helpers that turn the current viewport size into tank geometry.
## Everything that places things in the tank asks here, so aspect changes stay consistent.

const SAND_HEIGHT := 96.0
const WALL_THICKNESS := 32.0
const TOP_HUD_SPACE := 90.0
const WATER_SIDE_MARGIN := 56.0
const WATER_BOTTOM_GAP := 36.0


static func floor_y(size: Vector2) -> float:
	return size.y - SAND_HEIGHT


## Where fish are allowed to swim.
static func water_rect(size: Vector2) -> Rect2:
	var top := TOP_HUD_SPACE
	var bottom := floor_y(size) - WATER_BOTTOM_GAP
	return Rect2(WATER_SIDE_MARGIN, top, size.x - WATER_SIDE_MARGIN * 2.0, bottom - top)


## Horizontal span where crates may be dropped.
static func crate_drop_range(size: Vector2) -> Vector2:
	return Vector2(WATER_SIDE_MARGIN + 30.0, size.x - WATER_SIDE_MARGIN - 30.0)


static func clamp_to_water(size: Vector2, point: Vector2) -> Vector2:
	var rect := water_rect(size)
	return Vector2(
		clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y)
	)
