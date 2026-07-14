extends SceneTree

const GlovePreviewScene = preload("res://levels/glove/glove_preview.tscn")

func _init() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var preview = GlovePreviewScene.instantiate()
	root.add_child(preview)
	var overlay = preview.get_node_or_null("GestureFlashLayer/GestureFlashOverlay")
	var failures: Array[String] = []
	if overlay == null:
		failures.append("gesture flash uses a dedicated full-screen canvas layer")
	elif overlay.size.x < 1920.0 or overlay.size.y < 1080.0:
		failures.append("gesture flash overlay covers the complete game viewport")
	preview.queue_free()
	if failures.is_empty():
		print("glove gesture flash scene tests passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)
