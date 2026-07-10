extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const HelmetR6 = preload("res://levels/helmet/helmet_r6.gd")

var failures: Array[String] = []

func _init() -> void:
	test_r6_map_size_and_initial_state()
	test_r6_creek_hint_is_available_immediately()
	test_r6_player_merges_with_bird_into_goose()

	if failures.is_empty():
		print("helmet_r6 tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func test_r6_map_size_and_initial_state() -> void:
	var level := HelmetR6.build_level()
	assert_equal(level.name, "四目头盔 过河第六关", "sixth level name is set")
	assert_equal(level.rows.size(), 18, "helmet r6 has 18 rows")
	for i in range(level.rows.size()):
		assert_equal(str(level.rows[i]).length(), 32, "helmet r6 row %s has 32 columns" % i)

	var world := GridWorld.new()
	world.load_level(level)
	assert_equal(world.player_pos, Vector2i(3, 4), "sixth level starts at the 我 in the sentence")
	assert_equal(world.player_text, "我", "player starts as 我")
	assert_true(world.get_any_entity_at(Vector2i(3, 4)) == null, "player cell is empty in the text map")
	assert_any_text(world, Vector2i(7, 4), "鸟", "sentence contains 鸟")
	assert_any_text(world, Vector2i(21, 5), "溪", "creek blocks the front")

func test_r6_creek_hint_is_available_immediately() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetR6.build_level())
	world.player_pos = Vector2i(20, 5)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "initial creek can show the final hint")
	assert_any_text(world, Vector2i(2, 7), "是", "creek hint first line appears")
	assert_any_text(world, Vector2i(2, 9), "看", "creek hint bird line appears")
	assert_any_text(world, Vector2i(2, 11), "「", "creek hint final line appears")
	assert_true(world.get_any_entity_at(Vector2i(12, 11)) == null, "creek hint has no down-triangle prompt")

func test_r6_player_merges_with_bird_into_goose() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetR6.build_level())
	world.player_pos = Vector2i(7, 5)
	world.facing = Vector2i.UP
	var result := world.try_move_player(Vector2i.UP)
	assert_true(result.success, "player can merge with 鸟")
	assert_equal(world.player_text, "鹅", "player becomes 鹅")
	assert_equal(world.player_pos, Vector2i(7, 4), "goose stays under player control instead of teleporting")
	assert_true(world.get_any_entity_at(Vector2i(7, 4)) == null, "鸟 disappears after merge")
	assert_any_text(world, Vector2i(2, 9), "看", "goose merge keeps the hint text visible")

	world.player_pos = Vector2i(20, 5)
	world.facing = Vector2i.RIGHT
	var swim := world.try_move_player(Vector2i.RIGHT)
	assert_true(swim.success, "goose can move through creek")
	assert_equal(world.player_pos, Vector2i(21, 5), "goose steps onto the creek cell")

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
