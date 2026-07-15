extends SceneTree

const GlovePreviewScene = preload("res://levels/glove/glove_preview.tscn")

func _init() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var preview = GlovePreviewScene.instantiate()
	root.add_child(preview)
	await process_frame
	preview._set_direction_held(Vector2i.RIGHT, true)
	if preview._current_held_direction() != Vector2i.ZERO:
		printerr("a released physical key must clear a stale held direction before it can repeat movement")
		preview.queue_free()
		quit(1)
		return
	preview.queue_free()
	print("glove stale direction input tests passed")
	quit(0)
