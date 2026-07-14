extends RefCounted

const BASE_RATIO := 0.28
const LENGTH_RATIO := 0.24
const GAP_RATIO := 0.12

static func local_points(cell_size: float, direction: Vector2i) -> PackedVector2Array:
	var half_base := cell_size * BASE_RATIO * 0.5
	var length := cell_size * LENGTH_RATIO

	match direction:
		Vector2i.RIGHT:
			return PackedVector2Array([
				Vector2(0, -half_base),
				Vector2(0, half_base),
				Vector2(length, 0)
			])
		Vector2i.LEFT:
			return PackedVector2Array([
				Vector2(0, -half_base),
				Vector2(-length, 0),
				Vector2(0, half_base)
			])
		Vector2i.UP:
			return PackedVector2Array([
				Vector2(-half_base, 0),
				Vector2(half_base, 0),
				Vector2(0, -length)
			])
		Vector2i.DOWN:
			return PackedVector2Array([
				Vector2(-half_base, 0),
				Vector2(0, length),
				Vector2(half_base, 0)
			])
		_:
			return PackedVector2Array()

static func anchor_offset(cell_size: float, direction: Vector2i) -> Vector2:
	var distance := cell_size * (0.5 + GAP_RATIO)
	return Vector2(direction.x, direction.y) * distance
