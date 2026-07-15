extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const PoetOpening = preload("res://levels/prologue/poet_opening.gd")

func _init() -> void:
	var failures: Array[String] = []
	var world := GridWorld.new()
	world.load_level(PoetOpening.build_level())
	_assert_char(world, PoetOpening.POET_START, "诗", "poet begins at the left edge", failures)
	if not PoetOpening.DIALOGUES[0].ends_with("，」") or not PoetOpening.DIALOGUES[1].ends_with("，」") or not PoetOpening.DIALOGUES[2].ends_with("，」"):
		failures.append("the first three poet lines end with commas")
	if not PoetOpening.FOURTH_SUFFIX.ends_with("。」"):
		failures.append("the fourth poet line ends with a full stop")
	if world.player_visible:
		failures.append("player is hidden until the fourth line")
	for _step in range(PoetOpening.POET_POS.x - PoetOpening.POET_START.x + 1):
		world.resolve_pending_timed_effect()
	_assert_char(world, PoetOpening.POET_POS, "诗", "poet reaches the speaker position one cell at a time", failures)
	_assert_text(world, PoetOpening.DIALOGUE_POS, PoetOpening.DIALOGUES[0], "first dialogue appears after the poet arrives", failures)
	_assert_char(world, PoetOpening.DIALOGUE_POS + Vector2i(PoetOpening.DIALOGUES[0].length(), 0), "▼", "first dialogue has a continue marker", failures)
	for page in range(2, 4):
		world.interact_front()
		_assert_text(world, PoetOpening.DIALOGUE_POS, PoetOpening.DIALOGUES[page - 1], "dialogue page %d replaces the prior page" % page, failures)
		_assert_char(world, PoetOpening.DIALOGUE_POS + Vector2i(PoetOpening.DIALOGUES[page - 1].length(), 0), "▼", "dialogue page %d has a continue marker" % page, failures)
	world.interact_front()
	_assert_text(world, PoetOpening.DIALOGUE_POS, PoetOpening.FOURTH_PREFIX, "fourth dialogue starts at the same speaker position", failures)
	_assert_text(world, PoetOpening.PLAYER_POS + Vector2i.RIGHT, PoetOpening.FOURTH_SUFFIX, "fourth dialogue continues after the player", failures)
	if not world.player_visible or world.player_pos != PoetOpening.PLAYER_POS:
		failures.append("player appears at the 我 position in the fourth dialogue")
	if world.get_any_entity_at(PoetOpening.DIALOGUE_POS + Vector2i(24, 0)) != null:
		failures.append("fourth dialogue must not have a continue marker")
	if world.get_any_entity_at(PoetOpening.ROAD_TOP_POS) != null:
		failures.append("road must wait one second after the fourth dialogue")
	world.resolve_pending_timed_effect()
	_assert_text(world, PoetOpening.ROAD_TOP_POS, PoetOpening.ROAD_TEXT, "upper road appears after the delay", failures)
	_assert_text(world, PoetOpening.ROAD_BOTTOM_POS, PoetOpening.ROAD_TEXT, "lower road appears after the delay", failures)
	if world.player_input_locked:
		failures.append("player regains control after the road appears")
	if failures.is_empty():
		print("poet opening tests passed")
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
