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
		_fail(preview, "confirming the 4397号勇者 page must clear it and start the hero encroachment")
		return
	preview.world.apply_preview_effect(next_effect)
	preview._consume_visual_effect_request()
	if preview.acquisition_dialogue_label.visible or preview.acquisition_tutorial_label.visible or preview.map_layer.visible:
		_fail(preview, "the hero encroachment must clear existing tutorial, dialogue, and map content")
		return
	if not preview.hero_encroach_active or preview.hero_encroach_units.size() != 32:
		_fail(preview, "the first wave must place every other 勇 on the top, left, and right outer border")
		return
	for unit in preview.hero_encroach_units:
		var cell: Vector2i = unit.cell
		if cell.y != 0 and cell.x != 0 and cell.x != 31:
			_fail(preview, "the first wave must only begin on the top, left, and right outer border")
			return
	var initial_top: int = preview.hero_encroach_units.filter(func(unit): return Vector2i(unit.cell).y == 0).size()
	if initial_top != 16:
		_fail(preview, "the first top row must use every other grid cell")
		return
	for _step in range(240):
		preview._advance_hero_encroach(0.1)
	if preview.hero_encroach_active or not preview.hero_encroach_completed:
		_fail(preview, "the three waves must finish on a held final wall state")
		return
	var final_cells: Array[Vector2i] = preview._hero_encroach_final_wall_cells()
	if preview.hero_encroach_units.size() != final_cells.size():
		_fail(preview, "the final state must fill every cell of the three-sided five-column wall exactly once")
		return
	var occupied := {}
	for unit in preview.hero_encroach_units:
		occupied[unit.cell] = true
	for cell in final_cells:
		if not occupied.has(cell):
			_fail(preview, "the final wall has a missing 勇 cell")
			return
	if not preview.world.player_input_locked or not preview.hero_encroach_root.visible:
		_fail(preview, "the completed hero wall must remain visible with player input locked")
		return
	preview.queue_free()
	print("glove hero encroachment tests passed")
	quit(0)

func _fail(preview, message: String) -> void:
	printerr(message)
	preview.queue_free()
	quit(1)
