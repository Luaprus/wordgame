extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const HelmetR4 = preload("res://levels/helmet/helmet_r4.gd")

var failures: Array[String] = []

func _init() -> void:
	test_r4_map_size_and_initial_state()
	test_r4_needs_near_bridge_and_far_bridge_split()
	test_r4_far_bridge_can_be_restored()
	test_r4_hint_syncs_with_near_bridge()

	if failures.is_empty():
		print("helmet_r4 tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func test_r4_map_size_and_initial_state() -> void:
	var level := HelmetR4.build_level()
	assert_equal(level.name, "四目头盔 过河第四关", "fourth level name is set")
	assert_equal(level.rows.size(), 18, "helmet r4 has 18 rows")
	for i in range(level.rows.size()):
		assert_equal(str(level.rows[i]).length(), 32, "helmet r4 row %s has 32 columns" % i)

	var world := GridWorld.new()
	world.load_level(level)
	assert_equal(world.player_pos, Vector2i(7, 5), "fourth level starts at the 我 in the third sentence")
	assert_true(world.get_any_entity_at(Vector2i(7, 5)) == null, "player cell is empty in the text map")
	assert_any_text(world, Vector2i(14, 3), "乔", "near sentence starts with 乔")
	assert_any_text(world, Vector2i(15, 3), "木", "near sentence starts with 木")
	assert_any_text(world, Vector2i(14, 4), "桥", "far sentence starts with 桥")
	assert_any_text(world, Vector2i(28, 9), "桥", "far bridge blocks the route")
	assert_any_text(world, Vector2i(19, 8), "树", "near tree exists before bridge merge")

func test_r4_needs_near_bridge_and_far_bridge_split() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetR4.build_level())

	assert_true(world.try_merge_entities(Vector2i(15, 3), Vector2i(14, 3)).success, "near 乔木 merges into bridge")
	assert_any_text(world, Vector2i(14, 3), "桥", "near sentence becomes bridge")
	assert_any_text(world, Vector2i(21, 8), "桥", "near bridge appears")
	assert_true(world.get_any_entity_at(Vector2i(21, 9)) == null, "near bridge leaves a road through the creek")
	assert_any_text(world, Vector2i(28, 9), "桥", "far bridge still blocks after only near bridge merge")
	world.player_pos = Vector2i(27, 9)
	world.facing = Vector2i.RIGHT
	assert_true(not world.try_move_player(Vector2i.RIGHT).success, "cannot pass while far bridge remains")

	world = GridWorld.new()
	world.load_level(HelmetR4.build_level())
	world.player_pos = Vector2i(13, 4)
	world.facing = Vector2i.RIGHT
	assert_true(world.split_front().success, "far sentence bridge splits into 乔木")
	assert_any_text(world, Vector2i(14, 4), "乔", "far sentence becomes 乔")
	assert_any_text(world, Vector2i(15, 4), "木", "far sentence becomes 木")
	assert_true(world.get_any_entity_at(Vector2i(28, 9)) == null, "far bridge disappears after far sentence split")
	assert_any_text(world, Vector2i(30, 6), "树", "far tree appears after bridge split")
	assert_any_text(world, Vector2i(21, 9), "溪", "creek still blocks after only far bridge split")

	assert_true(world.try_merge_entities(Vector2i(15, 3), Vector2i(14, 3)).success, "near bridge merges after far bridge split")
	assert_true(world.get_any_entity_at(Vector2i(21, 9)) == null, "near bridge opens the creek after both changes")
	assert_true(world.get_any_entity_at(Vector2i(28, 9)) == null, "far blocker remains gone after both changes")
	world.player_pos = Vector2i(27, 9)
	world.facing = Vector2i.RIGHT
	assert_true(world.try_move_player(Vector2i.RIGHT).success, "can pass after near bridge is built and far bridge is split")
	assert_equal(world.player_pos, Vector2i(28, 9), "player steps through the former far bridge cell")

func test_r4_far_bridge_can_be_restored() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetR4.build_level())
	world.player_pos = Vector2i(13, 4)
	world.facing = Vector2i.RIGHT
	assert_true(world.split_front().success, "setup far bridge split")
	assert_true(world.get_any_entity_at(Vector2i(28, 9)) == null, "setup far bridge removed")

	assert_true(world.try_merge_entities(Vector2i(15, 4), Vector2i(14, 4)).success, "far 乔木 can merge back to bridge")
	assert_any_text(world, Vector2i(14, 4), "桥", "far sentence bridge returns")
	assert_any_text(world, Vector2i(28, 9), "桥", "far physical bridge returns")
	assert_any_text(world, Vector2i(27, 5), "桥", "far bridge top-left endpoint is shifted left")
	assert_true(world.get_any_entity_at(Vector2i(29, 9)) == null, "far bridge keeps a blank column between its halves")
	assert_any_text(world, Vector2i(30, 6), "桥", "far tree is replaced by the shifted right bridge half")

func test_r4_hint_syncs_with_near_bridge() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetR4.build_level())

	world.player_pos = Vector2i(17, 9)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "space on near tree reveals tree hint")
	assert_any_text(world, Vector2i(3, 7), "乔", "tree hint starts as 乔木")
	assert_any_text(world, Vector2i(4, 7), "木", "tree hint has 木")
	assert_true(world.try_merge_entities(Vector2i(15, 3), Vector2i(14, 3)).success, "near bridge merges after hint")
	assert_any_text(world, Vector2i(3, 7), "桥", "tree hint syncs to 桥")
	assert_true(world.get_any_entity_at(Vector2i(4, 7)) == null, "hint 木 cell clears after merge")

	world.player_pos = Vector2i(15, 3)
	world.facing = Vector2i.LEFT
	assert_true(world.split_front().success, "near bridge splits after hint")
	assert_any_text(world, Vector2i(3, 7), "乔", "hint syncs back to 乔")
	assert_any_text(world, Vector2i(4, 7), "木", "hint syncs back to 木")

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
