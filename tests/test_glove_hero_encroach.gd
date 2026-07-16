extends SceneTree

const GlovePreviewScene = preload("res://levels/glove/glove_preview.tscn")
const GloveEffects = preload("res://scripts/levels/glove/glove_effects.gd")

func _init() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var preview = GlovePreviewScene.instantiate()
	root.add_child(preview)
	await process_frame
	var page_three: Dictionary = GloveEffects._transition_dialogue_page_three()
	var next_effect: Dictionary = page_three.get("set_pending_interact_effect", {})
	if next_effect.get("visual_effect", {}).get("type", "") != "hero_encroach":
		_fail(preview, "confirming the 4397 hero page must start the hero encroachment")
		return
	preview.world.apply_preview_effect(next_effect)
	preview._consume_visual_effect_request()
	if preview.acquisition_dialogue_label.visible or preview.acquisition_tutorial_label.visible or preview.map_layer.visible:
		_fail(preview, "the hero encroachment must clear existing tutorial, dialogue, and map content")
		return
	if not preview.hero_encroach_active or not preview.hero_encroach_source_mode:
		_fail(preview, "the formal hero encroachment must use the source-restored sequence")
		return
	await process_frame
	if preview.hero_encroach_units.size() != 28:
		_fail(preview, "the source-restored first stage must spawn the original 28 hero words")
		return
	var has_source_route := false
	for unit in preview.hero_encroach_units:
		if unit.has("groups") and Array(unit.groups).has("up1"):
			has_source_route = true
			break
	if not has_source_route:
		_fail(preview, "the source-restored first stage must keep original source route groups")
		return
	await create_timer(11.0).timeout
	if preview.hero_encroach_active or not preview.hero_encroach_completed:
		_fail(preview, "the source-restored sequence must finish on a held final wall state")
		return
	var occupied := {}
	for unit in preview.hero_encroach_units:
		var label: Label = unit.label
		if is_instance_valid(label):
			occupied[preview._hero_encroach_label_cell(label)] = true
	for required_cell in [Vector2i(0, 2), Vector2i(13, 2), Vector2i(18, 2), Vector2i(31, 2)]:
		if not occupied.has(required_cell):
			_fail(preview, "the source-restored postprocess must preserve the top-side anchor cells")
			return
	for filled_cell in [Vector2i(0, 12), Vector2i(4, 12), Vector2i(27, 12), Vector2i(31, 12)]:
		if not occupied.has(filled_cell):
			_fail(preview, "the source-restored postprocess must fade in the outer side-wall gaps")
			return
	for cleared_cell in [Vector2i(5, 12), Vector2i(6, 12), Vector2i(25, 12), Vector2i(26, 12)]:
		if occupied.has(cleared_cell):
			_fail(preview, "the source-restored postprocess must fade out the inner side-wall columns")
			return
	if preview.hero_encroach_root.get_node_or_null("HeroEncroachFinalMessage") == null:
		_fail(preview, "the source-restored ending must typewrite the final message")
		return
	if not preview.world.player_input_locked or not preview.hero_encroach_root.visible:
		_fail(preview, "the completed hero wall must remain visible with player input locked")
		return
	await create_timer(2.0).timeout
	if not preview.hero_encroach_epilogue_active:
		_fail(preview, "the completed hero wall must continue into the movable epilogue")
		return
	preview.queue_free()
	print("glove hero encroachment source-restored tests passed")
	quit(0)

func _fail(preview, message: String) -> void:
	printerr(message)
	preview.queue_free()
	quit(1)
