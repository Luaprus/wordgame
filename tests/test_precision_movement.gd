extends SceneTree

const GridWorld = preload("res://core/grid_world.gd")
const PrecisionMovement = preload("res://gameplay/precision_movement.gd")
const PlayerDirectionMarker = preload("res://gameplay/player_moving/player_direction_marker.gd")
const PlayerDirectionDemoScene = preload("res://scenes/player_moving/PlayerDirectionDemo.tscn")

var failures: Array[String] = []

func _init() -> void:
	test_turn_first_then_move()
	test_pixel_move_stays_on_grid_center()
	test_repeated_pixel_moves_do_not_accumulate_drift()
	test_direction_keys_and_wasd_share_mapping()
	test_direction_marker_points_face_the_input()
	test_direction_demo_scene_loads()
	test_direction_echo_is_rejected_for_uniform_hold_loop()

	if failures.is_empty():
		print("precision_movement tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func test_turn_first_then_move() -> void:
	var world := make_world()
	world.facing = Vector2i.DOWN
	world.player_pos = Vector2i(2, 2)

	var first_press: Dictionary = world.try_move_player(Vector2i.RIGHT)
	assert_true(first_press.success, "first different direction input should be accepted as a turn")
	assert_equal(world.facing, Vector2i.RIGHT, "first different direction input updates facing")
	assert_equal(world.player_pos, Vector2i(2, 2), "first different direction input does not move the player")

	var second_press: Dictionary = world.try_move_player(Vector2i.RIGHT)
	assert_true(second_press.success, "second same direction input moves the player")
	assert_equal(world.player_pos, Vector2i(3, 2), "second same direction input moves exactly one grid")

func test_pixel_move_stays_on_grid_center() -> void:
	var moved := PrecisionMovement.move(PrecisionMovement.START_POSITION, Vector2.RIGHT)
	assert_equal(moved, Vector2(336, 180), "move right lands on the next grid center")
	assert_equal(
		PrecisionMovement.snap_to_grid_center(moved),
		Vector2(336, 180),
		"grid center snapping keeps an aligned position unchanged"
	)

func test_repeated_pixel_moves_do_not_accumulate_drift() -> void:
	var position := PrecisionMovement.START_POSITION + Vector2(0.4, -0.35)
	for _i in range(6):
		position = PrecisionMovement.move(position, Vector2.RIGHT)
	assert_equal(position, Vector2(416, 180), "repeated movement snaps away drift instead of accumulating it")
	assert_equal(
		PrecisionMovement.snap_to_grid_center(position),
		position,
		"repeated movement still finishes exactly on a grid center"
	)

func test_direction_keys_and_wasd_share_mapping() -> void:
	assert_equal(PrecisionMovement.direction_from_keycode(KEY_RIGHT), Vector2i.RIGHT, "right arrow maps to right")
	assert_equal(PrecisionMovement.direction_from_keycode(KEY_D), Vector2i.RIGHT, "D maps to right")
	assert_equal(PrecisionMovement.direction_from_keycode(KEY_LEFT), Vector2i.LEFT, "left arrow maps to left")
	assert_equal(PrecisionMovement.direction_from_keycode(KEY_A), Vector2i.LEFT, "A maps to left")
	assert_equal(PrecisionMovement.direction_from_keycode(KEY_DOWN), Vector2i.DOWN, "down arrow maps to down")
	assert_equal(PrecisionMovement.direction_from_keycode(KEY_S), Vector2i.DOWN, "S maps to down")
	assert_equal(PrecisionMovement.direction_from_keycode(KEY_UP), Vector2i.UP, "up arrow maps to up")
	assert_equal(PrecisionMovement.direction_from_keycode(KEY_W), Vector2i.UP, "W maps to up")

func test_direction_echo_is_rejected_for_uniform_hold_loop() -> void:
	assert_true(
		PrecisionMovement.should_process_key_event(true, false, Vector2i.RIGHT),
		"fresh direction press should be processed"
	)
	assert_false(
		PrecisionMovement.should_process_key_event(true, true, Vector2i.RIGHT),
		"echo direction press should be ignored so held movement stays uniform"
	)
	assert_false(
		PrecisionMovement.should_process_key_event(true, true, Vector2i.ZERO),
		"echo on a non-direction key should not be treated as movement"
	)
	assert_false(
		PrecisionMovement.should_process_key_event(false, false, Vector2i.RIGHT),
		"released keys should not be processed"
	)

func test_direction_marker_points_face_the_input() -> void:
	var right_points := PlayerDirectionMarker.local_points(60.0, Vector2i.RIGHT)
	assert_true(right_points[2].x > right_points[0].x, "right-facing triangle apex extends further right than its base")
	assert_true(right_points[2].x > right_points[1].x, "right-facing triangle apex is the furthest-right point")
	assert_equal(PlayerDirectionMarker.anchor_offset(60.0, Vector2i.RIGHT), Vector2(37.2, 0), "right-facing marker anchor sits in front of the player")

	var up_points := PlayerDirectionMarker.local_points(60.0, Vector2i.UP)
	assert_true(up_points[2].y < up_points[0].y, "up-facing triangle apex extends above its base")
	assert_true(up_points[2].y < up_points[1].y, "up-facing triangle apex is the highest point")

func test_direction_demo_scene_loads() -> void:
	var scene := PlayerDirectionDemoScene.instantiate()
	assert_true(scene != null, "standalone player direction demo scene loads")
	if scene != null:
		scene.queue_free()

func make_world() -> RefCounted:
	var world = GridWorld.new()
	world.load_level({
		"rows": [
			"墙墙墙墙墙墙",
			"墙    墙",
			"墙    墙",
			"墙    墙",
			"墙墙墙墙墙墙"
		],
		"player_start": Vector2i(2, 2),
		"player_facing": Vector2i.RIGHT,
		"screen_size": Vector2i(6, 5),
		"entities": {}
	})
	return world

func assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s but got %s" % [label, expected, actual])

func assert_true(actual: bool, label: String) -> void:
	if not actual:
		failures.append("%s expected true but got false" % label)

func assert_false(actual: bool, label: String) -> void:
	if actual:
		failures.append("%s expected false but got true" % label)
