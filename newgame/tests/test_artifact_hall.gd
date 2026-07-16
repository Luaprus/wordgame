extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const ArtifactHall = preload("res://levels/hall/artifact_hall.gd")

func _init() -> void:
	var failures: Array[String] = []
	var world := GridWorld.new()
	world.load_level(ArtifactHall.build_level())

	_assert_char(world, ArtifactHall.SWORD_GATE_POS, "门", "sword gate uses 门", failures)
	_assert_char(world, ArtifactHall.HAND_GATE_POS, "门", "hand gate uses 门", failures)
	_assert_char(world, ArtifactHall.HELMET_GATE_POS, "门", "helmet gate uses 门", failures)
	_assert_char(world, ArtifactHall.PRINCESS_GATE_POS, "门", "princess gate uses 门", failures)
	_assert_no_text(world, "闩", "artifact hall no longer contains 闩", failures)

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

	_assert_gate_scene_path(ArtifactHall.SWORD_GATE_POS, ArtifactHall.SWORD_SCENE_PATH, "sword gate", failures)
	_assert_gate_scene_path(ArtifactHall.HAND_GATE_POS, ArtifactHall.HAND_SCENE_PATH, "hand gate", failures)
	_assert_gate_scene_path(ArtifactHall.PRINCESS_GATE_POS, ArtifactHall.PRINCESS_SCENE_PATH, "princess gate", failures)
	_assert_gate_level_index(ArtifactHall.HELMET_GATE_POS, ArtifactHall.HELMET_LEVEL_INDEX, "helmet gate", failures)

	if failures.is_empty():
		print("artifact hall tests passed")
		quit(0)
	for failure in failures:
		push_error(failure)
	quit(1)

func _assert_gate_scene_path(gate_pos: Vector2i, expected_scene_path: String, label: String, failures: Array[String]) -> void:
	var world := GridWorld.new()
	world.load_level(ArtifactHall.build_level())
	_open_gate(world, gate_pos, label, failures)
	var enter_result: Dictionary = world.interact_front()
	if not enter_result.success:
		failures.append("%s remains interactable after opening" % label)
	if world.pending_scene_path != expected_scene_path:
		failures.append("%s requests %s" % [label, expected_scene_path])

func _assert_gate_level_index(gate_pos: Vector2i, expected_level_index: int, label: String, failures: Array[String]) -> void:
	var world := GridWorld.new()
	world.load_level(ArtifactHall.build_level())
	_open_gate(world, gate_pos, label, failures)
	var enter_result: Dictionary = world.interact_front()
	if not enter_result.success:
		failures.append("%s remains interactable after opening" % label)
	if world.pending_level_index != expected_level_index:
		failures.append("%s requests level index %d" % [label, expected_level_index])

func _open_gate(world, gate_pos: Vector2i, label: String, failures: Array[String]) -> void:
	world.player_pos = gate_pos + Vector2i.LEFT
	world.facing = Vector2i.RIGHT
	var open_result: Dictionary = world.interact_front()
	if not open_result.success:
		failures.append("%s triggers the door animation" % label)
	var gate = world.get_any_entity_at(gate_pos)
	if gate == null or gate.text != "门" or gate.visual_style != "hall_door_open":
		failures.append("%s keeps the opened door visual state" % label)
	var blocked_result: Dictionary = world.try_move_player(Vector2i.RIGHT)
	if blocked_result.success:
		failures.append("%s still blocks the player like the source door interaction" % label)
	var found_door_visual := false
	for request in world.consume_visual_effects():
		if str(request.get("type", "")) != "hall_door_open":
			continue
		if request.get("cell", Vector2i(-1, -1)) != gate_pos:
			continue
		found_door_visual = true
	if not found_door_visual:
		failures.append("%s emits a hall_door_open visual request" % label)

func _assert_char(world, pos: Vector2i, expected: String, message: String, failures: Array[String]) -> void:
	var entity = world.get_any_entity_at(pos)
	if entity == null or entity.text != expected:
		failures.append(message)

func _assert_no_text(world, text: String, message: String, failures: Array[String]) -> void:
	for entity in world.entities.values():
		if entity.text == text:
			failures.append(message)
			return
