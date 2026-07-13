extends SceneTree

const GloveLevel = preload("res://levels/glove/glove_level.gd")
const GridWorld = preload("res://scripts/grid_world.gd")
const GloveLayouts = preload("res://scripts/levels/glove/glove_layouts.gd")

func _init() -> void:
	var boundary_world := GridWorld.new()
	boundary_world.load_level(GloveLevel.build_level())
	boundary_world.player_pos = Vector2i(0, 0)
	boundary_world.facing = Vector2i.LEFT
	var boundary_failures: Array[String] = []
	if boundary_world.try_move_player(Vector2i.LEFT).get("success", false):
		boundary_failures.append("glove player cannot walk past the left map boundary")
	boundary_world.player_pos = Vector2i(30, 5)
	boundary_world.facing = Vector2i.RIGHT
	boundary_world.add_entity("二", Vector2i(31, 5), {"solid": true, "pushable": true})
	if boundary_world.try_move_player(Vector2i.RIGHT).get("success", false):
		boundary_failures.append("glove player cannot push a movable word past the right map boundary")
	var edge_word = boundary_world.get_any_entity_at(Vector2i(31, 5))
	if edge_word == null or edge_word.text != "二":
		boundary_failures.append("failed edge push leaves the movable word inside the map")
	boundary_world.player_pos = Vector2i(0, 6)
	boundary_world.facing = Vector2i.RIGHT
	boundary_world.add_entity("一", Vector2i(1, 6), {"solid": true, "pushable": true})
	if boundary_world.pull_front(Vector2i.LEFT).get("success", false):
		boundary_failures.append("glove player cannot pull itself past the left map boundary")
	if not boundary_failures.is_empty():
		for failure in boundary_failures:
			printerr(failure)
		quit(1)
		return
	var wall_world := GridWorld.new()
	wall_world.load_level(GloveLevel.build_level())
	wall_world.interact_front()
	var wall_good = wall_world.find_first_entity_by_text("好")
	var wall_failures: Array[String] = []
	if wall_good == null:
		wall_failures.append("figure 2 exposes 好 for the wall restoration check")
	else:
		wall_world.move_entity_to(wall_good.id, Vector2i(14, 12))
		wall_world.move_entity_to(wall_good.id, Vector2i(14, 13))
		for wall_cell in GloveLayouts.LIFELINE_WALL_CELLS:
			_assert_char(wall_world, wall_cell, "掌", "returning 好 restores every middle palm-wall cell", wall_failures)
	if not wall_failures.is_empty():
		for failure in wall_failures:
			printerr(failure)
		quit(1)
		return
	var moved_opening_world := GridWorld.new()
	moved_opening_world.load_level(GloveLevel.build_level())
	moved_opening_world.player_pos = Vector2i(20, 14)
	moved_opening_world.facing = Vector2i.RIGHT
	var moved_opening: Dictionary = moved_opening_world.interact_front()
	var moved_failures: Array[String] = []
	if not moved_opening.get("success", false):
		moved_failures.append("opening interact must work after the player moves")
	_assert_char(moved_opening_world, Vector2i(12, 13), "逼", "moved opening replaces the palm row with the lifeline sentence", moved_failures)
	_assert_char(moved_opening_world, Vector2i(14, 13), "好", "moved opening exposes 好 without overlap", moved_failures)
	if not moved_failures.is_empty():
		for failure in moved_failures:
			printerr(failure)
		quit(1)
		return
	var world := GridWorld.new()
	world.load_level(GloveLevel.build_level())
	var opening: Dictionary = world.interact_front()
	if not opening.get("success", false):
		printerr("cannot enter DOCX figure 2")
		quit(1)
		return
	var zero_word = world.find_first_entity_by_text("零")
	var good_word = world.find_first_entity_by_text("好")
	if zero_word == null or good_word == null:
		printerr("figure 2 must expose zero and good")
		quit(1)
		return
	world.move_entity_to(zero_word.id, Vector2i(25, 16))
	world.move_entity_to(good_word.id, Vector2i(26, 17))
	var failures: Array[String] = []
	_assert_char(world, Vector2i(8, 13), "逼", "figure 4 open sentence starts at x=8", failures)
	_assert_char(world, Vector2i(9, 13), "退", "figure 4 open sentence keeps 逼退", failures)
	_assert_char(world, Vector2i(10, 13), " ", "figure 4 leaves the good-word gap open", failures)
	_assert_char(world, Vector2i(11, 13), "手", "figure 4 continues sentence after the gap", failures)
	_assert_char(world, Vector2i(15, 13), "线", "figure 4 sentence ends at x=15", failures)
	_assert_char(world, Vector2i(21, 12), " ", "figure 4 removes the isolated lifeline marker", failures)
	var good_in_slot = world.find_first_entity_by_text("好")
	if good_in_slot != null:
		world.move_entity_to(good_in_slot.id, Vector2i(25, 16))
		_assert_char(world, Vector2i(8, 13), "逼", "removing 好 from the gesture slot keeps the open sentence", failures)
		var like_anchor := GloveLayouts.hand_cells("like")[0]
		var like_entity = world.get_any_entity_at(like_anchor)
		if like_entity == null or like_entity.text != "掌":
			failures.append("removing 好 from the gesture slot must keep the like-hand layout")
	var zero_world := GridWorld.new()
	zero_world.load_level(GloveLevel.build_level())
	var zero_word_case = zero_world.find_first_entity_by_text("零")
	if zero_word_case != null:
		zero_world.move_entity_to(zero_word_case.id, Vector2i(26, 17))
		zero_world.move_entity_to(zero_word_case.id, Vector2i(25, 16))
		var zero_anchor = zero_world.get_any_entity_at(GloveLayouts.hand_cells("zero")[0])
		if zero_anchor == null or zero_anchor.text != "掌":
			failures.append("removing 零 from the gesture slot must keep the zero-hand layout")
	var one_world := GridWorld.new()
	one_world.load_level(GloveLevel.build_level())
	one_world.interact_front()
	var one_zero = one_world.find_first_entity_by_text("零")
	var one_word = one_world.find_first_entity_by_text("一")
	if one_zero != null and one_word != null:
		one_world.move_entity_to(one_zero.id, Vector2i(25, 16))
		one_world.move_entity_to(one_word.id, Vector2i(26, 17))
		_assert_char(one_world, Vector2i(12, 13), "逼", "one gesture restores the closed lifeline sentence", failures)
		_assert_char(one_world, Vector2i(14, 13), "好", "one gesture keeps 好 in the closed lifeline sentence", failures)
		_assert_char(one_world, Vector2i(19, 13), "线", "one gesture restores the closed lifeline sentence ending", failures)
		if one_world.find_first_entity_by_text("怜爱之深，") == null or one_world.find_first_entity_by_text("责任之切，") == null or one_world.find_first_entity_by_text("勇者之情。") == null:
			failures.append("one gesture shows the source hand clue")
		if one_world.find_first_entity_by_text("：改变手势，扭转守势！") == null:
			failures.append("one gesture shows the source change-gesture dialogue")
	var release_world := GridWorld.new()
	release_world.load_level(GloveLevel.build_level())
	release_world.interact_front()
	var release_zero = release_world.find_first_entity_by_text("零")
	var release_good = release_world.find_first_entity_by_text("好")
	if release_zero != null and release_good != null:
		release_world.move_entity_to(release_zero.id, Vector2i(25, 16))
		release_world.move_entity_to(release_good.id, Vector2i(26, 17))
		release_world.player_pos = Vector2i(5, 3)
		release_world.facing = Vector2i.RIGHT
		var delete_result: Dictionary = release_world.delete_front()
		if not delete_result.get("success", false):
			failures.append("deleting 不 succeeds before the release-state check")
		_assert_char(release_world, Vector2i(14, 0), "掌", "deleting 不 immediately selects the release-hand layout", failures)
		_assert_char(release_world, Vector2i(8, 13), "逼", "release state keeps the open lifeline sentence", failures)
	var ending_world := GridWorld.new()
	ending_world.load_level(GloveLevel.build_level())
	ending_world.interact_front()
	ending_world.player_pos = Vector2i(24, 5)
	ending_world.facing = Vector2i.UP
	var ending_result: Dictionary = ending_world.interact_front()
	if not ending_result.get("success", false):
		failures.append("interacting with the final hero opens the ending dialogue")
	if ending_world.player_visible or not ending_world.player_input_locked:
		failures.append("final hero interaction enters the locked dialogue scene")
	_assert_char(ending_world, Vector2i(1, 3), "「", "final hero interaction starts the first source dialogue line", failures)
	if not ending_world.has_pending_timed_effect():
		failures.append("final hero dialogue schedules a 0.2-second typewriter step")
	else:
		ending_world.resolve_pending_timed_effect()
		_assert_char(ending_world, Vector2i(2, 3), "果", "final hero typewriter reveals exactly one next character per step", failures)
	if ending_world.find_first_entity_by_text("勇") == null:
		failures.append("final hero interaction shows the two source dialogue lines")
	if failures.is_empty():
		print("glove DOCX state tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func _assert_char(world: RefCounted, pos: Vector2i, expected: String, message: String, failures: Array[String]) -> void:
	var actual := _character_at(world, pos)
	if actual != expected:
		failures.append("%s at %s: expected=%s actual=%s" % [message, pos, _shown(expected), _shown(actual)])

func _character_at(world: RefCounted, pos: Vector2i) -> String:
	if world.player_visible and world.player_pos == pos:
		return world.player_text
	var entity = world.get_any_entity_at(pos)
	if entity == null:
		return " "
	var index: int = entity.cells.find(pos)
	return entity.text.substr(index, 1) if index >= 0 and index < entity.text.length() else " "

func _shown(value: String) -> String:
	return "<space>" if value == " " else value
