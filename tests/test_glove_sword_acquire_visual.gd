extends SceneTree

const GlovePreviewScene = preload("res://levels/glove/glove_preview.tscn")
const GloveEffects = preload("res://scripts/levels/glove/glove_effects.gd")
const GloveLayouts = preload("res://scripts/levels/glove/glove_layouts.gd")

func _init() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var preview = GlovePreviewScene.instantiate()
	root.add_child(preview)
	await process_frame
	var sword_effect: Dictionary = GloveEffects._toggle_sword_anchor_effect()
	var acquire_effect: Dictionary = sword_effect.condition.then
	var acquire_visual: Dictionary = acquire_effect.get("visual_effect", {})
	if acquire_effect.has("spawn") or acquire_visual.get("type", "") != "sword_acquire" or acquire_visual.get("from_grid", Vector2i.ZERO) != GloveLayouts.SWORD_LEFT_POS:
		_fail(preview, "the sword rule must remove the source word instead of spawning it at the right anchor")
		return
	if not preview.has_method("_play_sword_acquire"):
		_fail(preview, "the glove preview must provide the sword acquire animation")
		return
	preview.world.load_level({
		"screen_size": Vector2i(32, 18),
		"bounded": true,
		"player_start": Vector2i(5, 5),
		"player_text": "我",
		"rows": []
	})
	preview._player_visual_ready = false
	preview._refresh_view()
	preview._play_sword_acquire({"from_grid": Vector2i(4, 5)})
	var sword_word = preview.get_node_or_null("MapLayer/SwordAcquireWord")
	if sword_word == null or sword_word.position != preview._grid_to_pixels(Vector2i(4, 5)) or sword_word.z_index >= preview.player_label.z_index:
		_fail(preview, "the acquired sword must start in its source cell below the player layer")
		return
	await create_timer(0.5).timeout
	if is_instance_valid(sword_word):
		_fail(preview, "the acquired sword must disappear after moving under the player")
		return
	preview.queue_free()
	print("glove sword acquire visual tests passed")
	quit(0)

func _fail(preview, message: String) -> void:
	printerr(message)
	preview.queue_free()
	quit(1)
