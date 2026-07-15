extends SceneTree

const GlovePreviewScene = preload("res://levels/glove/glove_preview.tscn")
const REVIEWED_GLOVE_FONT = preload("res://Fonts/Zpix.tres")
const REVIEWED_GLOVE_FONT_SIZE := 54

func _init() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var preview = GlovePreviewScene.instantiate()
	root.add_child(preview)
	await process_frame
	if not _all_labels_use_reviewed_font(preview):
		preview.queue_free()
		quit(1)
		return
	preview._start_hero_quote()
	preview._advance_hero_quote(10.0)
	if not _all_labels_use_reviewed_font(preview):
		preview.queue_free()
		quit(1)
		return
	preview.queue_free()
	print("glove font consistency tests passed")
	quit(0)

func _all_labels_use_reviewed_font(node: Node) -> bool:
	if node is Label:
		if node.get_theme_font("font") != REVIEWED_GLOVE_FONT:
			printerr("all glove preview text must use Fonts/Zpix.tres; mismatched node: %s" % node.name)
			return false
		if node.name != "DemoStatus" and node.get_theme_font_size("font_size") != REVIEWED_GLOVE_FONT_SIZE:
			printerr("all visible glove gameplay text must use the reviewed 54px style; mismatched node: %s" % node.name)
			return false
	for child in node.get_children():
		if not _all_labels_use_reviewed_font(child):
			return false
	return true
