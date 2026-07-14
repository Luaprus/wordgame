extends SceneTree

const GLOVE_LEVEL_PATH := "res://levels/glove/glove_level.gd"
const GLOVE_CORRECT_ROUTE_PATH := "res://../harness/demo_routes/glove/glove_correct_route.json"
const GLOVE_GESTURE_CHANGE_ROUTE_PATH := "res://../harness/demo_routes/glove/glove_gesture_change.json"
const GLOVE_RELEASE_AFTER_DELETE_ROUTE_PATH := "res://../harness/demo_routes/glove/glove_release_after_delete_no.json"
const GLOVE_COLLISION_CHANGE_ROUTE_PATH := "res://../harness/demo_routes/glove/glove_collision_change.json"
const GLOVE_WRONG_ROUTE_PATH := "res://../harness/demo_routes/glove/glove_wrong_route.json"
const GLOVE_CORRECT_ROUTE_RUNTIME_PATH := "res://../harness/demo_routes/glove/glove_correct_route_runtime.json"
const GLOVE_WRONG_ROUTE_RUNTIME_PATH := "res://../harness/demo_routes/glove/glove_wrong_route_runtime.json"
const GLOVE_GESTURE_CYCLE_ROUTE_RUNTIME_PATH := "res://../harness/demo_routes/glove/glove_gesture_cycle_runtime.json"
const GLOVE_LIKE_GESTURE_ROUTE_RUNTIME_PATH := "res://../harness/demo_routes/glove/glove_like_gesture_runtime.json"
const GLOVE_RELEASE_ROUTE_RUNTIME_PATH := "res://../harness/demo_routes/glove/glove_release_after_delete_runtime.json"
const GLOVE_COLLISION_CHANGE_ROUTE_RUNTIME_PATH := "res://../harness/demo_routes/glove/glove_collision_change_runtime.json"
const GLOVE_GOOD_CLUE_ROUTE_RUNTIME_PATH := "res://../harness/demo_routes/glove/glove_good_clue_runtime.json"
const GLOVE_LIFELINE_RECLOSE_ROUTE_RUNTIME_PATH := "res://../harness/demo_routes/glove/glove_lifeline_reclose_runtime.json"
const GLOVE_PATH_OPENED_ROUTE_PATH := "res://../harness/demo_routes/glove/glove_path_opened.json"
const GLOVE_PATH_OPENED_ROUTE_RUNTIME_PATH := "res://../harness/demo_routes/glove/glove_path_opened_runtime.json"
const GLOVE_TRANSITION_OUT_ROUTE_PATH := "res://../harness/demo_routes/glove/glove_transition_out.json"
const GLOVE_TRANSITION_OUT_ROUTE_RUNTIME_PATH := "res://../harness/demo_routes/glove/glove_transition_out_runtime.json"
const GLOVE_SWORD_SWAP_ROUTE_RUNTIME_PATH := "res://../harness/demo_routes/glove/glove_sword_swap_runtime.json"
const GLOVE_ROUTES_INDEX_PATH := "res://../harness/demo_routes/glove/routes.json"
const GLOVE_PREVIEW_SCENE_PATH := "res://levels/glove/glove_preview.tscn"
const MAIN_SCENE_PATH := "res://app/Main.tscn"
const GLOVE_LEVEL_MANIFEST_PATH := "res://levels/glove/level_manifest.json"
const GLOVE_HANDOFF_PATH := "res://levels/glove/handoff.md"
const GLOVE_REPORT_OUTPUT_DIR := "res://../harness/reports/demo/glove"
const GLOVE_MANUAL_REVIEW_OVERRIDES_PATH := "res://../harness/demo_routes/glove/manual_review_overrides.json"
const GridWorld = preload("res://core/grid_world.gd")
const GloveEffects = preload("res://scripts/levels/glove/glove_effects.gd")
const GloveRouteRunner = preload("res://scripts/levels/glove/glove_route_runner.gd")
const GloveRouteReportExporter = preload("res://scripts/levels/glove/glove_route_report_exporter.gd")
const GloveManualReviewImporter = preload("res://scripts/levels/glove/glove_manual_review_importer.gd")
const GloveLayouts = preload("res://scripts/levels/glove/glove_layouts.gd")
const GloveSourceSceneParser = preload("res://scripts/levels/glove/glove_source_scene_parser.gd")

var failures: Array[String] = []

func _init() -> void:
	test_glove_level_file_and_builder_exist()
	test_glove_level_manifest_and_handoff_exist_and_match_runtime()
	test_glove_level_initial_layout_anchor()
	test_docx_figure_one_advances_to_figure_two_on_global_interact()
	test_docx_figure_three_opens_and_recloses_middle_palm_wall()
	test_source_initial_scene_uses_original_figure_one_anchors()
	test_moving_one_into_gesture_slot_switches_automatically()
	test_hand_interaction_switches_like_and_release_states()
	test_lifeline_hint_reveals_good_word()
	test_good_word_switches_like_layout()
	test_source_confirmed_love_word_activates_love_gesture()
	test_all_switchable_gesture_words_match_expected_layouts()
	test_gesture_switch_preserves_dynamic_word_without_duplication()
	test_sword_sentence_requires_two_gesture_and_swaps_between_source_positions()
	test_glove_delete_feedback_only_allows_the_no_word()
	test_glove_preview_scene_loads_runtime_world()
	test_glove_preview_supports_transition_out_startup_route_arg()
	test_glove_preview_supports_slow_demo_route_expansion()
	test_glove_preview_slow_demo_reaches_correct_route_ending()
	test_glove_preview_parses_startup_capture_arg()
	test_glove_preview_supports_return_to_main_shortcut()
	test_glove_preview_activates_transition_reference_overlay()
	test_glove_preview_resolves_failure_reference_capture_image()
	test_lifeline_fails_on_wrong_hand_and_opens_on_like()
	test_failure_reset_restores_initial_glove_gate_state()
	test_lifeline_recloses_after_switching_back_to_closed_gesture()
	test_open_lifeline_enters_playable_path_state()
	test_transition_out_requires_sword_shift_to_right()
	test_transition_out_uses_screenshot_backed_black_screen_dialogue()
	test_transition_out_advances_through_source_tail_dialogue()
	test_transition_out_matches_baseline_anchor_cells()
	test_transition_out_blocks_followup_actions()
	test_runtime_route_expectations_fail_on_mismatch()
	test_glove_route_runner_supports_move_path_steps()
	test_glove_route_runner_supports_action_sequence_steps()
	test_glove_route_runner_supports_verified_route_segments()
	test_correct_route_uses_move_path_to_good_hand_palm_point()
	test_correct_route_uses_real_pull_and_push_for_good_word()
	test_correct_route_uses_move_path_to_mid_anchor_after_opening_lifeline()
	test_correct_route_uses_move_path_to_sentence_sword_anchor()
	test_correct_route_uses_source_event_to_transition_anchor()
	test_correct_route_no_longer_uses_set_player_steps()
	test_canonical_route_catalog_points_to_real_glove_routes()
	test_path_opened_route_no_longer_uses_set_player_steps()
	test_wrong_route_no_longer_uses_set_player_steps()
	test_good_clue_route_no_longer_uses_set_player_steps()
	test_transition_out_route_no_longer_uses_set_player_steps()
	test_sword_swap_route_no_longer_uses_set_player_steps()
	test_runtime_routes_cover_success_and_failure_flows()
	test_canonical_routes_cover_correct_wrong_path_opened_transition_and_helper_flows()
	test_correct_route_report_records_source_backed_checkpoints()
	test_path_opened_route_report_records_mid_path_checkpoint()
	test_correct_route_report_records_initial_layout_checkpoint()
	test_gesture_cycle_route_records_source_backed_gesture_checkpoints()
	test_wrong_route_report_records_failure_feedback_checkpoint()
	test_collision_change_route_records_candidate_collision_checkpoint()
	test_good_clue_route_records_candidate_good_hand_checkpoint()
	test_sword_swap_route_records_rule_only_checkpoint()
	test_runtime_routes_record_trace_for_gesture_change_release_and_path_opened()
	test_runtime_routes_record_trace_for_transition_and_failure_feedback()
	test_helper_routes_record_checkpoint_review_status()
	test_runtime_routes_cover_gesture_cycle_and_release_flow()
	test_runtime_route_covers_real_like_word_flow()
	test_runtime_route_covers_collision_change_flow()
	test_runtime_route_covers_good_clue_flow()
	test_runtime_route_covers_lifeline_reclose_flow()
	test_runtime_route_covers_path_opened_flow()
	test_runtime_route_covers_transition_out_flow()
	test_runtime_route_covers_sword_swap_flow()
	test_glove_manual_review_importer_normalizes_input()
	test_glove_route_report_exporter_writes_runtime_reports()
	test_glove_source_scene_parser_extracts_all_gesture_shapes()
	test_glove_hand_layout_uses_source_node_origin()
	test_glove_source_scene_parser_extracts_love_gesture_state_details()
	test_glove_source_scene_parser_extracts_love_word_source_details()
	test_glove_source_scene_parser_extracts_typewriter_layer_reference_details()
	test_glove_source_scene_parser_extracts_typewriter_runtime_generation_details()
	test_glove_source_visual_shapes_extend_runtime_collision_layouts()

	if failures.is_empty():
		print("glove_level tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func test_glove_level_file_and_builder_exist() -> void:
	assert_true(FileAccess.file_exists(GLOVE_LEVEL_PATH), "glove level script exists")
	if not FileAccess.file_exists(GLOVE_LEVEL_PATH):
		return
	var glove_script = load(GLOVE_LEVEL_PATH)
	assert_true(glove_script != null, "glove level script loads")
	assert_true(glove_script.has_method("build_level"), "glove level exposes build_level")

func test_glove_level_manifest_and_handoff_exist_and_match_runtime() -> void:
	assert_true(FileAccess.file_exists(GLOVE_LEVEL_MANIFEST_PATH), "glove level manifest exists")
	assert_true(FileAccess.file_exists(GLOVE_HANDOFF_PATH), "glove level handoff exists")
	if not FileAccess.file_exists(GLOVE_LEVEL_MANIFEST_PATH) or not FileAccess.file_exists(GLOVE_HANDOFF_PATH):
		return

	var manifest := read_json_file(GLOVE_LEVEL_MANIFEST_PATH)
	assert_equal(str(manifest.get("level_id", "")), "glove", "glove manifest level_id matches runtime")
	assert_equal(str(manifest.get("display_name", "")), "手套关", "glove manifest display name matches runtime")

	var target: Dictionary = manifest.get("target", {})
	assert_equal(str(target.get("preview_scene", "")), GLOVE_PREVIEW_SCENE_PATH, "glove manifest preview scene matches runtime scene")
	assert_equal(str(target.get("level_script", "")), GLOVE_LEVEL_PATH, "glove manifest level script matches runtime script")

	var map_info: Dictionary = manifest.get("map", {})
	assert_equal(normalize_numeric_array(map_info.get("screen_size", [])), [32, 18], "glove manifest screen size matches runtime")
	assert_equal(normalize_numeric_array(map_info.get("player_spawn_pos", [])), [20, 15], "glove manifest player spawn matches runtime")

	var source: Dictionary = manifest.get("source", {})
	var source_maps: Array = source.get("source_maps", [])
	assert_true(source_maps.size() >= 5, "glove manifest records the main source map candidates")
	assert_manifest_source_map(source_maps, "04_手套教學.tscn", "glove manifest includes the teaching source map")
	assert_manifest_source_map(source_maps, "11_添譜來堂_開場.tscn", "glove manifest includes the gesture source map")
	assert_manifest_source_map(source_maps, "15_添譜來堂_拳頭.tscn", "glove manifest includes the fist-stage source map")

	var flow: Dictionary = manifest.get("flow", {})
	var route_ids: Array = flow.get("route_ids", [])
	assert_true(route_ids.has("glove_correct_route_runtime"), "glove manifest includes the correct route id")
	assert_true(route_ids.has("glove_transition_out_runtime"), "glove manifest includes the transition route id")

	var handoff_text := read_text_file(GLOVE_HANDOFF_PATH)
	assert_text_contains(handoff_text, "GLOVE-SHOT-009", "glove handoff mentions the transition visual anchor")
	assert_text_contains(handoff_text, "GLOVE-GRID-015", "glove handoff mentions the good-hand candidate grid anchor")
	assert_text_contains(handoff_text, "candidate", "glove handoff distinguishes candidate evidence from confirmed runtime truth")
	assert_text_contains(handoff_text, "仍未完成的人工复查", "glove handoff includes the manual review section")
	assert_true(not handoff_text.contains("�"), "glove handoff is valid UTF-8 without replacement characters")
	assert_text_contains(handoff_text, "当前手套关不再只是“独立 preview 入口”", "glove handoff keeps the readable main-entry bridge supplement")

func test_glove_level_initial_layout_anchor() -> void:
	if not FileAccess.file_exists(GLOVE_LEVEL_PATH):
		fail("cannot verify glove layout before glove level script exists")
		return
	var glove_script = load(GLOVE_LEVEL_PATH)
	if glove_script == null or not glove_script.has_method("build_level"):
		fail("cannot verify glove layout before build_level exists")
		return
	var level: Dictionary = glove_script.build_level()
	assert_equal(level.get("rows", []).size(), 18, "glove level has 18 rows")
	for i in range(level.get("rows", []).size()):
		assert_equal(str(level.rows[i]).length(), 32, "glove row %s has 32 columns" % i)
	var world := GridWorld.new()
	world.load_level(level)
	assert_equal(world.player_pos, Vector2i(20, 15), "glove initial player anchor matches baseline")
	assert_true(world.find_first_entity_by_text("掌") != null, "glove initial layout includes palm wall text")
	assert_true(world.find_first_entity_by_text("零") != null, "glove initial layout includes zero gesture word")
	assert_true(world.find_first_entity_by_text("好") == null, "DOCX figure 1 does not expose the good word before the opening interact")

func test_docx_figure_one_advances_to_figure_two_on_global_interact() -> void:
	var world := make_world()
	var result: Dictionary = world.interact_front()
	assert_true(result.success, "DOCX figure 1 accepts the opening interact without requiring a front target")
	assert_any_text(world, GloveLayouts.GOOD_WORD_POS, "好", "DOCX figure 2 exposes 好 inside the lifeline sentence")
	assert_equal(str(world.last_message), "勇：别被一条线给困住了！", "DOCX figure 2 shows the opening dialogue line")

func test_docx_figure_three_opens_and_recloses_middle_palm_wall() -> void:
	var world := make_world()
	assert_true(world.interact_front().success, "enter DOCX figure 2 before moving 好")
	var good_word = world.find_first_entity_by_text("好")
	assert_true(good_word != null, "DOCX figure 2 contains a movable 好")
	if good_word == null:
		return
	var middle_wall: Array[Vector2i] = [Vector2i(21, 12), Vector2i(22, 12), Vector2i(23, 12), Vector2i(23, 13), Vector2i(23, 14), Vector2i(23, 15), Vector2i(23, 16)]
	assert_true(not middle_wall.is_empty(), "figure 3 defines the middle palm wall segment")
	world.move_entity_to(good_word.id, GloveLayouts.GOOD_WORD_POS + Vector2i.UP)
	world.check_sentence_rules()
	for cell in middle_wall:
		assert_true(world.get_any_entity_at(cell) == null, "DOCX figure 3 removes middle palm wall cell %s" % cell)
	world.move_entity_to(good_word.id, GloveLayouts.GOOD_WORD_POS)
	world.check_sentence_rules()
	for cell in middle_wall:
		assert_any_text(world, cell, "掌", "returning 好 restores middle palm wall cell %s" % cell)

func test_source_initial_scene_uses_original_figure_one_anchors() -> void:
	var world := make_world()
	var lifeline_wall: Array[Vector2i] = [Vector2i(21, 12), Vector2i(22, 12), Vector2i(23, 12), Vector2i(23, 13), Vector2i(23, 14), Vector2i(23, 15), Vector2i(23, 16)]
	assert_any_text(world, Vector2i(16, 7), "剑", "source figure 1 places the palm sword at [16,7]")
	assert_any_text(world, Vector2i(24, 4), "勇", "source figure 1 places the inner hero at [24,4]")
	assert_any_text(world, Vector2i(1, 8), "勇", "source figure 1 places the upper spectator hero at [1,8]")
	assert_any_text(world, Vector2i(1, 16), "勇", "source figure 1 places the lower spectator hero at [1,16]")
	for cell in lifeline_wall:
		assert_any_text(world, cell, "掌", "source figure 1 includes lifeline palm wall cell %s" % cell)
	assert_any_text(world, Vector2i(1, 8), "勇", "document figure 1 renders the opening hero dialogue at its source anchor")

func test_moving_one_into_gesture_slot_switches_automatically() -> void:
	var world := make_world()
	var zero_word = world.find_first_entity_by_text("零")
	var one_word = world.find_first_entity_by_text("一")
	assert_true(zero_word != null and one_word != null, "figure 1 exposes zero and one as movable words")
	if zero_word == null or one_word == null:
		return
	world.move_entity_to(zero_word.id, Vector2i(25, 16))
	world.move_entity_to(one_word.id, Vector2i(26, 17))
	assert_equal(str(world.last_message), "巨大手掌，是一的手势。", "placing 一 in the sentence switches gesture without another palm interaction")
	assert_hand_layout(world, "one", "placing 一 in the gesture slot automatically selects the one-hand layout")

func test_hand_interaction_switches_like_and_release_states() -> void:
	var world := make_world()
	set_gesture_slot(world, "赞")
	place_player_left_of_first_palm(world)
	var like_result: Dictionary = world.interact_front()
	assert_true(like_result.success, "interacting with palm applies like gesture")
	assert_any_text(world, GloveLayouts.HAND_ORIGIN + Vector2i(0, 8), "掌", "like gesture extends the left thumb anchor")

	world.player_pos = Vector2i(5, 3)
	world.facing = Vector2i.RIGHT
	var delete_result: Dictionary = world.delete_front()
	assert_true(delete_result.success, "delete removes 不 from the release sentence")
	place_player_left_of_first_palm(world)
	var release_result: Dictionary = world.interact_front()
	assert_true(release_result.success, "interacting with palm after deleting 不 enters release state")
	assert_any_text(world, GloveLayouts.HAND_ORIGIN + Vector2i(0, 12), "掌", "release gesture exposes the lower-left open palm anchor")

func test_lifeline_hint_reveals_good_word() -> void:
	var world := make_world()
	world.player_pos = Vector2i(20, 13)
	world.facing = Vector2i.RIGHT
	var result: Dictionary = world.interact_front()
	assert_true(result.success, "interacting with the lower lifeline clue succeeds")
	assert_any_text(world, Vector2i(14, 13), "好", "lifeline clue reveals the good word")
	assert_equal(str(world.last_message), "逼退好手的生命线", "lifeline clue uses the original good-hand phrasing")

func test_good_word_switches_like_layout() -> void:
	var world := make_world()
	world.player_pos = Vector2i(20, 13)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "reveal the good word before using it")
	var good_word = world.find_first_entity_by_text("好")
	assert_true(good_word != null, "good word exists after lifeline clue")
	if good_word == null:
		return
	set_gesture_slot(world, "好")
	place_player_left_of_first_palm(world)
	var result: Dictionary = world.interact_front()
	assert_true(result.success, "good word can drive the hand gesture")
	assert_equal(str(world.last_message), "巨大手掌，是好的手势。", "good word maps to the good-hand message")
	assert_hand_layout(world, "like", "good word shares the like-hand layout")

func test_source_confirmed_love_word_activates_love_gesture() -> void:
	var world := make_world()
	world.add_entity("爱", Vector2i(31, 16), {"solid": true, "pushable": true})
	set_gesture_slot(world, "爱")
	place_player_left_of_first_palm(world)
	var hand_result: Dictionary = world.interact_front()
	assert_true(hand_result.success, "love-word palm interaction still resolves")
	assert_equal(str(world.last_message), "巨大手掌，是爱的手势。", "source-confirmed love word selects the love gesture")
	assert_hand_layout(world, "love", "source-confirmed love word activates the dedicated love layout")

	world.player_pos = Vector2i(20, 12)
	world.facing = Vector2i.RIGHT
	var lifeline_result: Dictionary = world.interact_front()
	assert_true(lifeline_result.success, "lifeline interaction resolves with the love word in slot")
	assert_any_text(world, Vector2i(15, 10), "勇", "love gesture keeps its source-specific blocked lifeline behavior")

func test_all_switchable_gesture_words_match_expected_layouts() -> void:
	var cases := [
		{"text": "赞", "state": "like", "message": "巨大手掌，是赞的手势。"},
		{"text": "一", "state": "one", "message": "巨大手掌，是一的手势。"},
		{"text": "二", "state": "two", "message": "巨大手掌，是二的手势。"},
		{"text": "赢", "state": "win", "message": "巨大手掌，是赢的手势。"},
		{"text": "零", "state": "zero", "message": "巨大手掌，是零的手势。"}
	]
	for case_entry in cases:
		var world := make_world()
		set_gesture_slot(world, str(case_entry.text))
		place_player_left_of_first_palm(world)
		var result: Dictionary = world.interact_front()
		assert_true(result.success, "gesture %s interaction succeeds" % case_entry.text)
		assert_equal(str(world.last_message), str(case_entry.message), "gesture %s updates hand message" % case_entry.text)
		assert_hand_layout(world, str(case_entry.state), "gesture %s matches expected hand layout" % case_entry.text)

func test_gesture_switch_preserves_dynamic_word_without_duplication() -> void:
	var world := make_world()
	set_gesture_slot(world, "赞")
	place_player_left_of_first_palm(world)
	assert_true(world.interact_front().success, "switching into the like gesture succeeds before the preservation check")

	var preserved_word = world.find_first_entity_by_text("二")
	assert_true(preserved_word != null, "preserved test word exists before the gesture-switch check")
	if preserved_word == null:
		return
	var stressed_cell := Vector2i(0, 13)
	world.move_entity_to(preserved_word.id, stressed_cell)
	assert_equal(preserved_word.grid_pos, stressed_cell, "test setup moves the dynamic word into a next-gesture redraw cell")

	set_gesture_slot(world, "一")
	place_player_left_of_first_palm(world)
	var switch_result: Dictionary = world.interact_front()
	assert_true(switch_result.success, "switching from like to one succeeds during the preservation check")
	assert_equal(str(world.last_message), "巨大手掌，是一的手势。", "preservation check reaches the one gesture")
	assert_equal(count_entities_by_text(world, "二"), 1, "gesture switching does not duplicate or swallow the stressed dynamic word")

	var relocated_word = world.find_first_entity_by_text("二")
	assert_true(relocated_word != null, "stressed dynamic word still exists after the gesture switch")
	if relocated_word == null:
		return
	assert_equal(relocated_word.grid_pos, stressed_cell, "gesture switching keeps the stressed dynamic word on its original grid cell")
	assert_equal(relocated_word.cells, [stressed_cell], "gesture switching keeps the stressed dynamic word cell footprint stable")

func test_sword_sentence_requires_two_gesture_and_swaps_between_source_positions() -> void:
	var world := make_world()
	assert_any_text(world, GloveLayouts.SWORD_LEFT_POS, "剑", "sword starts on the left source anchor")
	place_player_left_of_sentence_sword(world)
	var blocked_result: Dictionary = world.interact_front()
	assert_true(blocked_result.success, "sentence sword interaction resolves even before the two gesture")
	assert_equal(str(world.last_message), "得先比出二的手势。", "sword sentence blocks swapping before the two gesture")
	assert_any_text(world, GloveLayouts.SWORD_LEFT_POS, "剑", "sword stays on the left anchor before the two gesture")
	assert_true(world.get_any_entity_at(GloveLayouts.SWORD_RIGHT_POS) == null, "right sword anchor stays empty before the two gesture")

	set_gesture_slot(world, "二")
	place_player_left_of_first_palm(world)
	assert_true(world.interact_front().success, "switching to the two gesture succeeds")
	place_player_left_of_sentence_sword(world)
	var move_right_result: Dictionary = world.interact_front()
	assert_true(move_right_result.success, "sentence sword interaction swaps after the two gesture")
	assert_true(world.get_any_entity_at(GloveLayouts.SWORD_LEFT_POS) == null, "left sword anchor clears after the first swap")
	assert_any_text(world, GloveLayouts.SWORD_RIGHT_POS, "剑", "first sword swap lands on the right source anchor")
	assert_equal(str(world.last_message), "二指伸直，掌中剑换到了右边。", "first sword swap reports the rightward move")

	place_player_left_of_sentence_sword(world)
	var move_left_result: Dictionary = world.interact_front()
	assert_true(move_left_result.success, "sentence sword interaction swaps back while staying in the two gesture")
	assert_any_text(world, GloveLayouts.SWORD_LEFT_POS, "剑", "second sword swap lands back on the left source anchor")
	assert_true(world.get_any_entity_at(GloveLayouts.SWORD_RIGHT_POS) == null, "right sword anchor clears after swapping back")
	assert_equal(str(world.last_message), "二指伸直，掌中剑换到了左边。", "second sword swap reports the leftward move")

	var win_world := make_world()
	set_gesture_slot(win_world, "赢")
	place_player_left_of_first_palm(win_world)
	assert_true(win_world.interact_front().success, "switching to the win gesture succeeds")
	place_player_left_of_source_sword(win_world)
	assert_true(win_world.interact_front().success, "source sword interaction still resolves during the win gesture")
	assert_equal(str(win_world.last_message), "得先比出二的手势。", "win gesture cannot trigger the sword swap")
	assert_any_text(win_world, GloveLayouts.SWORD_LEFT_POS, "剑", "win gesture keeps the sword on the left source anchor")
	assert_true(win_world.get_any_entity_at(GloveLayouts.SWORD_RIGHT_POS) == null, "win gesture does not populate the right sword anchor")

	var release_world := make_world()
	release_world.player_pos = Vector2i(5, 3)
	release_world.facing = Vector2i.RIGHT
	assert_true(release_world.delete_front().success, "delete removes 不 before the release gesture")
	place_player_left_of_first_palm(release_world)
	assert_true(release_world.interact_front().success, "switching to the release gesture succeeds")
	place_player_left_of_source_sword(release_world)
	assert_true(release_world.interact_front().success, "source sword interaction still resolves during the release gesture")
	assert_equal(str(release_world.last_message), "得先比出二的手势。", "release gesture cannot trigger the sword swap")
	assert_any_text(release_world, GloveLayouts.SWORD_LEFT_POS, "剑", "release gesture keeps the sword on the left source anchor")
	assert_true(release_world.get_any_entity_at(GloveLayouts.SWORD_RIGHT_POS) == null, "release gesture does not populate the right sword anchor")

func test_glove_delete_feedback_only_allows_the_no_word() -> void:
	var blocked_world := make_world()
	blocked_world.player_pos = Vector2i(0, 2)
	blocked_world.facing = Vector2i.RIGHT
	var blocked_delete: Dictionary = blocked_world.delete_front()
	assert_true(not blocked_delete.success, "glove delete rejects non-deletable words")
	assert_equal(str(blocked_delete.get("message", "")), "not deletable", "glove delete returns the core non-deletable feedback")
	assert_equal(count_entities_by_text(blocked_world, "赢"), 1, "failed glove delete keeps the target word in place")

	var allowed_world := make_world()
	allowed_world.player_pos = Vector2i(5, 3)
	allowed_world.facing = Vector2i.RIGHT
	var allowed_delete: Dictionary = allowed_world.delete_front()
	assert_true(allowed_delete.success, "glove delete still allows removing 不")
	assert_true(allowed_world.get_any_entity_at(Vector2i(6, 3)) == null, "successful glove delete clears the 不 gate cell")

func test_lifeline_fails_on_wrong_hand_and_opens_on_like() -> void:
	var wrong_world := make_world()
	wrong_world.player_pos = Vector2i(20, 12)
	wrong_world.facing = Vector2i.RIGHT
	var wrong_result: Dictionary = wrong_world.interact_front()
	assert_true(wrong_result.success, "wrong-hand life line interaction still resolves")
	assert_any_text(wrong_world, Vector2i(15, 10), "勇", "wrong-hand life line interaction enters failure feedback")
	assert_true(wrong_world.interact_front().success, "failure feedback accepts one more interact to reset")
	assert_equal(wrong_world.player_pos, Vector2i(20, 15), "failure feedback reset returns player to start")

	var like_world := make_world()
	set_gesture_slot(like_world, "赞")
	place_player_left_of_first_palm(like_world)
	assert_true(like_world.interact_front().success, "setup palm interaction enters like state")
	like_world.player_pos = Vector2i(20, 12)
	like_world.facing = Vector2i.RIGHT
	var open_result: Dictionary = like_world.interact_front()
	assert_true(open_result.success, "like hand opens the life line")
	assert_true(like_world.get_any_entity_at(Vector2i(21, 12)) == null, "life line center cell clears after the correct hand")

func test_failure_reset_restores_initial_glove_gate_state() -> void:
	var world := make_world()
	world.player_pos = Vector2i(20, 12)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "wrong-hand life line interaction enters the failure branch")
	assert_any_text(world, Vector2i(15, 10), "勇", "failure branch renders the surrounded-by-heroes feedback")
	assert_true(world.player_input_locked, "failure feedback locks ordinary player input")
	var blocked_move: Dictionary = world.try_move_player(Vector2i.LEFT)
	assert_true(not blocked_move.success, "failure feedback blocks movement before retry")
	assert_equal(str(blocked_move.get("message", "")), "input locked", "failure feedback movement reports input locked")
	var blocked_delete: Dictionary = world.delete_front()
	assert_true(not blocked_delete.success, "failure feedback blocks delete before retry")
	assert_equal(str(blocked_delete.get("message", "")), "input locked", "failure feedback delete reports input locked")
	assert_true(world.interact_front().success, "failure branch accepts interact to reset")
	assert_equal(world.player_pos, GloveLayouts.PLAYER_START, "failure reset returns the player to the glove spawn")
	assert_any_text(world, GloveEffects.DELETE_NO_POS, "不", "failure reset restores the deletable 不 gate")
	assert_any_text(world, GloveLayouts.LIFELINE_POS, "线", "failure reset restores the closed life line")

func test_lifeline_recloses_after_switching_back_to_closed_gesture() -> void:
	var world := make_world()
	set_gesture_slot(world, "赞")
	place_player_left_of_first_palm(world)
	assert_true(world.interact_front().success, "setup palm interaction enters like state")
	world.player_pos = Vector2i(20, 12)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "like hand opens the life line")
	assert_true(world.get_any_entity_at(Vector2i(21, 12)) == null, "life line is open before switching away")

	set_gesture_slot(world, "零")
	place_player_left_of_first_palm(world)
	assert_true(world.interact_front().success, "switching back to zero gesture still succeeds")
	assert_any_text(world, Vector2i(21, 12), "线", "switching back to a closed gesture restores the life line")
	world.player_pos = Vector2i(20, 12)
	world.facing = Vector2i.RIGHT
	var blocked_result: Dictionary = world.try_move_player(Vector2i.RIGHT)
	assert_true(not blocked_result.success, "restored life line blocks movement again")
	assert_equal(str(blocked_result.get("message", "")), "blocked", "restored life line reports blocked movement")

func test_open_lifeline_enters_playable_path_state() -> void:
	var world := make_world()
	set_gesture_slot(world, "赞")
	place_player_left_of_first_palm(world)
	assert_true(world.interact_front().success, "setup palm interaction enters like state")
	world.player_pos = Vector2i(20, 12)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "like hand opens the life line")
	var move_result: Dictionary = world.try_move_player(Vector2i.RIGHT)
	assert_true(move_result.success, "player can step through the opened life line")
	assert_equal(world.player_pos, Vector2i(21, 12), "opened life line becomes a traversable path anchor")
	assert_true(world.player_visible, "path-opened state keeps player visible")
	assert_true(not world.player_input_locked, "path-opened state does not lock input")
	assert_equal(str(world.last_message), "好手逼退了生命线。", "path-opened state keeps the open-path message until transition")

func test_transition_out_requires_sword_shift_to_right() -> void:
	var world := make_world()
	set_gesture_slot(world, "赞")
	place_player_left_of_first_palm(world)
	assert_true(world.interact_front().success, "setup palm interaction enters like state")
	world.player_pos = Vector2i(20, 12)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "like hand opens the life line")
	world.player_pos = Vector2i(24, 6)
	world.facing = Vector2i.UP
	var blocked_transition: Dictionary = world.try_move_player(Vector2i.UP)
	assert_true(blocked_transition.success, "player can still step onto the transition tile without a sword swap")
	assert_equal(world.player_pos, Vector2i(24, 5), "player still reaches the transition tile position")
	assert_true(world.player_visible, "transition stays inactive before the sword is shifted right")
	assert_true(not world.player_input_locked, "input stays unlocked before the sword is shifted right")
	assert_true(world.get_any_entity_at(Vector2i(24, 5)) == null, "transition marker does not spawn before the sword is shifted right")

func test_transition_out_uses_screenshot_backed_black_screen_dialogue() -> void:
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_TRANSITION_OUT_ROUTE_RUNTIME_PATH)
	var world := make_world()
	var result: Dictionary = runner.run_route(world, route)
	assert_true(result.get("success", false), "transition-out route completes before dialogue verification")
	assert_any_text(world, Vector2i(1, 3), "「", "transition-out uses the screenshot-backed opening quote")
	assert_any_text(world, Vector2i(2, 3), "果", "transition-out uses the screenshot-backed first dialogue line")
	assert_any_text(world, Vector2i(2, 4), "你", "transition-out uses the screenshot-backed second dialogue line")
	assert_any_text(world, Vector2i(11, 4), "▽", "transition-out keeps the screenshot-backed prompt marker")
	assert_any_text(world, Vector2i(24, 5), "勇", "transition-out keeps the right-side vertical role text")
	assert_any_text(world, Vector2i(24, 6), "我", "transition-out keeps the right-side player text")
	assert_any_text(world, Vector2i(1, 9), "勇", "transition-out keeps the upper-left role text")
	assert_any_text(world, Vector2i(1, 17), "勇", "transition-out keeps the lower-left role text")
	assert_true(world.get_any_entity_at(Vector2i(24, 5)) == null or world.get_any_entity_at(Vector2i(24, 5)).text != "终", "transition-out no longer renders a synthetic terminal glyph over the screenshot-backed black screen")

func test_transition_out_advances_through_source_tail_dialogue() -> void:
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_TRANSITION_OUT_ROUTE_RUNTIME_PATH)
	var world := make_world()
	var result: Dictionary = runner.run_route(world, route)
	assert_true(result.get("success", false), "transition-out route completes before source dialogue progression")
	assert_true(world.interact_front().success, "first black-screen prompt advances to the second source dialogue page")
	assert_any_text(world, Vector2i(2, 3), "你", "second source dialogue page starts with the you-and-us line")
	assert_any_text(world, Vector2i(2, 5), "才", "second source dialogue page keeps the final breakthrough line")
	assert_true(world.interact_front().success, "second black-screen prompt advances to the third source dialogue page")
	assert_any_text(world, Vector2i(2, 3), "四", "third source dialogue page calls the player by number")
	assert_any_text(world, Vector2i(2, 4), "請", "third source dialogue page asks the player to step forward")
	assert_true(world.interact_front().success, "third black-screen prompt completes the source map handoff")
	assert_equal(str(world.last_message), "进入第三章/16_添譜來堂_尾聲", "black-screen dialogue records the source destination map")
	assert_true(world.pending_interact_effect.is_empty(), "source tail dialogue has no extra synthetic page after the map handoff")

func test_transition_out_matches_baseline_anchor_cells() -> void:
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_TRANSITION_OUT_ROUTE_RUNTIME_PATH)
	var world := make_world()
	var result: Dictionary = runner.run_route(world, route)
	assert_true(result.get("success", false), "transition-out route completes before baseline-anchor verification")
	assert_any_text(world, Vector2i(1, 3), "「", "transition-out first dialogue line starts on the baseline-backed row")
	assert_any_text(world, Vector2i(1, 4), "「", "transition-out second dialogue line starts on the baseline-backed row")
	assert_any_text(world, Vector2i(11, 4), "▽", "transition-out prompt marker sits near the baseline-backed dialogue tail")
	assert_any_text(world, Vector2i(24, 5), "勇", "transition-out right-side role text uses the baseline-backed column")
	assert_any_text(world, Vector2i(24, 6), "我", "transition-out right-side player text uses the baseline-backed column")
	assert_any_text(world, Vector2i(1, 9), "勇", "transition-out upper-left role text uses the baseline-backed row")
	assert_any_text(world, Vector2i(1, 17), "勇", "transition-out lower-left role text uses the baseline-backed row")

func test_transition_out_blocks_followup_actions() -> void:
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_TRANSITION_OUT_ROUTE_RUNTIME_PATH)
	var world := make_world()
	var result: Dictionary = runner.run_route(world, route)
	assert_true(result.get("success", false), "transition-out route completes before locked-input verification")
	assert_true(world.player_input_locked, "transition-out leaves input locked")
	assert_true(world.player_event_locked, "transition-out leaves events locked")

	var move_result: Dictionary = world.try_move_player(Vector2i.LEFT)
	assert_true(not move_result.success, "transition-out blocks follow-up movement")
	assert_equal(str(move_result.get("message", "")), "input locked", "transition-out movement reports input locked")

	var interact_result: Dictionary = world.interact_front()
	assert_true(interact_result.success, "transition-out keeps interaction available for the source tail dialogue")
	assert_equal(str(interact_result.get("message", "")), "尾声对白第二页", "transition-out interaction advances to the second source dialogue page")

	var delete_result: Dictionary = world.delete_front()
	assert_true(not delete_result.success, "transition-out blocks follow-up delete")
	assert_equal(str(delete_result.get("message", "")), "input locked", "transition-out delete reports input locked")

func test_glove_preview_scene_loads_runtime_world() -> void:
	assert_true(FileAccess.file_exists(GLOVE_PREVIEW_SCENE_PATH), "glove preview scene exists")
	if not FileAccess.file_exists(GLOVE_PREVIEW_SCENE_PATH):
		return
	var packed_scene := load(GLOVE_PREVIEW_SCENE_PATH)
	assert_true(packed_scene is PackedScene, "glove preview scene loads as PackedScene")
	if not packed_scene is PackedScene:
		return
	var preview = (packed_scene as PackedScene).instantiate()
	assert_true(preview != null, "glove preview scene instantiates")
	assert_true(preview.has_method("initialize_preview_world"), "glove preview exposes initialize_preview_world")
	if preview == null or not preview.has_method("initialize_preview_world"):
		return
	preview.initialize_preview_world()
	assert_true(preview.world != null, "glove preview builds a world instance")
	assert_equal(preview.world.player_pos, Vector2i(20, 15), "glove preview world starts at glove baseline anchor")
	assert_true(preview.world.find_first_entity_by_text("掌") != null, "glove preview world includes palm wall")
	preview.queue_free()

func test_glove_preview_supports_transition_out_startup_route_arg() -> void:
	assert_true(FileAccess.file_exists(GLOVE_PREVIEW_SCENE_PATH), "glove preview scene exists for startup-route arg coverage")
	if not FileAccess.file_exists(GLOVE_PREVIEW_SCENE_PATH):
		return
	var packed_scene := load(GLOVE_PREVIEW_SCENE_PATH)
	assert_true(packed_scene is PackedScene, "glove preview scene loads for startup-route arg coverage")
	if not packed_scene is PackedScene:
		return
	var preview = (packed_scene as PackedScene).instantiate()
	assert_true(preview != null, "glove preview scene instantiates for startup-route arg coverage")
	assert_true(preview.has_method("apply_startup_route_args"), "glove preview exposes startup-route arg application")
	if preview == null or not preview.has_method("apply_startup_route_args"):
		return
	preview.initialize_preview_world()
	preview.apply_startup_route_args(PackedStringArray(["--glove-route=transition_out"]))
	assert_equal(preview.world.player_pos, Vector2i(24, 5), "startup route arg can drive the preview into transition_out")
	assert_true(not preview.world.player_visible, "startup route arg can reach the hidden-player transition state")
	assert_true(preview.world.player_input_locked, "startup route arg can reach the locked-input transition state")
	assert_any_text(preview.world, Vector2i(2, 3), "果", "startup route arg preserves the transition dialogue anchor")
	preview.queue_free()

func test_glove_preview_supports_slow_demo_route_expansion() -> void:
	var packed_scene := load(GLOVE_PREVIEW_SCENE_PATH)
	assert_true(packed_scene is PackedScene, "glove preview scene loads for slow-demo coverage")
	if not packed_scene is PackedScene:
		return
	var preview = (packed_scene as PackedScene).instantiate()
	var expanded: Array = preview._flatten_demo_steps([
		{"type": "checkpoint", "caption": "机器内部检查点"},
		{"type": "move_path", "path": [[1, 0], [0, -1]], "caption": "测试移动"},
		{"type": "action", "action": "interact", "direction": [0, 0], "caption": "测试互动"}
	])
	assert_equal(expanded.size(), 3, "slow demo expands move_path into individual visible inputs")
	assert_equal(str(expanded[0].get("action", "")), "move", "slow demo preserves movement actions")
	assert_equal(str(expanded[2].get("action", "")), "interact", "slow demo preserves interaction actions")
	preview.queue_free()

func test_glove_preview_slow_demo_reaches_correct_route_ending() -> void:
	var packed_scene := load(GLOVE_PREVIEW_SCENE_PATH)
	assert_true(packed_scene is PackedScene, "glove preview scene loads for complete slow-demo coverage")
	if not packed_scene is PackedScene:
		return
	var preview = (packed_scene as PackedScene).instantiate()
	preview.start_demo_for_route(GLOVE_CORRECT_ROUTE_RUNTIME_PATH)
	var guard := 0
	while preview.demo_running and guard < 1000:
		preview._demo_step()
		guard += 1
	assert_true(guard < 1000, "slow demo terminates without looping")
	assert_equal(preview.demo_index, preview.demo_entries.size(), "slow demo executes every visible correct-route input")
	assert_equal(preview.world.player_pos, Vector2i(24, 5), "slow demo reaches the correct-route transition anchor")
	assert_true(preview.world.player_input_locked, "slow demo reaches the locked transition state")
	preview.queue_free()

func test_glove_preview_parses_startup_capture_arg() -> void:
	assert_true(FileAccess.file_exists(GLOVE_PREVIEW_SCENE_PATH), "glove preview scene exists for startup-capture arg coverage")
	if not FileAccess.file_exists(GLOVE_PREVIEW_SCENE_PATH):
		return
	var packed_scene := load(GLOVE_PREVIEW_SCENE_PATH)
	assert_true(packed_scene is PackedScene, "glove preview scene loads for startup-capture arg coverage")
	if not packed_scene is PackedScene:
		return
	var preview = (packed_scene as PackedScene).instantiate()
	assert_true(preview != null, "glove preview scene instantiates for startup-capture arg coverage")
	assert_true(preview.has_method("resolve_capture_path_from_args"), "glove preview exposes startup-capture arg parsing")
	if preview == null or not preview.has_method("resolve_capture_path_from_args"):
		return
	var capture_path = preview.resolve_capture_path_from_args(PackedStringArray(["--glove-capture=E:/tmp/glove-capture.png"]))
	assert_equal(str(capture_path), "E:/tmp/glove-capture.png", "startup capture arg resolves to the requested output path")
	preview.queue_free()

func test_glove_preview_supports_return_to_main_shortcut() -> void:
	assert_true(FileAccess.file_exists(GLOVE_PREVIEW_SCENE_PATH), "glove preview scene exists for return-shortcut coverage")
	if not FileAccess.file_exists(GLOVE_PREVIEW_SCENE_PATH):
		return
	var packed_scene := load(GLOVE_PREVIEW_SCENE_PATH)
	assert_true(packed_scene is PackedScene, "glove preview scene loads for return-shortcut coverage")
	if not packed_scene is PackedScene:
		return
	var preview = (packed_scene as PackedScene).instantiate()
	assert_true(preview != null, "glove preview scene instantiates for return-shortcut coverage")
	assert_true(preview.has_method("resolve_scene_shortcut_from_keycode"), "glove preview exposes scene shortcut resolver")
	if preview == null or not preview.has_method("resolve_scene_shortcut_from_keycode"):
		if preview != null:
			preview.queue_free()
		return
	assert_equal(
		str(preview.resolve_scene_shortcut_from_keycode(KEY_ESCAPE)),
		MAIN_SCENE_PATH,
		"glove preview reserves Escape as the return-to-main shortcut"
	)
	assert_equal(
		str(preview.resolve_scene_shortcut_from_keycode(KEY_F5)),
		"",
		"glove preview keeps route replay hotkeys separate from scene switching"
	)
	preview.queue_free()

func test_glove_preview_activates_transition_reference_overlay() -> void:
	assert_true(FileAccess.file_exists(GLOVE_PREVIEW_SCENE_PATH), "glove preview scene exists for transition overlay coverage")
	if not FileAccess.file_exists(GLOVE_PREVIEW_SCENE_PATH):
		return
	var packed_scene := load(GLOVE_PREVIEW_SCENE_PATH)
	assert_true(packed_scene is PackedScene, "glove preview scene loads for transition overlay coverage")
	if not packed_scene is PackedScene:
		return
	var preview = (packed_scene as PackedScene).instantiate()
	assert_true(preview != null, "glove preview scene instantiates for transition overlay coverage")
	assert_true(preview.has_method("is_transition_reference_overlay_active"), "glove preview exposes transition overlay state helper")
	if preview == null or not preview.has_method("is_transition_reference_overlay_active"):
		return
	preview.initialize_preview_world()
	assert_true(not preview.is_transition_reference_overlay_active(), "transition overlay stays hidden before the transition-out route")
	preview.apply_startup_route_args(PackedStringArray(["--glove-route=transition_out"]))
	assert_true(preview.is_transition_reference_overlay_active(), "transition overlay activates after the transition-out route")
	preview.queue_free()

func test_glove_preview_resolves_failure_reference_capture_image() -> void:
	assert_true(FileAccess.file_exists(GLOVE_PREVIEW_SCENE_PATH), "glove preview scene exists for failure reference coverage")
	if not FileAccess.file_exists(GLOVE_PREVIEW_SCENE_PATH):
		return
	var packed_scene := load(GLOVE_PREVIEW_SCENE_PATH)
	assert_true(packed_scene is PackedScene, "glove preview scene loads for failure reference coverage")
	if not packed_scene is PackedScene:
		return
	var preview = (packed_scene as PackedScene).instantiate()
	assert_true(preview != null, "glove preview scene instantiates for failure reference coverage")
	assert_true(preview.has_method("resolve_reference_capture_image_path"), "glove preview exposes reference capture path resolution")
	if preview == null or not preview.has_method("resolve_reference_capture_image_path"):
		return
	preview.initialize_preview_world()
	preview.apply_startup_route_args(PackedStringArray(["--glove-route=wrong"]))
	var image_path := str(preview.resolve_reference_capture_image_path())
	assert_true(image_path.ends_with("GLOVE_010.png"), "failure route resolves the failure reference capture image")
	preview.queue_free()

func test_runtime_route_expectations_fail_on_mismatch() -> void:
	var runner := GloveRouteRunner.new()
	var world := make_world()
	var route := {
		"route_id": "glove-expect-mismatch",
		"feature_id": "F024",
		"target_feature_id": "F024",
		"baseline_id": "GLOVE-BEH-001",
		"behavior_id": "GLOVE-CORRECT-ROUTE",
		"level_id": "glove",
		"world_source": "glove_level",
		"steps": [
			{
				"type": "set_gesture_slot",
				"text": "赞",
				"caption": "put like gesture into slot",
				"expect": {
					"text_at": {"pos": [26, 17], "text": "零"}
				}
			}
		]
	}
	var result: Dictionary = runner.run_route(world, route)
	assert_true(not result.get("success", true), "route runner rejects mismatched expectations")
	assert_equal(int(result.get("failed_step", -1)), 0, "mismatched expectation reports failed step index")

func test_glove_route_runner_supports_move_path_steps() -> void:
	var runner := GloveRouteRunner.new()
	var world := make_world()
	var route := {
		"route_id": "glove-move-path-probe",
		"feature_id": "F024",
		"steps": [
			{
				"type": "move_path",
				"path": [[0, -1], [0, -1]],
				"caption": "walk upward twice",
				"expect": {"player_pos": [20, 13]}
			}
		]
	}
	var result: Dictionary = runner.run_route(world, route)
	assert_true(result.get("success", false), "route runner accepts move_path steps")
	assert_equal(world.player_pos, Vector2i(20, 13), "move_path walks the player through each segment")

func test_glove_route_runner_supports_action_sequence_steps() -> void:
	var runner := GloveRouteRunner.new()
	var world := make_world()
	var route := {
		"steps": [{
			"type": "action_sequence",
			"actions": [
				{"action": "move", "direction": [0, -1]},
				{"action": "move", "direction": [0, -1]},
				{"action": "move", "direction": [0, -1]}
			],
			"caption": "execute two real movement inputs",
			"expect": {"player_pos": [20, 13]}
		}]
	}
	var result: Dictionary = runner.run_route(world, route)
	assert_true(result.get("success", false), "route runner accepts action_sequence steps")
	assert_equal(world.player_pos, Vector2i(20, 13), "action_sequence executes every input in order")

func test_glove_route_runner_supports_verified_route_segments() -> void:
	var runner := GloveRouteRunner.new()
	var world := make_world()
	var route := {
		"route_id": "verified-segment-test",
		"steps": [{
			"type": "route_segment",
			"route_path": GLOVE_CORRECT_ROUTE_RUNTIME_PATH,
			"through_caption": "walk from opened lifeline to mid path anchor",
			"caption": "reuse verified route to opened path"
		}]
	}
	var result: Dictionary = runner.run_route(world, route)
	assert_true(result.get("success", false), "route runner executes a verified route segment")
	assert_equal(world.player_pos, Vector2i(24, 14), "verified route segment stops after the requested caption")
	assert_any_text(world, Vector2i(26, 17), "好", "verified route segment executes the real good-word push sequence")

func test_correct_route_uses_move_path_to_good_hand_palm_point() -> void:
	assert_true(FileAccess.file_exists(GLOVE_CORRECT_ROUTE_RUNTIME_PATH), "correct route exists for good-hand palm move_path coverage")
	if not FileAccess.file_exists(GLOVE_CORRECT_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_CORRECT_ROUTE_RUNTIME_PATH)
	var found := false
	for step in route.get("steps", []):
		var entry: Dictionary = step
		if str(entry.get("caption", "")) != "walk from clue to the good-hand palm point":
			continue
		found = true
		assert_equal(str(entry.get("type", "")), "move_path", "correct route uses move_path for the good-hand palm approach")
		assert_equal(_variant_to_vec2i(entry.get("expect", {}).get("player_pos", [])), Vector2i(30, 15), "good-hand palm move_path lands at the reachable palm interaction point")
	assert_true(found, "correct route records a dedicated move_path segment for the good-hand palm approach")

func test_correct_route_uses_real_pull_and_push_for_good_word() -> void:
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_CORRECT_ROUTE_RUNTIME_PATH)
	assert_true(route_contains_step_caption(route, "pull zero out of the gesture slot"), "correct route pulls the old zero word out of the slot")
	assert_true(route_contains_step_caption(route, "push good into the gesture slot"), "correct route pushes the revealed good word into the slot")
	assert_true(route_contains_step_caption(route, "push one into the gesture slot"), "correct route uses the one gesture to open the two-word corridor")
	assert_true(route_contains_step_caption(route, "push two into the gesture slot"), "correct route pushes the two word through the one-hand corridor into the slot")
	for step in route.get("steps", []):
		var entry: Dictionary = step
		assert_true(str(entry.get("type", "")) != "set_gesture_slot", "correct route no longer directly places gesture words into the slot")
		assert_true(str(entry.get("type", "")) != "place_at_palm", "correct route no longer teleports the player to a palm interaction point")

func test_correct_route_uses_move_path_to_mid_anchor_after_opening_lifeline() -> void:
	assert_true(FileAccess.file_exists(GLOVE_CORRECT_ROUTE_RUNTIME_PATH), "correct route exists for post-lifeline move_path coverage")
	if not FileAccess.file_exists(GLOVE_CORRECT_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_CORRECT_ROUTE_RUNTIME_PATH)
	var found := false
	for step in route.get("steps", []):
		var entry: Dictionary = step
		if str(entry.get("caption", "")) != "walk from opened lifeline to mid path anchor":
			continue
		found = true
		assert_equal(str(entry.get("type", "")), "move_path", "correct route uses move_path after opening the lifeline")
		assert_equal(_variant_to_vec2i(entry.get("expect", {}).get("player_pos", [])), Vector2i(24, 14), "post-lifeline move_path lands at the mid path anchor")
	assert_true(found, "correct route records a dedicated move_path segment after opening the lifeline")

func test_correct_route_uses_move_path_to_sentence_sword_anchor() -> void:
	assert_true(FileAccess.file_exists(GLOVE_CORRECT_ROUTE_RUNTIME_PATH), "correct route exists for move_path coverage")
	if not FileAccess.file_exists(GLOVE_CORRECT_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_CORRECT_ROUTE_RUNTIME_PATH)
	var found := false
	for step in route.get("steps", []):
		var entry: Dictionary = step
		if str(entry.get("caption", "")) != "walk from the two-hand palm to the sentence sword":
			continue
		found = true
		assert_equal(str(entry.get("type", "")), "move_path", "correct route uses move_path for the sentence sword approach")
		assert_equal(_variant_to_vec2i(entry.get("expect", {}).get("player_pos", [])), Vector2i(4, 1), "move_path sentence sword segment lands at the reachable sword anchor")
	assert_true(found, "correct route records a dedicated move_path segment for the sentence sword approach")

func test_correct_route_uses_source_event_to_transition_anchor() -> void:
	assert_true(FileAccess.file_exists(GLOVE_CORRECT_ROUTE_RUNTIME_PATH), "correct route exists for final source event coverage")
	if not FileAccess.file_exists(GLOVE_CORRECT_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_CORRECT_ROUTE_RUNTIME_PATH)
	var found := false
	for step in route.get("steps", []):
		var entry: Dictionary = step
		if str(entry.get("caption", "")) != "walk from sentence sword to final corridor tile":
			continue
		found = true
		assert_equal(str(entry.get("type", "")), "source_event", "correct route uses the source transition event")
		assert_equal(_variant_to_vec2i(entry.get("pos", [])), Vector2i(24, 5), "source transition event uses the source hero event coordinate")
		assert_equal(_variant_to_vec2i(entry.get("expect", {}).get("player_pos", [])), Vector2i(24, 5), "source transition event lands at the source handoff point")
	assert_true(found, "correct route records a dedicated source transition event")

func test_correct_route_no_longer_uses_set_player_steps() -> void:
	assert_true(FileAccess.file_exists(GLOVE_CORRECT_ROUTE_RUNTIME_PATH), "correct route exists for set_player audit")
	if not FileAccess.file_exists(GLOVE_CORRECT_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_CORRECT_ROUTE_RUNTIME_PATH)
	for step in route.get("steps", []):
		var entry: Dictionary = step
		assert_true(str(entry.get("type", "")) != "set_player", "correct route no longer relies on set_player: %s" % str(entry.get("caption", "")))

func test_path_opened_route_no_longer_uses_set_player_steps() -> void:
	assert_true(FileAccess.file_exists(GLOVE_PATH_OPENED_ROUTE_RUNTIME_PATH), "path-opened route exists for set_player audit")
	if not FileAccess.file_exists(GLOVE_PATH_OPENED_ROUTE_RUNTIME_PATH):
		return
	assert_route_has_no_set_player_steps(GLOVE_PATH_OPENED_ROUTE_RUNTIME_PATH, "path-opened route")
	assert_route_has_no_auxiliary_steps(GLOVE_PATH_OPENED_ROUTE_RUNTIME_PATH, "path-opened route")

func test_wrong_route_no_longer_uses_set_player_steps() -> void:
	assert_true(FileAccess.file_exists(GLOVE_WRONG_ROUTE_RUNTIME_PATH), "wrong route exists for set_player audit")
	if not FileAccess.file_exists(GLOVE_WRONG_ROUTE_RUNTIME_PATH):
		return
	assert_route_has_no_set_player_steps(GLOVE_WRONG_ROUTE_RUNTIME_PATH, "wrong route")

func test_good_clue_route_no_longer_uses_set_player_steps() -> void:
	assert_route_has_no_set_player_steps(GLOVE_GOOD_CLUE_ROUTE_RUNTIME_PATH, "good-clue route")
	assert_route_has_no_auxiliary_steps(GLOVE_GOOD_CLUE_ROUTE_RUNTIME_PATH, "good-clue route")

func test_transition_out_route_no_longer_uses_set_player_steps() -> void:
	assert_true(FileAccess.file_exists(GLOVE_TRANSITION_OUT_ROUTE_RUNTIME_PATH), "transition-out route exists for set_player audit")
	if not FileAccess.file_exists(GLOVE_TRANSITION_OUT_ROUTE_RUNTIME_PATH):
		return
	assert_route_has_no_set_player_steps(GLOVE_TRANSITION_OUT_ROUTE_RUNTIME_PATH, "transition-out route")
	assert_route_has_no_auxiliary_steps(GLOVE_TRANSITION_OUT_ROUTE_RUNTIME_PATH, "transition-out route")

func test_sword_swap_route_no_longer_uses_set_player_steps() -> void:
	assert_true(FileAccess.file_exists(GLOVE_SWORD_SWAP_ROUTE_RUNTIME_PATH), "sword-swap route exists for set_player audit")
	if not FileAccess.file_exists(GLOVE_SWORD_SWAP_ROUTE_RUNTIME_PATH):
		return
	assert_route_has_no_set_player_steps(GLOVE_SWORD_SWAP_ROUTE_RUNTIME_PATH, "sword-swap route")
	assert_route_has_no_auxiliary_steps(GLOVE_SWORD_SWAP_ROUTE_RUNTIME_PATH, "sword-swap route")

func test_runtime_routes_cover_success_and_failure_flows() -> void:
	assert_true(FileAccess.file_exists(GLOVE_CORRECT_ROUTE_RUNTIME_PATH), "runtime correct route exists")
	assert_true(FileAccess.file_exists(GLOVE_WRONG_ROUTE_RUNTIME_PATH), "runtime wrong route exists")
	if not FileAccess.file_exists(GLOVE_CORRECT_ROUTE_RUNTIME_PATH) or not FileAccess.file_exists(GLOVE_WRONG_ROUTE_RUNTIME_PATH):
		return

	var runner := GloveRouteRunner.new()
	var correct_route := runner.load_route_file(GLOVE_CORRECT_ROUTE_RUNTIME_PATH)
	assert_equal(correct_route.get("world_source", ""), "glove_level", "correct route targets glove level")
	assert_true(route_contains_step_caption(correct_route, "push good into the gesture slot"), "correct route uses the source-backed good-word branch through real movement")
	var correct_world := make_world()
	var correct_run: Dictionary = runner.run_route(correct_world, correct_route)
	assert_true(correct_run.get("success", false), "runtime correct route completes")
	assert_equal(correct_world.player_pos, Vector2i(24, 5), "correct route reaches transition-out anchor")
	assert_true(not correct_world.player_visible, "transition-out hides player")
	assert_true(correct_world.player_input_locked, "transition-out locks input")
	assert_any_text(correct_world, Vector2i(2, 3), "果", "transition-out keeps the screenshot-backed dialogue anchor after the correct route")

	var wrong_route := runner.load_route_file(GLOVE_WRONG_ROUTE_RUNTIME_PATH)
	assert_equal(wrong_route.get("world_source", ""), "glove_level", "wrong route targets glove level")
	var wrong_world := make_world()
	var wrong_run: Dictionary = runner.run_route(wrong_world, wrong_route)
	assert_true(wrong_run.get("success", false), "runtime wrong route resolves through failure and reset")
	assert_equal(wrong_world.player_pos, Vector2i(20, 15), "wrong route ends at reset start anchor")
	assert_any_text(wrong_world, Vector2i(21, 12), "线", "wrong route reset restores life line")

func test_canonical_route_catalog_points_to_real_glove_routes() -> void:
	assert_true(FileAccess.file_exists(GLOVE_CORRECT_ROUTE_PATH), "canonical correct route exists")
	assert_true(FileAccess.file_exists(GLOVE_GESTURE_CHANGE_ROUTE_PATH), "canonical gesture-change route exists")
	assert_true(FileAccess.file_exists(GLOVE_RELEASE_AFTER_DELETE_ROUTE_PATH), "canonical release-after-delete route exists")
	assert_true(FileAccess.file_exists(GLOVE_COLLISION_CHANGE_ROUTE_PATH), "canonical collision-change route exists")
	assert_true(FileAccess.file_exists(GLOVE_WRONG_ROUTE_PATH), "canonical wrong route exists")
	assert_true(FileAccess.file_exists(GLOVE_PATH_OPENED_ROUTE_PATH), "canonical path-opened route exists")
	assert_true(FileAccess.file_exists(GLOVE_TRANSITION_OUT_ROUTE_PATH), "canonical transition-out route exists")
	assert_true(FileAccess.file_exists(GLOVE_ROUTES_INDEX_PATH), "glove routes index exists")
	if not FileAccess.file_exists(GLOVE_CORRECT_ROUTE_PATH) or not FileAccess.file_exists(GLOVE_GESTURE_CHANGE_ROUTE_PATH) or not FileAccess.file_exists(GLOVE_RELEASE_AFTER_DELETE_ROUTE_PATH) or not FileAccess.file_exists(GLOVE_COLLISION_CHANGE_ROUTE_PATH) or not FileAccess.file_exists(GLOVE_WRONG_ROUTE_PATH) or not FileAccess.file_exists(GLOVE_PATH_OPENED_ROUTE_PATH) or not FileAccess.file_exists(GLOVE_TRANSITION_OUT_ROUTE_PATH) or not FileAccess.file_exists(GLOVE_ROUTES_INDEX_PATH):
		return
	var runner := GloveRouteRunner.new()
	var correct_route := runner.load_route_file(GLOVE_CORRECT_ROUTE_PATH)
	assert_equal(str(correct_route.get("world_source", "")), "glove_level", "canonical correct route targets the glove level instead of the old shared test level")
	assert_equal(str(correct_route.get("route_stage", "")), "canonical", "canonical correct route is no longer tagged as skeleton")
	assert_route_has_no_set_player_steps(GLOVE_CORRECT_ROUTE_PATH, "canonical correct route")
	var gesture_route := runner.load_route_file(GLOVE_GESTURE_CHANGE_ROUTE_PATH)
	assert_equal(str(gesture_route.get("world_source", "")), "glove_level", "canonical gesture-change route targets the glove level")
	assert_equal(str(gesture_route.get("route_stage", "")), "canonical", "canonical gesture-change route is marked canonical")
	assert_route_has_no_set_player_steps(GLOVE_GESTURE_CHANGE_ROUTE_PATH, "canonical gesture-change route")
	var release_route := runner.load_route_file(GLOVE_RELEASE_AFTER_DELETE_ROUTE_PATH)
	assert_equal(str(release_route.get("world_source", "")), "glove_level", "canonical release-after-delete route targets the glove level")
	assert_equal(str(release_route.get("route_stage", "")), "canonical", "canonical release-after-delete route is marked canonical")
	assert_text_contains(str(release_route.get("notes", "")), "real inputs", "canonical release-after-delete route declares its real-input flow")
	var collision_route := runner.load_route_file(GLOVE_COLLISION_CHANGE_ROUTE_PATH)
	assert_equal(str(collision_route.get("world_source", "")), "glove_level", "canonical collision-change route targets the glove level")
	assert_equal(str(collision_route.get("route_stage", "")), "canonical", "canonical collision-change route is marked canonical")
	assert_text_contains(str(collision_route.get("notes", "")), "真实复用", "canonical collision-change route declares its verified route reuse")
	assert_route_has_no_auxiliary_steps(GLOVE_COLLISION_CHANGE_ROUTE_PATH, "canonical collision-change route")
	var wrong_route := runner.load_route_file(GLOVE_WRONG_ROUTE_PATH)
	assert_equal(str(wrong_route.get("world_source", "")), "glove_level", "canonical wrong route targets the glove level")
	assert_equal(str(wrong_route.get("route_stage", "")), "canonical", "canonical wrong route is marked canonical")
	assert_route_has_no_set_player_steps(GLOVE_WRONG_ROUTE_PATH, "canonical wrong route")
	var path_route := runner.load_route_file(GLOVE_PATH_OPENED_ROUTE_PATH)
	assert_equal(str(path_route.get("world_source", "")), "glove_level", "canonical path-opened route targets the glove level")
	assert_equal(str(path_route.get("route_stage", "")), "canonical", "canonical path-opened route is marked canonical")
	assert_route_has_no_set_player_steps(GLOVE_PATH_OPENED_ROUTE_PATH, "canonical path-opened route")
	var transition_route := runner.load_route_file(GLOVE_TRANSITION_OUT_ROUTE_PATH)
	assert_equal(str(transition_route.get("world_source", "")), "glove_level", "canonical transition-out route targets the glove level")
	assert_equal(str(transition_route.get("route_stage", "")), "canonical", "canonical transition-out route is marked canonical")
	assert_route_has_no_set_player_steps(GLOVE_TRANSITION_OUT_ROUTE_PATH, "canonical transition-out route")
	var routes_index := read_json_file(GLOVE_ROUTES_INDEX_PATH)
	assert_route_catalog_entry_field(routes_index, "glove-correct-route", "route_path", GLOVE_CORRECT_ROUTE_PATH, "routes index points glove-correct-route at the canonical glove route file")
	assert_route_catalog_entry_field(routes_index, "glove-correct-route", "status", "in_progress", "routes index no longer leaves glove-correct-route blocked behind the old skeleton")
	assert_route_catalog_entry_field(routes_index, "glove-gesture-change", "route_path", GLOVE_GESTURE_CHANGE_ROUTE_PATH, "routes index points glove-gesture-change at the canonical glove route file")
	assert_route_catalog_entry_field(routes_index, "glove-gesture-change", "status", "in_progress", "routes index no longer leaves glove-gesture-change blocked behind a missing file")
	assert_route_catalog_entry_field(routes_index, "glove-release-after-delete-no", "route_path", GLOVE_RELEASE_AFTER_DELETE_ROUTE_PATH, "routes index points glove-release-after-delete-no at the canonical glove route file")
	assert_route_catalog_entry_field(routes_index, "glove-release-after-delete-no", "status", "in_progress", "routes index no longer leaves glove-release-after-delete-no blocked behind a missing file")
	assert_route_catalog_entry_field(routes_index, "glove-collision-change", "route_path", GLOVE_COLLISION_CHANGE_ROUTE_PATH, "routes index points glove-collision-change at the canonical glove route file")
	assert_route_catalog_entry_field(routes_index, "glove-collision-change", "status", "in_progress", "routes index no longer leaves glove-collision-change blocked behind a missing file")
	assert_route_catalog_entry_field(routes_index, "glove-wrong-route", "route_path", GLOVE_WRONG_ROUTE_PATH, "routes index points glove-wrong-route at the canonical glove route file")
	assert_route_catalog_entry_field(routes_index, "glove-wrong-route", "status", "in_progress", "routes index no longer leaves glove-wrong-route blocked behind a missing file")
	assert_route_catalog_entry_field(routes_index, "glove-path-opened", "route_path", GLOVE_PATH_OPENED_ROUTE_PATH, "routes index points glove-path-opened at the canonical glove route file")
	assert_route_catalog_entry_field(routes_index, "glove-path-opened", "status", "in_progress", "routes index no longer leaves glove-path-opened blocked behind a missing file")
	assert_route_catalog_entry_field(routes_index, "glove-transition-out", "route_path", GLOVE_TRANSITION_OUT_ROUTE_PATH, "routes index points glove-transition-out at the canonical glove route file")
	assert_route_catalog_entry_field(routes_index, "glove-transition-out", "status", "in_progress", "routes index no longer leaves glove-transition-out blocked behind a missing file")
	assert_route_catalog_entry_field(routes_index, "glove-lifeline-reclose-runtime", "route_path", GLOVE_LIFELINE_RECLOSE_ROUTE_RUNTIME_PATH, "routes index includes the verified lifeline-reclose runtime route")

func test_canonical_routes_cover_correct_wrong_path_opened_transition_and_helper_flows() -> void:
	assert_true(FileAccess.file_exists(GLOVE_CORRECT_ROUTE_PATH), "canonical correct route file exists for replay")
	assert_true(FileAccess.file_exists(GLOVE_GESTURE_CHANGE_ROUTE_PATH), "canonical gesture-change route file exists for replay")
	assert_true(FileAccess.file_exists(GLOVE_RELEASE_AFTER_DELETE_ROUTE_PATH), "canonical release-after-delete route file exists for replay")
	assert_true(FileAccess.file_exists(GLOVE_COLLISION_CHANGE_ROUTE_PATH), "canonical collision-change route file exists for replay")
	assert_true(FileAccess.file_exists(GLOVE_WRONG_ROUTE_PATH), "canonical wrong route file exists for replay")
	assert_true(FileAccess.file_exists(GLOVE_PATH_OPENED_ROUTE_PATH), "canonical path-opened route file exists for replay")
	assert_true(FileAccess.file_exists(GLOVE_TRANSITION_OUT_ROUTE_PATH), "canonical transition-out route file exists for replay")
	if not FileAccess.file_exists(GLOVE_CORRECT_ROUTE_PATH) or not FileAccess.file_exists(GLOVE_GESTURE_CHANGE_ROUTE_PATH) or not FileAccess.file_exists(GLOVE_RELEASE_AFTER_DELETE_ROUTE_PATH) or not FileAccess.file_exists(GLOVE_COLLISION_CHANGE_ROUTE_PATH) or not FileAccess.file_exists(GLOVE_WRONG_ROUTE_PATH) or not FileAccess.file_exists(GLOVE_PATH_OPENED_ROUTE_PATH) or not FileAccess.file_exists(GLOVE_TRANSITION_OUT_ROUTE_PATH):
		return
	var runner := GloveRouteRunner.new()
	var correct_route := runner.load_route_file(GLOVE_CORRECT_ROUTE_PATH)
	var correct_world := make_world()
	var correct_run: Dictionary = runner.run_route(correct_world, correct_route)
	assert_true(correct_run.get("success", false), "canonical correct route completes on the glove level")
	assert_equal(correct_world.player_pos, Vector2i(24, 5), "canonical correct route reaches the transition-out anchor")
	assert_true(not correct_world.player_visible, "canonical correct route hides the player at transition-out")
	assert_true(correct_world.player_input_locked, "canonical correct route locks input at transition-out")
	var gesture_route := runner.load_route_file(GLOVE_GESTURE_CHANGE_ROUTE_PATH)
	var gesture_world := make_world()
	var gesture_run: Dictionary = runner.run_route(gesture_world, gesture_route)
	assert_true(gesture_run.get("success", false), "canonical gesture-change route completes on the glove level")
	assert_equal(str(gesture_world.last_message), "巨大手掌，是零的手势。", "canonical gesture-change route returns to the zero gesture")
	var release_route := runner.load_route_file(GLOVE_RELEASE_AFTER_DELETE_ROUTE_PATH)
	var release_world := make_world()
	var release_run: Dictionary = runner.run_route(release_world, release_route)
	assert_true(release_run.get("success", false), "canonical release-after-delete route completes on the glove level")
	assert_equal(str(release_world.last_message), "巨大手掌已经放开。", "canonical release-after-delete route reaches the release state")
	assert_any_text(release_world, GloveLayouts.HAND_ORIGIN + Vector2i(0, 12), "掌", "canonical release-after-delete route leaves the release palm anchor open")
	var collision_route := runner.load_route_file(GLOVE_COLLISION_CHANGE_ROUTE_PATH)
	var collision_world := make_world()
	var collision_run: Dictionary = runner.run_route(collision_world, collision_route)
	assert_true(collision_run.get("success", false), "canonical collision-change route completes on the glove level")
	assert_equal(collision_world.player_pos, Vector2i(0, 11), "canonical collision-change route passes through the lower entrance")
	assert_true(collision_world.get_any_entity_at(Vector2i(0, 11)) == null, "canonical collision-change route keeps the lower entrance open in the shared good-like layout")
	var wrong_route := runner.load_route_file(GLOVE_WRONG_ROUTE_PATH)
	var wrong_world := make_world()
	var wrong_run: Dictionary = runner.run_route(wrong_world, wrong_route)
	assert_true(wrong_run.get("success", false), "canonical wrong route completes on the glove level")
	assert_equal(wrong_world.player_pos, Vector2i(20, 15), "canonical wrong route resets to the start anchor")
	assert_true(wrong_world.player_visible, "canonical wrong route keeps the player visible after reset")
	assert_true(not wrong_world.player_input_locked, "canonical wrong route restores input after reset")
	var path_route := runner.load_route_file(GLOVE_PATH_OPENED_ROUTE_PATH)
	var path_world := make_world()
	var path_run: Dictionary = runner.run_route(path_world, path_route)
	assert_true(path_run.get("success", false), "canonical path-opened route completes on the glove level")
	assert_equal(path_world.player_pos, Vector2i(24, 14), "canonical path-opened route reaches the mid-path anchor")
	assert_true(path_world.player_visible, "canonical path-opened route keeps the player visible")
	assert_true(not path_world.player_input_locked, "canonical path-opened route keeps input unlocked")
	var transition_route := runner.load_route_file(GLOVE_TRANSITION_OUT_ROUTE_PATH)
	var transition_world := make_world()
	var transition_run: Dictionary = runner.run_route(transition_world, transition_route)
	assert_true(transition_run.get("success", false), "canonical transition-out route completes on the glove level")
	assert_equal(transition_world.player_pos, Vector2i(24, 5), "canonical transition-out route reaches the final anchor")
	assert_true(not transition_world.player_visible, "canonical transition-out route hides the player")
	assert_true(transition_world.player_input_locked, "canonical transition-out route locks input")

func test_correct_route_report_records_source_backed_checkpoints() -> void:
	assert_true(FileAccess.file_exists(GLOVE_CORRECT_ROUTE_RUNTIME_PATH), "runtime correct route exists for checkpoint audit")
	if not FileAccess.file_exists(GLOVE_CORRECT_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_CORRECT_ROUTE_RUNTIME_PATH)
	var world := make_world()
	var run_result: Dictionary = runner.run_route(world, route)
	assert_true(run_result.get("success", false), "correct route completes before checkpoint audit")
	var report: Dictionary = run_result.get("report", {})
	assert_report_checkpoint(
		report,
		"correct_route_step",
		"GLOVE-SHOT-003",
		"walk from clue to the good-hand palm point",
		[30, 15],
		"correct route report records the screenshot-backed mid-route anchor"
	)
	assert_report_checkpoint_grid_id(
		report,
		"correct_route_step",
		"GLOVE-GRID-002",
		"correct route report links the mid-route anchor back to the baseline grid catalog"
	)
	assert_report_checkpoint(
		report,
		"gesture_good",
		"GLOVE-SHOT-007",
		"switch to good gesture",
		[30, 15],
		"correct route report records the good-gesture screenshot checkpoint"
	)
	assert_report_checkpoint_grid_id(
		report,
		"gesture_good",
		"GLOVE-GRID-007",
		"correct route report links the good-gesture checkpoint back to the baseline grid catalog"
	)
	assert_report_checkpoint(
		report,
		"path_opened",
		"GLOVE-SHOT-012",
		"walk from opened lifeline to mid path anchor",
		[24, 14],
		"correct route report records the opened-path screenshot checkpoint"
	)
	assert_report_checkpoint_grid_id(
		report,
		"path_opened",
		"GLOVE-GRID-008",
		"correct route report links the opened-path checkpoint back to the baseline grid catalog"
	)
	assert_report_checkpoint(
		report,
		"gesture_two",
		"GLOVE-SHOT-004",
		"walk from two-hand switch point to screenshot anchor",
		[26, 15],
		"correct route report records the baseline-backed two-hand screenshot checkpoint"
	)
	assert_report_checkpoint_grid_id(
		report,
		"gesture_two",
		"GLOVE-GRID-005",
		"correct route report links the two-hand checkpoint back to the baseline grid catalog"
	)
	assert_report_checkpoint(
		report,
		"transition_out",
		"GLOVE-SHOT-009",
		"enter transition",
		[24, 5],
		"correct route report records the transition-out screenshot checkpoint"
	)
	assert_report_checkpoint_grid_id(
		report,
		"transition_out",
		"GLOVE-GRID-012",
		"correct route report links the transition-out checkpoint back to the baseline grid catalog"
	)

func test_path_opened_route_report_records_mid_path_checkpoint() -> void:
	assert_true(FileAccess.file_exists(GLOVE_PATH_OPENED_ROUTE_RUNTIME_PATH), "path-opened route exists for checkpoint audit")
	if not FileAccess.file_exists(GLOVE_PATH_OPENED_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_PATH_OPENED_ROUTE_RUNTIME_PATH)
	var world := make_world()
	var run_result: Dictionary = runner.run_route(world, route)
	assert_true(run_result.get("success", false), "path-opened route completes before checkpoint audit")
	var report: Dictionary = run_result.get("report", {})
	assert_report_checkpoint(
		report,
		"path_opened",
		"GLOVE-SHOT-012",
		"walk from opened lifeline to mid path anchor",
		[24, 14],
		"path-opened route report records the opened-path screenshot checkpoint"
	)
	assert_report_checkpoint_grid_id(
		report,
		"path_opened",
		"GLOVE-GRID-008",
		"path-opened route report links the opened-path checkpoint back to the baseline grid catalog"
	)

func test_gesture_cycle_route_records_source_backed_gesture_checkpoints() -> void:
	assert_true(FileAccess.file_exists(GLOVE_GESTURE_CYCLE_ROUTE_RUNTIME_PATH), "gesture cycle route exists for checkpoint audit")
	if not FileAccess.file_exists(GLOVE_GESTURE_CYCLE_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_GESTURE_CYCLE_ROUTE_RUNTIME_PATH)
	var world := make_world()
	var run_result: Dictionary = runner.run_route(world, route)
	assert_true(run_result.get("success", false), "gesture cycle route completes before checkpoint audit")
	assert_route_has_no_auxiliary_steps(GLOVE_GESTURE_CYCLE_ROUTE_RUNTIME_PATH, "gesture cycle route")
	var report: Dictionary = run_result.get("report", {})
	assert_report_checkpoint(
		report,
		"gesture_one",
		"GLOVE-SHOT-014",
		"切换到一手势",
		[29, 14],
		"gesture cycle report records the real one-hand route checkpoint"
	)
	assert_report_checkpoint_grid_id(
		report,
		"gesture_one",
		"GLOVE-GRID-013",
		"gesture cycle report links the one-hand checkpoint back to the baseline grid catalog"
	)
	assert_report_checkpoint(
		report,
		"gesture_win",
		"GLOVE-SHOT-005",
		"切换到赢手势",
		[23, 16],
		"gesture cycle report records the real win-hand route checkpoint"
	)
	assert_report_checkpoint_grid_id(
		report,
		"gesture_win",
		"GLOVE-GRID-006",
		"gesture cycle report links the win-hand checkpoint back to the baseline grid catalog"
	)

func test_correct_route_report_records_initial_layout_checkpoint() -> void:
	assert_true(FileAccess.file_exists(GLOVE_CORRECT_ROUTE_RUNTIME_PATH), "runtime correct route exists for initial checkpoint audit")
	if not FileAccess.file_exists(GLOVE_CORRECT_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_CORRECT_ROUTE_RUNTIME_PATH)
	var world := make_world()
	var run_result: Dictionary = runner.run_route(world, route)
	assert_true(run_result.get("success", false), "correct route completes before initial checkpoint audit")
	var report: Dictionary = run_result.get("report", {})
	assert_report_checkpoint(
		report,
		"initial_layout",
		"GLOVE-SHOT-001",
		"record initial layout anchor",
		[20, 15],
		"correct route report records the initial layout checkpoint"
	)
	assert_report_checkpoint_grid_id(
		report,
		"initial_layout",
		"GLOVE-GRID-001",
		"correct route report links the initial layout checkpoint back to the baseline grid catalog"
	)

func test_wrong_route_report_records_failure_feedback_checkpoint() -> void:
	assert_true(FileAccess.file_exists(GLOVE_WRONG_ROUTE_RUNTIME_PATH), "runtime wrong route exists for checkpoint audit")
	if not FileAccess.file_exists(GLOVE_WRONG_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_WRONG_ROUTE_RUNTIME_PATH)
	var world := make_world()
	var run_result: Dictionary = runner.run_route(world, route)
	assert_true(run_result.get("success", false), "wrong route completes before checkpoint audit")
	var report: Dictionary = run_result.get("report", {})
	assert_report_checkpoint(
		report,
		"failure_feedback",
		"GLOVE-SHOT-010",
		"错误手势触发失败",
		[20, 12],
		"wrong route report records the failure screenshot checkpoint"
	)
	assert_report_checkpoint_grid_id(
		report,
		"failure_feedback",
		"GLOVE-GRID-011",
		"wrong route report links the failure checkpoint back to the baseline grid catalog"
	)

func test_collision_change_route_records_candidate_collision_checkpoint() -> void:
	assert_true(FileAccess.file_exists(GLOVE_COLLISION_CHANGE_ROUTE_RUNTIME_PATH), "collision-change route exists for checkpoint audit")
	if not FileAccess.file_exists(GLOVE_COLLISION_CHANGE_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_COLLISION_CHANGE_ROUTE_RUNTIME_PATH)
	var world := make_world()
	var run_result: Dictionary = runner.run_route(world, route)
	assert_true(run_result.get("success", false), "collision-change route completes before checkpoint audit")
	var report: Dictionary = run_result.get("report", {})
	assert_report_checkpoint(
		report,
		"collision_changed",
		"GLOVE-SHOT-018",
		"好手势触发同态碰撞布局",
		[30, 15],
		"collision-change route records the real good-like collision checkpoint"
	)
	assert_report_checkpoint_grid_id(
		report,
		"collision_changed",
		"GLOVE-GRID-014",
		"collision-change route links the collision-change checkpoint back to the baseline grid catalog"
	)
	assert_report_checkpoint_status(
		report,
		"collision_changed",
		"candidate",
		"collision-change route marks the collision-change screenshot as a candidate checkpoint"
	)

func test_good_clue_route_records_candidate_good_hand_checkpoint() -> void:
	assert_true(FileAccess.file_exists(GLOVE_GOOD_CLUE_ROUTE_RUNTIME_PATH), "good-clue route exists for checkpoint audit")
	if not FileAccess.file_exists(GLOVE_GOOD_CLUE_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_GOOD_CLUE_ROUTE_RUNTIME_PATH)
	var world := make_world()
	var run_result: Dictionary = runner.run_route(world, route)
	assert_true(run_result.get("success", false), "good-clue route completes before checkpoint audit")
	var report: Dictionary = run_result.get("report", {})
	assert_report_checkpoint(
		report,
		"good_hand_followup",
		"GLOVE-SHOT-008",
		"switch to the good-hand gesture",
		[30, 15],
		"good-clue route records the screenshot-backed good-hand helper checkpoint"
	)
	assert_report_checkpoint_grid_id(
		report,
		"good_hand_followup",
		"GLOVE-GRID-015",
		"good-clue route links the good-hand helper checkpoint back to the baseline grid catalog"
	)
	assert_report_checkpoint_status(
		report,
		"good_hand_followup",
		"candidate",
		"good-clue route marks the helper good-hand screenshot as a candidate checkpoint"
	)

func test_sword_swap_route_records_rule_only_checkpoint() -> void:
	assert_true(FileAccess.file_exists(GLOVE_SWORD_SWAP_ROUTE_RUNTIME_PATH), "sword-swap route exists for checkpoint audit")
	if not FileAccess.file_exists(GLOVE_SWORD_SWAP_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_SWORD_SWAP_ROUTE_RUNTIME_PATH)
	var world := make_world()
	var run_result: Dictionary = runner.run_route(world, route)
	assert_true(run_result.get("success", false), "sword-swap route completes before checkpoint audit")
	var report: Dictionary = run_result.get("report", {})
	assert_report_checkpoint(
		report,
		"sword_swap_right",
		"",
		"reuse verified correct route through right sword swap",
		[4, 1],
		"sword-swap route records the right-swap rule-only checkpoint"
	)

func test_helper_routes_record_checkpoint_review_status() -> void:
	var runner := GloveRouteRunner.new()

	var release_route := runner.load_route_file(GLOVE_RELEASE_ROUTE_RUNTIME_PATH)
	assert_route_has_no_auxiliary_steps(GLOVE_RELEASE_ROUTE_RUNTIME_PATH, "release-after-delete route")
	var release_world := make_world()
	var release_run: Dictionary = runner.run_route(release_world, release_route)
	assert_true(release_run.get("success", false), "release route completes before checkpoint review-status audit")
	var release_report: Dictionary = release_run.get("report", {})
	assert_report_checkpoint(
		release_report,
		"released_after_delete_no",
		"GLOVE-SHOT-016",
		"切换到放开状态",
		[29, 14],
		"release route records the release screenshot candidate checkpoint"
	)
	assert_report_checkpoint_grid_id(
		release_report,
		"released_after_delete_no",
		"GLOVE-GRID-009",
		"release route links the release candidate checkpoint back to the baseline grid catalog"
	)
	assert_report_checkpoint_status(
		release_report,
		"released_after_delete_no",
		"candidate",
		"release route marks the release screenshot as a candidate checkpoint"
	)

	var transition_route := runner.load_route_file(GLOVE_TRANSITION_OUT_ROUTE_RUNTIME_PATH)
	var transition_world := make_world()
	var transition_run: Dictionary = runner.run_route(transition_world, transition_route)
	assert_true(transition_run.get("success", false), "transition route completes before checkpoint review-status audit")
	var transition_report: Dictionary = transition_run.get("report", {})
	assert_report_checkpoint(
		transition_report,
		"transition_out",
		"GLOVE-SHOT-009",
		"reuse verified correct route through transition",
		[24, 5],
		"transition route records the black-screen screenshot checkpoint"
	)
	assert_report_checkpoint_grid_id(
		transition_report,
		"transition_out",
		"GLOVE-GRID-012",
		"transition route links the black-screen checkpoint back to the baseline grid catalog"
	)
	assert_report_checkpoint_status(
		transition_report,
		"transition_out",
		"candidate",
		"transition route marks the black-screen screenshot as candidate timing evidence"
	)

	var wrong_route := runner.load_route_file(GLOVE_WRONG_ROUTE_RUNTIME_PATH)
	var wrong_world := make_world()
	var wrong_run: Dictionary = runner.run_route(wrong_world, wrong_route)
	assert_true(wrong_run.get("success", false), "wrong route completes before candidate-status audit")
	var wrong_report: Dictionary = wrong_run.get("report", {})
	assert_report_checkpoint_status(
		wrong_report,
		"failure_feedback",
		"candidate",
		"wrong route marks the failure screenshot as a candidate semantic anchor"
	)

func test_runtime_routes_record_trace_for_gesture_change_release_and_path_opened() -> void:
	var runner := GloveRouteRunner.new()

	var gesture_route := runner.load_route_file(GLOVE_GESTURE_CYCLE_ROUTE_RUNTIME_PATH)
	var gesture_world := make_world()
	var gesture_run: Dictionary = runner.run_route(gesture_world, gesture_route)
	assert_true(gesture_run.get("success", false), "gesture trace route completes")
	var gesture_report: Dictionary = gesture_run.get("report", {})
	assert_report_trace_contains(gesture_report, "G-04", "gesture cycle report records the gesture transition animation")
	assert_report_trace_contains(gesture_report, "G-05", "gesture cycle report records the glove morph animation")
	assert_report_trace_contains(gesture_report, "G-06", "gesture cycle report records the collision-change animation")
	assert_report_trace_contains(gesture_report, "GLOVE-AUD-003", "gesture cycle report records the glove put-on audio")
	assert_report_trace_contains(gesture_report, "GLOVE-AUD-004", "gesture cycle report records the alternate glove switch audio")
	assert_report_trace_contains(gesture_report, "GLOVE-AUD-005", "gesture cycle report records the giant-fist smash audio")

	var release_route := runner.load_route_file(GLOVE_RELEASE_ROUTE_RUNTIME_PATH)
	var release_world := make_world()
	var release_run: Dictionary = runner.run_route(release_world, release_route)
	assert_true(release_run.get("success", false), "release trace route completes")
	var release_report: Dictionary = release_run.get("report", {})
	assert_report_trace_contains(release_report, "G-07", "release report records the delete-no release animation")
	assert_report_trace_contains(release_report, "GLOVE-AUD-006", "release report records the release-hit audio")

	var path_route := runner.load_route_file(GLOVE_PATH_OPENED_ROUTE_RUNTIME_PATH)
	var path_world := make_world()
	var path_run: Dictionary = runner.run_route(path_world, path_route)
	assert_true(path_run.get("success", false), "path-opened trace route completes")
	var path_report: Dictionary = path_run.get("report", {})
	assert_report_trace_contains(path_report, "G-02", "path-opened report records the chain-loop animation")
	assert_report_trace_contains(path_report, "G-03", "path-opened report records the skull-loop animation")
	assert_report_trace_contains(path_report, "GLOVE-AUD-001", "path-opened report records the intro BGM trigger")
	assert_report_trace_contains(path_report, "GLOVE-AUD-002", "path-opened report records the main loop BGM trigger")

func test_runtime_routes_record_trace_for_transition_and_failure_feedback() -> void:
	var runner := GloveRouteRunner.new()

	var transition_route := runner.load_route_file(GLOVE_TRANSITION_OUT_ROUTE_RUNTIME_PATH)
	var transition_world := make_world()
	var transition_run: Dictionary = runner.run_route(transition_world, transition_route)
	assert_true(transition_run.get("success", false), "transition trace route completes")
	var transition_report: Dictionary = transition_run.get("report", {})
	assert_report_trace_contains(transition_report, "G-08", "transition report records the ending animation trace")
	assert_report_trace_contains(transition_report, "GLOVE-AUD-007", "transition report records the ambience/transition audio trace")

	var wrong_route := runner.load_route_file(GLOVE_WRONG_ROUTE_RUNTIME_PATH)
	var wrong_world := make_world()
	var wrong_run: Dictionary = runner.run_route(wrong_world, wrong_route)
	assert_true(wrong_run.get("success", false), "wrong-route trace route completes")
	var wrong_report: Dictionary = wrong_run.get("report", {})
	assert_step_trace_contains(wrong_report, "错误手势触发失败", "G-08", "wrong-route report records the failure animation trace on the failure step")
	assert_step_trace_contains(wrong_report, "错误手势触发失败", "GLOVE-AUD-008", "wrong-route report records the crowd-yell failure audio trace on the failure step")

func test_runtime_routes_cover_gesture_cycle_and_release_flow() -> void:
	assert_true(FileAccess.file_exists(GLOVE_GESTURE_CYCLE_ROUTE_RUNTIME_PATH), "gesture cycle route exists")
	assert_true(FileAccess.file_exists(GLOVE_RELEASE_ROUTE_RUNTIME_PATH), "release route exists")
	if not FileAccess.file_exists(GLOVE_GESTURE_CYCLE_ROUTE_RUNTIME_PATH) or not FileAccess.file_exists(GLOVE_RELEASE_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var gesture_route := runner.load_route_file(GLOVE_GESTURE_CYCLE_ROUTE_RUNTIME_PATH)
	assert_equal(gesture_route.get("world_source", ""), "glove_level", "gesture cycle route targets glove level")
	var gesture_world := make_world()
	var gesture_run: Dictionary = runner.run_route(gesture_world, gesture_route)
	assert_true(gesture_run.get("success", false), "gesture cycle route completes")
	assert_equal(str(gesture_world.last_message), "巨大手掌，是赢的手势。", "gesture cycle route reaches the win hand message")
	assert_hand_layout(gesture_world, "win", "gesture cycle route ends on win layout")

	var release_route := runner.load_route_file(GLOVE_RELEASE_ROUTE_RUNTIME_PATH)
	assert_equal(release_route.get("world_source", ""), "glove_level", "release route targets glove level")
	var release_world := make_world()
	var release_run: Dictionary = runner.run_route(release_world, release_route)
	assert_true(release_run.get("success", false), "release route completes")
	assert_equal(str(release_world.last_message), "巨大手掌已经放开。", "release route ends with release message")
	assert_hand_layout(release_world, "release", "release route ends on release layout")

func test_runtime_route_covers_real_like_word_flow() -> void:
	assert_true(FileAccess.file_exists(GLOVE_LIKE_GESTURE_ROUTE_RUNTIME_PATH), "real like-word route exists")
	if not FileAccess.file_exists(GLOVE_LIKE_GESTURE_ROUTE_RUNTIME_PATH):
		return
	assert_route_has_no_auxiliary_steps(GLOVE_LIKE_GESTURE_ROUTE_RUNTIME_PATH, "real like-word route")
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(GLOVE_LIKE_GESTURE_ROUTE_RUNTIME_PATH)
	var world := make_world()
	var run_result: Dictionary = runner.run_route(world, route)
	assert_true(run_result.get("success", false), "real like-word route completes")
	assert_equal(world.player_pos, Vector2i(23, 16), "real like-word route reaches the palm interaction point")
	assert_any_text(world, Vector2i(26, 17), "赞", "real like-word route leaves the like word in the gesture slot")
	assert_equal(str(world.last_message), "巨大手掌已经放开。", "real like-word route preserves the visible release state")
	assert_hand_layout(world, "release", "real like-word route stays on the release layout while recording the underlying gesture word")

func test_runtime_route_covers_collision_change_flow() -> void:
	assert_true(FileAccess.file_exists(GLOVE_COLLISION_CHANGE_ROUTE_RUNTIME_PATH), "collision change route exists")
	if not FileAccess.file_exists(GLOVE_COLLISION_CHANGE_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var collision_route := runner.load_route_file(GLOVE_COLLISION_CHANGE_ROUTE_RUNTIME_PATH)
	assert_equal(collision_route.get("world_source", ""), "glove_level", "collision change route targets glove level")
	assert_equal(str((collision_route.get("steps", []) as Array)[0].get("type", "")), "route_segment", "collision change route reuses the verified real good-hand prefix")
	assert_route_has_no_auxiliary_steps(GLOVE_COLLISION_CHANGE_ROUTE_RUNTIME_PATH, "collision-change route")
	var collision_world := make_world()
	var collision_run: Dictionary = runner.run_route(collision_world, collision_route)
	assert_true(collision_run.get("success", false), "collision change route completes")
	assert_equal(str(collision_world.last_message), "巨大手掌，是好的手势。", "collision change route keeps the real good-hand state")
	assert_hand_layout(collision_world, "like", "collision change route ends on the shared good-like layout")
	assert_equal(collision_world.player_pos, Vector2i(0, 11), "collision change route passes through the lower entrance")

func test_runtime_route_covers_good_clue_flow() -> void:
	assert_true(FileAccess.file_exists(GLOVE_GOOD_CLUE_ROUTE_RUNTIME_PATH), "good clue route exists")
	if not FileAccess.file_exists(GLOVE_GOOD_CLUE_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var good_route := runner.load_route_file(GLOVE_GOOD_CLUE_ROUTE_RUNTIME_PATH)
	assert_equal(good_route.get("world_source", ""), "glove_level", "good clue route targets glove level")
	var good_world := make_world()
	var good_run: Dictionary = runner.run_route(good_world, good_route)
	assert_true(good_run.get("success", false), "good clue route completes")
	assert_any_text(good_world, Vector2i(26, 17), "好", "good clue route parks ? inside the gesture slot")
	assert_equal(str(good_world.last_message), "巨大手掌，是好的手势。", "good clue route ends on the good-hand message")
	assert_hand_layout(good_world, "like", "good clue route ends on the shared like layout")

func test_runtime_route_covers_lifeline_reclose_flow() -> void:
	assert_true(FileAccess.file_exists(GLOVE_LIFELINE_RECLOSE_ROUTE_RUNTIME_PATH), "lifeline reclose route exists")
	if not FileAccess.file_exists(GLOVE_LIFELINE_RECLOSE_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var reclose_route := runner.load_route_file(GLOVE_LIFELINE_RECLOSE_ROUTE_RUNTIME_PATH)
	assert_equal(reclose_route.get("world_source", ""), "glove_level", "lifeline reclose route targets glove level")
	assert_route_has_no_auxiliary_steps(GLOVE_LIFELINE_RECLOSE_ROUTE_RUNTIME_PATH, "lifeline-reclose route")
	var reclose_world := make_world()
	var reclose_run: Dictionary = runner.run_route(reclose_world, reclose_route)
	assert_true(reclose_run.get("success", false), "lifeline reclose route completes")
	assert_any_text(reclose_world, Vector2i(21, 12), "线", "lifeline reclose route restores the life line")
	reclose_world.player_pos = Vector2i(20, 12)
	reclose_world.facing = Vector2i.RIGHT
	var probe_result: Dictionary = reclose_world.try_move_player(Vector2i.RIGHT)
	assert_true(not probe_result.success, "restored life line blocks movement after route replay")
	assert_equal(str(probe_result.get("message", "")), "blocked", "restored life line reports blocked after route replay")

func test_runtime_route_covers_path_opened_flow() -> void:
	assert_true(FileAccess.file_exists(GLOVE_PATH_OPENED_ROUTE_RUNTIME_PATH), "path opened route exists")
	if not FileAccess.file_exists(GLOVE_PATH_OPENED_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var path_route := runner.load_route_file(GLOVE_PATH_OPENED_ROUTE_RUNTIME_PATH)
	assert_equal(path_route.get("world_source", ""), "glove_level", "path opened route targets glove level")
	var path_world := make_world()
	var path_run: Dictionary = runner.run_route(path_world, path_route)
	assert_true(path_run.get("success", false), "path opened route completes")
	assert_equal(path_world.player_pos, Vector2i(24, 14), "path opened route reaches the newly traversable corridor")
	assert_true(path_world.player_visible, "path opened route does not trigger transition-out")
	assert_true(not path_world.player_input_locked, "path opened route leaves input unlocked")

func test_runtime_route_covers_transition_out_flow() -> void:
	assert_true(FileAccess.file_exists(GLOVE_TRANSITION_OUT_ROUTE_RUNTIME_PATH), "transition-out route exists")
	if not FileAccess.file_exists(GLOVE_TRANSITION_OUT_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var transition_route := runner.load_route_file(GLOVE_TRANSITION_OUT_ROUTE_RUNTIME_PATH)
	assert_equal(transition_route.get("world_source", ""), "glove_level", "transition-out route targets glove level")
	var transition_world := make_world()
	var transition_run: Dictionary = runner.run_route(transition_world, transition_route)
	assert_true(transition_run.get("success", false), "transition-out route completes")
	assert_equal(transition_world.player_pos, Vector2i(24, 5), "transition-out route reaches the final anchor")
	assert_true(not transition_world.player_visible, "transition-out route hides the player")
	assert_true(transition_world.player_input_locked, "transition-out route locks input")
	assert_any_text(transition_world, Vector2i(2, 3), "果", "transition-out route keeps the screenshot-backed dialogue anchor")

func test_runtime_route_covers_sword_swap_flow() -> void:
	assert_true(FileAccess.file_exists(GLOVE_SWORD_SWAP_ROUTE_RUNTIME_PATH), "sword swap route exists")
	if not FileAccess.file_exists(GLOVE_SWORD_SWAP_ROUTE_RUNTIME_PATH):
		return
	var runner := GloveRouteRunner.new()
	var sword_route := runner.load_route_file(GLOVE_SWORD_SWAP_ROUTE_RUNTIME_PATH)
	assert_equal(sword_route.get("world_source", ""), "glove_level", "sword swap route targets glove level")
	var sword_world := make_world()
	var sword_run: Dictionary = runner.run_route(sword_world, sword_route)
	assert_true(sword_run.get("success", false), "sword swap route completes")
	assert_any_text(sword_world, GloveLayouts.SWORD_LEFT_POS, "剑", "sword swap route ends with the sword back on the left source anchor")
	assert_true(sword_world.get_any_entity_at(GloveLayouts.SWORD_RIGHT_POS) == null, "sword swap route clears the right source anchor after the return swap")
	assert_equal(str(sword_world.last_message), "二指伸直，掌中剑换到了左边。", "sword swap route ends on the return-swap message")

func test_glove_route_report_exporter_writes_runtime_reports() -> void:
	var exporter := GloveRouteReportExporter.new()
	var output_dir := ProjectSettings.globalize_path("user://glove-report-export-test")
	remove_dir_recursive(output_dir)
	var original_overrides_text := read_text_file(GLOVE_MANUAL_REVIEW_OVERRIDES_PATH)
	write_text_file(
		GLOVE_MANUAL_REVIEW_OVERRIDES_PATH,
		JSON.stringify({
			"level_id": "glove",
			"updated_at": "2026-07-12 04:00:00",
			"checkpoint_reviews": [
				{
					"id": "good_hand_followup",
					"ref": "GLOVE-SHOT-008",
					"source_grid_id": "GLOVE-GRID-015",
					"route_id": "glove-good-clue-runtime",
					"review_status": "confirmed",
					"reviewer": "tester",
					"reviewed_at": "2026-07-12 04:00:00",
					"resolution_note": "人工确认该辅助锚点可接受。"
				},
				{
					"id": "collision_changed",
					"ref": "GLOVE-SHOT-018",
					"source_grid_id": "GLOVE-GRID-014",
					"route_id": "glove-collision-change-runtime",
					"review_status": "rejected",
					"reviewer": "tester",
					"reviewed_at": "2026-07-12 04:01:00",
					"resolution_note": "逐格碰撞仍与原版不一致。"
				}
			],
			"focus_reviews": [
				{
					"focus": "爱字源码计算候选格 [2,12] 的原版运行确认，以及从该格推入手势槽的真实路径",
					"review_status": "resolved",
					"reviewer": "tester",
					"reviewed_at": "2026-07-12 04:02:00",
					"resolution_note": "仍需保留候选，不纳入主流程。"
				}
			]
		}, "\t")
	)
	var summary: Dictionary = exporter.export_runtime_reports(output_dir)
	assert_equal(int(summary.get("exported_count", 0)), 11, "glove report exporter writes every runtime route report")
	assert_equal(int(summary.get("failed_count", -1)), 0, "glove report exporter has no failed route exports")

	var correct_report_path := output_dir.path_join("glove-correct-route-runtime__report.json")
	assert_true(FileAccess.file_exists(correct_report_path), "glove report exporter writes the correct-route report file")
	var correct_report: Dictionary = read_json_file(correct_report_path)
	assert_equal(str(correct_report.get("route_id", "")), "glove-correct-route-runtime", "exported correct-route report keeps route id")
	assert_report_checkpoint(
		correct_report,
		"transition_out",
		"GLOVE-SHOT-009",
		"enter transition",
		[24, 5],
		"exported correct-route report keeps the transition checkpoint"
	)
	assert_report_checkpoint_grid_id(
		correct_report,
		"transition_out",
		"GLOVE-GRID-012",
		"exported correct-route report keeps the transition checkpoint grid catalog link"
	)
	assert_report_step_input_path(
		correct_report,
		"walk from start to lower lifeline clue",
		[[0, -1], [0, -1]],
		"exported correct-route report keeps structured input data for move_path steps"
	)

	var wrong_report_path := output_dir.path_join("glove-wrong-route-runtime__report.json")
	assert_true(FileAccess.file_exists(wrong_report_path), "glove report exporter writes the wrong-route report file")
	var wrong_report: Dictionary = read_json_file(wrong_report_path)
	assert_report_checkpoint(
		wrong_report,
		"failure_feedback",
		"GLOVE-SHOT-010",
		"错误手势触发失败",
		[20, 12],
		"exported wrong-route report keeps the failure checkpoint"
	)
	assert_report_checkpoint_grid_id(
		wrong_report,
		"failure_feedback",
		"GLOVE-GRID-011",
		"exported wrong-route report keeps the failure checkpoint grid catalog link"
	)
	var lifeline_reclose_report_path := output_dir.path_join("glove-lifeline-reclose-runtime__report.json")
	assert_true(FileAccess.file_exists(lifeline_reclose_report_path), "glove report exporter writes the lifeline-reclose report file")

	var review_packet_path := output_dir.path_join("glove_manual_review_packet.json")
	assert_true(FileAccess.file_exists(review_packet_path), "glove report exporter writes the manual review packet")
	var review_packet: Dictionary = read_json_file(review_packet_path)
	assert_equal(str(review_packet.get("level_id", "")), "glove", "manual review packet keeps the glove level id")
	assert_equal(str(review_packet.get("display_name", "")), "手套关", "manual review packet keeps the glove display name")
	assert_equal(int(review_packet.get("report_count", 0)), 11, "manual review packet records every exported runtime report")
	assert_equal(int(review_packet.get("auxiliary_setup_count", -1)), 0, "manual review packet has no remaining non-player setup steps")
	assert_equal(int(review_packet.get("auxiliary_setup_steps", []).size()), 0, "manual review packet exports no non-player setup steps")
	assert_packet_checkpoint(review_packet, "confirmed_checkpoints", "initial_layout", "manual review packet keeps the initial layout checkpoint")
	assert_packet_checkpoint(review_packet, "confirmed_checkpoints", "sword_swap_right", "manual review packet keeps the sword-swap rule-only checkpoint")
	assert_packet_checkpoint(review_packet, "confirmed_checkpoints", "transition_out", "manual review packet keeps confirmed transition checkpoint")
	assert_packet_checkpoint(review_packet, "reviewed_confirmed_checkpoints", "good_hand_followup", "manual review packet upgrades manually confirmed candidate checkpoint")
	assert_packet_checkpoint(review_packet, "candidate_checkpoints", "released_after_delete_no", "manual review packet keeps unresolved candidate checkpoints")
	assert_packet_checkpoint(review_packet, "reviewed_rejected_checkpoints", "collision_changed", "manual review packet records manually rejected candidate checkpoint")
	assert_packet_checkpoint_field(review_packet, "confirmed_checkpoints", "sword_swap_right", "evidence_type", "rule_only", "manual review packet marks the sword-swap checkpoint as rule-only evidence")
	assert_packet_checkpoint_field(review_packet, "confirmed_checkpoints", "sword_swap_right", "evidence_type_label", "规则锚点", "manual review packet localizes the sword-swap evidence type")
	assert_packet_checkpoint_field(review_packet, "confirmed_checkpoints", "sword_swap_right", "caption_localized", "掌中剑换到右边", "manual review packet localizes the sword-swap checkpoint caption")
	assert_packet_checkpoint_field(review_packet, "candidate_checkpoints", "released_after_delete_no", "evidence_type", "screenshot_grid", "manual review packet marks screenshot-backed candidates as screenshot-grid evidence")
	assert_packet_checkpoint_field(review_packet, "candidate_checkpoints", "released_after_delete_no", "evidence_type_label", "截图+格子锚点", "manual review packet localizes screenshot-grid evidence")
	assert_packet_checkpoint_field(review_packet, "reviewed_confirmed_checkpoints", "good_hand_followup", "caption_localized", "切到好手势辅助状态", "manual review packet localizes reviewed candidate checkpoint captions")
	assert_packet_manual_focus(review_packet, "爱字源码计算候选格 [2,12] 的原版运行确认，以及从该格推入手势槽的真实路径", "manual review packet keeps the love-word reachability review focus")
	assert_packet_visual_report(review_packet, "GLOVE-SHOT-009", "manual review packet links the transition visual report")
	assert_packet_visual_report(review_packet, "GLOVE-SHOT-010", "manual review packet links the failure visual report")
	assert_packet_guidance(review_packet, "先核主流程", "manual review packet includes the first review guidance card")
	assert_packet_walkthrough(review_packet, "glove-correct-route-runtime", "manual review packet exports the correct-route walkthrough")
	assert_packet_walkthrough_step_field(review_packet, "glove-correct-route-runtime", "walk from start to lower lifeline clue", "caption_localized", "从起点走到下方生命线线索", "manual review packet localizes the correct-route step caption")
	assert_packet_walkthrough_step_field(review_packet, "glove-correct-route-runtime", "walk from start to lower lifeline clue", "input_summary", "移动路径：上、上", "manual review packet exports the localized input summary")
	assert_packet_walkthrough_step_field(review_packet, "glove-correct-route-runtime", "push good into the gesture slot", "caption_localized", "把好字真实推入手势槽", "manual review packet records the real good-word push sequence")
	assert_packet_walkthrough_step_field(review_packet, "glove-correct-route-runtime", "push two into the gesture slot", "caption_localized", "把二字真实推入手势槽", "manual review packet records the real two-word push sequence")
	assert_packet_walkthrough_step_field(review_packet, "glove-release-after-delete-runtime", "walk through the one-hand corridor to the no word", "caption_localized", "沿一手势通道走到不字前", "manual review packet records the real route to the no word")
	assert_packet_walkthrough_step_field(review_packet, "glove-sword-swap-runtime", "reuse verified correct route through right sword swap", "caption_localized", "复用已验证正确路线直到掌中剑右移", "manual review packet localizes helper-route walkthrough captions")
	assert_packet_generated_from_field(review_packet, "route_walkthroughs_path", output_dir.path_join("glove_route_walkthroughs.md").replace("\\", "/"), "manual review packet exposes the route walkthrough markdown path")
	assert_packet_generated_from_field(review_packet, "source_evidence_path", output_dir.path_join("glove_source_evidence.json").replace("\\", "/"), "manual review packet exposes the source evidence json path")
	assert_packet_generated_from_field(review_packet, "source_evidence_markdown_path", output_dir.path_join("glove_source_evidence.md").replace("\\", "/"), "manual review packet exposes the source evidence markdown path")
	assert_packet_source_finding_field(review_packet, "SRC-LOVE-GESTURE", "title", "爱手势在原始 scene 中确实存在", "manual review packet records the love-gesture source finding")
	assert_packet_source_finding_field(review_packet, "SRC-LOVE-GESTURE", "pt_love_test_node", "T_愛的手勢", "manual review packet records the PT love-hand test node")
	assert_packet_source_finding_field(review_packet, "SRC-LOVE-GESTURE", "achievement_id", "3-5", "manual review packet records the first-love achievement id")
	assert_packet_source_finding_field(review_packet, "SRC-LOVE-WORD-SOURCE", "title", "爱字在原始 scene 中有可推标签来源", "manual review packet records the love-word source finding")
	assert_packet_source_finding_field(review_packet, "SRC-LOVE-WORD-SOURCE", "source_scene_node", "零的手勢", "manual review packet records the love-word source node")
	assert_packet_source_finding_field(review_packet, "SRC-LOVE-WORD-SOURCE", "pushable_label_text", "愛", "manual review packet records the love-word pushable label text")
	assert_packet_source_finding_array_field(review_packet, "SRC-LOVE-WORD-SOURCE", "typed_text_pos", [1, 12], "manual review packet records the love-word typed text position")
	assert_packet_source_finding_array_field(review_packet, "SRC-LOVE-WORD-SOURCE", "computed_label_grid_candidate", [2, 12], "manual review packet records the computed love-word grid candidate")
	assert_packet_source_finding_bool_field(review_packet, "SRC-LOVE-WORD-SOURCE", "label_can_push", true, "manual review packet records that the love-word label is pushable")
	assert_packet_source_finding_field(review_packet, "SRC-LOVE-WORD-SOURCE", "gating_condition", "s:ch3_手掌調查敘述出現==false", "manual review packet records the love-word gating condition")
	assert_packet_source_finding_field(review_packet, "SRC-TYPEWRITER-LAYER", "title", "@[type]/@[clear_typed] 在测试地图里表现为打字机对白层", "manual review packet records the typewriter-layer source finding")
	assert_packet_source_finding_array_field(review_packet, "SRC-TYPEWRITER-LAYER", "sample_event_now_pos", [6, 1], "manual review packet records the sample event world position for typed-layer evidence")
	assert_packet_source_finding_array_field(review_packet, "SRC-TYPEWRITER-LAYER", "sample_typed_pos", [3, 9], "manual review packet records the sample typed-layer position")
	assert_packet_source_finding_field(review_packet, "SRC-TYPEWRITER-LAYER", "sample_tag", "room", "manual review packet records the sample typed-layer tag")
	assert_packet_source_finding_field(review_packet, "SRC-TYPEWRITER-RUNTIME-GENERATION", "title", "Typewriter.gdc 暗示标签字会在运行时生成实体", "manual review packet records the typewriter runtime-generation source finding")
	assert_packet_source_finding_bool_field(review_packet, "SRC-TYPEWRITER-RUNTIME-GENERATION", "supports_runtime_pushable_label_inference", true, "manual review packet records the typewriter runtime-generation inference flag")
	assert_packet_source_finding_field(review_packet, "SRC-GOOD-LIKE-SHARED", "title", "好手势与赞手势在源码里共用同一手势状态", "manual review packet records the good-like shared source finding")
	assert_packet_source_finding_field(review_packet, "SRC-RELEASE-GESTURE", "title", "放开状态在原始 scene 中是独立手势分支", "manual review packet records the release source finding")
	assert_packet_source_finding_field(review_packet, "SRC-RELEASE-GESTURE", "audio_path", "res://Sounds/se/第三章 音效/SE_3_58_gear_rock.wav", "manual review packet records the source release audio")
	assert_packet_source_finding_array_field(review_packet, "SRC-RELEASE-GESTURE", "sentence_animation_pos", [6, 3], "manual review packet records the release sentence animation position")
	assert_packet_source_finding_array_field(review_packet, "SRC-RELEASE-GESTURE", "camera_shake", [80, 15], "manual review packet records the release camera shake parameters")
	assert_packet_source_finding_field(review_packet, "SRC-SWORD-SWAP", "title", "掌中剑换位在原始 scene 中有明确状态标记", "manual review packet records the sword-swap source finding")
	assert_packet_source_finding_field(review_packet, "SRC-TRANSITION-TAIL", "target_map", "第三章/16_添譜來堂_尾聲", "manual review packet records the source tail destination")
	assert_packet_source_finding_field(review_packet, "SRC-TRANSITION-TAIL", "dialogue_page_count", "3.0", "manual review packet records all three source tail dialogue pages")
	assert_acceptance_detail(review_packet, "tools/run_all_tests.ps1 passes", "仓库一键总测通过。", "manual review packet localizes acceptance items")
	assert_packet_source_artifact(review_packet, "原始视频：E:/wordgame copy/参考资料/视频参考/手套关卡全录屏.mkv", "manual review packet exposes the glove source video")
	assert_packet_source_artifact(review_packet, "原始文档：E:/wordgame copy/参考资料/图片参考/手套流程.docx", "manual review packet exposes the glove source docx")
	assert_focus_review_status(review_packet, "爱字源码计算候选格 [2,12] 的原版运行确认，以及从该格推入手势槽的真实路径", "已解决", "manual review packet applies focus review overrides")
	assert_equal(int((review_packet.get("review_summary", {}) as Dictionary).get("confirmed_count", -1)), 8, "manual review packet counts the confirmed automatic checkpoints including real like-word insertion")
	assert_equal(int((review_packet.get("review_summary", {}) as Dictionary).get("reviewed_confirmed_count", -1)), 1, "manual review packet counts reviewed confirmed candidates")
	assert_equal(int((review_packet.get("review_summary", {}) as Dictionary).get("reviewed_rejected_count", -1)), 1, "manual review packet counts reviewed rejected candidates")
	assert_equal(int((review_packet.get("review_summary", {}) as Dictionary).get("auxiliary_setup_count", -1)), 0, "manual review summary exposes zero setup debt")

	var response_template_path := output_dir.path_join("glove_manual_review_response_template.json")
	assert_true(FileAccess.file_exists(response_template_path), "glove report exporter writes the glove review response template")
	var response_template: Dictionary = read_json_file(response_template_path)
	assert_equal(str(response_template.get("level_id", "")), "glove", "review response template keeps glove level id")
	assert_response_template_checkpoint(response_template, "released_after_delete_no", "review response template includes pending candidate checkpoints")
	assert_response_template_route_step(response_template, "glove-correct-route-runtime", 3, "review response template includes correct-route step reviews")
	assert_response_template_route_step(response_template, "glove-path-opened-runtime", 0, "review response template includes mid-path route step reviews")
	assert_response_template_route_step(response_template, "glove-transition-out-runtime", 0, "review response template includes transition route step reviews")
	var priority_review_step_count := 0
	var review_runner := GloveRouteRunner.new()
	for route_path in [GLOVE_CORRECT_ROUTE_RUNTIME_PATH, GLOVE_PATH_OPENED_ROUTE_RUNTIME_PATH, GLOVE_TRANSITION_OUT_ROUTE_RUNTIME_PATH]:
		priority_review_step_count += (review_runner.load_route_file(route_path).get("steps", []) as Array).size()
	assert_equal(int(response_template.get("route_step_reviews", []).size()), priority_review_step_count, "review response template scopes structured route-step review down to the three priority routes")
	assert_response_template_route_step_field(response_template, "glove-correct-route-runtime", 3, "caption_localized", "露出好字", "review response template exposes localized route-step captions")
	assert_response_template_lacks_route(response_template, "glove-sword-swap-runtime", "review response template leaves helper sword-swap steps out of the structured reviewer payload")

	var review_html_path := output_dir.path_join("glove_manual_review_packet.html")
	assert_true(FileAccess.file_exists(review_html_path), "glove report exporter writes the manual review html dashboard")
	var review_html := read_text_file(review_html_path)
	assert_text_contains(review_html, "手套关人工复查包", "manual review html includes the packet heading")
	assert_text_contains(review_html, "已确认锚点（自动证据）", "manual review html includes the confirmed checkpoint section")
	assert_text_contains(review_html, "已人工确认的候选锚点", "manual review html includes the reviewed-confirmed section")
	assert_text_contains(review_html, "候选锚点（必须人工复查）", "manual review html includes the candidate checkpoint section")
	assert_text_contains(review_html, "已人工驳回的候选锚点", "manual review html includes the reviewed-rejected section")
	assert_text_contains(review_html, "组员怎么复查", "manual review html includes the review guidance section")
	assert_text_contains(review_html, "关卡清单", "manual review html includes the generated-from file links section")
	assert_text_contains(review_html, "原始资料", "manual review html includes the source artifacts section")
	assert_text_contains(review_html, "回传模板", "manual review html includes the reviewer handoff template")
	assert_text_contains(review_html, "结构化回传", "manual review html includes the structured-review form section")
	assert_text_contains(review_html, "导出复查结果 JSON", "manual review html includes the review export button")
	assert_text_contains(review_html, "路线步骤录入", "manual review html includes the route-step review form section")
	assert_text_contains(review_html, "只需要优先复查 3 条路线", "manual review html explains that the structured route-step form is scoped to the three priority routes")
	assert_text_contains(review_html, "<div>辅助设置</div><div><span class=\"warn\">0</span>", "manual review html shows zero setup debt")
	assert_text_contains(review_html, "gloveReviewData", "manual review html embeds glove review form data")
	assert_text_contains(review_html, "人工确认", "manual review html includes the localized manual-review status")
	assert_text_contains(review_html, "正确路线运行版", "manual review html includes the localized route label")
	assert_text_contains(review_html, "当前 route 步骤明细", "manual review html includes the route walkthrough section")
	assert_text_contains(review_html, "移动路径：上、上", "manual review html includes localized route step input summaries")
	assert_text_contains(review_html, "源码证据", "manual review html includes the source evidence section")
	assert_text_contains(review_html, "爱手势在原始 scene 中确实存在", "manual review html includes the love-gesture source finding")
	assert_text_contains(review_html, "零的手勢", "manual review html surfaces the structured love-word source node")
	assert_text_contains(review_html, "愛", "manual review html surfaces the structured love-word label text")
	assert_text_contains(review_html, "[1, 12]", "manual review html surfaces the structured love-word text position")
	assert_text_contains(review_html, "规则锚点", "manual review html includes the rule-only evidence label")
	assert_text_contains(review_html, "截图+格子锚点", "manual review html includes the screenshot-grid evidence label")
	assert_text_contains(review_html, "掌中剑换到右边", "manual review html includes the localized sword-swap caption")
	assert_text_contains(review_html, "爱字源码计算候选格 [2,12] 的原版运行确认，以及从该格推入手势槽的真实路径", "manual review html includes the love-word reachability focus text")
	var embedded_review_data: Dictionary = extract_embedded_review_data(review_html)
	assert_equal(str(embedded_review_data.get("level_id", "")), "glove", "manual review html embeds parseable glove review data json")
	assert_equal(int(embedded_review_data.get("checkpoint_reviews", []).size()), 7, "manual review html embeds the pending checkpoint review entries")
	assert_equal(int(embedded_review_data.get("route_step_reviews", []).size()), priority_review_step_count, "manual review html embeds only the scoped priority route-step review entries")
	assert_review_form_entry_field(embedded_review_data, "released_after_delete_no", "evidence_type_label", "截图+格子锚点", "manual review html embeds localized evidence labels for reviewer forms")
	assert_review_form_entry_field(embedded_review_data, "good_hand_followup", "caption_localized", "切到好手势辅助状态", "manual review html embeds localized checkpoint captions for reviewer forms")
	assert_review_route_step_field(embedded_review_data, "glove-correct-route-runtime", 3, "caption_localized", "露出好字", "manual review html embeds localized route-step captions for reviewer forms")
	assert_review_route_step_field(embedded_review_data, "glove-correct-route-runtime", 3, "input_summary", "互动", "manual review html embeds localized route-step input summaries for reviewer forms")
	assert_review_route_step_field(embedded_review_data, "glove-transition-out-runtime", 0, "route_label", "收尾转场运行版", "manual review html keeps the transition route in the structured route-step reviewer payload")
	assert_review_route_step_absent(embedded_review_data, "glove-sword-swap-runtime", 7, "manual review html leaves helper sword-swap steps out of the structured route-step reviewer payload")

	var walkthrough_markdown_path := output_dir.path_join("glove_route_walkthroughs.md")
	assert_true(FileAccess.file_exists(walkthrough_markdown_path), "glove report exporter writes the route walkthrough markdown file")
	var walkthrough_markdown := read_text_file(walkthrough_markdown_path)
	assert_text_contains(walkthrough_markdown, "# 手套关 Route 步骤明细", "route walkthrough markdown includes the document heading")
	assert_text_contains(walkthrough_markdown, "## 正确路线运行版", "route walkthrough markdown includes the localized correct-route heading")
	assert_text_contains(walkthrough_markdown, "移动路径：上、上", "route walkthrough markdown includes localized input summaries")
	assert_text_contains(walkthrough_markdown, "复用已验证正确路线直到掌中剑右移", "route walkthrough markdown localizes helper-route step captions")

	var source_evidence_json_path := output_dir.path_join("glove_source_evidence.json")
	assert_true(FileAccess.file_exists(source_evidence_json_path), "glove report exporter writes the source evidence json file")
	var source_evidence_doc: Dictionary = read_json_file(source_evidence_json_path)
	assert_true(int(source_evidence_doc.get("source_findings", []).size()) >= 5, "source evidence json keeps the expected glove source findings")

	var source_evidence_markdown_path := output_dir.path_join("glove_source_evidence.md")
	assert_true(FileAccess.file_exists(source_evidence_markdown_path), "glove report exporter writes the source evidence markdown file")
	var source_evidence_markdown := read_text_file(source_evidence_markdown_path)
	assert_text_contains(source_evidence_markdown, "# 手套关源码证据", "source evidence markdown includes the document heading")
	assert_text_contains(source_evidence_markdown, "爱手势在原始 scene 中确实存在", "source evidence markdown includes the love-gesture finding")
	assert_text_contains(source_evidence_markdown, "T_愛的手勢", "source evidence markdown includes the PT love-hand test node")
	assert_text_contains(source_evidence_markdown, "3-5", "source evidence markdown includes the first-love achievement id")
	assert_text_contains(source_evidence_markdown, "爱字在原始 scene 中有可推标签来源", "source evidence markdown includes the love-word source finding")
	assert_text_contains(source_evidence_markdown, "@[type]/@[clear_typed] 在测试地图里表现为打字机对白层", "source evidence markdown includes the typewriter-layer finding")
	assert_text_contains(source_evidence_markdown, "Typewriter.gdc 暗示标签字会在运行时生成实体", "source evidence markdown includes the typewriter runtime-generation finding")
	assert_text_contains(source_evidence_markdown, "generated_in_runtime", "source evidence markdown includes the typewriter runtime-generation token")
	assert_text_contains(source_evidence_markdown, "零的手勢", "source evidence markdown includes the structured love-word source node")
	assert_text_contains(source_evidence_markdown, "愛", "source evidence markdown includes the structured love-word label text")
	assert_text_contains(source_evidence_markdown, "[1, 12]", "source evidence markdown includes the structured love-word text position")
	assert_text_contains(source_evidence_markdown, "map0002.tscn", "source evidence markdown includes the typed-layer sample map path")
	assert_text_contains(source_evidence_markdown, "[6, 1]", "source evidence markdown includes the typed-layer sample event world position")
	assert_text_contains(source_evidence_markdown, "[3, 9]", "source evidence markdown includes the typed-layer sample typed position")

	var source_shapes_json_path := output_dir.path_join("glove_source_gesture_shapes.json")
	assert_true(FileAccess.file_exists(source_shapes_json_path), "glove report exporter writes the source gesture shapes json file")
	var source_shapes_doc: Dictionary = read_json_file(source_shapes_json_path)
	assert_equal(str(source_shapes_doc.get("level_id", "")), "glove", "source gesture shapes json keeps the glove level id")
	assert_true(int(source_shapes_doc.get("states", []).size()) == 7, "source gesture shapes json keeps the seven glove gesture states")

	var source_shapes_markdown_path := output_dir.path_join("glove_source_gesture_shapes.md")
	assert_true(FileAccess.file_exists(source_shapes_markdown_path), "glove report exporter writes the source gesture shapes markdown file")
	var source_shapes_markdown := read_text_file(source_shapes_markdown_path)
	assert_text_contains(source_shapes_markdown, "# 手套关手势版型源码对照", "source gesture shapes markdown includes the document heading")
	assert_text_contains(source_shapes_markdown, "视觉尾巴", "source gesture shapes markdown explains the visual-tail rows")

	write_text_file(GLOVE_MANUAL_REVIEW_OVERRIDES_PATH, original_overrides_text)
	var production_output_dir := ProjectSettings.globalize_path(GLOVE_REPORT_OUTPUT_DIR)
	var production_summary: Dictionary = exporter.export_runtime_reports(production_output_dir)
	assert_equal(int(production_summary.get("exported_count", 0)), 11, "glove report exporter refreshes the production glove runtime reports")
	assert_true(FileAccess.file_exists(production_output_dir.path_join("glove_manual_review_packet.html")), "glove report exporter refreshes the production glove review html")
	assert_true(FileAccess.file_exists(production_output_dir.path_join("glove_manual_review_packet.json")), "glove report exporter refreshes the production glove review json")

func test_glove_source_scene_parser_extracts_all_gesture_shapes() -> void:
	var parser := GloveSourceSceneParser.new()
	var source_shapes := parser.extract_gesture_shapes()
	var expected_states := ["zero", "like", "one", "two", "win", "love", "release"]
	for state_name in expected_states:
		assert_true(source_shapes.has(state_name), "source scene parser extracts %s hand shape" % state_name)
		var lines: Array = source_shapes.get(state_name, [])
		assert_true(lines.size() > 0, "source scene parser keeps non-empty lines for %s" % state_name)

func test_glove_hand_layout_uses_source_node_origin() -> void:
	var zero_cells := GloveLayouts.hand_cells("zero")
	assert_true(zero_cells.has(Vector2i(15, 0)), "zero hand applies source now_pos x=7 to the first row")
	assert_true(not zero_cells.has(Vector2i(8, 0)), "zero hand does not render at the unshifted local text coordinate")
	assert_true(zero_cells.has(Vector2i(30, 14)), "zero hand keeps the source-backed lower-right palm edge inside the 32x18 grid")

func test_glove_source_scene_parser_extracts_love_gesture_state_details() -> void:
	var parser := GloveSourceSceneParser.new()
	var details: Dictionary = parser.extract_love_gesture_state_details()
	assert_equal(int(details.get("love_state_value", -1)), 5, "source scene parser records the love gesture state value")
	assert_equal(str(details.get("love_activation_switch", "")), "ch3_愛的手勢成立", "source scene parser records the love gesture activation switch")
	assert_equal(str(details.get("first_love_switch", "")), "ch3_第一次愛的手勢", "source scene parser records the first-love switch")
	assert_equal(str(details.get("achievement_id", "")), "3-5", "source scene parser records the first-love achievement id")
	assert_equal(str(details.get("pt_love_test_node", "")), "T_愛的手勢", "source scene parser records the PT love-hand test node")

func test_glove_source_scene_parser_extracts_love_word_source_details() -> void:
	var parser := GloveSourceSceneParser.new()
	var details: Dictionary = parser.extract_love_word_source_details()
	assert_equal(str(details.get("source_scene_node", "")), "零的手勢", "source scene parser records the love-word source node")
	assert_equal(str(details.get("pushable_label_text", "")), "愛", "source scene parser records the pushable love label text")
	assert_equal(normalize_numeric_array(details.get("typed_text_pos", [])), [1, 12], "source scene parser records the love-word typed text position")
	assert_equal(normalize_numeric_array(details.get("computed_label_grid_candidate", [])), [2, 12], "source scene parser computes the love label grid candidate")
	assert_equal(bool(details.get("label_can_push", false)), true, "source scene parser records that the love-word label is pushable")
	assert_equal(str(details.get("gating_condition", "")), "s:ch3_手掌調查敘述出現==false", "source scene parser records the love-word gating condition")
	assert_text_contains(str(details.get("typed_texts_raw", "")), "<l>愛</l>", "source scene parser keeps the tagged love-word source text")
	assert_text_contains(str(details.get("commands_excerpt", "")), "\"can_push\": true", "source scene parser keeps the can_push excerpt")

func test_glove_source_scene_parser_extracts_typewriter_layer_reference_details() -> void:
	var parser := GloveSourceSceneParser.new()
	var details: Dictionary = parser.extract_typewriter_layer_reference_details()
	assert_equal(str(details.get("intro_clear_tag", "")), "typed", "source scene parser records the intro typed-layer clear tag")
	assert_equal(normalize_numeric_array(details.get("intro_typed_pos", [])), [4, 8], "source scene parser records the intro typed-layer position")
	assert_equal(str(details.get("sample_clear_tag", "")), "room", "source scene parser records the sample typed-layer clear tag")
	assert_equal(str(details.get("sample_tag", "")), "room", "source scene parser records the sample typed-layer tag")
	assert_equal(normalize_numeric_array(details.get("sample_event_now_pos", [])), [6, 1], "source scene parser records the sample event world position")
	assert_equal(normalize_numeric_array(details.get("sample_typed_pos", [])), [3, 9], "source scene parser records the sample typed-layer position")

func test_glove_source_scene_parser_extracts_typewriter_runtime_generation_details() -> void:
	var parser := GloveSourceSceneParser.new()
	var details: Dictionary = parser.extract_typewriter_runtime_generation_details()
	assert_equal(bool(details.get("contains_generated_in_runtime", false)), true, "source scene parser records the generated_in_runtime token")
	assert_equal(bool(details.get("contains_exist_event", false)), true, "source scene parser records the exist_event token")
	assert_equal(bool(details.get("contains_both", false)), true, "source scene parser records the both token")
	assert_equal(bool(details.get("contains_copy", false)), true, "source scene parser records the copy token")
	assert_equal(bool(details.get("contains_label_settings", false)), true, "source scene parser records the label_settings token")
	assert_equal(bool(details.get("contains_has_default_tag", false)), true, "source scene parser records the has_defalut_tag token")
	assert_equal(bool(details.get("supports_runtime_pushable_label_inference", false)), true, "source scene parser records the runtime pushable-label inference flag")

func test_glove_source_visual_shapes_extend_runtime_collision_layouts() -> void:
	var parser := GloveSourceSceneParser.new()
	var source_shapes := parser.extract_gesture_shapes()
	for state_name in ["zero", "like", "one", "two", "win", "love", "release"]:
		var source_lines: Array = source_shapes.get(state_name, [])
		var runtime_lines := GloveLayouts.hand_lines(state_name)
		assert_true(source_lines.size() >= runtime_lines.size(), "source visual shape keeps at least the runtime rows for %s" % state_name)
		assert_true(source_lines.size() - runtime_lines.size() <= 2, "source visual tail stays limited for %s" % state_name)
		for line_index in range(runtime_lines.size()):
			assert_equal(
				source_lines[line_index],
				runtime_lines[line_index],
				"runtime collision layout stays aligned with the source visual prefix for %s row %s" % [state_name, line_index]
			)

func test_glove_manual_review_importer_normalizes_input() -> void:
	var importer := GloveManualReviewImporter.new()
	var input_path := ProjectSettings.globalize_path("user://glove-manual-review-import-input.json")
	var output_path := ProjectSettings.globalize_path("user://glove-manual-review-import-output.json")
	write_text_file(
		input_path,
		JSON.stringify({
			"level_id": "glove",
			"checkpoint_reviews": [
				{
					"checkpoint_id": "good_hand_followup",
					"screenshot_ref": "GLOVE-SHOT-008",
					"grid_ref": "GLOVE-GRID-015",
					"status": "人工确认",
					"actor": "reviewer-a",
					"time": "2026-07-12 05:00:00",
					"note": "确认可接受。"
				}
			],
			"focus_reviews": [
				{
					"manual_review_focus": "黑屏对白的真实文案、时机与去向",
					"status": "已解决",
					"actor": "reviewer-b",
					"time": "2026-07-12 05:01:00",
					"note": "对白时机已核定。"
				}
			],
			"route_step_reviews": [
				{
					"route_id": "glove-correct-route-runtime",
					"step_index": 3,
					"caption": "reveal the good word",
					"status": "人工确认",
					"actor": "reviewer-c",
					"time": "2026-07-12 05:02:00",
					"note": "这一步与原版一致。"
				}
			]
		}, "\t")
	)
	var result: Dictionary = importer.import_review_result(input_path, output_path)
	assert_true(bool(result.get("success", false)), "glove manual review importer completes")
	assert_true(FileAccess.file_exists(output_path), "glove manual review importer writes output json")
	var output_doc: Dictionary = read_json_file(output_path)
	assert_equal(str(output_doc.get("level_id", "")), "glove", "glove manual review importer keeps glove level id")
	assert_equal(int(output_doc.get("checkpoint_reviews", []).size()), 1, "glove manual review importer keeps checkpoint review count")
	assert_equal(int(output_doc.get("focus_reviews", []).size()), 1, "glove manual review importer keeps focus review count")
	assert_equal(int(output_doc.get("route_step_reviews", []).size()), 1, "glove manual review importer keeps route-step review count")
	var checkpoint_review: Dictionary = output_doc.get("checkpoint_reviews", [])[0]
	assert_equal(str(checkpoint_review.get("review_status", "")), "confirmed", "glove manual review importer normalizes checkpoint review status")
	assert_equal(str(checkpoint_review.get("resolution_note", "")), "确认可接受。", "glove manual review importer keeps checkpoint review note")
	var focus_review: Dictionary = output_doc.get("focus_reviews", [])[0]
	assert_equal(str(focus_review.get("review_status", "")), "resolved", "glove manual review importer normalizes focus review status")
	assert_equal(str(focus_review.get("resolution_note", "")), "对白时机已核定。", "glove manual review importer keeps focus review note")
	var route_step_review: Dictionary = output_doc.get("route_step_reviews", [])[0]
	assert_equal(str(route_step_review.get("review_status", "")), "confirmed", "glove manual review importer normalizes route-step review status")
	assert_equal(str(route_step_review.get("resolution_note", "")), "这一步与原版一致。", "glove manual review importer keeps route-step review note")

func make_world() -> RefCounted:
	var glove_script = load(GLOVE_LEVEL_PATH)
	var world := GridWorld.new()
	world.load_level(glove_script.build_level())
	return world

func set_gesture_slot(world: RefCounted, text: String) -> void:
	var target_pos := Vector2i(26, 17)
	var parked_pos := Vector2i(31, 17)
	var occupying = world.get_any_entity_at(target_pos)
	if occupying != null and occupying.text != text:
		world.move_entity_to(occupying.id, parked_pos)
	var gesture_word = world.find_first_entity_by_text(text)
	assert_true(gesture_word != null, "gesture word %s exists" % text)
	if gesture_word == null:
		return
	world.move_entity_to(gesture_word.id, target_pos)

func place_player_left_of_first_palm(world: RefCounted) -> void:
	var palm = world.find_first_entity_by_text("掌")
	assert_true(palm != null, "palm wall exists for interaction setup")
	if palm == null:
		return
	world.player_pos = palm.grid_pos + Vector2i.LEFT
	world.facing = Vector2i.RIGHT

func place_player_left_of_sentence_sword(world: RefCounted) -> void:
	world.player_pos = Vector2i(3, 2)
	world.facing = Vector2i.RIGHT

func place_player_left_of_source_sword(world: RefCounted) -> void:
	world.player_pos = GloveLayouts.SWORD_LEFT_POS + Vector2i.LEFT
	world.facing = Vector2i.RIGHT

func route_contains_step_text(route: Dictionary, expected_text: String) -> bool:
	for step in route.get("steps", []):
		if str(step.get("text", "")) == expected_text:
			return true
	return false

func route_contains_step_caption(route: Dictionary, expected_caption: String) -> bool:
	for step in route.get("steps", []):
		if str(step.get("caption", "")) == expected_caption:
			return true
	return false

func assert_route_has_no_set_player_steps(route_path: String, label: String) -> void:
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(route_path)
	for step in route.get("steps", []):
		var entry: Dictionary = step
		assert_true(str(entry.get("type", "")) != "set_player", "%s no longer relies on set_player: %s" % [label, str(entry.get("caption", ""))])

func assert_route_has_no_auxiliary_steps(route_path: String, label: String) -> void:
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(route_path)
	for step in route.get("steps", []):
		var entry: Dictionary = step
		assert_true(str(entry.get("type", "")) not in ["set_player", "set_gesture_slot", "place_at_palm"], "%s uses only real player inputs: %s" % [label, str(entry.get("caption", ""))])

func assert_report_trace_contains(report: Dictionary, expected_token: String, message: String) -> void:
	var trace: Dictionary = report.get("runtime_trace", {})
	var animation_ids: Array = trace.get("animation_ids", [])
	var audio_ids: Array = trace.get("audio_ids", [])
	var all_tokens: Array[String] = []
	for animation_id in animation_ids:
		all_tokens.append(str(animation_id))
	for audio_id in audio_ids:
		all_tokens.append(str(audio_id))
	assert_true(all_tokens.has(expected_token), message)

func assert_step_trace_contains(report: Dictionary, caption: String, expected_token: String, message: String) -> void:
	for step in report.get("steps", []):
		var step_entry: Dictionary = step
		if str(step_entry.get("caption", "")) != caption:
			continue
		var trace: Dictionary = step_entry.get("runtime_trace", {})
		var animation_ids: Array = trace.get("animation_ids", [])
		var audio_ids: Array = trace.get("audio_ids", [])
		var all_tokens: Array[String] = []
		for animation_id in animation_ids:
			all_tokens.append(str(animation_id))
		for audio_id in audio_ids:
			all_tokens.append(str(audio_id))
		assert_true(all_tokens.has(expected_token), message)
		return
	assert_true(false, "%s (missing caption %s)" % [message, caption])

func assert_report_checkpoint(report: Dictionary, checkpoint_id: String, expected_ref: String, expected_caption: String, expected_player_pos: Array, message: String) -> void:
	for checkpoint in report.get("checkpoints", []):
		var entry: Dictionary = checkpoint
		if str(entry.get("id", "")) != checkpoint_id:
			continue
		assert_equal(str(entry.get("ref", "")), expected_ref, "%s ref" % message)
		assert_equal(str(entry.get("caption", "")), expected_caption, "%s caption" % message)
		assert_equal(normalize_numeric_array(entry.get("player_pos", [])), normalize_numeric_array(expected_player_pos), "%s player_pos" % message)
		return
	assert_true(false, "%s (missing checkpoint %s)" % [message, checkpoint_id])

func assert_report_checkpoint_status(report: Dictionary, checkpoint_id: String, expected_status: String, message: String) -> void:
	for checkpoint in report.get("checkpoints", []):
		var entry: Dictionary = checkpoint
		if str(entry.get("id", "")) != checkpoint_id:
			continue
		assert_equal(str(entry.get("verification_status", "")), expected_status, message)
		return
	assert_true(false, "%s (missing checkpoint %s)" % [message, checkpoint_id])

func assert_report_checkpoint_grid_id(report: Dictionary, checkpoint_id: String, expected_grid_id: String, message: String) -> void:
	for checkpoint in report.get("checkpoints", []):
		var entry: Dictionary = checkpoint
		if str(entry.get("id", "")) != checkpoint_id:
			continue
		assert_equal(str(entry.get("source_grid_id", "")), expected_grid_id, message)
		return
	assert_true(false, "%s (missing checkpoint %s)" % [message, checkpoint_id])

func assert_report_step_input_path(report: Dictionary, caption: String, expected_path: Array, message: String) -> void:
	for step_variant in report.get("steps", []):
		var step: Dictionary = step_variant
		if str(step.get("caption", "")) != caption:
			continue
		assert_equal(normalize_vec2_path(step.get("input_data", {}).get("path", [])), normalize_vec2_path(expected_path), message)
		return
	assert_true(false, "%s (missing step %s)" % [message, caption])

func assert_route_catalog_entry_field(index_doc: Dictionary, route_id: String, field_name: String, expected_value: String, message: String) -> void:
	for route_variant in index_doc.get("routes", []):
		var route: Dictionary = route_variant
		if str(route.get("route_id", "")) != route_id:
			continue
		assert_equal(str(route.get(field_name, "")), expected_value, message)
		return
	fail("%s" % message)

func read_json_file(path: String) -> Dictionary:
	assert_true(FileAccess.file_exists(path), "json file exists: %s" % path)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "json file opens: %s" % path)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "json file parses as dictionary: %s" % path)
	if parsed is Dictionary:
		return (parsed as Dictionary).duplicate(true)
	return {}

func read_text_file(path: String) -> String:
	assert_true(FileAccess.file_exists(path), "text file exists: %s" % path)
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "text file opens: %s" % path)
	if file == null:
		return ""
	return file.get_as_text()

func write_text_file(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_true(file != null, "text file opens for write: %s" % path)
	if file == null:
		return
	file.store_string(text)

func extract_embedded_review_data(html: String) -> Dictionary:
	var start_token := "<script id=\"gloveReviewData\" type=\"application/json\">"
	var end_token := "</script>"
	var start_index := html.find(start_token)
	assert_true(start_index != -1, "manual review html contains gloveReviewData script block")
	if start_index == -1:
		return {}
	start_index += start_token.length()
	var end_index := html.find(end_token, start_index)
	assert_true(end_index != -1, "manual review html closes the gloveReviewData script block")
	if end_index == -1:
		return {}
	var json_text := html.substr(start_index, end_index - start_index)
	var parsed = JSON.parse_string(json_text)
	assert_true(parsed is Dictionary, "manual review html gloveReviewData block parses as dictionary")
	if parsed is Dictionary:
		return (parsed as Dictionary).duplicate(true)
	return {}

func remove_dir_recursive(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for entry_name in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(entry_name))
	for dir_name in DirAccess.get_directories_at(path):
		remove_dir_recursive(path.path_join(dir_name))
	DirAccess.remove_absolute(path)

func normalize_numeric_array(value: Variant) -> Array[int]:
	var normalized: Array[int] = []
	if value is Array:
		for item in value:
			normalized.append(int(item))
	return normalized

func normalize_vec2_path(value: Variant) -> Array:
	var normalized: Array = []
	if value is Array:
		for item in value:
			normalized.append(normalize_numeric_array(item))
	return normalized

func assert_manifest_source_map(source_maps: Array, expected_suffix: String, message: String) -> void:
	for source_map_entry in source_maps:
		var entry: Dictionary = source_map_entry
		if str(entry.get("source_map", "")).ends_with(expected_suffix):
			return
	fail("%s" % message)

func assert_text_contains(text: String, expected_substring: String, message: String) -> void:
	assert_true(text.contains(expected_substring), message)

func assert_packet_checkpoint(packet: Dictionary, list_key: String, checkpoint_id: String, message: String) -> void:
	for checkpoint_variant in packet.get(list_key, []):
		var checkpoint: Dictionary = checkpoint_variant
		if str(checkpoint.get("id", "")) == checkpoint_id:
			return
	fail("%s" % message)

func assert_packet_checkpoint_field(packet: Dictionary, list_key: String, checkpoint_id: String, field_name: String, expected_value: String, message: String) -> void:
	for checkpoint_variant in packet.get(list_key, []):
		var checkpoint: Dictionary = checkpoint_variant
		if str(checkpoint.get("id", "")) != checkpoint_id:
			continue
		assert_equal(str(checkpoint.get(field_name, "")), expected_value, message)
		return
	fail("%s" % message)

func assert_packet_manual_focus(packet: Dictionary, expected_focus: String, message: String) -> void:
	for focus_variant in packet.get("manual_review_focus", []):
		if str(focus_variant) == expected_focus:
			return
	fail("%s" % message)

func assert_packet_visual_report(packet: Dictionary, baseline_id: String, message: String) -> void:
	for report_variant in packet.get("visual_reports", []):
		var report: Dictionary = report_variant
		if str(report.get("baseline_id", "")) == baseline_id:
			return
	fail("%s" % message)

func assert_packet_guidance(packet: Dictionary, expected_title: String, message: String) -> void:
	for guidance_variant in packet.get("review_guidance", []):
		var guidance: Dictionary = guidance_variant
		if str(guidance.get("title", "")) == expected_title:
			return
	fail("%s" % message)

func assert_packet_generated_from_field(packet: Dictionary, field_name: String, expected_value: String, message: String) -> void:
	var generated_from: Dictionary = packet.get("generated_from", {})
	assert_equal(str(generated_from.get(field_name, "")), expected_value, message)

func assert_packet_source_finding_field(packet: Dictionary, finding_id: String, field_name: String, expected_value: String, message: String) -> void:
	for finding_variant in packet.get("source_findings", []):
		var finding: Dictionary = finding_variant
		if str(finding.get("id", "")) != finding_id:
			continue
		assert_equal(str(finding.get(field_name, "")), expected_value, message)
		return
	fail("%s" % message)

func assert_packet_source_finding_array_field(packet: Dictionary, finding_id: String, field_name: String, expected_value: Array[int], message: String) -> void:
	for finding_variant in packet.get("source_findings", []):
		var finding: Dictionary = finding_variant
		if str(finding.get("id", "")) != finding_id:
			continue
		assert_equal(normalize_numeric_array(finding.get(field_name, [])), expected_value, message)
		return
	fail("%s" % message)

func assert_packet_source_finding_bool_field(packet: Dictionary, finding_id: String, field_name: String, expected_value: bool, message: String) -> void:
	for finding_variant in packet.get("source_findings", []):
		var finding: Dictionary = finding_variant
		if str(finding.get("id", "")) != finding_id:
			continue
		assert_equal(bool(finding.get(field_name, false)), expected_value, message)
		return
	fail("%s" % message)

func assert_packet_walkthrough(packet: Dictionary, route_id: String, message: String) -> void:
	for walkthrough_variant in packet.get("route_walkthroughs", []):
		var walkthrough: Dictionary = walkthrough_variant
		if str(walkthrough.get("route_id", "")) == route_id:
			return
	fail("%s" % message)

func assert_packet_walkthrough_step_field(packet: Dictionary, route_id: String, caption: String, field_name: String, expected_value: String, message: String) -> void:
	for walkthrough_variant in packet.get("route_walkthroughs", []):
		var walkthrough: Dictionary = walkthrough_variant
		if str(walkthrough.get("route_id", "")) != route_id:
			continue
		for step_variant in walkthrough.get("steps", []):
			var step: Dictionary = step_variant
			if str(step.get("caption", "")) != caption:
				continue
			assert_equal(str(step.get(field_name, "")), expected_value, message)
			return
		fail("%s (missing step %s)" % [message, caption])
		return
	fail("%s (missing route %s)" % [message, route_id])

func assert_acceptance_detail(packet: Dictionary, expected_id: String, expected_text: String, message: String) -> void:
	for acceptance_variant in packet.get("acceptance_details", []):
		var acceptance: Dictionary = acceptance_variant
		if str(acceptance.get("id", "")) != expected_id:
			continue
		assert_equal(str(acceptance.get("text", "")), expected_text, message)
		return
	fail("%s" % message)

func assert_packet_source_artifact(packet: Dictionary, expected_label: String, message: String) -> void:
	for artifact_variant in packet.get("source_artifacts", []):
		var artifact: Dictionary = artifact_variant
		if str(artifact.get("label", "")) == expected_label:
			return
	fail("%s" % message)

func assert_focus_review_status(packet: Dictionary, expected_focus: String, expected_label: String, message: String) -> void:
	for focus_variant in packet.get("manual_review_focus_items", []):
		var focus_item: Dictionary = focus_variant
		if str(focus_item.get("focus", "")) != expected_focus:
			continue
		assert_equal(str(focus_item.get("review_status_label", "")), expected_label, message)
		return
	fail("%s" % message)

func assert_response_template_checkpoint(template_doc: Dictionary, checkpoint_id: String, message: String) -> void:
	for review_variant in template_doc.get("checkpoint_reviews", []):
		var review: Dictionary = review_variant
		if str(review.get("id", "")) == checkpoint_id:
			return
	fail("%s" % message)

func assert_response_template_route_step(template_doc: Dictionary, route_id: String, step_index: int, message: String) -> void:
	for review_variant in template_doc.get("route_step_reviews", []):
		var review: Dictionary = review_variant
		if str(review.get("route_id", "")) != route_id:
			continue
		if int(review.get("step_index", -1)) != step_index:
			continue
		return
	fail("%s" % message)

func assert_response_template_route_step_field(template_doc: Dictionary, route_id: String, step_index: int, field_name: String, expected_value: String, message: String) -> void:
	for review_variant in template_doc.get("route_step_reviews", []):
		var review: Dictionary = review_variant
		if str(review.get("route_id", "")) != route_id:
			continue
		if int(review.get("step_index", -1)) != step_index:
			continue
		assert_equal(str(review.get(field_name, "")), expected_value, message)
		return
	fail("%s" % message)

func assert_response_template_lacks_route(template_doc: Dictionary, route_id: String, message: String) -> void:
	for review_variant in template_doc.get("route_step_reviews", []):
		var review: Dictionary = review_variant
		if str(review.get("route_id", "")) == route_id:
			fail("%s" % message)
			return

func assert_review_route_step_absent(doc: Dictionary, route_id: String, step_index: int, message: String) -> void:
	for review_variant in doc.get("route_step_reviews", []):
		var review: Dictionary = review_variant
		if str(review.get("route_id", "")) != route_id:
			continue
		if int(review.get("step_index", -1)) != step_index:
			continue
		fail("%s" % message)
		return

func assert_review_form_entry_field(doc: Dictionary, checkpoint_id: String, field_name: String, expected_value: String, message: String) -> void:
	for review_variant in doc.get("checkpoint_reviews", []):
		var review: Dictionary = review_variant
		if str(review.get("id", "")) != checkpoint_id:
			continue
		assert_equal(str(review.get(field_name, "")), expected_value, message)
		return
	fail("%s" % message)

func assert_review_route_step_field(doc: Dictionary, route_id: String, step_index: int, field_name: String, expected_value: String, message: String) -> void:
	for review_variant in doc.get("route_step_reviews", []):
		var review: Dictionary = review_variant
		if str(review.get("route_id", "")) != route_id:
			continue
		if int(review.get("step_index", -1)) != step_index:
			continue
		assert_equal(str(review.get(field_name, "")), expected_value, message)
		return
	fail("%s" % message)

func _variant_to_vec2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i.ZERO

func assert_hand_layout(world: RefCounted, state_name: String, message: String) -> void:
	var universe := GloveLayouts.all_hand_cells()
	var expected_cells := GloveLayouts.hand_cells(state_name)
	var actual_map := {}
	for cell in universe:
		var entity = world.get_any_entity_at(cell)
		if entity != null and entity.text == "掌":
			actual_map[cell] = true
	var expected_map := {}
	for cell in expected_cells:
		expected_map[cell] = true
	assert_equal(actual_map.size(), expected_map.size(), "%s cell count" % message)
	for cell in expected_map.keys():
		assert_true(actual_map.has(cell), "%s missing %s" % [message, cell])
	for cell in actual_map.keys():
		assert_true(expected_map.has(cell), "%s unexpected %s" % [message, cell])

func assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		fail("%s: expected %s, got %s" % [message, expected, actual])

func assert_true(condition: bool, message: String) -> void:
	if not condition:
		fail(message)

func assert_any_text(world: RefCounted, pos: Vector2i, expected: String, message: String) -> void:
	var entity = world.get_any_entity_at(pos)
	assert_true(entity != null and entity.text == expected, message)

func count_entities_by_text(world: RefCounted, expected_text: String) -> int:
	var total := 0
	for entity in world.entities.values():
		if entity.text == expected_text:
			total += 1
	return total

func fail(message: String) -> void:
	failures.append(message)





