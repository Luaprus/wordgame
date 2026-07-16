extends SceneTree

const GlovePreviewScene = preload("res://levels/glove/glove_preview.tscn")

func _init() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var preview = GlovePreviewScene.instantiate()
	root.add_child(preview)
	await process_frame
	preview._start_intro_push_tutorial()
	var intro_cell_step: float = preview._intro_grid_to_pixels(Vector2i(1, 0)).x - preview._intro_grid_to_pixels(Vector2i.ZERO).x
	if not is_equal_approx(intro_cell_step, 60.0):
		_fail(preview, "the intro grid must use the same 60px advance as its single-character labels")
		return
	preview.intro_world.player_pos = Vector2i(4, 7)
	preview.intro_world.facing = Vector2i.DOWN
	preview._apply_intro_direction_step(Vector2i.DOWN)
	if not preview.intro_quote_started or not preview.intro_world.player_input_locked:
		_fail(preview, "pushing 不 into the target must lock movement while the brave quote types")
		return
	var locked_position: Vector2i = preview.intro_world.player_pos
	preview._apply_intro_direction_step(Vector2i.LEFT)
	if preview.intro_world.player_pos != locked_position:
		_fail(preview, "the player must not move during the automatic rewrite sequence")
		return
	preview._advance_intro_typewriter(10.0)
	var first_lower_word = preview.intro_world.get_entity_at(preview.INTRO_NO_TARGET + Vector2i.RIGHT)
	if not preview.intro_bottom_rewrite_started or first_lower_word == null or first_lower_word.text != "相" or not preview.intro_world.player_input_locked:
		_fail(preview, "the completed brave quote must automatically begin the locked lower typewriter")
		return
	preview._advance_intro_typewriter(10.0)
	if not preview.intro_top_rewrite_started or not preview.intro_world.player_input_locked:
		_fail(preview, "the completed lower typewriter must automatically begin the locked upper typewriter")
		return
	preview._advance_intro_typewriter(10.0)
	if preview.intro_world.has_pending_timed_effect() or preview.intro_world.player_input_locked:
		_fail(preview, "movement must unlock only after the final automatic rewrite character appears")
		return
	preview._finish_push_recovery()
	var player_before_unlock_move: Vector2i = preview.intro_world.player_pos
	preview._apply_intro_direction_step(Vector2i.LEFT)
	preview._apply_intro_direction_step(Vector2i.LEFT)
	if preview.intro_world.player_pos == player_before_unlock_move:
		_fail(preview, "the player must be able to move after the final automatic rewrite completes")
		return
	# Returning 不 to its original cell then pushing it back must not restart the completed push tutorial.
	var no_word = preview.intro_world.get_entity_at(preview.INTRO_NO_TARGET)
	if no_word == null or no_word.text != "不":
		_fail(preview, "the push tutorial must retain 不 at its target for the repeat-trigger check")
		return
	preview.intro_world.move_entity_to(no_word.id, preview.INTRO_NO_START)
	preview.intro_world.move_entity_to(no_word.id, preview.INTRO_NO_TARGET)
	if preview.intro_world.has_pending_timed_effect() or preview.intro_world.player_input_locked:
		_fail(preview, "a completed push tutorial must not restart when 不 returns to its original target")
		return
	preview.queue_free()
	print("glove intro auto rewrite tests passed")
	quit(0)

func _fail(preview, message: String) -> void:
	printerr(message)
	preview.queue_free()
	quit(1)
