extends SceneTree

const GloveLevel = preload("res://levels/glove/glove_level.gd")
const GridWorld = preload("res://scripts/grid_world.gd")

func _init() -> void:
	var failures: Array[String] = []
	var intro_world := GridWorld.new()
	intro_world.load_level(GloveLevel.build_level())
	var intro_request: Dictionary = intro_world.consume_visual_effect_request()
	if str(intro_request.get("type", "")) != "glove_acquire":
		failures.append("the glove level starts with the glove acquisition visual")
	if not intro_world.player_input_locked:
		failures.append("the glove acquisition visual locks input until it finishes")

	var delete_world := GridWorld.new()
	delete_world.load_level(GloveLevel.build_level())
	delete_world.consume_visual_effect_request()
	delete_world.player_input_locked = false
	delete_world.player_pos = Vector2i(5, 3)
	delete_world.facing = Vector2i.RIGHT
	var delete_result: Dictionary = delete_world.delete_front()
	if not delete_result.get("success", false):
		failures.append("deleting 不 succeeds before the cut visual check")
	var cut_request: Dictionary = delete_world.consume_visual_effect_request()
	if str(cut_request.get("type", "")) != "delete_cut":
		failures.append("deleting 不 requests the word-cut visual")
	if cut_request.get("pos", Vector2i.ZERO) != Vector2i(6, 3):
		failures.append("the word-cut visual is anchored at the deleted word")
	if failures.is_empty():
		print("glove visual effect request tests passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)
