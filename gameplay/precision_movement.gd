extends RefCounted

const START_POSITION := Vector2(320, 180)
const STEP_SIZE := 16

static func move(current_position: Vector2, direction: Vector2) -> Vector2:
	if direction == Vector2.ZERO:
		return snap_to_grid_center(current_position)

	var snapped_position := snap_to_grid_center(current_position)
	return snap_to_grid_center(snapped_position + direction.normalized() * STEP_SIZE)

static func snap_to_grid_center(position: Vector2, origin := START_POSITION) -> Vector2:
	var steps_x := int(round((position.x - origin.x) / STEP_SIZE))
	var steps_y := int(round((position.y - origin.y) / STEP_SIZE))
	return Vector2(
		origin.x + steps_x * STEP_SIZE,
		origin.y + steps_y * STEP_SIZE
	)

static func resolve_turn_or_move(current_facing: Vector2i, input_direction: Vector2i) -> Dictionary:
	if input_direction == Vector2i.ZERO:
		return {
			"facing": current_facing,
			"should_turn": false,
			"should_move": false
		}
	if current_facing != input_direction:
		return {
			"facing": input_direction,
			"should_turn": true,
			"should_move": false
		}
	return {
		"facing": current_facing,
		"should_turn": false,
		"should_move": true
	}

static func direction_from_keycode(keycode: Key) -> Vector2i:
	match keycode:
		KEY_RIGHT, KEY_D:
			return Vector2i.RIGHT
		KEY_LEFT, KEY_A:
			return Vector2i.LEFT
		KEY_DOWN, KEY_S:
			return Vector2i.DOWN
		KEY_UP, KEY_W:
			return Vector2i.UP
	return Vector2i.ZERO

static func should_process_key_event(pressed: bool, echo: bool, direction: Vector2i) -> bool:
	if not pressed:
		return false
	return not echo
