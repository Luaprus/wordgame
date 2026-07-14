extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const HelmetR1 = preload("res://levels/helmet/helmet_r1.gd")
const HelmetR6 = preload("res://levels/helmet/helmet_r6.gd")
const HelmetReturn = preload("res://levels/helmet/helmet_return.gd")

var failures: Array[String] = []

func _init() -> void:
	test_helmet_levels_are_bounded_and_exit_right()
	test_unbounded_world_keeps_page_crossing_behavior()
	test_sixth_to_return_entry_coordinates()

	if failures.is_empty():
		print("helmet_sequence tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func test_helmet_levels_are_bounded_and_exit_right() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetR1.build_level())
	world.player_pos = Vector2i(0, 5)
	world.facing = Vector2i.LEFT
	assert_false(world.try_move_player(Vector2i.LEFT).success, "helmet level blocks the left edge")
	world.player_pos = Vector2i(10, 0)
	world.facing = Vector2i.UP
	assert_false(world.try_move_player(Vector2i.UP).success, "helmet level blocks the top edge")
	world.player_pos = Vector2i(10, 17)
	world.facing = Vector2i.DOWN
	assert_false(world.try_move_player(Vector2i.DOWN).success, "helmet level blocks the bottom edge")

	world.player_pos = Vector2i(31, 5)
	world.facing = Vector2i.RIGHT
	var exit := world.try_move_player(Vector2i.RIGHT)
	assert_true(exit.success, "helmet level accepts a right-edge exit")
	assert_equal(exit.get("transition", ""), "next_level", "right edge requests the next level")
	assert_equal(exit.get("exit_y", -1), 5, "right edge preserves the exit height")
	assert_equal(world.player_pos, Vector2i(31, 5), "right-edge transition does not move inside the old map")

func test_unbounded_world_keeps_page_crossing_behavior() -> void:
	var world := GridWorld.new()
	world.load_level({
		"screen_size": Vector2i(32, 18),
		"rows": ["                                "],
		"player_start": Vector2i(31, 0),
		"player_facing": Vector2i.RIGHT
	})
	var move := world.try_move_player(Vector2i.RIGHT)
	assert_true(move.success, "unbounded fixtures can still cross page edges")
	assert_equal(world.player_pos, Vector2i(32, 0), "unbounded right edge moves to the next page")

func test_sixth_to_return_entry_coordinates() -> void:
	var sixth := HelmetR6.build_level()
	var ending := HelmetReturn.build_level()
	assert_true(bool(sixth.get("bounded", false)), "sixth level is bounded")
	assert_true(bool(ending.get("bounded", false)), "return level is bounded")
	assert_equal(ending.get("player_text", ""), "鹅", "return level still starts as goose when entered directly")

func assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		fail("%s: expected %s, got %s" % [message, expected, actual])

func assert_true(condition: bool, message: String) -> void:
	if not condition:
		fail(message)

func assert_false(condition: bool, message: String) -> void:
	if condition:
		fail(message)

func fail(message: String) -> void:
	failures.append(message)
