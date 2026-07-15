extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const HelmetR5 = preload("res://levels/helmet/helmet_r5.gd")

var failures: Array[String] = []

func _init() -> void:
	test_r5_map_size_and_initial_state()
	test_r5_bridge_is_short_until_dry_water_level()
	test_r5_hint_split_and_dry_water_are_reversible()

	if failures.is_empty():
		print("helmet_r5 tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func test_r5_map_size_and_initial_state() -> void:
	var level := HelmetR5.build_level()
	assert_equal(level.name, "四目头盔 过河第五关", "fifth level name is set")
	assert_equal(level.rows.size(), 18, "helmet r5 has 18 rows")
	for i in range(level.rows.size()):
		assert_equal(str(level.rows[i]).length(), 32, "helmet r5 row %s has 32 columns" % i)

	var world := GridWorld.new()
	world.load_level(level)
	assert_equal(world.player_pos, Vector2i(6, 4), "fifth level starts before 感觉")
	assert_true(world.get_any_entity_at(Vector2i(6, 4)) == null, "player cell is empty in the text map")
	assert_any_text(world, Vector2i(14, 3), "乔", "initial sentence contains 乔")
	assert_any_text(world, Vector2i(15, 3), "木", "initial sentence contains 木")
	assert_any_text(world, Vector2i(25, 9), "溪", "high water blocks the future crossing")
	world.player_pos = Vector2i(20, 6)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "initial creek can show the plant and water-level hint")
	assert_any_text(world, Vector2i(2, 11), "植", "initial creek interaction exposes 植")
	assert_any_text(world, Vector2i(7, 12), "古", "initial creek interaction exposes 古")
	world.player_pos = Vector2i(13, 3)
	world.facing = Vector2i.RIGHT
	assert_true(not world.interact_front().success, "bridge hint is unavailable before the bridge is built")

func test_r5_bridge_is_short_until_dry_water_level() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetR5.build_level())

	assert_true(world.try_merge_entities(Vector2i(15, 3), Vector2i(14, 3)).success, "乔木 merges into a bridge")
	assert_any_text(world, Vector2i(14, 3), "桥", "sentence bridge appears")
	assert_any_text(world, Vector2i(21, 8), "桥", "bridge upper rail appears")
	assert_any_text(world, Vector2i(25, 7), "桥", "shifted short bridge right post appears before high water")
	assert_true(world.get_any_entity_at(Vector2i(25, 8)) == null or world.get_any_entity_at(Vector2i(25, 8)).text == "溪", "short bridge does not extend into the high-water column")
	assert_true(world.get_any_entity_at(Vector2i(21, 9)) == null, "bridge clears the near crossing row")
	assert_any_text(world, Vector2i(25, 9), "溪", "high water still blocks the far side")
	world.player_pos = Vector2i(13, 3)
	world.facing = Vector2i.RIGHT
	assert_true(not world.interact_front().success, "sentence bridge does not show the physical bridge hint")
	world.player_pos = Vector2i(24, 9)
	world.facing = Vector2i.RIGHT
	assert_true(not world.try_move_player(Vector2i.RIGHT).success, "cannot pass before 枯水位")

	world.player_pos = Vector2i(20, 8)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "space on bridge shows short bridge hint")
	assert_any_text(world, Vector2i(3, 7), "桥", "bridge hint starts as 桥")
	assert_any_text(world, Vector2i(2, 8), "可", "bridge hint second line appears")

	world.player_pos = Vector2i(20, 6)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "space on creek shows plant and water-level hint")
	assert_any_text(world, Vector2i(2, 11), "植", "creek hint exposes 植")
	assert_any_text(world, Vector2i(7, 12), "古", "creek hint exposes 古")

func test_r5_hint_split_and_dry_water_are_reversible() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetR5.build_level())
	assert_true(world.try_merge_entities(Vector2i(15, 3), Vector2i(14, 3)).success, "setup bridge")
	world.player_pos = Vector2i(20, 6)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "setup creek hint")

	world.consume_visual_effects()
	world.player_pos = Vector2i(1, 11)
	world.facing = Vector2i.RIGHT
	assert_true(world.split_front().success, "植 splits into 木 and 直")
	var plant_requests := world.consume_visual_effects()
	var found_plant_split_visual := false
	for request_value in plant_requests:
		var request: Dictionary = request_value
		if str(request.get("type", "")) != "word_split_transition":
			continue
		found_plant_split_visual = true
		assert_equal(request.get("source_cell", Vector2i.ZERO), Vector2i(2, 11), "植 split visual anchors at 植")
		assert_equal(request.get("source_text", ""), "植", "植 split visual keeps source text")
		assert_equal(request.get("part_texts", []), ["木", "直"], "植 split visual records split texts")
		assert_equal(request.get("part_cells", []), [Vector2i(1, 11), Vector2i(2, 11)], "植 split visual records target cells")
		assert_equal(request.get("part_jump_heights", []), [0.0, 30.0], "植 split keeps 直 as the jumping in-place part")
	assert_true(found_plant_split_visual, "植 split emits a word_split_transition visual request")
	assert_any_text(world, Vector2i(1, 11), "木", "植 split creates 木 on the left")
	assert_any_text(world, Vector2i(2, 11), "直", "植 split creates 直")
	assert_any_text(world, Vector2i(7, 12), "古", "古 remains available for the merge")

	assert_true(world.try_merge_entities(Vector2i(1, 11), Vector2i(7, 12)).success, "木 and 古 merge into 枯")
	assert_any_text(world, Vector2i(7, 12), "枯", "古水位 becomes 枯水位")
	assert_true(world.get_any_entity_at(Vector2i(25, 9)) == null, "high water disappears after 枯水位")
	assert_true(world.get_any_entity_at(Vector2i(25, 13)) == null, "lower high-water cell disappears after 枯水位")
	assert_true(world.get_any_entity_at(Vector2i(25, 14)) == null, "lowest high-water cell disappears after 枯水位")
	world.player_pos = Vector2i(24, 9)
	world.facing = Vector2i.RIGHT
	assert_true(world.try_move_player(Vector2i.RIGHT).success, "player can cross after high water disappears")
	assert_equal(world.player_pos, Vector2i(25, 9), "player steps into the former high-water cell")

	world.player_pos = Vector2i(7, 13)
	world.facing = Vector2i.UP
	assert_true(world.split_front().success, "枯 splits back into 木 and 古")
	assert_equal(world.player_pos, Vector2i(7, 14), "player is pushed below 木 when 枯 splits")
	assert_any_text(world, Vector2i(7, 13), "木", "木 returns below 古 after 枯 splits")
	assert_any_text(world, Vector2i(2, 11), "直", "直 remains after 枯 splits")
	assert_any_text(world, Vector2i(7, 12), "古", "古 returns after 枯 splits")
	assert_any_text(world, Vector2i(25, 9), "溪", "high water returns after 枯 splits")
	assert_any_text(world, Vector2i(25, 13), "溪", "lower high water returns after 枯 splits")

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
