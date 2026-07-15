extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")

var failures: Array[String] = []

func _init() -> void:
	test_push_emits_push_flash()
	test_merge_emits_word_merge_flash()
	test_player_merge_emits_word_merge_flash()
	test_pull_mirror_emits_pull_particles()

	if failures.is_empty():
		print("interaction visual effect request tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func test_push_emits_push_flash() -> void:
	var world := GridWorld.new()
	world.load_level({
		"screen_size": Vector2i(6, 4),
		"bounded": true,
		"player_start": Vector2i(1, 1),
		"player_facing": Vector2i.RIGHT,
		"rows": [
			"      ",
			"  木   ",
			"      ",
			"      "
		],
		"entities": {
			"木": {"solid": true, "pushable": true}
		}
	})
	var result := world.try_move_player(Vector2i.RIGHT)
	assert_true(result.success, "push setup succeeds")
	assert_request_type(world.consume_visual_effects(), "player_push_flash", "push emits player_push_flash")

func test_merge_emits_word_merge_flash() -> void:
	var world := GridWorld.new()
	world.load_level({
		"screen_size": Vector2i(6, 4),
		"bounded": true,
		"player_start": Vector2i(0, 0),
		"rows": [
			"      ",
			"  乔木  ",
			"      ",
			"      "
		],
		"entities": {
			"乔": {"solid": true, "pushable": true},
			"木": {"solid": true, "pushable": true},
			"桥": {"solid": true, "pushable": true, "splittable": true}
		},
		"split_rules": {"桥": ["乔", "木"]},
		"merge_rules": {"乔+木": "桥", "木+乔": "桥"}
	})
	var result := world.try_merge_entities(Vector2i(2, 1), Vector2i(3, 1))
	assert_true(result.success, "word merge setup succeeds")
	var requests := world.consume_visual_effects()
	var found := false
	for request_value in requests:
		var request: Dictionary = request_value
		if str(request.get("type", "")) != "word_merge_flash":
			continue
		found = true
		assert_equal(str(request.get("merged_text", "")), "桥", "merge request reports 桥")
	assert_true(found, "word merge emits word_merge_flash")

func test_player_merge_emits_word_merge_flash() -> void:
	var world := GridWorld.new()
	world.load_level({
		"screen_size": Vector2i(6, 4),
		"bounded": true,
		"player_start": Vector2i(2, 2),
		"player_facing": Vector2i.UP,
		"player_text": "我",
		"rows": [
			"      ",
			"  鸟   ",
			"      ",
			"      "
		],
		"entities": {
			"鸟": {"solid": true}
		},
		"player_merge_rules": {
			"我+鸟": "鹅",
			"鸟+我": "鹅"
		}
	})
	var result := world.try_move_player(Vector2i.UP)
	assert_true(result.success, "player merge setup succeeds")
	var requests := world.consume_visual_effects()
	var found := false
	for request_value in requests:
		var request: Dictionary = request_value
		if str(request.get("type", "")) != "word_merge_flash":
			continue
		if not bool(request.get("is_player_merge", false)):
			continue
		found = true
		assert_equal(str(request.get("merged_text", "")), "鹅", "player merge request reports 鹅")
	assert_true(found, "player merge emits player-tagged word_merge_flash")

func test_pull_mirror_emits_pull_particles() -> void:
	var world := GridWorld.new()
	world.load_level({
		"screen_size": Vector2i(6, 5),
		"bounded": true,
		"player_start": Vector2i(2, 3),
		"player_facing": Vector2i.UP,
		"rows": [
			"      ",
			"      ",
			"  镜   ",
			"      ",
			"      "
		],
		"entities": {
			"镜": {"solid": true, "pushable": true}
		},
		"pullable_texts": ["镜"]
	})
	var result := world.pull_front(Vector2i.DOWN)
	assert_true(result.success, "mirror pull setup succeeds")
	assert_request_type(world.consume_visual_effects(), "pull_particles", "mirror pull emits pull_particles")

func assert_request_type(requests: Array, expected_type: String, message: String) -> void:
	for request_value in requests:
		var request: Dictionary = request_value
		if str(request.get("type", "")) == expected_type:
			return
	fail(message)

func assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		fail("%s: expected %s, got %s" % [message, expected, actual])

func assert_true(condition: bool, message: String) -> void:
	if not condition:
		fail(message)

func fail(message: String) -> void:
	failures.append(message)
