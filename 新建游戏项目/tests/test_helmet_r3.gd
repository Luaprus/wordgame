extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const HelmetR3 = preload("res://levels/helmet/helmet_r3.gd")

var failures: Array[String] = []

func _init() -> void:
	test_r3_map_size_and_initial_state()
	test_r3_loose_bridge_death_flow()
	test_r3_tree_prompt_bridge_sync()
	test_r3_shore_stabilizes_and_splits_back()

	if failures.is_empty():
		print("helmet_r3 tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func test_r3_map_size_and_initial_state() -> void:
	var level := HelmetR3.build_level()
	assert_equal(level.name, "四目头盔 过河第三关", "third level name is set")
	assert_equal(level.rows.size(), 18, "helmet r3 has 18 rows")
	for i in range(level.rows.size()):
		assert_equal(str(level.rows[i]).length(), 32, "helmet r3 row %s has 32 columns" % i)

	var world := GridWorld.new()
	world.load_level(level)
	assert_equal(world.player_pos, Vector2i(6, 4), "third level starts before 感觉")
	assert_any_text(world, Vector2i(14, 3), "乔", "initial sentence contains 乔")
	assert_any_text(world, Vector2i(15, 3), "木", "initial sentence contains 木")
	world.player_pos = Vector2i(20, 5)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "creek responds before bridge appears")
	assert_any_text(world, Vector2i(10, 10), "水", "initial creek interaction exposes 水")
	assert_any_text(world, Vector2i(11, 10), "难", "initial creek interaction exposes 难")

func test_r3_loose_bridge_death_flow() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetR3.build_level())

	assert_true(world.try_merge_entities(Vector2i(15, 3), Vector2i(14, 3)).success, "乔木 merges into loose bridge")
	assert_any_text(world, Vector2i(21, 8), "桥", "loose bridge upper rail appears")
	assert_true(world.get_any_entity_at(Vector2i(21, 9)) == null, "loose bridge middle row leaves road")
	var loose_bridge = world.get_any_entity_at(Vector2i(21, 8))
	assert_true(loose_bridge != null and absf(loose_bridge.visual_rotation_degrees) > 0.1, "loose bridge has visual tilt")

	world.player_pos = Vector2i(19, 8)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "space on loose bridge reveals bridge hint")
	assert_any_text(world, Vector2i(3, 6), "桥", "bridge hint appears on bridge interaction")
	assert_any_text(world, Vector2i(2, 7), "小", "bridge hint second line appears")
	assert_true(world.get_any_entity_at(Vector2i(10, 10)) == null, "creek hint is hidden before creek interaction")

	world.player_pos = Vector2i(20, 6)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "space on creek after bridge reveals creek hint")
	assert_any_text(world, Vector2i(10, 10), "水", "creek hint exposes 水")
	assert_any_text(world, Vector2i(11, 10), "难", "creek hint exposes 难")

	world.player_pos = Vector2i(22, 9)
	world.facing = Vector2i.RIGHT
	var death_trigger := world.try_move_player(Vector2i.RIGHT)
	assert_true(death_trigger.success, "entering loose bridge center succeeds before fall")
	assert_equal(world.player_pos, Vector2i(23, 9), "player reaches the bridge center")
	assert_true(world.player_input_locked, "player is locked while falling event waits")
	assert_true(world.has_pending_timed_effect(), "fall event is pending")

	var fall := world.resolve_pending_timed_effect()
	assert_true(fall.success, "fall event resolves")
	assert_true(not world.player_visible, "player disappears after falling")
	assert_true(not world.player_input_locked, "player can press space after fall prompt")
	assert_any_text(world, Vector2i(2, 13), "我", "fall prompt appears in lower left")
	assert_any_text(world, Vector2i(21, 8), "溪", "bridge is gone after falling")
	assert_true(world.get_any_entity_at(Vector2i(3, 7)) == null, "bridge hint disappears after falling")

	var death_screen := world.interact_front()
	assert_true(death_screen.success, "space on fall prompt enters death screen")
	assert_true(world.player_visible, "player reappears on death screen")
	assert_equal(world.player_pos, Vector2i(23, 9), "death screen keeps player at bridge center")
	assert_any_text(world, Vector2i(23, 10), "淹", "death screen shows 淹")
	assert_any_text(world, Vector2i(23, 11), "死", "death screen shows 死")
	assert_any_text(world, Vector2i(23, 12), "了", "death screen shows 了")
	assert_any_text(world, Vector2i(23, 14), "。", "death screen shows punctuation")
	assert_true(world.entities.size() == 4, "death screen clears all other words")
	var reset := world.interact_front()
	assert_true(reset.success, "space after death screen resets the level")
	assert_equal(world.player_pos, Vector2i(6, 4), "reset returns player to initial position")
	assert_any_text(world, Vector2i(14, 3), "乔", "reset restores sentence 乔")
	assert_any_text(world, Vector2i(15, 3), "木", "reset restores sentence 木")
	assert_any_text(world, Vector2i(23, 10), "溪", "reset clears death text and restores creek")

func test_r3_tree_prompt_bridge_sync() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetR3.build_level())

	world.player_pos = Vector2i(17, 9)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "space on tree reveals tree hint")
	assert_any_text(world, Vector2i(3, 6), "乔", "tree hint starts with 乔")
	assert_any_text(world, Vector2i(4, 6), "木", "tree hint starts with 木")

	assert_true(world.try_merge_entities(Vector2i(15, 3), Vector2i(14, 3)).success, "sentence 乔木 merges after tree hint")
	assert_any_text(world, Vector2i(14, 3), "桥", "sentence bridge appears")
	assert_any_text(world, Vector2i(3, 6), "桥", "tree hint merges into bridge hint")
	assert_true(world.get_any_entity_at(Vector2i(4, 6)) == null, "tree hint 木 cell clears after merge")

	world.player_pos = Vector2i(20, 6)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "space on creek reveals creek hint")
	assert_any_text(world, Vector2i(3, 10), "桥", "creek hint bridge starts as 桥")

	world.player_pos = Vector2i(15, 3)
	world.facing = Vector2i.LEFT
	assert_true(world.split_front().success, "sentence bridge splits with all hints visible")
	assert_any_text(world, Vector2i(14, 3), "乔", "sentence bridge splits to 乔")
	assert_any_text(world, Vector2i(15, 3), "木", "sentence bridge splits to 木")
	assert_any_text(world, Vector2i(3, 6), "乔", "second hint also splits to 乔")
	assert_any_text(world, Vector2i(4, 6), "木", "second hint also splits to 木")
	assert_any_text(world, Vector2i(3, 10), "乔", "third hint also splits to 乔")
	assert_any_text(world, Vector2i(4, 10), "木", "third hint also splits to 木")

func test_r3_shore_stabilizes_and_splits_back() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetR3.build_level())

	assert_true(world.try_merge_entities(Vector2i(15, 3), Vector2i(14, 3)).success, "setup loose bridge")
	world.player_pos = Vector2i(19, 8)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "setup bridge hint")
	world.player_pos = Vector2i(20, 6)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "setup creek hint")
	assert_any_text(world, Vector2i(3, 10), "桥", "creek hint bridge starts synced")
	world.player_pos = Vector2i(15, 3)
	world.facing = Vector2i.LEFT
	assert_true(world.split_front().success, "sentence bridge splits while creek hint is visible")
	assert_any_text(world, Vector2i(3, 6), "乔", "bridge hint splits to 乔")
	assert_any_text(world, Vector2i(4, 6), "木", "bridge hint splits to 木")
	assert_any_text(world, Vector2i(3, 10), "乔", "creek hint bridge also splits to 乔")
	assert_any_text(world, Vector2i(4, 10), "木", "creek hint bridge also splits to 木")
	assert_true(world.try_merge_entities(Vector2i(15, 3), Vector2i(14, 3)).success, "sentence bridge remerges while creek hint is visible")
	assert_any_text(world, Vector2i(3, 6), "桥", "bridge hint merges back to 桥")
	assert_true(world.get_any_entity_at(Vector2i(4, 6)) == null, "bridge hint 木 slot clears after merge")
	assert_any_text(world, Vector2i(3, 10), "桥", "creek hint bridge merges back to 桥")
	assert_true(world.get_any_entity_at(Vector2i(4, 10)) == null, "creek hint 木 slot clears after merge")
	assert_true(world.try_merge_entities(Vector2i(11, 10), Vector2i(10, 10)).success, "水难 merges into 滩")
	assert_any_text(world, Vector2i(10, 10), "滩", "滩 appears in the creek hint line")
	var stable_bridge = world.get_any_entity_at(Vector2i(21, 8))
	assert_true(stable_bridge != null and absf(stable_bridge.visual_rotation_degrees) < 0.1, "滩 straightens the bridge")

	world.player_pos = Vector2i(22, 9)
	world.facing = Vector2i.RIGHT
	var safe_step := world.try_move_player(Vector2i.RIGHT)
	assert_true(safe_step.success, "stable bridge center is safe")
	assert_true(not world.player_input_locked, "stable bridge does not lock the player")
	assert_true(not world.has_pending_timed_effect(), "stable bridge does not schedule death")

	world.player_pos = Vector2i(10, 11)
	world.facing = Vector2i.UP
	var split := world.split_front()
	assert_true(split.success, "滩 splits back into 水难")
	assert_any_text(world, Vector2i(10, 10), "水", "水 returns after 滩 splits")
	assert_any_text(world, Vector2i(11, 10), "难", "难 returns after 滩 splits")
	var loose_again = world.get_any_entity_at(Vector2i(21, 8))
	assert_true(loose_again != null and absf(loose_again.visual_rotation_degrees) > 0.1, "splitting 滩 loosens the bridge again")

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
