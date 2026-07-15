extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")

func _init() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var world = GridWorld.new()
	world.load_level({
		"name": "推拉动画测试",
		"screen_size": Vector2i(8, 5),
		"bounded": true,
		"player_start": Vector2i(1, 1),
		"player_facing": Vector2i.RIGHT,
		"player_text": "我",
		"rows": [],
		"initial_spawn": [{"text": "字", "pos": Vector2i(2, 1), "config": {"solid": true, "pushable": true}}]
	})
	if not world.try_move_player(Vector2i.RIGHT).success or not _contains_type(world.consume_visual_effects(), "player_push_flash"):
		printerr("a successful push must request the glove push animation")
		quit(1)
		return
	if not world.pull_front(Vector2i.LEFT).success:
		printerr("the test setup must be able to pull the pushed word back")
		quit(1)
		return
	var pull_requests: Array = world.consume_visual_effects()
	if not _contains_type(pull_requests, "pull_particles"):
		printerr("a successful pull must request the pull particle animation")
		quit(1)
		return
	for request_value in pull_requests:
		var request: Dictionary = request_value
		if str(request.get("type", "")) == "pull_particles" and request.get("origin_grid", Vector2i.ZERO) != Vector2i(2, 1):
			printerr("pull particles must originate from the word's destination cell")
			quit(1)
			return
	print("glove push and pull visual request tests passed")
	quit(0)

func _contains_type(requests: Array, expected_type: String) -> bool:
	for request_value in requests:
		if str((request_value as Dictionary).get("type", "")) == expected_type:
			return true
	return false
