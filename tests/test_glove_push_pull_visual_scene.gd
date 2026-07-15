extends SceneTree

const GlovePreviewScene = preload("res://levels/glove/glove_preview.tscn")

func _init() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var preview = GlovePreviewScene.instantiate()
	root.add_child(preview)
	await process_frame
	if preview.player_sprite == null or preview.intro_player_sprite == null or preview.hero_quote_player_sprite == null:
		printerr("every controllable glove-level player must use the shared walk visual")
		preview.queue_free()
		quit(1)
		return
	if not is_equal_approx(preview.MOVE_REPEAT_INTERVAL, preview.move_visual_duration):
		printerr("the glove tutorial must start each next grid move when the prior smooth move ends")
		preview.queue_free()
		quit(1)
		return
	preview.world.load_level({
		"screen_size": Vector2i(6, 4),
		"bounded": true,
		"player_start": Vector2i(1, 1),
		"player_facing": Vector2i.RIGHT,
		"player_text": "我",
		"rows": []
	})
	preview._player_visual_ready = false
	preview._refresh_view()
	preview._apply_direction_step(Vector2i.RIGHT)
	var movement_cooldown = preview.get("player_move_repeat_timer")
	if movement_cooldown == null or not is_equal_approx(float(movement_cooldown), 0.12):
		printerr("the glove player must use the sword-level 0.12 second movement cooldown")
		preview.queue_free()
		quit(1)
		return
	preview.world.load_level({
		"screen_size": Vector2i(6, 4),
		"bounded": true,
		"player_start": Vector2i(1, 1),
		"player_facing": Vector2i.RIGHT,
		"player_text": "我",
		"push_keeps_player_in_place": true,
		"push_recovery_duration": 0.05,
		"rows": [],
		"initial_spawn": [{"text": "字", "pos": Vector2i(2, 1), "config": {"solid": true, "pushable": true}}]
	})
	preview._player_visual_ready = false
	preview._refresh_view()
	preview._apply_direction_step(Vector2i.RIGHT)
	if preview.world.player_pos != Vector2i(1, 1) or preview.world.get_entity_at(Vector2i(3, 1)) == null:
		printerr("a glove push must leave the player in place while moving only the pushed word")
		preview.queue_free()
		quit(1)
		return
	var push_recovery_active = preview.get("push_recovery_active")
	var push_recovery_timer = preview.get("push_recovery_timer")
	if push_recovery_active != true or push_recovery_timer == null or push_recovery_timer.time_left < preview.move_visual_duration + 0.05:
		printerr("a glove push must lock input through the word movement and 0.05 second recovery")
		preview.queue_free()
		quit(1)
		return
	preview._apply_direction_step(Vector2i.RIGHT)
	if preview.world.player_pos != Vector2i(1, 1):
		printerr("the player must not move while a glove push recovery is active")
		preview.queue_free()
		quit(1)
		return
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
	preview.push_recovery_active = false
	preview.push_recovery_timer.stop()
	preview.intro_world.load_level({
		"screen_size": Vector2i(6, 4),
		"bounded": true,
		"player_start": Vector2i(1, 1),
		"player_facing": Vector2i.RIGHT,
		"player_text": "我",
		"push_keeps_player_in_place": true,
		"push_recovery_duration": 0.05,
		"rows": [],
		"initial_spawn": [{"text": "字", "pos": Vector2i(2, 1), "config": {"solid": true, "pushable": true}}]
	})
	preview._apply_intro_direction_step(Vector2i.RIGHT)
	if preview.intro_world.player_pos != Vector2i(1, 1) or not preview.push_recovery_active:
		printerr("the tutorial push must leave the player in place and start recovery")
		preview.queue_free()
		quit(1)
		return
	if preview.intro_glove_effect_layer.get_child_count() == 0:
		printerr("a tutorial push must render the glove animation above the tutorial text")
		preview.queue_free()
		quit(1)
		return
	if preview.intro_player_sprite == null or preview.intro_player_sprite.texture.resource_path != "res://assets/player/me_default.png":
		printerr("a tutorial push that leaves the player in place must not play a walk visual")
		preview.queue_free()
		quit(1)
		return
	preview.push_recovery_active = false
	preview._apply_intro_direction_step(Vector2i.RIGHT)
	if preview.intro_world.player_pos != Vector2i(2, 1) or not preview.intro_world.pull_front(Vector2i.LEFT).success:
		printerr("the tutorial setup must allow the player to step into the freed cell before pulling")
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
