extends RefCounted

var current_position := Vector2.ZERO
var is_animating := false

var _start_position := Vector2.ZERO
var _target_position := Vector2.ZERO
var _duration := 0.0
var _elapsed := 0.0

func snap_to(position: Vector2) -> void:
	current_position = position
	_start_position = position
	_target_position = position
	_duration = 0.0
	_elapsed = 0.0
	is_animating = false

func move_to(position: Vector2, duration := 0.12) -> void:
	if duration <= 0.0 or current_position == position:
		snap_to(position)
		return

	_start_position = current_position
	_target_position = position
	_duration = duration
	_elapsed = 0.0
	is_animating = true

func advance(delta: float) -> Vector2:
	if not is_animating:
		return current_position

	_elapsed += max(delta, 0.0)
	var t := minf(_elapsed / _duration, 1.0)
	current_position = _start_position.lerp(_target_position, t)
	if t >= 1.0:
		current_position = _target_position
		is_animating = false
	return current_position
