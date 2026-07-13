extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const HelmetR1 = preload("res://levels/helmet/helmet_r1.gd")
const HelmetR2 = preload("res://levels/helmet/helmet_r2.gd")

var failures: Array[String] = []

func _init() -> void:
	test_r1_is_still_available()
	test_r2_map_size_and_initial_text()
	test_r2_bridge_and_distance_merge()

	if failures.is_empty():
		print("helmet_r2 tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func test_r1_is_still_available() -> void:
	var r1 := HelmetR1.build_level()
	assert_equal(r1.name, "四目头盔 过河第一关", "first level is still preserved")
	assert_equal(r1.player_start, Vector2i(6, 4), "first level player start is unchanged")

func test_r2_map_size_and_initial_text() -> void:
	var level := HelmetR2.build_level()
	assert_equal(level.name, "四目头盔 过河第二关", "second level name is set")
	assert_equal(level.rows.size(), 18, "helmet r2 has 18 rows")
	for i in range(level.rows.size()):
		assert_equal(str(level.rows[i]).length(), 32, "helmet r2 row %s has 32 columns" % i)

	var world := GridWorld.new()
	world.load_level(level)
	assert_equal(world.player_pos, Vector2i(6, 4), "second level starts before 感觉")
	assert_any_text(world, Vector2i(14, 3), "乔", "initial sentence contains 乔")
	assert_any_text(world, Vector2i(15, 3), "木", "initial sentence contains 木")
	assert_true(world.get_any_entity_at(Vector2i(6, 4)) == null, "player cell is left empty in the text map")

func test_r2_bridge_and_distance_merge() -> void:
	var world := GridWorld.new()
	world.load_level(HelmetR2.build_level())

	var bridge_result := world.try_merge_entities(Vector2i(15, 3), Vector2i(14, 3))
	assert_true(bridge_result.success, "乔木 merges into bridge in r2")
	assert_any_text(world, Vector2i(14, 3), "桥", "sentence bridge appears")
	assert_any_text(world, Vector2i(18, 8), "桥", "unusable bridge upper rail appears offset left")
	assert_any_text(world, Vector2i(22, 7), "溪", "unusable bridge keeps upper creek cells outside the post")
	assert_any_text(world, Vector2i(23, 7), "溪", "unusable bridge keeps upper creek cells beside the post")
	assert_true(world.get_any_entity_at(Vector2i(21, 9)) == null, "unusable bridge clears only the near side")
	assert_any_text(world, Vector2i(24, 9), "溪", "unusable bridge still leaves creek blocking the far side")
	assert_any_text(world, Vector2i(24, 11), "桥", "unusable bridge post occupies the lower creek edge")
	assert_any_text(world, Vector2i(25, 11), "溪", "unusable bridge keeps lower creek cells outside the post")
	assert_any_text(world, Vector2i(18, 10), "桥", "unusable bridge lower rail appears offset left")
	assert_true(world.get_any_entity_at(Vector2i(8, 7)) == null, "distance text is hidden before bridge interaction")

	world.player_pos = Vector2i(16, 8)
	world.facing = Vector2i.RIGHT
	var interact_result := world.interact_front()
	assert_true(interact_result.success, "interacting with unusable bridge shows distance text")
	assert_any_text(world, Vector2i(17, 8), "桥", "bridge left half remains after interaction text appears")
	assert_any_text(world, Vector2i(21, 8), "桥", "bridge over creek remains after interaction text appears")
	assert_any_text(world, Vector2i(21, 6), "溪", "creek column above the bridge is not erased by text refresh")
	assert_any_text(world, Vector2i(8, 7), "一", "distance sentence contains 一")
	assert_any_text(world, Vector2i(8, 8), "二", "distance sentence contains 二")
	assert_any_text(world, Vector2i(9, 8), "十", "distance sentence contains 十")
	assert_true(world.get_any_entity_at(Vector2i(2, 12)) == null, "bridge interaction does not show creek hint first line")
	assert_true(world.get_any_entity_at(Vector2i(2, 13)) == null, "bridge interaction does not show creek hint second line")
	assert_true(world.get_any_entity_at(Vector2i(2, 6)).solid, "distance hint text blocks movement")
	world.player_pos = Vector2i(1, 6)
	world.facing = Vector2i.RIGHT
	var blocked_by_hint := world.try_move_player(Vector2i.RIGHT)
	assert_true(not blocked_by_hint.success, "player cannot walk through distance hint text")

	world.player_pos = Vector2i(20, 12)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "creek interaction shows creek hint after bridge hint")
	assert_any_text(world, Vector2i(2, 12), "无", "creek hint appears at its reserved first line")
	assert_any_text(world, Vector2i(2, 13), "必", "creek hint appears at its reserved second line")
	assert_true(world.get_any_entity_at(Vector2i(2, 14)) == null, "creek hint does not duplicate into extra rows")

	world.player_pos = Vector2i(8, 9)
	world.facing = Vector2i.UP
	var push_result := world.try_move_player(Vector2i.UP)
	assert_true(push_result.success, "pushing 二 upward into 一 solves distance")
	assert_any_text(world, Vector2i(8, 7), "三", "一 and 二 merge into 三")
	assert_true(world.get_any_entity_at(Vector2i(8, 8)) == null, "二 position becomes a blank after distance is solved")
	assert_any_text(world, Vector2i(9, 8), "十", "十 keeps its original column after distance is solved")
	assert_true(world.get_any_entity_at(Vector2i(21, 9)) == null, "final bridge keeps a middle road")
	assert_any_text(world, Vector2i(22, 7), "溪", "final bridge restores upper creek above the bridge")
	assert_any_text(world, Vector2i(23, 7), "溪", "final bridge restores second upper creek above the bridge")
	assert_any_text(world, Vector2i(22, 11), "溪", "final bridge restores lower creek below the bridge")
	assert_any_text(world, Vector2i(23, 11), "溪", "final bridge restores second lower creek below the bridge")
	assert_any_text(world, Vector2i(21, 8), "桥", "final bridge upper rail reaches the first-level bridge position")
	assert_any_text(world, Vector2i(21, 10), "桥", "final bridge lower rail reaches the first-level bridge position")

	world.player_pos = Vector2i(15, 3)
	world.facing = Vector2i.LEFT
	var bridge_split := world.split_front()
	assert_true(bridge_split.success, "sentence bridge can split back after hint text appeared")
	assert_any_text(world, Vector2i(14, 3), "乔", "sentence 乔 returns after bridge split")
	assert_any_text(world, Vector2i(15, 3), "木", "sentence 木 returns after bridge split")
	assert_any_text(world, Vector2i(2, 6), "这", "bridge hint text remains after bridge split")
	assert_any_text(world, Vector2i(3, 6), "乔", "bridge hint splits to 乔 with the sentence bridge")
	assert_any_text(world, Vector2i(4, 6), "木", "bridge hint splits to 木 with the sentence bridge")
	assert_any_text(world, Vector2i(8, 7), "三", "distance result text remains after bridge split")
	assert_any_text(world, Vector2i(22, 7), "溪", "bridge split restores upper creek")
	assert_any_text(world, Vector2i(23, 7), "溪", "bridge split restores second upper creek")
	assert_any_text(world, Vector2i(22, 11), "溪", "bridge split restores lower creek")
	assert_any_text(world, Vector2i(23, 11), "溪", "bridge split restores second lower creek")

	var bridge_remerge := world.try_merge_entities(Vector2i(15, 3), Vector2i(14, 3))
	assert_true(bridge_remerge.success, "sentence 乔木 can merge back after hint text appeared")
	assert_any_text(world, Vector2i(14, 3), "桥", "sentence bridge returns after remerge")
	assert_any_text(world, Vector2i(3, 6), "桥", "bridge hint merges back to 桥 with the sentence")
	assert_true(world.get_any_entity_at(Vector2i(4, 6)) == null, "bridge hint keeps the split 木 space empty after remerge")
	assert_any_text(world, Vector2i(5, 6), "肯", "bridge hint keeps following text in place after remerge")
	assert_any_text(world, Vector2i(21, 8), "桥", "remerged bridge stays at the solved crossing position")
	assert_true(world.get_any_entity_at(Vector2i(21, 9)) == null, "remerged solved bridge keeps the road open")
	assert_any_text(world, Vector2i(21, 10), "桥", "remerged bridge lower rail stays at the solved crossing position")
	assert_true(world.get_any_entity_at(Vector2i(24, 9)) == null, "remerged solved bridge opens the far-side road gap")

	world = GridWorld.new()
	world.load_level(HelmetR2.build_level())
	assert_true(world.try_merge_entities(Vector2i(15, 3), Vector2i(14, 3)).success, "second setup merges bridge")
	world.player_pos = Vector2i(16, 8)
	world.facing = Vector2i.RIGHT
	assert_true(world.interact_front().success, "second setup reveals hint text")
	world.player_pos = Vector2i(8, 9)
	world.facing = Vector2i.UP
	assert_true(world.try_move_player(Vector2i.UP).success, "second setup solves distance")
	var split_result := world.split_front()
	assert_true(split_result.success, "三 can split back into 一 and 二")
	assert_equal(world.player_pos, Vector2i(8, 9), "player standing on 二 position is pushed downward when 三 splits")
	assert_any_text(world, Vector2i(8, 7), "一", "一 returns after 三 splits")
	assert_any_text(world, Vector2i(8, 8), "二", "二 returns after 三 splits")
	assert_any_text(world, Vector2i(17, 8), "桥", "bridge returns to the unusable offset after 三 splits")
	assert_any_text(world, Vector2i(24, 9), "溪", "far-side creek is restored after 三 splits")

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
