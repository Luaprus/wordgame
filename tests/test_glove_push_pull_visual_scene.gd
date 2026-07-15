extends SceneTree

const GlovePreviewScene = preload("res://levels/glove/glove_preview.tscn")

func _init() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var preview = GlovePreviewScene.instantiate()
	root.add_child(preview)
	await process_frame
	if not preview.has_method("_play_glove_push_flash") or not preview.has_method("_play_glove_pull_particles"):
		printerr("the glove preview must render both push frames and pull particles")
		preview.queue_free()
		quit(1)
		return
	preview._play_glove_push_flash({"direction": Vector2i.RIGHT, "player_to": Vector2i(2, 1)})
	if preview.glove_effect_layer.get_child_count() == 0:
		printerr("a push request must create the source hand animation overlay")
		preview.queue_free()
		quit(1)
		return
	preview._play_glove_pull_particles({"origin_grid": Vector2i(2, 1), "duration": 0.42, "seed": 17})
	if not preview.glove_pull_particles.visible:
		printerr("a pull request must show the particle layer at the pulled word cell")
		preview.queue_free()
		quit(1)
		return
	preview.intro_world.load_level({
		"screen_size": Vector2i(6, 4),
		"bounded": true,
		"player_start": Vector2i(1, 1),
		"player_facing": Vector2i.RIGHT,
		"player_text": "我",
		"rows": [],
		"initial_spawn": [{"text": "字", "pos": Vector2i(2, 1), "config": {"solid": true, "pushable": true}}]
	})
	preview._apply_intro_direction_step(Vector2i.RIGHT)
	if preview.intro_glove_effect_layer.get_child_count() == 0:
		printerr("a tutorial push must render the glove animation above the tutorial text")
		preview.queue_free()
		quit(1)
		return
	if not preview.intro_world.pull_front(Vector2i.LEFT).success:
		printerr("the tutorial setup must allow a pull after pushing the word")
		preview.queue_free()
		quit(1)
		return
	preview._consume_intro_visual_effect_requests()
	if not preview.intro_glove_pull_particles.visible:
		printerr("a tutorial pull must render particles above the tutorial text")
		preview.queue_free()
		quit(1)
		return
	preview.queue_free()
	print("glove push and pull visual scene tests passed")
	quit(0)
