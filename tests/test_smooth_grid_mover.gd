extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	test_interpolates_before_snapping_to_target()
	test_zero_duration_snaps_immediately()

	if failures.is_empty():
		print("smooth_grid_mover tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func test_interpolates_before_snapping_to_target() -> void:
	var smooth_grid_mover = load("res://scripts/smooth_grid_mover.gd")
	assert_true(smooth_grid_mover != null, "smooth mover script exists")
	if smooth_grid_mover == null:
		return

	var mover = smooth_grid_mover.new()
	mover.snap_to(Vector2.ZERO)
	mover.move_to(Vector2(60, 0), 0.12)

	assert_equal(mover.current_position, Vector2.ZERO, "move start does not jump to target instantly")
	assert_true(mover.is_animating, "mover enters animating state after a timed move")

	mover.advance(0.04)
	assert_true(mover.current_position.x > 0.0, "position advances during interpolation")
	assert_true(mover.current_position.x < 60.0, "position remains between start and target before animation completes")

	mover.advance(0.20)
	assert_equal(mover.current_position, Vector2(60, 0), "final position snaps exactly to target grid pixel")
	assert_false(mover.is_animating, "mover stops animating once the target is reached")

func test_zero_duration_snaps_immediately() -> void:
	var smooth_grid_mover = load("res://scripts/smooth_grid_mover.gd")
	if smooth_grid_mover == null:
		return

	var mover = smooth_grid_mover.new()
	mover.snap_to(Vector2(12, 18))
	mover.move_to(Vector2(72, 18), 0.0)
	assert_equal(mover.current_position, Vector2(72, 18), "zero-duration move snaps immediately")
	assert_false(mover.is_animating, "zero-duration move does not keep animating")

func assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s but got %s" % [label, expected, actual])

func assert_true(actual: bool, label: String) -> void:
	if not actual:
		failures.append("%s expected true but got false" % label)

func assert_false(actual: bool, label: String) -> void:
	if actual:
		failures.append("%s expected false but got true" % label)
