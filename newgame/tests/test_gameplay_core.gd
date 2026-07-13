extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const MainSceneScript = preload("res://scripts/main.gd")
const GLOVE_PREVIEW_SCENE_PATH := "res://levels/glove/glove_preview.tscn"

var failures: Array[String] = []

func _init() -> void:
	test_player_state_model_api()
	test_movement_collision_and_page_shift()
	test_facing_gate_requires_target_in_front()
	test_interact_delete_push_pull()
	test_split_merge_and_sentence_rule()
	test_sentence_rules_support_vertical_matches_and_revert_state()
	test_sentence_rules_can_keep_state_after_match_breaks()
	test_sentence_match_starts_highlight_animation_state()
	test_highlight_visual_config_resource_is_present()
	test_main_scene_resolves_glove_startup_entry_arg()
	test_main_scene_resolves_glove_scene_shortcut()
	test_pull_direction_is_locked_to_player_side()
	test_push_into_merge_target_auto_merges()
	test_merged_word_splits_to_source_cells_and_moves_player()
	test_sentence_caption_is_map_collision_text()
	test_interaction_prompt_stays_as_map_collision_text()

	if failures.is_empty():
		print("gameplay_core tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func make_world() -> RefCounted:
	var world = GridWorld.new()
	world.load_level({
		"rows": [
			"墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙",
			"墙我 手表  石 墙          天 气很好        墙",
			"墙    删  戏  又 戈                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙"
		],
		"player_start": Vector2i(1, 1),
		"screen_size": Vector2i(32, 18),
		"entities": {
			"手表": {"interact_text": "手表可以查看人类世界的时间", "solid": true},
			"石": {"pushable": true, "solid": true},
			"删": {"deletable": true, "solid": true},
			"戏": {"splittable": true, "pushable": true, "solid": true},
			"又": {"pushable": true, "solid": true},
			"戈": {"pushable": true, "solid": true},
			"天": {"pushable": true, "solid": true},
			"气": {"solid": true},
			"很": {"solid": true},
			"好": {"solid": true}
		},
		"split_rules": {"戏": ["又", "戈"]},
		"merge_rules": {"又+戈": "戏", "戈+又": "戏"},
		"sentence_rules": {"天气": {"message": "已识别"}}
	})
	return world

func test_player_state_model_api() -> void:
	var world = make_world()
	assert_true(world.has_method("get_player_state"), "world exposes player state query")
	assert_true(world.has_method("set_input_locked"), "world exposes input lock setter")
	assert_true(world.has_method("set_event_locked"), "world exposes event lock setter")
	assert_true(world.has_method("set_player_move_cooldown"), "world exposes cooldown setter")
	assert_true(world.has_method("tick_player_state"), "world exposes player state tick")
	assert_true(world.has_method("set_player_abilities"), "world exposes ability setter")
	assert_true(world.has_method("player_has_ability"), "world exposes ability query")

	if not world.has_method("get_player_state"):
		return

	var initial_state: Dictionary = world.get_player_state()
	assert_equal(initial_state.get("grid_pos"), Vector2i(1, 1), "player state reports current grid position")
	assert_equal(initial_state.get("facing"), Vector2i(1, 0), "player state reports default facing")
	assert_false(initial_state.get("moving", true), "player starts idle")
	assert_equal(initial_state.get("move_cooldown"), 0, "player starts without cooldown")
	assert_false(initial_state.get("input_locked", true), "player starts without input lock")
	assert_false(initial_state.get("event_locked", true), "player starts without event lock")
	assert_equal(initial_state.get("abilities"), PackedStringArray(), "player starts with empty abilities")

	world.set_input_locked(true)
	var locked_move: Dictionary = world.try_move_player(Vector2i(1, 0))
	assert_false(locked_move.success, "input lock prevents movement")
	assert_equal(locked_move.get("message", ""), "input locked", "input lock returns explicit failure reason")
	assert_equal(world.player_pos, Vector2i(1, 1), "input lock keeps player in place")

	world.set_input_locked(false)
	world.set_event_locked(true)
	var event_locked_interact: Dictionary = world.interact_front()
	assert_false(event_locked_interact.success, "event lock prevents interaction")
	assert_equal(event_locked_interact.get("message", ""), "event locked", "event lock returns explicit failure reason")
	world.set_event_locked(false)

	world.set_player_move_cooldown(2)
	var cooldown_state: Dictionary = world.get_player_state()
	assert_equal(cooldown_state.get("move_cooldown"), 2, "cooldown setter updates player state")
	var cooldown_move: Dictionary = world.try_move_player(Vector2i(1, 0))
	assert_false(cooldown_move.success, "cooldown prevents movement")
	assert_equal(cooldown_move.get("message", ""), "cooldown", "cooldown returns explicit failure reason")
	world.tick_player_state()
	world.tick_player_state()
	assert_equal(world.get_player_state().get("move_cooldown"), 0, "tick consumes movement cooldown")
	assert_true(world.try_move_player(Vector2i(1, 0)).success, "movement resumes after cooldown expires")
	assert_false(world.get_player_state().get("moving", true), "movement flag settles back to idle after grid move completes")

	world.set_player_abilities(["delete", "split"])
	assert_true(world.player_has_ability("delete"), "ability query recognizes granted ability")
	assert_true(world.player_has_ability("split"), "ability query recognizes second granted ability")
	assert_false(world.player_has_ability("pull"), "ability query rejects missing ability")

func test_movement_collision_and_page_shift() -> void:
	var world = make_world()
	assert_equal(world.player_pos, Vector2i(1, 1), "player starts at configured grid position")
	assert_true(world.try_move_player(Vector2i(1, 0)).success, "player can move into empty grid cell")
	assert_equal(world.player_pos, Vector2i(2, 1), "player moved right")
	world.player_pos = Vector2i(1, 1)
	world.facing = Vector2i.RIGHT
	var turn_left = world.try_move_player(Vector2i(-1, 0))
	assert_true(turn_left.success, "first opposite direction input is accepted as a turn")
	assert_equal(world.facing, Vector2i.LEFT, "first opposite direction input updates facing")
	assert_equal(world.player_pos, Vector2i(1, 1), "first opposite direction input does not move into wall")
	assert_false(world.try_move_player(Vector2i(-1, 0)).success, "player cannot move into wall on the second same-direction input")

	world.player_pos = Vector2i(31, 1)
	world.facing = Vector2i.DOWN
	world.update_page()
	assert_equal(world.current_page_origin, Vector2i(0, 0), "page before crossing right edge")
	var turn_right = world.try_move_player(Vector2i(1, 0))
	assert_true(turn_right.success, "first right input at the page edge turns before moving")
	assert_equal(world.player_pos, Vector2i(31, 1), "turning at the page edge keeps the player in place")
	assert_true(world.try_move_player(Vector2i(1, 0)).success, "player can cross page boundary on the second same-direction input")
	assert_equal(world.current_page_origin, Vector2i(32, 0), "page shifts by one screen after crossing right edge")
	assert_no_overlap(world)

func test_facing_gate_requires_target_in_front() -> void:
	var interact_world = make_world()
	interact_world.player_pos = Vector2i(3, 1)
	interact_world.facing = Vector2i.DOWN
	var side_interact = interact_world.interact_front()
	assert_false(side_interact.success, "player cannot interact from the side of a target")
	assert_equal(side_interact.get("message", ""), "target not in front", "side interaction shares the same facing gate message")
	interact_world.facing = Vector2i.LEFT
	var back_interact = interact_world.interact_front()
	assert_false(back_interact.success, "player cannot interact from behind a target")
	assert_equal(back_interact.get("message", ""), "target not in front", "back interaction shares the same facing gate message")

	var delete_world = make_world()
	delete_world.player_pos = Vector2i(4, 2)
	delete_world.facing = Vector2i.DOWN
	var side_delete = delete_world.delete_front()
	assert_false(side_delete.success, "player cannot delete from the side of a target")
	assert_equal(side_delete.get("message", ""), "target not in front", "delete shares the same facing gate message")

	var split_world = make_world()
	split_world.player_pos = Vector2i(7, 2)
	split_world.facing = Vector2i.DOWN
	var side_split = split_world.split_front()
	assert_false(side_split.success, "player cannot split from the side of a target")
	assert_equal(side_split.get("message", ""), "target not in front", "split shares the same facing gate message")

	var pull_world = make_pull_fixture()
	pull_world.facing = Vector2i.RIGHT
	var side_pull = pull_world.pull_front(Vector2i.LEFT)
	assert_false(side_pull.success, "player cannot pull without facing the target")
	assert_equal(side_pull.get("message", ""), "target not in front", "pull shares the same facing gate message")

	var push_world = make_world()
	push_world.player_pos = Vector2i(6, 1)
	push_world.facing = Vector2i.DOWN
	var push_turn = push_world.try_move_player(Vector2i(1, 0))
	assert_true(push_turn.success, "push entry first accepts the turn")
	assert_equal(push_world.player_pos, Vector2i(6, 1), "first push-direction input only turns")
	assert_equal(push_world.get_entity_at(Vector2i(7, 1)).text, "石", "first push-direction input does not move the target")
	assert_true(push_world.try_move_player(Vector2i(1, 0)).success, "second push-direction input moves the target")
	assert_equal(push_world.player_pos, Vector2i(7, 1), "second push-direction input advances the player")

func test_interact_delete_push_pull() -> void:
	var world = make_world()
	world.player_pos = Vector2i(3, 1)
	world.facing = Vector2i(1, 0)
	assert_equal(world.interact_front().message, "手表可以查看人类世界的时间", "space interaction reports watch text")

	world.player_pos = Vector2i(4, 2)
	world.facing = Vector2i(1, 0)
	assert_true(world.delete_front().success, "backspace deletes deletable word")
	assert_equal(world.get_entity_at(Vector2i(5, 2)), null, "deleted word frees its grid cell")

	world.player_pos = Vector2i(6, 1)
	assert_true(world.try_move_player(Vector2i(1, 0)).success, "pushing stone succeeds")
	assert_equal(world.get_entity_at(Vector2i(8, 1)).text, "石", "stone moves one grid right")
	assert_equal(world.player_pos, Vector2i(7, 1), "player also advances when pushing")

	world.player_pos = Vector2i(9, 1)
	world.facing = Vector2i(-1, 0)
	assert_true(world.pull_front(Vector2i(1, 0)).success, "alt pull moves target toward player movement")
	assert_equal(world.get_entity_at(Vector2i(9, 1)).text, "石", "stone is pulled into player's old cell")
	assert_equal(world.player_pos, Vector2i(10, 1), "player moves while pulling")
	assert_no_overlap(world)

func test_split_merge_and_sentence_rule() -> void:
	var world = make_world()
	world.player_pos = Vector2i(7, 2)
	world.facing = Vector2i(1, 0)
	assert_true(world.split_front().success, "tab splits configured word")
	assert_equal(world.get_entity_at(Vector2i(8, 2)).text, "又", "split leaves first part in source cell")
	assert_equal(world.get_entity_at(Vector2i(9, 2)).text, "戈", "split places second part in facing cell")

	var merged = world.try_merge_entities(Vector2i(8, 2), Vector2i(9, 2))
	assert_true(merged.success, "configured parts merge")
	assert_equal(world.get_entity_at(Vector2i(9, 2)).text, "戏", "merged word appears at destination")

	var sky = world.find_first_entity_by_text("天")
	var air = world.find_first_entity_by_text("气")
	var sentence_start: Vector2i = air.grid_pos - Vector2i(1, 0)
	world.move_entity_to(sky.id, sentence_start)
	var result = world.check_sentence_rules()
	assert_true(result.has("天气"), "sentence rule recognizes word")
	assert_equal(result["天气"].message, "已识别", "sentence rule emits configured caption")
	assert_true(world.highlighted_cells.has(sentence_start), "sentence start cell highlighted")
	assert_true(world.highlighted_cells.has(air.grid_pos), "sentence second cell highlighted")

func test_sentence_rules_support_vertical_matches_and_revert_state() -> void:
	var world = GridWorld.new()
	world.load_level({
		"rows": [
			" A  ",
			" B  ",
			"    "
		],
		"sentence_rules": {
			"AB": {
				"direction": "vertical",
				"message": "vertical matched",
				"set_switches": {"gate_open": true},
				"set_variables": {"bridge_stage": 2}
			}
		}
	})
	assert_true(world.has_method("get_rule_state"), "world exposes rule state query")
	var matched = world.check_sentence_rules()
	assert_true(matched.has("AB"), "vertical sentence rule recognizes stacked text")
	assert_true(world.highlighted_cells.has(Vector2i(1, 0)), "vertical match highlights first cell")
	assert_true(world.highlighted_cells.has(Vector2i(1, 1)), "vertical match highlights second cell")
	if world.has_method("get_rule_state"):
		var state: Dictionary = world.get_rule_state()
		assert_equal(state.get("switches", {}).get("gate_open"), true, "matching rule enables configured switch")
		assert_equal(state.get("variables", {}).get("bridge_stage"), 2, "matching rule writes configured variable")
	var lower = world.get_entity_at(Vector2i(1, 1))
	assert_true(lower != null, "vertical fixture second word exists before breaking match")
	if lower:
		world.move_entity_to(lower.id, Vector2i(2, 1))
	var after_break = world.check_sentence_rules()
	assert_false(after_break.has("AB"), "vertical sentence rule no longer matches after text moves away")
	assert_false(world.highlighted_cells.has(Vector2i(1, 0)), "highlight clears after rule stops matching")
	if world.has_method("get_rule_state"):
		var cleared_state: Dictionary = world.get_rule_state()
		assert_false(cleared_state.get("switches", {}).has("gate_open"), "reverting rule clears configured switch")
		assert_false(cleared_state.get("variables", {}).has("bridge_stage"), "reverting rule clears configured variable")

func test_sentence_rules_can_keep_state_after_match_breaks() -> void:
	var world = GridWorld.new()
	world.load_level({
		"rows": [
			"AB ",
			"   "
		],
		"sentence_rules": {
			"AB": {
				"message": "sticky matched",
				"set_switches": {"sticky_gate": true},
				"set_variables": {"sticky_stage": 7},
				"persist_state_on_miss": true
			}
		}
	})
	assert_true(world.has_method("get_rule_state"), "world exposes rule state query for sticky rules")
	var matched = world.check_sentence_rules()
	assert_true(matched.has("AB"), "horizontal sentence rule matches control fixture")
	var second = world.get_entity_at(Vector2i(1, 0))
	assert_true(second != null, "sticky fixture second word exists before breaking match")
	if second:
		world.move_entity_to(second.id, Vector2i(2, 1))
	var after_break = world.check_sentence_rules()
	assert_false(after_break.has("AB"), "sticky rule also stops matching after text moves away")
	if world.has_method("get_rule_state"):
		var sticky_state: Dictionary = world.get_rule_state()
		assert_equal(sticky_state.get("switches", {}).get("sticky_gate"), true, "sticky rule keeps configured switch after match breaks")
		assert_equal(sticky_state.get("variables", {}).get("sticky_stage"), 7, "sticky rule keeps configured variable after match breaks")

func test_sentence_match_starts_highlight_animation_state() -> void:
	var world = make_world()
	assert_true(world.has_method("get_highlight_animation_strength"), "world exposes highlight animation strength query")
	assert_true(world.has_method("advance_highlight_animation"), "world exposes highlight animation tick")
	if not world.has_method("get_highlight_animation_strength") or not world.has_method("advance_highlight_animation"):
		return
	var sentence := String(world.sentence_rules.keys()[0])
	var first = world.find_first_entity_by_text(sentence.substr(0, 1))
	var second = world.find_first_entity_by_text(sentence.substr(1, 1))
	assert_true(first != null, "highlight animation fixture first word exists")
	assert_true(second != null, "highlight animation fixture second word exists")
	if first == null or second == null:
		return
	var sentence_start: Vector2i = second.grid_pos - Vector2i(1, 0)
	world.move_entity_to(first.id, sentence_start)
	world.check_sentence_rules()
	var start_strength := float(world.get_highlight_animation_strength(sentence_start))
	assert_true(start_strength > 0.9, "sentence match starts highlight animation near full strength")
	world.advance_highlight_animation(0.4)
	var mid_strength := float(world.get_highlight_animation_strength(sentence_start))
	assert_true(mid_strength > 0.0 and mid_strength < start_strength, "highlight animation strength decays over time")
	world.advance_highlight_animation(2.0)
	assert_equal(float(world.get_highlight_animation_strength(sentence_start)), 0.0, "highlight animation strength eventually returns to zero")

func test_highlight_visual_config_resource_is_present() -> void:
	var main_view = MainSceneScript.new()
	assert_true(FileAccess.file_exists("res://assets/animations/highlight/highlight_visual_config.json"), "highlight visual config resource exists")
	assert_true(main_view.has_method("load_highlight_visual_config"), "main scene exposes highlight visual config loader")
	if not main_view.has_method("load_highlight_visual_config"):
		main_view.queue_free()
		return
	var config: Dictionary = main_view.load_highlight_visual_config()
	assert_true(float(config.get("pulse_scale_max", 0.0)) > 1.0, "highlight config defines pulse scale above 1.0")
	assert_true(config.has("accent_color"), "highlight config defines accent color")
	assert_true(config.has("matched_color"), "highlight config defines matched color")
	main_view.queue_free()

func test_main_scene_resolves_glove_startup_entry_arg() -> void:
	var main_view = MainSceneScript.new()
	assert_true(main_view.has_method("resolve_startup_scene_path"), "main scene exposes startup scene-path parser")
	if not main_view.has_method("resolve_startup_scene_path"):
		main_view.queue_free()
		return
	assert_equal(
		str(main_view.resolve_startup_scene_path(PackedStringArray(["--entry=glove"]))),
		GLOVE_PREVIEW_SCENE_PATH,
		"main scene maps --entry=glove to the glove preview scene"
	)
	assert_equal(
		str(main_view.resolve_startup_scene_path(PackedStringArray(["--entry=helmet"]))),
		"",
		"main scene keeps the default helmet flow for unknown or default entry keys"
	)
	main_view.queue_free()

func test_main_scene_resolves_glove_scene_shortcut() -> void:
	var main_view = MainSceneScript.new()
	assert_true(main_view.has_method("resolve_scene_shortcut_from_keycode"), "main scene exposes scene shortcut resolver")
	if not main_view.has_method("resolve_scene_shortcut_from_keycode"):
		main_view.queue_free()
		return
	assert_equal(
		str(main_view.resolve_scene_shortcut_from_keycode(KEY_F9)),
		GLOVE_PREVIEW_SCENE_PATH,
		"main scene reserves F9 as the glove preview shortcut"
	)
	assert_equal(
		str(main_view.resolve_scene_shortcut_from_keycode(KEY_F5)),
		"",
		"existing demo hotkey remains unrelated to scene switching"
	)
	main_view.queue_free()

func test_pull_direction_is_locked_to_player_side() -> void:
	var sideways_world = make_pull_fixture()
	assert_false(sideways_world.pull_front(Vector2i(1, 0)).success, "alt pull rejects sideways movement")
	var toward_world = make_pull_fixture()
	assert_false(toward_world.pull_front(Vector2i(0, 1)).success, "alt pull rejects movement toward the pulled word")
	var valid_world = make_pull_fixture()
	assert_true(valid_world.pull_front(Vector2i(0, -1)).success, "alt pull allows moving away from the pulled word")
	assert_equal(valid_world.get_entity_at(Vector2i(7, 3)).text, "石", "pulled word moves into player's old cell")
	assert_equal(valid_world.player_pos, Vector2i(7, 2), "player moves away while pulling")

func make_pull_fixture() -> RefCounted:
	var world = make_world()
	world.player_pos = Vector2i(7, 3)
	world.facing = Vector2i(0, 1)
	var stone = world.find_first_entity_by_text("石")
	world.move_entity_to(stone.id, Vector2i(7, 4))
	return world

func test_push_into_merge_target_auto_merges() -> void:
	var world = make_world()
	var part_left = world.find_first_entity_by_text("又")
	var part_right = world.find_first_entity_by_text("戈")
	world.move_entity_to(part_left.id, Vector2i(8, 4))
	world.move_entity_to(part_right.id, Vector2i(9, 4))
	world.player_pos = Vector2i(7, 4)
	var pushed = world.try_move_player(Vector2i(1, 0))
	assert_true(pushed.success, "pushing a mergeable part into another part succeeds")
	assert_equal(world.get_entity_at(Vector2i(9, 4)).text, "戏", "pushed parts automatically merge at target cell")
	assert_equal(world.player_pos, Vector2i(8, 4), "player moves into pushed word's old cell")
	assert_equal(world.get_entity_at(Vector2i(8, 4)), null, "source part cell is freed after merge")

func test_merged_word_splits_to_source_cells_and_moves_player() -> void:
	var world = GridWorld.new()
	world.split_rules = {"戏": ["又", "戈"]}
	world.merge_rules = {"戈+又": "戏"}
	world.add_entity("又", Vector2i(8, 4), {"solid": true, "pushable": true})
	world.add_entity("戈", Vector2i(9, 4), {"solid": true, "pushable": true})
	var merged = world.try_merge_entities(Vector2i(9, 4), Vector2i(8, 4))
	assert_true(merged.success, "merge records original source cells")
	assert_equal(world.get_entity_at(Vector2i(8, 4)).text, "戏", "merged word appears at merge destination")
	world.player_pos = Vector2i(9, 4)
	world.facing = Vector2i.LEFT
	var split = world.split_front()
	assert_true(split.success, "merged word splits back to remembered cells")
	assert_equal(world.player_pos, Vector2i(10, 4), "player is pushed out of the returning second part cell")
	assert_equal(world.get_entity_at(Vector2i(8, 4)).text, "又", "first part returns to original cell")
	assert_equal(world.get_entity_at(Vector2i(9, 4)).text, "戈", "second part returns to original cell")

func test_sentence_caption_is_map_collision_text() -> void:
	var world = make_world()
	var sky = world.find_first_entity_by_text("天")
	var air = world.find_first_entity_by_text("气")
	var sentence_start: Vector2i = air.grid_pos - Vector2i(1, 0)
	world.move_entity_to(sky.id, sentence_start)
	world.check_sentence_rules()
	var caption = world.find_first_entity_by_text("已识别")
	assert_true(caption != null, "recognized caption becomes a word entity")
	if caption:
		assert_true(caption.solid, "recognized caption has collision")
		world.player_pos = caption.grid_pos - Vector2i(1, 0)
		assert_false(world.try_move_player(Vector2i(1, 0)).success, "player cannot walk through recognized caption")

func test_interaction_prompt_stays_as_map_collision_text() -> void:
	var world = make_world()
	world.player_pos = Vector2i(3, 1)
	world.facing = Vector2i(1, 0)
	var result = world.interact_front()
	assert_true(result.success, "watch interaction succeeds")
	var prompt = world.find_first_entity_by_text("手表可以查看人类世界的时间")
	assert_true(prompt != null, "interaction prompt becomes a word entity")
	if prompt:
		var prompt_id = prompt.id
		assert_true(prompt.solid, "interaction prompt has collision")
		world.player_pos = prompt.grid_pos - Vector2i(1, 0)
		assert_false(world.try_move_player(Vector2i(1, 0)).success, "player cannot walk through interaction prompt")
		world.interact_front()
		assert_equal(world.find_first_entity_by_text("手表可以查看人类世界的时间").id, prompt_id, "same prompt is not respawned or replaced")

func assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s but got %s" % [label, expected, actual])

func assert_true(actual: bool, label: String) -> void:
	if not actual:
		failures.append("%s expected true but got false" % label)

func assert_false(actual: bool, label: String) -> void:
	if actual:
		failures.append("%s expected false but got true" % label)

func assert_no_overlap(world: RefCounted) -> void:
	for entity in world.entities.values():
		if entity.grid_pos == world.player_pos:
			failures.append("player overlaps word %s at %s" % [entity.text, entity.grid_pos])
