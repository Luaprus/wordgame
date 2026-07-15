extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const HelmetR1 = preload("res://levels/helmet/helmet_r1.gd")

var failures: Array[String] = []

func _init() -> void:
	test_map_size_and_sentence_player_glyph()
	test_fixed_interaction_captions()
	test_bridge_merge_and_split_effects()
	test_bridge_split_requests_visual_effect()

	if failures.is_empty():
		print("helmet_r1 tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func test_map_size_and_sentence_player_glyph() -> void:
	var level := HelmetR1.build_level()
	assert_equal(level.rows.size(), 18, "helmet r1 has 18 rows")
	for i in range(level.rows.size()):
		assert_equal(str(level.rows[i]).length(), 32, "helmet r1 row %s has 32 columns" % i)

	var world := GridWorld.new()
	world.load_level(level)
	assert_equal(world.player_pos, Vector2i(6, 4), "player starts at the sentence 我")
	var sentence_player := world.get_entity_at(Vector2i(6, 4))
	assert_true(sentence_player == null, "the sentence 我 is the player glyph, not a static entity")
	assert_true(world.find_first_entity_by_text("无法跨越的湍急野溪，") == null, "creek caption is hidden initially")
	assert_true(world.find_first_entity_by_text("这乔木看起来很结实，") == null, "tree caption is hidden initially")

func test_fixed_interaction_captions() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetR1.build_level())

	world.player_pos = Vector2i(17, 9)
	world.facing = Vector2i(1, 0)
	var tree_result := world.interact_front()
	assert_true(tree_result.success, "tree interaction succeeds")
	var tree_line_1 := world.find_first_entity_by_text("这乔木看起来很结实，")
	var tree_line_2 := world.find_first_entity_by_text("肯定能够帮得上忙吧。")
	assert_true(tree_line_1 != null and tree_line_1.grid_pos == Vector2i(2, 6), "tree caption line 1 appears at fixed position")
	assert_true(tree_line_2 != null and tree_line_2.grid_pos == Vector2i(2, 7), "tree caption line 2 appears at fixed position")
	assert_true(tree_line_1.solid, "tree caption blocks movement")
	world.player_pos = Vector2i(1, 6)
	world.facing = Vector2i.RIGHT
	var blocked_by_tree_caption := world.try_move_player(Vector2i.RIGHT)
	assert_true(not blocked_by_tree_caption.success, "player cannot walk through tree caption text")

	world.player_pos = Vector2i(20, 5)
	world.facing = Vector2i(1, 0)
	var creek_result := world.interact_front()
	assert_true(creek_result.success, "creek interaction succeeds")
	var creek_line_1 := world.find_first_entity_by_text("无法跨越的湍急野溪，")
	var creek_line_2 := world.find_first_entity_by_text("必须想办法造一条路。")
	assert_true(creek_line_1 != null and creek_line_1.grid_pos == Vector2i(2, 9), "creek caption line 1 appears at fixed position")
	assert_true(creek_line_2 != null and creek_line_2.grid_pos == Vector2i(2, 10), "creek caption line 2 appears at fixed position")
	assert_true(creek_line_1.solid, "creek caption blocks movement")

func test_bridge_merge_and_split_effects() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetR1.build_level())
	world.spawn_map_caption("这乔木看起来很结实，", Vector2i(2, 6), {
		"caption_pos": Vector2i(2, 6),
		"caption_solid": true
	})
	world.spawn_map_caption("肯定能够帮得上忙吧。", Vector2i(2, 7), {
		"caption_pos": Vector2i(2, 7),
		"caption_solid": true
	})

	var merged := world.try_merge_entities(Vector2i(15, 3), Vector2i(14, 3))
	assert_true(merged.success, "sentence 木 and 乔 merge into 桥")
	var sentence_bridge := world.get_entity_at(Vector2i(14, 3))
	assert_true(sentence_bridge != null and sentence_bridge.text == "桥", "merged 桥 appears at the sentence position")
	assert_any_text(world, Vector2i(19, 7), "桥", "upper left bridge post moves up")
	assert_any_text(world, Vector2i(20, 8), "桥", "upper bridge rail starts on the left bank")
	assert_any_text(world, Vector2i(21, 8), "桥", "upper bridge rail replaces creek")
	assert_true(world.get_any_entity_at(Vector2i(21, 8)).solid, "bridge glyph itself blocks movement")
	assert_true(world.get_any_entity_at(Vector2i(21, 9)) == null, "middle bridge row is an empty road")
	assert_any_text(world, Vector2i(21, 10), "桥", "lower bridge rail replaces creek")
	assert_any_text(world, Vector2i(19, 11), "桥", "lower left bridge post mirrors upper post")
	assert_true(world.get_any_entity_at(Vector2i(19, 8)) == null, "tree top disappears while bridge is active")
	assert_true(world.get_any_entity_at(Vector2i(19, 10)) == null, "tree trunk disappears while bridge is active")
	assert_true(world.find_first_entity_by_text("这乔木看起来很结实，") == null, "tree prompt switches away from 乔木")
	var bridge_prompt := world.find_first_entity_by_text("这桥看起来很结实，")
	assert_true(bridge_prompt != null and bridge_prompt.grid_pos == Vector2i(2, 6), "tree prompt switches to 桥")

	world.player_pos = Vector2i(15, 3)
	world.facing = Vector2i.LEFT
	var split := world.split_front()
	assert_true(split.success, "bridge splits back to 乔木")
	assert_equal(world.player_pos, Vector2i(16, 3), "player standing on 木 position is pushed right")
	assert_any_text(world, Vector2i(14, 3), "乔", "乔 returns to its original cell")
	assert_any_text(world, Vector2i(15, 3), "木", "木 returns to its original cell")
	assert_any_text(world, Vector2i(21, 8), "溪", "upper rail returns to creek after bridge split")
	assert_any_text(world, Vector2i(21, 9), "溪", "middle road returns to creek after bridge split")
	assert_any_text(world, Vector2i(21, 10), "溪", "lower rail returns to creek after bridge split")
	assert_any_text(world, Vector2i(19, 8), "树", "tree top returns after bridge split")
	assert_any_text(world, Vector2i(19, 10), "木", "tree trunk returns after bridge split")
	assert_true(world.find_first_entity_by_text("这桥看起来很结实，") == null, "tree prompt switches away from 桥")
	var tree_prompt := world.find_first_entity_by_text("这乔木看起来很结实，")
	assert_true(tree_prompt != null and tree_prompt.grid_pos == Vector2i(2, 6), "tree prompt switches back to 乔木")

func test_bridge_split_requests_visual_effect() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetR1.build_level())
	world.try_merge_entities(Vector2i(15, 3), Vector2i(14, 3))
	world.consume_visual_effects()
	world.player_pos = Vector2i(15, 3)
	world.facing = Vector2i.LEFT
	var split := world.split_front()
	assert_true(split.success, "bridge split succeeds before visual effect request check")
	var requests := world.consume_visual_effects()
	var found := false
	for request_value in requests:
		var request: Dictionary = request_value
		if str(request.get("type", "")) != "word_split_transition":
			continue
		found = true
		assert_equal(request.get("source_cell", Vector2i.ZERO), Vector2i(14, 3), "split visual anchors at the source cell")
		assert_equal(request.get("source_text", ""), "桥", "split visual keeps source text")
		assert_equal(request.get("part_texts", []), ["乔", "木"], "split visual records split texts")
		assert_equal(request.get("part_cells", []), [Vector2i(14, 3), Vector2i(15, 3)], "split visual records target cells")
	assert_true(found, "bridge split emits a word_split_transition visual request")

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
