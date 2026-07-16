extends SceneTree

const GlovePreviewScene = preload("res://levels/glove/glove_preview.tscn")

func _init() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var preview = GlovePreviewScene.instantiate()
	root.add_child(preview)
	await process_frame
	if not preview.has_method("_start_hero_encroach_epilogue"):
		_fail(preview, "the hero encroachment needs a dedicated epilogue entry point")
		return
	preview._start_hero_encroach_epilogue()
	if not preview.hero_encroach_epilogue_active:
		_fail(preview, "the epilogue entry point must activate the post-encroachment sequence")
		return
	if preview.hero_encroach_epilogue_characters.get_child_count() != 1:
		_fail(preview, "the epilogue must begin typewriting the red-box sentence")
		return
	preview._advance_hero_encroach_epilogue(10.0)
	if not preview.hero_encroach_epilogue_player_active:
		_fail(preview, "the first character 我 must become a movable player after typewriting")
		return
	if not preview.hero_encroach_epilogue_blue_visible:
		_fail(preview, "the blue-box sentence must fade in after the red-box sentence completes")
		return
	preview.hero_encroach_epilogue_world.player_pos = Vector2i(15, 11)
	preview._check_hero_encroach_epilogue_triggers()
	if not preview.hero_encroach_epilogue_green_visible:
		_fail(preview, "entering 世界由_拯救 must reveal 公主由_解放")
		return
	preview.hero_encroach_epilogue_world.player_pos = Vector2i(15, 14)
	preview._check_hero_encroach_epilogue_triggers()
	if not preview.hero_encroach_epilogue_return_active:
		_fail(preview, "entering 公主由_解放 must start the hall-return transition")
		return
	if not preview.hero_encroach_epilogue_world.player_input_locked:
		_fail(preview, "the hall-return flash must lock player movement")
		return
	preview.queue_free()
	print("glove hero encroachment epilogue tests passed")
	quit(0)

func _fail(preview, message: String) -> void:
	printerr(message)
	preview.queue_free()
	quit(1)
