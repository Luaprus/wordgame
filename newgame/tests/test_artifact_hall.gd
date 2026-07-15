extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const ArtifactHall = preload("res://levels/hall/artifact_hall.gd")

func _init() -> void:
	var failures: Array[String] = []
	var world := GridWorld.new()
	world.load_level(ArtifactHall.build_level())
	_assert_char(world, ArtifactHall.SWORD_GATE_POS, "门", "sword gate starts open", failures)
	_assert_char(world, ArtifactHall.HAND_GATE_POS, "闩", "hand gate starts closed", failures)
	_assert_char(world, ArtifactHall.HELMET_GATE_POS, "闩", "helmet gate starts closed", failures)
	_assert_char(world, Vector2i(6, 10), "剑", "sword gate name includes 剑", failures)
	_assert_char(world, Vector2i(6, 11), "之", "sword gate name includes 之", failures)
	_assert_char(world, Vector2i(16, 10), "手", "hand gate name includes 手", failures)
	_assert_char(world, Vector2i(16, 11), "之", "hand gate name includes 之", failures)
	_assert_char(world, Vector2i(26, 10), "盔", "helmet gate name includes 盔", failures)
	_assert_char(world, Vector2i(26, 11), "之", "helmet gate name includes 之", failures)
	_assert_char(world, Vector2i(26, 0), "盔", "helmet shape starts with 盔", failures)
	_assert_char(world, Vector2i(26, 1), "头", "helmet shape alternates 头 and 盔 by row", failures)
	_assert_char(world, Vector2i(26, 6), "盔", "helmet shape includes the lower 盔", failures)
	if world.get_any_entity_at(Vector2i(23, 5)) != null or world.get_any_entity_at(Vector2i(29, 5)) != null:
		failures.append("helmet pattern removes the two marked lower-corner heads")
	_assert_char(world, Vector2i(13, 3), "手", "hand pattern includes the marked upper-left hand", failures)
	if world.get_any_entity_at(Vector2i(14, 3)) != null or world.get_any_entity_at(Vector2i(13, 4)) != null:
		failures.append("hand pattern removes the two marked cells")

	world.player_pos = ArtifactHall.HAND_GATE_POS + Vector2i.LEFT
	world.facing = Vector2i.RIGHT
	world.interact_front()
	_assert_text(world, ArtifactHall.HAND_DESC_POS, "手之门不会开", "interacting with the hand lock shows its description", failures)
	var hand_word = world.get_any_entity_at(ArtifactHall.HAND_DESC_POS)
	if hand_word == null or not hand_word.solid or not hand_word.pushable:
		failures.append("手 in the hand-door description is solid and pushable")
	var hand_desc_wall = world.get_any_entity_at(ArtifactHall.HAND_DESC_POS + Vector2i(1, 0))
	if hand_desc_wall == null or not hand_desc_wall.solid:
		failures.append("hand-door description blocks player movement")
	world.move_entity_by(hand_word.id, Vector2i.LEFT)
	world.move_entity_to(hand_word.id, Vector2i(5, 15))
	if world.get_any_entity_at(ArtifactHall.HAND_DESC_POS) != null:
		failures.append("hand must be moved away before the helmet character can occupy its position")
	world.player_pos = ArtifactHall.HAND_GATE_POS + Vector2i.LEFT
	world.facing = Vector2i.RIGHT
	world.interact_front()
	if world.get_any_entity_at(ArtifactHall.HAND_DESC_POS) != null:
		failures.append("hand lock interaction must not regenerate moved description text")

	world.player_pos = ArtifactHall.HAND_NOT_POS + Vector2i.LEFT
	world.facing = Vector2i.RIGHT
	world.delete_front()
	_assert_char(world, ArtifactHall.HAND_GATE_POS, "门", "deleting 不 changes the hand lock into a door", failures)

	world.player_pos = ArtifactHall.HELMET_GATE_POS + Vector2i.LEFT
	world.facing = Vector2i.RIGHT
	world.interact_front()
	_assert_text(world, ArtifactHall.HELMET_DESC_POS, "盔之门无法打开", "interacting with the helmet lock shows its description", failures)
	var helmet_key = world.get_any_entity_at(ArtifactHall.HELMET_DESC_POS)
	if helmet_key == null or helmet_key.text != "盔" or not helmet_key.pushable:
		failures.append("helmet description starts with a pushable 盔")
	else:
		world.move_entity_to(helmet_key.id, ArtifactHall.HELMET_DESC_POS + Vector2i.LEFT)
		world.player_pos = ArtifactHall.HELMET_GATE_POS + Vector2i.LEFT
		world.facing = Vector2i.RIGHT
		world.interact_front()
		if world.get_any_entity_at(ArtifactHall.HELMET_DESC_POS) != null:
			failures.append("helmet lock interaction must not regenerate moved description text")
		world.move_entity_to(helmet_key.id, ArtifactHall.HAND_DESC_POS + Vector2i.RIGHT)
		world.move_entity_by(helmet_key.id, Vector2i.LEFT)
	_assert_char(world, ArtifactHall.HAND_DESC_POS, "盔", "moving 盔 replaces 手 in the existing description", failures)
	_assert_char(world, ArtifactHall.HELMET_GATE_POS, "门", "moving 盔 to the 手 position opens the helmet gate", failures)
	world.player_pos = ArtifactHall.HELMET_GATE_POS + Vector2i.LEFT
	world.facing = Vector2i.RIGHT
	world.try_move_player(Vector2i.RIGHT)
	if world.get_any_entity_at(ArtifactHall.HAND_DESC_POS) != null or world.get_any_entity_at(ArtifactHall.HELMET_DESC_POS) != null:
		failures.append("entering the helmet door clears both door descriptions")
	if world.get_any_entity_at(Vector2i(5, 15)) != null:
		failures.append("entering the helmet door clears a moved temporary hand character")
	_assert_char(world, ArtifactHall.RETURN_POET_START, "诗", "poet enters from the left after the helmet door", failures)
	for _step in range(ArtifactHall.RETURN_POET_POS.x - ArtifactHall.RETURN_POET_START.x + 1):
		world.resolve_pending_timed_effect()
	_assert_char(world, ArtifactHall.RETURN_POET_POS, "诗", "poet reaches the hall dialogue position", failures)
	_assert_text(world, ArtifactHall.RETURN_DIALOGUE_POS, "「你已经拿到了全部神器，」", "poet shows the first return line", failures)
	_assert_text(world, ArtifactHall.RETURN_DIALOGUE_POS + Vector2i(0, 1), "「继续前进拯救公主吧！」", "poet shows the second return line", failures)
	if world.get_any_entity_at(ArtifactHall.RETURN_ROAD_TOP_POS) != null:
		failures.append("return road waits one second after the dialogue")
	world.resolve_pending_timed_effect()
	_assert_text(world, ArtifactHall.RETURN_ROAD_TOP_POS, ArtifactHall.RETURN_ROAD_TEXT, "upper return road appears after the delay", failures)
	_assert_text(world, ArtifactHall.RETURN_ROAD_BOTTOM_POS, ArtifactHall.RETURN_ROAD_TEXT, "lower return road appears after the delay", failures)
	if world.get_any_entity_at(ArtifactHall.RETURN_ROAD_TOP_POS + Vector2i.LEFT) != null:
		failures.append("return road removes its leftmost extra column")
	world.player_pos = Vector2i(31, 15)
	var edge_result := world.try_move_player(Vector2i.RIGHT)
	if not edge_result.has("transition"):
		failures.append("empty corridor between the road rows exits to the princess scene")
	world.player_pos = Vector2i(31, ArtifactHall.RETURN_ROAD_BOTTOM_POS.y)
	var road_exit := world.try_move_player(Vector2i.RIGHT)
	if road_exit.has("transition"):
		failures.append("road text itself must not transition to the princess scene")
	if failures.is_empty():
		print("artifact hall tests passed")
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
