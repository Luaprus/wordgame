extends SceneTree

const GlovePreviewScene = preload("res://levels/glove/glove_preview.tscn")
const DIALOGUE_POS := Vector2i(1, 8)
const DIALOGUE_INITIAL := "勇：别被一条线给困住了！"
const DIALOGUE_LIKE := "勇：加油！"

func _init() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var preview = GlovePreviewScene.instantiate()
	root.add_child(preview)
	await process_frame
	preview.world._apply_map_effect({
		"remove_texts": [DIALOGUE_INITIAL],
		"spawn": [{"text": DIALOGUE_LIKE, "pos": DIALOGUE_POS, "config": {"solid": false}}]
	})
	preview._refresh_view()
	var dialogue = preview.world.get_any_entity_at(DIALOGUE_POS)
	var entity_group: Node2D = preview.entity_labels.get(dialogue.id)
	if not preview.like_loop_prefix.visible or preview.like_loop_labels[0].text != "加" or preview.like_loop_labels[1].visible or entity_group.visible:
		printerr("the fixed brave prefix and the first 加 character replace the ordinary 加油 dialogue text")
		preview.queue_free()
		quit(1)
		return
	preview._process(0.2)
	if preview.like_loop_labels[1].text != "油" or not preview.like_loop_labels[1].visible:
		printerr("the brave encouragement types its second character after the shared 0.2-second interval")
		preview.queue_free()
		quit(1)
		return
	preview._process(0.4)
	if preview.like_loop_labels[0].visible or preview.like_loop_labels[1].visible or preview.like_loop_labels[2].visible:
		printerr("the completed 加油 prompt clears before its next typewriter loop")
		preview.queue_free()
		quit(1)
		return
	preview.queue_free()
	print("glove like prompt tests passed")
	quit(0)
