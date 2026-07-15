extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const PrincessCage = preload("res://levels/princess/princess_cage.gd")
const PrincessRescueTransition = preload("res://levels/princess/princess_rescue_transition.gd")

func _init() -> void:
	var failures: Array[String] = []
	var world := GridWorld.new()
	world.load_level(PrincessCage.build_level())
	if world.player_pos != PrincessCage.ENTRY_POS:
		failures.append("princess scene starts from the lower-left corner")
	_assert_char(world, Vector2i(15, 3), "公", "princess cage contains 公", failures)
	_assert_char(world, Vector2i(16, 3), "主", "princess cage contains 主", failures)
	for line_index in range(PrincessCage.DESCRIPTION_LINES.size()):
		_assert_text(world, PrincessCage.DESCRIPTION_POS + Vector2i(0, line_index), PrincessCage.DESCRIPTION_LINES[line_index], "princess scene shows its description", failures)
	var initial_ball = world.get_any_entity_at(PrincessCage.BALL_POS)
	if initial_ball == null or initial_ball.splittable:
		failures.append("球 cannot split before the other description text disappears")
	world.player_pos = PrincessCage.NOT_POS + Vector2i.LEFT
	world.facing = Vector2i.RIGHT
	world.delete_front()
	if not world.player_input_locked or not world.has_pending_timed_effect():
		failures.append("deleting 不 starts the one-second description change")
	world.resolve_pending_timed_effect()
	_assert_word_config(world, PrincessCage.BALL_POS + Vector2i(-1, -1), "球", true, "球 moves upper-left and remains pushable", failures)
	_assert_word_config(world, PrincessCage.AWAKE_POS + Vector2i(1, -1), "醒", true, "醒 moves upper-right and remains pushable", failures)
	_assert_word_config(world, PrincessCage.HUAN_POS + Vector2i.LEFT, "涣", true, "涣 moves left and remains pushable", failures)
	_assert_word_config(world, PrincessCage.PRINCESS_WORD_POS, "公", false, "公 stays fixed", failures)
	_assert_word_config(world, PrincessCage.PRINCESS_WORD_POS + Vector2i.RIGHT, "主", false, "主 stays fixed", failures)
	_assert_word_config(world, PrincessCage.KOU_POS + Vector2i.RIGHT, "扣", true, "扣 moves right and remains pushable", failures)
	_assert_word_config(world, PrincessCage.GU_POS + Vector2i.DOWN, "故", true, "故 moves away and remains pushable", failures)
	for split_word in ["球", "醒", "涣", "扣", "故"]:
		if not world.split_rules.has(split_word):
			failures.append("%s has its required split rule" % split_word)
	var moved_ball = world.get_any_entity_at(PrincessCage.BALL_POS + Vector2i(-1, -1))
	if moved_ball == null or not moved_ball.splittable:
		failures.append("球 can split only after the other description text disappears")
	if world.split_rules.get("星", []) != ["生", "日"]:
		failures.append("星 splits into 生 and 日")
	world.player_pos = PrincessCage.BALL_POS + Vector2i(-2, -1)
	world.facing = Vector2i.RIGHT
	world.split_front()
	_assert_char(world, PrincessCage.BALL_POS + Vector2i(-1, -1), "王", "球 splits into 王", failures)
	_assert_char(world, PrincessCage.BALL_POS + Vector2i(0, -1), "求", "球 splits into 求", failures)
	var ball_merge := world.try_merge_entities(PrincessCage.BALL_POS + Vector2i(-1, -1), PrincessCage.BALL_POS + Vector2i(0, -1))
	if not ball_merge.success:
		failures.append("王 and 求 merge back into 球")
	else:
		var merged_ball = world.get_any_entity_at(PrincessCage.BALL_POS + Vector2i(0, -1))
		if merged_ball == null or merged_ball.text != "球" or not merged_ball.splittable:
			failures.append("merged 球 remains available for another split")
		else:
			world.move_entity_to(merged_ball.id, Vector2i(6, 6))
			world.player_pos = Vector2i(5, 6)
			world.facing = Vector2i.RIGHT
			world.split_front()
			_assert_char(world, Vector2i(6, 6), "王", "merged 球 splits from its current position", failures)
			_assert_char(world, Vector2i(7, 6), "求", "merged 球 splits forward from its current position", failures)
	var extra_rules := {
		"口+奂": "唤", "手+奂": "换", "求+夂": "救", "水+酉": "酒"
	}
	for merge_key in extra_rules:
		if world.merge_rules.get(merge_key, "") != extra_rules[merge_key]:
			failures.append("%s merge rule is present" % merge_key)
	var reverse_splits := {
		"唤": ["口", "奂"], "换": ["手", "奂"], "救": ["求", "夂"], "酒": ["水", "酉"]
	}
	for merged_word in reverse_splits:
		if world.split_rules.get(merged_word, []) != reverse_splits[merged_word]:
			failures.append("%s can split back into its source characters" % merged_word)
	if world.get_any_entity_at(PrincessCage.DESCRIPTION_POS) != null:
		failures.append("non-preserved description text disappears after deleting 不")
	_test_special_sentences(failures)
	_test_rescue_transition(failures)
	if failures.is_empty():
		print("princess cage tests passed")
		quit(0)
	for failure in failures:
		push_error(failure)
	quit(1)

func _assert_char(world, pos: Vector2i, expected: String, message: String, failures: Array[String]) -> void:
	var entity = world.get_any_entity_at(pos)
	if entity == null or entity.text != expected:
		failures.append(message)

func _assert_text(world, start: Vector2i, text: String, message: String, failures: Array[String]) -> void:
	for index in range(text.length()):
		_assert_char(world, start + Vector2i(index, 0), text.substr(index, 1), message, failures)

func _assert_word_config(world, pos: Vector2i, text: String, pushable: bool, message: String, failures: Array[String]) -> void:
	var entity = world.get_any_entity_at(pos)
	if entity == null or entity.text != text or entity.pushable != pushable:
		failures.append(message)

func _test_special_sentences(failures: Array[String]) -> void:
	var rescue_world := _make_sentence_world("救公主", "before")
	rescue_world.check_sentence_rules()
	_assert_char(rescue_world, PrincessCage.PRINCESS_ESCAPE_POS, "公", "救公主 moves the caged princess outside", failures)
	_assert_char(rescue_world, PrincessCage.PRINCESS_ESCAPE_POS + Vector2i.RIGHT, "主", "救公主 moves both princess characters outside", failures)
	if rescue_world.get_any_entity_at(Vector2i(15, 3)) != null or rescue_world.get_any_entity_at(Vector2i(16, 3)) != null:
		failures.append("救公主 clears the princess from inside the cage")

	_test_caption_sentence("唤公主", "我尝试唤醒公主，但公主没有反应", "before", PrincessCage.CAPTION_BOTTOM_POS, failures)
	_test_caption_sentence("唤醒公主", "公主醒了过来，满怀希望地看着你", "before", PrincessCage.CAPTION_BOTTOM_POS, failures)
	_test_quote_caption_sentence("公主唤", "「勇者，救我！」", "after", failures)
	_test_quote_caption_sentence("公主唤醒", "「醒醒！别做梦了」", "after", failures)
	_test_quote_caption_sentence("公主救", "「你认真的吗？」", "after", failures)
	_test_quote_caption_sentence("公主生日", "「谢谢你来给我过生日」", "none", failures)
	_test_quote_caption_sentence("生日", "「祝你生日快乐~」", "before", failures)
	_test_quote_caption_sentence("求公主", "「求我也解决不了任何问题」", "before", failures)
	_test_quote_caption_sentence("公主求", "「求你一定要想办法放我出去」", "after", failures)
	_test_princess_swap_failure("换公主", "before", failures)
	_test_princess_swap_failure("公主换", "after", failures)

func _test_rescue_transition(failures: Array[String]) -> void:
	var rescue_world := _make_sentence_world("救公主", "before")
	rescue_world.check_sentence_rules()
	if not rescue_world.has_pending_timed_effect() or not rescue_world.player_input_locked:
		failures.append("救公主 pauses for one second after the princess leaves the cage")
	_assert_char(rescue_world, PrincessCage.PRINCESS_ESCAPE_POS, "公", "救公主 first moves the princess outside the cage", failures)
	if rescue_world.find_first_entity_by_text("救") == null:
		failures.append("救公主 keeps the surrounding words during the one-second pause")
	rescue_world.resolve_pending_timed_effect()
	if rescue_world.player_input_locked:
		failures.append("救公主 unlocks the player after clearing the other words")
	for entity in rescue_world.entities.values():
		if entity.text not in ["笼", "公", "主"]:
			failures.append("救公主 clears every word except the cage and green princess")
			break
	rescue_world.player_pos = PrincessCage.PRINCESS_ESCAPE_POS + Vector2i.LEFT
	rescue_world.facing = Vector2i.RIGHT
	var interaction: Dictionary = rescue_world.interact_front()
	var visual_requests: Array = rescue_world.consume_visual_effects()
	if not interaction.success or visual_requests.is_empty() or visual_requests[0].get("type", "") != "black_screen_transition":
		failures.append("interacting with the green princess requests the black-screen transition")
	elif int(visual_requests[0].get("target_level_index", -1)) != 3:
		failures.append("the rescued princess targets the post-rescue scene")
	var transition_world := GridWorld.new()
	transition_world.load_level(PrincessRescueTransition.build_level())
	if transition_world.player_visible:
		failures.append("post-rescue scene hides the player")
	if transition_world.entities.size() < 10:
		failures.append("post-rescue scene builds the coloured character layout")
	_assert_char(transition_world, Vector2i(22, 1), "框", "post-rescue scene keeps the top cage row", failures)
	_assert_char(transition_world, Vector2i(15, 6), "花", "post-rescue scene keeps the flower at the figure top", failures)
	_assert_char(transition_world, Vector2i(15, 10), "公", "post-rescue scene keeps the princess character in the figure", failures)
	_assert_char(transition_world, Vector2i(16, 11), "鼻", "post-rescue scene keeps the central face detail", failures)
	_assert_char(transition_world, Vector2i(12, 16), "制", "post-rescue scene keeps the bottom clothing row", failures)

func _test_princess_swap_failure(sentence: String, player_position: String, failures: Array[String]) -> void:
	var world := _make_sentence_world(sentence, player_position)
	var player_origin: Vector2i = world.player_pos
	world.check_sentence_rules()
	if world.player_pos != PrincessCage.CAGE_PLAYER_POS:
		failures.append("%s moves the player inside the cage" % sentence)
	if not world.player_input_locked or not world.has_pending_timed_effect():
		failures.append("%s locks the scene before the failure ending" % sentence)
	var expected_first := "主" if sentence == "换公主" else "公"
	var expected_second := "公" if sentence == "换公主" else "主"
	var second_offset := Vector2i.LEFT if sentence == "换公主" else Vector2i.RIGHT
	var escaped_first = world.get_any_entity_at(player_origin)
	var escaped_second = world.get_any_entity_at(player_origin + second_offset)
	if escaped_first == null or escaped_first.text != expected_first or escaped_first.visual_color != PrincessCage.PRINCESS_COLOR:
		failures.append("%s puts the correct first princess character at the player's old position" % sentence)
	if escaped_second == null or escaped_second.text != expected_second or escaped_second.visual_color != PrincessCage.PRINCESS_COLOR:
		failures.append("%s puts the second princess character beside the player position" % sentence)
	world.resolve_pending_timed_effect()
	if world.find_first_entity_by_text("换") != null:
		failures.append("%s clears the sentence characters after one second" % sentence)
	if world.find_first_entity_by_text(PrincessCage.FAILURE_TEXT) != null:
		failures.append("%s waits one more second before showing the ending" % sentence)
	if not world.has_pending_timed_effect():
		failures.append("%s schedules the ending text after the clear" % sentence)
	world.resolve_pending_timed_effect()
	var ending = world.find_first_entity_by_text(PrincessCage.FAILURE_TEXT)
	if ending == null or ending.grid_pos != PrincessCage.FAILURE_TEXT_POS:
		failures.append("%s shows the cage ending in the screen center" % sentence)
	if world.get_any_entity_at(player_origin) == null or world.get_any_entity_at(player_origin).text != expected_first:
		failures.append("%s keeps the green princess after clearing the scene" % sentence)
	world.interact_front()
	if world.player_pos != PrincessCage.ENTRY_POS:
		failures.append("%s resets the princess scene from its new start position on Space" % sentence)

func _test_quote_caption_sentence(sentence: String, caption: String, player_position: String, failures: Array[String]) -> void:
	_test_caption_sentence(sentence, caption, player_position, PrincessCage.quote_caption_pos(caption), failures)

func _make_sentence_world(sentence: String, player_position: String) -> RefCounted:
	var world := GridWorld.new()
	world.load_level(PrincessCage.build_level())
	var origin := Vector2i(4, 8)
	for index in range(sentence.length()):
		world.add_entity(sentence.substr(index, 1), origin + Vector2i(index, 0), {"solid": true, "pushable": true})
	if player_position == "after":
		world.player_pos = origin + Vector2i(sentence.length(), 0)
		world.facing = Vector2i.LEFT
	elif player_position == "before":
		world.player_pos = origin + Vector2i.LEFT
		world.facing = Vector2i.RIGHT
	return world

func _test_caption_sentence(sentence: String, caption: String, player_position: String, caption_pos: Vector2i, failures: Array[String]) -> void:
	var world := _make_sentence_world(sentence, player_position)
	world.check_sentence_rules()
	var caption_entity = world.find_first_entity_by_text(caption)
	if caption_entity == null:
		failures.append("%s shows its upper-right caption" % sentence)
		return
	if caption_entity.grid_pos != caption_pos:
		failures.append("%s caption appears in its configured corner" % sentence)
	var first = world.get_any_entity_at(Vector2i(4, 8))
	if first:
		world.move_entity_to(first.id, Vector2i(4, 9))
	world.check_sentence_rules()
	if world.find_first_entity_by_text(caption) != null:
		failures.append("%s caption disappears after the sentence breaks" % sentence)
