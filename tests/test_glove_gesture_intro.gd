extends SceneTree

const GlovePreviewScene = preload("res://levels/glove/glove_preview.tscn")

func _init() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var preview = GlovePreviewScene.instantiate()
	root.add_child(preview)
	await process_frame
	if not preview.has_method("_start_gesture_level_intro"):
		printerr("leaving the hero quote must start the dedicated gesture-level introduction")
		preview.queue_free()
		quit(1)
		return
	preview._enter_glove_gesture_level()
	if not preview.gesture_intro_active or preview.map_layer.visible or preview.gesture_intro_hand_root.position.y >= 0.0:
		printerr("the initial 堂 hand starts above the screen while the playable map remains hidden")
		preview.queue_free()
		quit(1)
		return
	preview._advance_gesture_intro(1.2)
	if not preview.gesture_intro_reveal_started or not preview.gesture_intro_player.visible or preview.gesture_intro_reveal_labels.is_empty():
		printerr("after the hand settles, the remaining solid words and fixed player word begin to appear")
		preview.queue_free()
		quit(1)
		return
	preview._advance_gesture_intro(1.0)
	if not preview.gesture_intro_swap_started or preview.gesture_intro_active_swaps.is_empty():
		printerr("the settled hand begins the two-dimensional top-left to bottom-right 堂-to-掌 replacement")
		preview.queue_free()
		quit(1)
		return
	var first_swap: Dictionary = preview.gesture_intro_active_swaps[0]
	var first_cell: Vector2i = first_swap.cell
	for swap in preview.gesture_intro_active_swaps:
		var cell: Vector2i = swap.cell
		if cell.x + cell.y < first_cell.x + first_cell.y:
			printerr("each replacement wave must begin from the smallest x+y diagonal")
			preview.queue_free()
			quit(1)
			return
	preview._advance_gesture_intro(12.0)
	if preview.gesture_intro_active or not preview.map_layer.visible or preview.world.player_input_locked:
		printerr("only the completed 堂-to-掌 introduction unlocks the playable gesture level")
		preview.queue_free()
		quit(1)
		return
	preview.queue_free()
	print("glove gesture introduction tests passed")
	quit(0)
