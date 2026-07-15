extends SceneTree

const GlovePreviewScene = preload("res://levels/glove/glove_preview.tscn")
const DIALOGUE_POS := Vector2i(1, 8)
const DIALOGUE_LIKE := "勇：加油！"
const LOOP_FIRST_CELL := Vector2i(3, 8)

func _init() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var preview = GlovePreviewScene.instantiate()
	root.add_child(preview)
	await process_frame
	_load_brave_loop(preview)
	var brave_prefix = preview.world.get_entity_at(Vector2i(24, 5))
	var brave_word = preview.world.get_entity_at(Vector2i(24, 6))
	if brave_prefix == null or brave_prefix.text != "：" or brave_word == null or brave_word.text != "来":
		_fail(preview, "the brave prompt must keep 勇： fixed and begin its 来吧 loop below the prefix")
		return
	if preview.world.player_pos != Vector2i(24, 7):
		_fail(preview, "the brave loop must push the player downward when the fixed brave word occupies the upper cell")
		return
	preview.brave_loop_prompt.frame_index = preview.brave_loop_prompt.text.length()
	preview._sync_brave_loop_prompt()
	if preview.world.get_entity_at(Vector2i(24, 6)) != null or preview.world.get_entity_at(Vector2i(24, 7)) != null or preview.world.get_entity_at(Vector2i(24, 5)) == null:
		_fail(preview, "clearing the brave loop must release 来吧 while keeping the fixed prefix")
		return
	_load_like_loop(preview, LOOP_FIRST_CELL, false)
	var first_word = preview.world.get_entity_at(LOOP_FIRST_CELL)
	if first_word == null or first_word.text != "加":
		_fail(preview, "a visible loop character must occupy its own solid grid cell")
		return
	if preview.world.player_pos != LOOP_FIRST_CELL + Vector2i.UP:
		_fail(preview, "a loop character must push a player above its cell upward when that cell is free")
		return
	preview.like_loop_prompt.frame_index = preview.like_loop_prompt.text.length()
	preview._sync_like_loop_prompt()
	if preview.world.get_entity_at(LOOP_FIRST_CELL) != null:
		_fail(preview, "a cleared loop character must release its grid cell")
		return
	_load_like_loop(preview, LOOP_FIRST_CELL, true)
	if preview.world.player_pos != LOOP_FIRST_CELL + Vector2i.DOWN:
		_fail(preview, "a loop character must push the player downward when the upper cell is occupied")
		return
	preview.queue_free()
	print("glove loop prompt entity tests passed")
	quit(0)

func _load_like_loop(preview, player_pos: Vector2i, block_above: bool) -> void:
	var initial_spawn: Array[Dictionary] = [
		{"text": DIALOGUE_LIKE, "pos": DIALOGUE_POS, "config": {"solid": false}}
	]
	if block_above:
		initial_spawn.append({"text": "墙", "pos": player_pos + Vector2i.UP, "config": {"solid": true}})
	preview.world.load_level({
		"screen_size": Vector2i(32, 18),
		"bounded": true,
		"player_start": player_pos,
		"player_text": "我",
		"rows": [],
		"initial_spawn": initial_spawn
	})
	preview.like_loop_prompt.frame_index = 0
	preview.like_loop_prompt.elapsed = 0.0
	preview._player_visual_ready = false
	preview._refresh_view()

func _load_brave_loop(preview) -> void:
	preview.world.load_level({
		"screen_size": Vector2i(32, 18),
		"bounded": true,
		"player_start": Vector2i(24, 6),
		"player_text": "我",
		"rows": [],
		"initial_spawn": [{"text": "勇", "pos": Vector2i(24, 4), "config": {"solid": true}}]
	})
	preview.brave_loop_prompt.frame_index = 0
	preview.brave_loop_prompt.elapsed = 0.0
	preview._player_visual_ready = false
	preview._refresh_view()

func _fail(preview, message: String) -> void:
	printerr(message)
	preview.queue_free()
	quit(1)
