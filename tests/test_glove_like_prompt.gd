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
	var prefix = preview.world.get_entity_at(DIALOGUE_POS)
	var first_loop_word = preview.world.get_entity_at(Vector2i(3, 8))
	if prefix == null or prefix.text != "勇：" or first_loop_word == null or first_loop_word.text != "加":
		printerr("the fixed brave prefix and the first 加 character must occupy real grid cells")
		preview.queue_free()
		quit(1)
		return
	preview._process(0.2)
	var second_loop_word = preview.world.get_entity_at(Vector2i(4, 8))
	if second_loop_word == null or second_loop_word.text != "油":
		printerr("the brave encouragement types its second character after the shared 0.2-second interval")
		preview.queue_free()
		quit(1)
		return
	preview._process(0.4)
	if preview.world.get_entity_at(Vector2i(3, 8)) != null or preview.world.get_entity_at(Vector2i(4, 8)) != null or preview.world.get_entity_at(Vector2i(5, 8)) != null:
		printerr("the completed 加油 prompt clears before its next typewriter loop")
		preview.queue_free()
		quit(1)
		return
	preview.queue_free()
	print("glove like prompt tests passed")
	quit(0)
