extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const HelmetTutorial = preload("res://levels/helmet/helmet_tutorial.gd")

var failures: Array[String] = []

func _init() -> void:
	test_tutorial_map_size_and_initial_state()
	test_intro_light_beam_grows_from_upper_right_to_lower_left()
	test_mirror_blocks_light_when_moved_onto_beam()
	test_pulled_out_mirror_does_not_reflect()
	test_mirror_reflects_down_right_when_left_of_light()
	test_mirror_reflects_up_left_when_below_light()
	test_magic_flow_triggers_helmet_acquisition_sequence()
	test_player_can_reach_and_push_mirror_without_passing_treasure_walls()
	test_he_splits_first_then_context_text_spawns_later()
	test_human_stacks_under_ye_and_restores_he()

	if failures.is_empty():
		print("helmet_tutorial tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func test_tutorial_map_size_and_initial_state() -> void:
	var level := HelmetTutorial.build_level()
	assert_equal(level.name, "四目头盔 教学", "tutorial level name is set")
	assert_equal(level.rows.size(), 18, "tutorial level has 18 rows")
	for i in range(level.rows.size()):
		assert_equal(str(level.rows[i]).length(), 32, "tutorial row %s has 32 columns" % i)

	var world := GridWorld.new()
	world.load_level(level)
	assert_equal(world.player_pos, Vector2i(23, 12), "player starts in the vault before the tutorial text appears")
	assert_equal(world.facing, Vector2i.DOWN, "player faces down toward the tutorial text")
	assert_true(world.player_input_locked, "player input is locked during the intro light animation")
	assert_any_text(world, Vector2i(14, 0), "石", "treasure vault background is present")
	assert_any_text(world, Vector2i(15, 0), "宝", "treasure vault top line is present")
	assert_any_text(world, Vector2i(15, 1), "头", "helmet label is present near the top opening")
	assert_any_text(world, Vector2i(16, 1), "盔", "helmet label second character is present")
	assert_color(world, Vector2i(14, 0), Color(0.0, 0.58, 0.62, 1.0), "vault 石 starts in the helmet blue")
	assert_color(world, Vector2i(15, 1), Color.WHITE, "helmet 头 stays white")
	assert_true(world.get_any_entity_at(HelmetTutorial.HE_POS) == null, "tutorial 他 is hidden during the intro")
	assert_true(world.has_pending_timed_effect(), "intro light beam starts automatically")
	assert_equal(world.pending_timed_delay, 0.2, "intro light beam advances slightly faster than normal walking speed")
	assert_vault_rows(level.rows)

func test_intro_light_beam_grows_from_upper_right_to_lower_left() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetTutorial.build_level())
	var light_path := [
		Vector2i(23, 4),
		Vector2i(22, 5),
		Vector2i(21, 6),
		Vector2i(20, 7),
		Vector2i(19, 8),
		Vector2i(18, 9),
		Vector2i(17, 10),
		Vector2i(16, 11),
		Vector2i(15, 12),
		Vector2i(14, 13),
		Vector2i(13, 14),
		Vector2i(12, 15)
	]
	for i in range(light_path.size()):
		var step := world.resolve_pending_timed_effect()
		assert_true(step.success, "light step %s resolves" % i)
		assert_any_text(world, light_path[i], "光", "light step %s appears at the expected cell" % i)
		assert_color(world, light_path[i], Color.WHITE, "light step %s stays white" % i)
		if i + 1 < light_path.size():
			assert_true(world.get_any_entity_at(light_path[i + 1]) == null or world.get_any_entity_at(light_path[i + 1]).text != "光", "next light cell is not visible early")
			assert_equal(world.pending_timed_delay, 0.2, "light continues at the tuned movement delay")
		else:
			assert_equal(world.pending_timed_delay, 2.0, "light pauses for two seconds at the final beam position")
	assert_true(world.player_input_locked, "player remains locked until the mirror reflection finishes")
	var description := world.resolve_pending_timed_effect()
	assert_true(description.success, "intro description appears after the light settles")
	assert_any_text(world, Vector2i(5, 14), "宝", "intro description first line appears")
	assert_any_text(world, Vector2i(5, 15), "像", "intro description second line appears")
	assert_any_text(world, Vector2i(13, 15), "镜", "reflection point is the 镜 character")
	assert_true(world.get_any_entity_at(Vector2i(12, 15)) == null or world.get_any_entity_at(Vector2i(12, 15)).text != "光", "light does not remain on the 射 character")
	assert_true(world.get_any_entity_at(Vector2i(13, 15)) == null or world.get_any_entity_at(Vector2i(13, 15)).text != "光", "light does not cover the 镜 character after the description appears")
	assert_true(world.get_any_entity_at(Vector2i(12, 13)) == null or world.get_any_entity_at(Vector2i(12, 13)).text != "光", "reflected light does not appear in the same frame as the description")
	assert_equal(world.pending_timed_delay, 0.2, "reflection starts after the same tuned delay")

	var first_reflection := world.resolve_pending_timed_effect()
	assert_true(first_reflection.success, "first reflected light step resolves")
	assert_any_text(world, Vector2i(12, 13), "光", "first reflected light appears above-left of 镜")
	assert_any_text(world, Vector2i(14, 13), "光", "first reflected light appears above-right of 镜")
	assert_equal(world.pending_timed_delay, 0.2, "reflection continues at the tuned movement delay")

	var reflection_steps := [
		[Vector2i(11, 12), Vector2i(15, 12)]
	]
	for i in range(reflection_steps.size()):
		var reflection := world.resolve_pending_timed_effect()
		assert_true(reflection.success, "reflected light step %s resolves" % i)
		for pos in reflection_steps[i]:
			assert_any_text(world, pos, "光", "reflected light step %s appears at %s" % [i, pos])
		if i + 1 < reflection_steps.size():
			assert_equal(world.pending_timed_delay, 0.2, "reflected light keeps moving outward")
	assert_no_overlay(world, Vector2i(10, 11), "光", "reflected light stops before crossing into upper-left text")
	assert_no_overlay(world, Vector2i(9, 10), "光", "reflected light does not overwrite vault text")

	assert_equal(world.player_pos, Vector2i(23, 12), "player stays in the vault after the light intro")
	assert_true(not world.player_input_locked, "player input unlocks after the reflected light finishes")
	assert_true(world.get_any_entity_at(HelmetTutorial.HE_POS) == null or world.get_any_entity_at(HelmetTutorial.HE_POS).text != "他", "tutorial 他 does not appear after the light intro")
	assert_true(world.get_any_entity_at(Vector2i(6, 14)).text != "跟", "split tutorial text does not appear after the light intro")
	assert_true(world.get_any_entity_at(Vector2i(12, 15)) == null or world.get_any_entity_at(Vector2i(12, 15)).text != "光", "the final beam no longer remains on the 射 character")

func test_mirror_blocks_light_when_moved_onto_beam() -> void:
	var world := _load_intro_finished_world()
	var mirror := world.find_first_entity_by_text("镜")
	world.move_entity_to(mirror.id, Vector2i(14, 13))
	var refreshed := world.move_entity_by(mirror.id, Vector2i.ZERO)
	assert_true(refreshed.success, "moving 镜 onto the beam recalculates light")
	assert_has_overlay(world, Vector2i(15, 12), "光", "incoming beam before the mirror remains visible")
	assert_no_overlay(world, Vector2i(14, 13), "光", "mirror cell blocks the direct light")
	assert_no_overlay(world, Vector2i(13, 14), "光", "beam behind the mirror is removed")
	assert_no_solid_at(world, Vector2i(13, 14), "the 光 in 光泽 is hidden when no beam crosses it")
	assert_no_overlay(world, Vector2i(12, 15), "光", "blocked light no longer reaches 射")

func test_pulled_out_mirror_does_not_reflect() -> void:
	var world := _load_intro_finished_world()
	var mirror := world.find_first_entity_by_text("镜")
	world.move_entity_to(mirror.id, Vector2i(13, 16))
	var refreshed := world.move_entity_by(mirror.id, Vector2i.ZERO)
	assert_true(refreshed.success, "pulling 镜 out of the sentence recalculates light")
	assert_has_overlay(world, Vector2i(12, 15), "光", "direct light reaches and covers 射")
	assert_no_solid_at(world, Vector2i(12, 15), "射 is removed when direct light reaches it")
	assert_no_overlay(world, Vector2i(12, 13), "光", "pulled-out mirror no longer keeps the old reflected branch")
	assert_no_overlay(world, Vector2i(11, 12), "光", "old upper-left reflected light is removed")

func test_mirror_reflects_down_right_when_left_of_light() -> void:
	var world := _load_intro_finished_world()
	var mirror := world.find_first_entity_by_text("镜")
	world.move_entity_to(mirror.id, Vector2i(13, 13))
	var refreshed := world.move_entity_by(mirror.id, Vector2i.ZERO)
	assert_true(refreshed.success, "moving 镜 left of a light recalculates light")
	assert_has_overlay(world, Vector2i(14, 13), "光", "source light remains to the right of 镜")
	assert_has_overlay(world, Vector2i(15, 14), "光", "light reflects down-right from the mirror")
	assert_has_overlay(world, Vector2i(16, 15), "光", "down-right reflection reaches the second description line")
	assert_no_overlay(world, Vector2i(13, 14), "光", "direct beam after the mirror is cut off")
	assert_no_overlay(world, Vector2i(12, 15), "光", "direct beam no longer reaches the 射 cell after reflection")
	assert_no_overlay(world, Vector2i(17, 16), "光", "down-right reflection stops below the second description line")
	assert_no_solid_at(world, Vector2i(13, 14), "the 光 in 光泽 is not restored when the beam is redirected")
	assert_no_solid_at(world, Vector2i(15, 14), "不 is replaced instead of overlapping with 光")
	assert_no_solid_at(world, Vector2i(16, 15), "周 is replaced instead of overlapping with 光")
	assert_no_overlay(world, Vector2i(13, 14), "色", "mirror reflection no longer spawns unrelated 色 text")
	assert_no_overlay(world, Vector2i(19, 14), "光", "mirror reflection no longer spawns unrelated 光滑 text")
	assert_no_overlay(world, Vector2i(20, 15), "光", "mirror reflection no longer spawns unrelated 流光 text")

func test_mirror_reflects_up_left_when_below_light() -> void:
	var world := _load_intro_finished_world()
	var mirror := world.find_first_entity_by_text("镜")
	world.move_entity_to(mirror.id, Vector2i(15, 13))
	var refreshed := world.move_entity_by(mirror.id, Vector2i.ZERO)
	assert_true(refreshed.success, "moving 镜 below a light recalculates light")
	assert_has_overlay(world, Vector2i(15, 12), "光", "source light remains above 镜")
	assert_has_overlay(world, Vector2i(14, 11), "光", "light reflects up-left from the mirror")
	assert_no_overlay(world, Vector2i(14, 13), "光", "direct beam after the below mirror is cut off")
	assert_no_overlay(world, Vector2i(13, 14), "光", "光泽 does not keep a stray 光 when the beam redirects")
	assert_no_overlay(world, Vector2i(12, 15), "光", "反射 does not keep a stray 光 when the beam redirects")
	assert_no_overlay(world, Vector2i(13, 10), "光", "up-left reflection stops before replacing treasure")
	assert_no_overlay(world, Vector2i(16, 14), "光", "below-light reflection does not go down-right")
	assert_no_solid_at(world, Vector2i(14, 11), "upper reflected light replaces the original character")
	assert_no_overlay(world, Vector2i(13, 14), "色", "below-light reflection does not form the final sentence")

func test_magic_flow_triggers_helmet_acquisition_sequence() -> void:
	var world := _load_intro_finished_world()
	assert_color(world, Vector2i(14, 0), Color(0.0, 0.58, 0.62, 1.0), "vault starts blue before the magic text is formed")
	var mirror := world.find_first_entity_by_text("镜")
	world.move_entity_to(mirror.id, Vector2i(15, 11))
	var refreshed := world.move_entity_by(mirror.id, Vector2i.ZERO)
	assert_true(refreshed.success, "moving 镜 to the final reflection position recalculates light")
	assert_has_overlay(world, Vector2i(20, 15), "光", "final reflection forms 四周魔力流光")
	assert_color(world, Vector2i(14, 0), Color(0.0, 0.58, 0.62, 1.0), "vault stays blue after 四周魔力流光 is formed")
	assert_true(world.player_input_locked, "player input locks during the helmet acquisition sequence")
	assert_true(world.player_event_locked, "player events lock during the helmet acquisition sequence")
	assert_true(world.has_pending_timed_effect(), "helmet ring shake is scheduled")
	assert_equal(world.pending_timed_delay, 0.25, "helmet ring waits briefly before shaking")

	var first_shake := world.resolve_pending_timed_effect()
	assert_true(first_shake.success, "helmet ring first shake resolves")
	assert_no_overlay(world, Vector2i(20, 15), "光", "final reflected light is removed before the helmet sequence")
	assert_true(world.get_any_entity_at(Vector2i(5, 14)) == null, "intro description is removed before the helmet sequence")
	assert_no_text_anywhere(world, "镜", "mirror is removed when the helmet sequence begins")
	assert_color(world, Vector2i(14, 0), Color(0.0, 0.58, 0.62, 1.0), "vault remains blue during the shake")
	assert_rotation(world, Vector2i(14, 0), 5.0, "helmet ring starts shaking")
	assert_true(world.get_any_entity_at(Vector2i(22, 5)) == null, "one of the first five beam cells remains open")
	assert_true(world.get_any_entity_at(Vector2i(21, 6)) == null, "another first-five beam cell remains open")
	assert_any_text(world, Vector2i(18, 9), "石", "later beam-covered stone is restored")
	assert_any_text(world, Vector2i(17, 10), "宝", "later beam-covered treasure is restored")

	for _i in range(3):
		var shake := world.resolve_pending_timed_effect()
		assert_true(shake.success, "helmet ring shake step resolves")
	assert_rotation(world, Vector2i(14, 0), 0.0, "helmet ring settles after shaking")

	var guard := 0
	while not _has_text_at(world, HelmetTutorial.HELMET_LANDED_POS, "头"):
		assert_true(world.has_pending_timed_effect(), "helmet keeps falling until it reaches the floor")
		var fall := world.resolve_pending_timed_effect()
		assert_true(fall.success, "helmet fall step resolves")
		guard += 1
		assert_true(guard < 30, "helmet lands within a bounded number of fall steps")
	assert_any_text(world, HelmetTutorial.HELMET_LANDED_POS, "头", "helmet 头 lands at the expected floor position")
	assert_any_text(world, HelmetTutorial.HELMET_LANDED_POS + Vector2i.RIGHT, "盔", "helmet 盔 lands beside 头")
	assert_color(world, Vector2i(14, 0), Color(0.0, 0.58, 0.62, 1.0), "vault still stays blue after the helmet lands")

	guard = 0
	while world.fullscreen_video_request.is_empty():
		assert_true(world.has_pending_timed_effect(), "player walks to the helmet before the video starts")
		var step := world.resolve_pending_timed_effect()
		assert_true(step.success, "automatic player step resolves")
		guard += 1
		assert_true(guard < 40, "helmet video request is reached within a bounded number of steps")
	assert_equal(world.player_pos, HelmetTutorial.EQUIP_PLAYER_POS, "player automatically walks to the left of 戴上")
	assert_any_text(world, HelmetTutorial.EQUIP_TEXT_POS, "戴", "戴 prompt appears two cells left of the helmet")
	assert_any_text(world, HelmetTutorial.EQUIP_TEXT_POS + Vector2i.RIGHT, "上", "上 prompt appears one cell left of the helmet")
	assert_equal(world.fullscreen_video_request.get("path", ""), "res://assets/video/u_helmet.ogv", "helmet acquisition video is requested")
	assert_true(world.has_fullscreen_video_finished_effect(), "helmet video has a configured finished effect")

	var video_finished := world.resolve_fullscreen_video_finished_effect()
	assert_true(video_finished.success, "helmet video finished effect resolves")
	assert_true(world.get_any_entity_at(HelmetTutorial.HELMET_LANDED_POS) == null, "helmet is removed after the full-screen video")
	assert_true(world.get_any_entity_at(HelmetTutorial.EQUIP_TEXT_POS) == null, "戴上 prompt is removed after the full-screen video")
	assert_equal(world.player_pos, HelmetTutorial.POST_HELMET_PLAYER_POS, "player becomes the 我 at the start of the post-helmet line")
	assert_any_text(world, HelmetTutorial.POST_HELMET_TEXT_POS, "戴", "post-helmet first page appears")
	assert_any_text(world, HelmetTutorial.POST_HELMET_PLAYER_POS + Vector2i.RIGHT, "在", "post-helmet second line continues after the player")
	assert_any_text(world, HelmetTutorial.POST_HELMET_POEM_POS, "诗", "诗 from 诗情画意 appears at the retained position")
	assert_any_text(world, HelmetTutorial.POST_HELMET_PLAYER_POS + Vector2i(22, 0), "▼", "post-helmet first page ends with a down triangle")
	assert_any_text(world, Vector2i(22, 5), "石", "post-helmet pages restore the first beam-opened stone")
	assert_any_text(world, Vector2i(21, 6), "石", "post-helmet pages restore the second beam-opened stone")
	assert_any_text(world, Vector2i(20, 7), "宝", "post-helmet pages restore the beam-opened treasure")
	var poem_id := world.get_any_entity_at(HelmetTutorial.POST_HELMET_POEM_POS).id

	var mentor_page := world.interact_front()
	assert_true(mentor_page.success, "space advances from the post-helmet page to the mentor page")
	assert_equal(world.player_pos, HelmetTutorial.MENTOR_PLAYER_POS, "player moves above the mentor line")
	assert_true(not world.player_visible, "mentor page does not show a stray player 我")
	assert_any_text(world, Vector2i(22, 5), "石", "mentor page keeps the first beam-opened stone restored")
	assert_any_text(world, Vector2i(21, 6), "石", "mentor page keeps the second beam-opened stone restored")
	assert_any_text(world, Vector2i(20, 7), "宝", "mentor page keeps the beam-opened treasure restored")
	assert_true(world.get_any_entity_at(HelmetTutorial.POST_HELMET_POEM_POS) != null and world.get_any_entity_at(HelmetTutorial.POST_HELMET_POEM_POS).id == poem_id, "诗 is retained in place instead of respawned")
	assert_any_text(world, HelmetTutorial.MENTOR_TEXT_POS, "「", "mentor page first line appears")
	assert_any_text(world, HelmetTutorial.POST_HELMET_POEM_POS + Vector2i.RIGHT, "人", "诗 is followed by 人皱着眉说")
	assert_any_text(world, HelmetTutorial.MENTOR_TEXT_POS + Vector2i(3, 1), "为", "mentor page keeps 为师")
	assert_any_text(world, HelmetTutorial.MENTOR_TEXT_POS + Vector2i(4, 1), "师", "mentor page keeps 师")
	assert_any_text(world, HelmetTutorial.MENTOR_TEXT_POS + Vector2i(22, 1), "▼", "mentor page ends with a down triangle")

	var watch_page := world.interact_front()
	assert_true(watch_page.success, "space advances from the mentor page to the watch-me page")
	assert_equal(world.player_pos, HelmetTutorial.WATCH_PLAYER_POS, "player controls the 我 in 你先看着我")
	assert_true(world.player_visible, "watch-me page shows the controllable sentence 我")
	assert_true(world.get_any_entity_at(HelmetTutorial.WATCH_PLAYER_POS) == null, "watch-me page does not spawn an extra text 我 under the player")
	assert_any_text(world, Vector2i(22, 5), "石", "watch-me page keeps the first beam-opened stone restored")
	assert_any_text(world, Vector2i(21, 6), "石", "watch-me page keeps the second beam-opened stone restored")
	assert_any_text(world, Vector2i(20, 7), "宝", "watch-me page keeps the beam-opened treasure restored")
	assert_any_text(world, HelmetTutorial.WATCH_TEXT_POS + Vector2i(1, 0), "这", "watch-me page first line appears")
	assert_any_text(world, HelmetTutorial.WATCH_HE_POS, "他", "watch-me page has an interactable 他")
	assert_no_text_at(world, HelmetTutorial.WATCH_TEXT_POS + Vector2i(21, 1), "▼", "watch-me page does not show a down triangle")

	world.player_pos = HelmetTutorial.WATCH_HE_POS + Vector2i.UP
	world.facing = Vector2i.DOWN
	var split_concept := world.interact_front()
	assert_true(split_concept.success, "facing 他 and pressing space opens the split concept page")
	assert_any_text(world, HelmetTutorial.SPLIT_CONCEPT_TEXT_POS, "「", "split concept first line appears")
	assert_any_text(world, HelmetTutorial.WATCH_HE_POS, "他", "split concept page keeps 他 in the same cell as the watch page")
	assert_any_text(world, HelmetTutorial.SPLIT_CONCEPT_TEXT_POS + Vector2i(3, 1), "分", "split concept line mentions 分裂")
	assert_any_text(world, HelmetTutorial.SPLIT_CONCEPT_TEXT_POS + Vector2i(17, 1), "▼", "split concept page ends with a down triangle")
	assert_any_text(world, Vector2i(22, 5), "石", "split concept page keeps the first beam-opened stone restored")
	assert_any_text(world, Vector2i(21, 6), "石", "split concept page keeps the second beam-opened stone restored")
	assert_any_text(world, Vector2i(20, 7), "宝", "split concept page keeps the beam-opened treasure restored")

	var tab_hint_page := world.interact_front()
	assert_true(tab_hint_page.success, "space advances from split concept to the TAB hint page")
	assert_any_text(world, HelmetTutorial.SPLIT_CONCEPT_TEXT_POS, "「", "TAB hint keeps the first tutorial line in the same position")
	assert_any_text(world, HelmetTutorial.SPLIT_CONCEPT_TEXT_POS + Vector2i(1, 1), "专", "TAB hint replaces only the second line with 专心看")
	assert_any_text(world, HelmetTutorial.SPLIT_CONCEPT_TEXT_POS + Vector2i(8, 1), "T", "TAB hint has T without comma")
	assert_any_text(world, HelmetTutorial.SPLIT_CONCEPT_TEXT_POS + Vector2i(9, 1), "A", "TAB hint has A immediately after T")
	assert_any_text(world, HelmetTutorial.SPLIT_CONCEPT_TEXT_POS + Vector2i(10, 1), "B", "TAB hint has B immediately after A")
	assert_no_text_at(world, HelmetTutorial.SPLIT_CONCEPT_TEXT_POS + Vector2i(9, 1), "，", "TAB hint has no comma between T and A")
	assert_no_text_at(world, HelmetTutorial.SPLIT_CONCEPT_TEXT_POS + Vector2i(10, 1), "，", "TAB hint has no comma between A and B")
	assert_any_text(world, Vector2i(22, 5), "石", "TAB hint keeps the first beam-opened stone restored")
	assert_any_text(world, Vector2i(21, 6), "石", "TAB hint keeps the second beam-opened stone restored")
	assert_any_text(world, Vector2i(20, 7), "宝", "TAB hint keeps the beam-opened treasure restored")

func test_player_can_reach_and_push_mirror_without_passing_treasure_walls() -> void:
	var world := _load_intro_finished_world()
	world.player_pos = Vector2i(13, 13)
	world.facing = Vector2i.DOWN
	var step_onto_text := world.try_move_player(Vector2i.DOWN)
	assert_true(not step_onto_text.success, "player cannot pass through solid intro description text")
	assert_equal(world.player_pos, Vector2i(13, 13), "player stays above the solid description text")
	world.player_pos = Vector2i(13, 16)
	world.facing = Vector2i.UP
	var pull_mirror := world.pull_front(Vector2i.DOWN)
	assert_true(pull_mirror.success, "player can pull 镜 out of the sentence")
	assert_any_text(world, Vector2i(13, 16), "镜", "镜 moves down into the player's old cell")
	assert_equal(world.player_pos, Vector2i(13, 17), "player steps down while pulling 镜")
	assert_no_overlay(world, Vector2i(12, 13), "光", "pulling 镜 immediately removes the old reflected branch")
	assert_has_overlay(world, Vector2i(12, 15), "光", "pulling 镜 immediately lets direct light reach 射")
	assert_no_solid_at(world, Vector2i(12, 15), "射 is replaced immediately after pulling 镜 away")
	world.player_pos = Vector2i(0, 10)
	world.facing = Vector2i.RIGHT
	var wall := world.try_move_player(Vector2i.RIGHT)
	assert_true(not wall.success, "treasure wall text remains solid")

func test_he_splits_first_then_context_text_spawns_later() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetTutorial.build_level())
	_finish_intro(world)
	var result := world.split_front()
	assert_true(result.success, "tab splits 他")
	assert_any_text(world, HelmetTutorial.HE_POS, "人", "人 appears where 他 was")
	assert_any_text(world, HelmetTutorial.HE_POS + Vector2i.DOWN, "也", "也 appears one row below 人")
	assert_no_text_at(world, HelmetTutorial.WATCH_TEXT_POS + Vector2i(23, 1), "呢", "stale watch-page tail is removed as soon as 他 splits")
	assert_no_text_at(world, HelmetTutorial.WATCH_TEXT_POS + Vector2i(24, 1), "？", "stale watch-page question mark is removed as soon as 他 splits")
	assert_no_text_at(world, HelmetTutorial.WATCH_TEXT_POS + Vector2i(25, 1), "」", "stale watch-page quote is removed as soon as 他 splits")
	assert_true(world.get_any_entity_at(Vector2i(6, 14)) == null, "context text is not spawned immediately")
	assert_true(world.has_pending_timed_effect(), "context text is scheduled")
	assert_equal(world.pending_timed_delay, 1.0, "context text waits one second")

	var timed := world.resolve_pending_timed_effect()
	assert_true(timed.success, "delayed context text resolves")
	assert_any_text(world, Vector2i(5, 14), "光", "flash first line appears after the delay")
	assert_any_text(world, Vector2i(23, 15), "▼", "flash page ends with a down triangle")
	assert_any_text(world, HelmetTutorial.HE_POS + Vector2i.DOWN, "也", "也 is embedded in the flash page")
	assert_any_text(world, HelmetTutorial.HE_POS, "人", "人 is embedded in the flash page")
	assert_true(world.get_any_entity_at(Vector2i(5, 13)) == null, "second page is not shown before pressing space")

	var advanced := world.interact_front()
	assert_true(advanced.success, "space advances from the flash page to the rebuild prompt")
	assert_any_text(world, Vector2i(5, 14), "看", "rebuild prompt appears after pressing space")
	assert_any_text(world, Vector2i(5, 15), "「", "rebuild prompt second line starts at the left")
	assert_true(world.get_any_entity_at(Vector2i(26, 15)) == null, "rebuild prompt does not end with a down triangle")
	assert_any_text(world, Vector2i(13, 15), "也", "也 is a playable character in the rebuild prompt")
	assert_any_text(world, Vector2i(22, 15), "人", "人 is a playable character in the rebuild prompt")
	assert_true(world.get_any_entity_at(Vector2i(15, 16)) == null, "push hint is not spawned on the pure prompt page")

func test_human_stacks_under_ye_and_restores_he() -> void:
	var world := _load_rebuild_prompt_world()
	world.player_pos = Vector2i(22, 14)
	world.facing = Vector2i.DOWN
	var push_down := world.try_move_player(Vector2i.DOWN)
	assert_true(push_down.success, "player can push 人 out of the sentence")
	assert_any_text(world, Vector2i(22, 16), "人", "人 moves to the open row below the prompt")

	world.player_pos = Vector2i(23, 16)
	world.facing = Vector2i.LEFT
	for _i in range(9):
		var push_left := world.try_move_player(Vector2i.LEFT)
		assert_true(push_left.success, "player can slide 人 left under 也")
	assert_any_text(world, Vector2i(13, 16), "人", "人 is stacked below 也")

	world.player_pos = Vector2i(14, 17)
	world.facing = Vector2i.LEFT
	var step_below := world.try_move_player(Vector2i.LEFT)
	assert_true(step_below.success, "player can stand below the stacked 人")
	assert_equal(world.player_pos, Vector2i(13, 17), "player stands below 人")
	assert_any_text(world, Vector2i(6, 17), "「", "push-up hint appears at the bottom")

	world.facing = Vector2i.UP
	var merge := world.try_move_player(Vector2i.UP)
	assert_true(merge.success, "pushing 人 upward merges 人 and 也")
	assert_any_text(world, Vector2i(13, 15), "他", "merged 他 first appears where 也 was")
	assert_true(not world.get_any_entity_at(Vector2i(13, 15)).pushable, "restored 他 is not pushable before moving up")
	assert_equal(world.player_pos, Vector2i(13, 16), "player remains below restored 他")
	assert_true(world.get_any_entity_at(Vector2i(5, 14)) == null, "final text is not spawned immediately")
	assert_true(world.has_pending_timed_effect(), "restored 他 is scheduled to move up")
	assert_equal(world.pending_timed_delay, 0.18, "restored 他 waits briefly before moving up")

	var move_up := world.resolve_pending_timed_effect()
	assert_true(move_up.success, "restored 他 moves up after the delay")
	assert_any_text(world, Vector2i(13, 14), "他", "restored 他 reaches the upper cell before final text appears")
	assert_true(not world.get_any_entity_at(Vector2i(13, 14)).pushable, "restored 他 is not pushable after moving up")
	assert_true(world.get_any_entity_at(Vector2i(5, 14)) == null, "final text is still hidden while 他 moves")
	assert_true(world.has_pending_timed_effect(), "final text is scheduled after 他 moves")
	assert_equal(world.pending_timed_delay, 0.22, "final text waits for the upward movement")

	var final_text := world.resolve_pending_timed_effect()
	assert_true(final_text.success, "final text appears after the delay")
	assert_any_text(world, Vector2i(5, 14), "「", "final line appears before 他")
	assert_any_text(world, Vector2i(14, 14), "恢", "final line continues after 他")
	assert_any_text(world, Vector2i(5, 15), "继", "continue prompt appears below the final line")
	assert_any_text(world, Vector2i(12, 15), "▼", "continue prompt ends with a down triangle")
	assert_true(world.get_any_entity_at(Vector2i(6, 16)) == null or world.get_any_entity_at(Vector2i(6, 16)).text != "我", "no stray lower-left 我 is spawned")

	var continue_pressed := world.interact_front()
	assert_true(continue_pressed.success, "space accepts the continue prompt")
	assert_true(world.has_pending_timed_effect(), "exit opening waits after space")
	assert_equal(world.pending_timed_delay, 1.0, "exit opens one second after space")
	world.resolve_pending_timed_effect()
	assert_true(world.get_any_entity_at(Vector2i(31, 14)) == null, "upper exit 宝 is removed")
	assert_true(world.get_any_entity_at(Vector2i(31, 15)) == null, "lower exit 宝 is removed")
	world.player_pos = Vector2i(31, 15)
	world.facing = Vector2i.RIGHT
	var exit := world.try_move_player(Vector2i.RIGHT)
	assert_equal(exit.get("transition", ""), "next_level", "walking through the right edge transitions to the first level")

func _load_rebuild_prompt_world() -> GridWorld:
	var world := GridWorld.new()
	world.load_level(HelmetTutorial.build_level())
	_finish_intro(world)
	world.split_front()
	world.resolve_pending_timed_effect()
	world.interact_front()
	return world

func _load_intro_finished_world() -> GridWorld:
	var world := GridWorld.new()
	world.load_level(HelmetTutorial.build_level())
	while world.has_pending_timed_effect():
		world.resolve_pending_timed_effect()
	return world

func _finish_intro(world: GridWorld) -> void:
	while world.has_pending_timed_effect():
		world.resolve_pending_timed_effect()
	world._apply_map_effect(HelmetTutorial._start_split_tutorial_effect())

func assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		fail("%s: expected %s, got %s" % [message, expected, actual])

func assert_true(condition: bool, message: String) -> void:
	if not condition:
		fail(message)

func assert_any_text(world, pos: Vector2i, expected: String, message: String) -> void:
	var entity = world.get_any_entity_at(pos)
	assert_true(entity != null and entity.text == expected, message)

func assert_has_overlay(world, pos: Vector2i, expected: String, message: String) -> void:
	for entity in world.entities.values():
		if entity.text == expected and not entity.solid and entity.cells.has(pos):
			return
	fail(message)

func assert_no_overlay(world, pos: Vector2i, expected: String, message: String) -> void:
	for entity in world.entities.values():
		if entity.text == expected and not entity.solid and entity.cells.has(pos):
			fail(message)
			return

func assert_no_text_anywhere(world, expected: String, message: String) -> void:
	for entity in world.entities.values():
		if entity.text == expected:
			fail(message)
			return

func assert_no_text_at(world, pos: Vector2i, expected: String, message: String) -> void:
	var entity = world.get_any_entity_at(pos)
	if entity != null and entity.text == expected:
		fail(message)

func assert_no_solid_at(world, pos: Vector2i, message: String) -> void:
	for entity in world.entities.values():
		if entity.solid and entity.cells.has(pos):
			fail("%s: found %s" % [message, entity.text])
			return

func assert_color(world, pos: Vector2i, expected: Color, message: String) -> void:
	var entity = world.get_any_entity_at(pos)
	assert_true(entity != null and entity.visual_color == expected, message)

func assert_rotation(world, pos: Vector2i, expected: float, message: String) -> void:
	var entity = world.get_any_entity_at(pos)
	assert_true(entity != null and is_equal_approx(entity.visual_rotation_degrees, expected), message)

func _has_text_at(world, pos: Vector2i, expected: String) -> bool:
	var entity = world.get_any_entity_at(pos)
	return entity != null and entity.text == expected

func assert_vault_rows(rows: Array) -> void:
	var expected := [
		"              石宝宝石              ",
		"           宝宝石宝头盔宝石宝宝           ",
		"        宝宝宝石石宝石宝宝石宝石石宝宝宝        ",
		"      宝宝宝石石石宝石石宝宝石石宝石石石 宝宝      ",
		"    宝宝石宝石石石石宝石石宝宝石石宝石石   石宝宝    ",
		"   宝石石宝石石石石宝石石石宝宝石石石宝石石 石宝石石宝   ",
		"  宝石石石宝石石石石宝石石石宝宝石石石宝石石石石宝石石石宝  ",
		"  宝石石宝石石石石石宝石石石宝宝石石石宝石石石石石宝石石宝  ",
		" 宝石石石宝石石石石宝石石石石宝宝石石石石宝石石石石宝石石石宝 ",
		" 宝石石宝石石石石石宝石石石石宝宝石石石石宝石石石石石宝石石宝 ",
		"宝石石石宝石石石石石宝宝宝宝宝宝宝宝宝宝宝宝石石石石石宝石石石宝",
		"宝石石石宝石宝宝宝宝宝          宝宝宝宝宝石宝石石石宝",
		"宝石石宝宝宝                    宝宝宝石石宝",
		"宝宝宝                          宝宝宝",
		"宝                              宝",
		"宝                              宝",
		" 宝宝                          宝宝 ",
		"   宝宝宝                    宝宝宝   "
	]
	for y in range(expected.size()):
		assert_equal(str(rows[y]), expected[y], "vault row %s matches source big_text" % y)

func fail(message: String) -> void:
	failures.append(message)
