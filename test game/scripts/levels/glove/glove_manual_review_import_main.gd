extends SceneTree

const GloveManualReviewImporter = preload("res://scripts/levels/glove/glove_manual_review_importer.gd")

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("Usage: Godot --headless --path <newgame> -s res://scripts/levels/glove/glove_manual_review_import_main.gd -- <input_review.json> [output_override.json]")
		quit(1)
		return
	var input_path := args[0]
	var output_path := GloveManualReviewImporter.DEFAULT_OUTPUT_PATH
	if args.size() >= 2:
		output_path = args[1]
	var importer := GloveManualReviewImporter.new()
	var result := importer.import_review_result(input_path, output_path)
	if not bool(result.get("success", false)):
		printerr(str(result.get("message", "import failed")))
		quit(1)
		return
	print(JSON.stringify(result, "\t"))
	quit(0)
