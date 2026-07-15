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
	preview.queue_free()
	print("glove push and pull visual scene tests passed")
	quit(0)
