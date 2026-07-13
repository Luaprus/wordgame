extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const HelmetReturn = preload("res://levels/helmet/helmet_return.gd")

var failures: Array[String] = []

func _init() -> void:
	test_return_map_size_and_initial_state()
	test_goose_splits_back_to_player_and_bird_flies_left()
	test_goose_split_works_away_from_start()

	if failures.is_empty():
		print("helmet_return tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func test_return_map_size_and_initial_state() -> void:
	var level := HelmetReturn.build_level()
	assert_equal(level.name, "四目头盔 找回自己", "return level name is set")
	assert_equal(level.rows.size(), 18, "return level has 18 rows")
	for i in range(level.rows.size()):
		assert_equal(str(level.rows[i]).length(), 32, "return level row %s has 32 columns" % i)

	var world := GridWorld.new()
	world.load_level(level)
	assert_equal(world.player_pos, Vector2i(7, 12), "return level player starts near the lower middle")
	assert_equal(world.player_text, "鹅", "return level starts with goose player text")
	assert_any_text(world, Vector2i(1, 3), "再", "return hint first line appears")
	assert_any_text(world, Vector2i(1, 4), "应", "return hint second line appears")
	assert_true(world.find_first_entity_by_text("鸟") == null, "bird is not present before splitting the goose")

func test_goose_splits_back_to_player_and_bird_flies_left() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetReturn.build_level())
	var start_pos := world.player_pos
	var result := world.split_front()
	assert_true(result.success, "tab splits goose even without a front target")
	assert_equal(world.player_text, "我", "goose becomes the original player")
	assert_equal(world.player_pos, start_pos, "player stays in place after splitting")
	assert_any_text(world, start_pos + Vector2i.LEFT, "鸟", "bird appears behind the player")
	assert_true(world.has_pending_timed_effect(), "bird fly-away is scheduled")
	assert_equal(world.pending_timed_delay, 1.0, "bird waits one second before flying left")

	var timed := world.resolve_pending_timed_effect()
	assert_true(timed.success, "first timed bird fly-away step resolves")
	assert_true(world.get_any_entity_at(start_pos + Vector2i.LEFT) == null, "bird leaves the cell behind the player")
	var bird = world.find_first_entity_by_text("鸟")
	assert_true(bird != null, "bird entity still exists while flying left")
	assert_equal(bird.grid_pos, Vector2i(5, start_pos.y), "bird moves one cell left on the first fly-away step")
	assert_true(world.has_pending_timed_effect(), "bird keeps flying until it leaves the screen")
	assert_equal(world.pending_timed_delay, 0.12, "bird repeats at the shift movement interval")

	while world.has_pending_timed_effect():
		world.resolve_pending_timed_effect()
	assert_equal(bird.grid_pos, Vector2i(-3, start_pos.y), "bird walks off the left side of the screen")

func test_goose_split_works_away_from_start() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetReturn.build_level())
	world.player_pos = Vector2i(20, 10)
	world.facing = Vector2i.LEFT
	var result := world.split_front()
	assert_true(result.success, "goose split works from any empty position")
	assert_equal(world.player_text, "我", "goose becomes me away from start")
	assert_any_text(world, Vector2i(21, 10), "鸟", "bird uses the current facing to appear behind the player")

func assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		fail("%s: expected %s, got %s" % [message, expected, actual])

func assert_true(condition: bool, message: String) -> void:
	if not condition:
		fail(message)

func assert_any_text(world, pos: Vector2i, expected: String, message: String) -> void:
	var entity = world.get_any_entity_at(pos)
	assert_true(entity != null and entity.text == expected, message)

func fail(message: String) -> void:
	failures.append(message)
