extends RefCounted

const KEY_INFO_EMPHASIS := "key_info_emphasis"

static func effect(mode: String, tree_cells: Array, bridge_cells: Array) -> Dictionary:
	return {
		"type": "bridge_tree_transition",
		"mode": mode,
		"tree_cells": tree_cells.duplicate(),
		"bridge_cells": bridge_cells.duplicate(),
		"tree_fade_duration": 0.7,
		"creek_fade_duration": 0.5,
		"tree_fade_in_duration": 0.8,
		"bridge_step_delay": 0.16,
		"bridge_fade_duration": 0.32
	}

static func merge_effect(tree_cells: Array, bridge_cells: Array, before_effect: Dictionary = {}, creek_fade_cells: Array = []) -> Dictionary:
	var merge_visual := effect("merge", tree_cells, bridge_cells)
	merge_visual["reverse_split"] = true
	if not before_effect.is_empty():
		merge_visual["before_effect"] = before_effect.duplicate(true)
	if not creek_fade_cells.is_empty():
		merge_visual["creek_fade_cells"] = creek_fade_cells.duplicate()
	return merge_visual

static func key_info_emphasis(cells: Array) -> Dictionary:
	return {
		"type": KEY_INFO_EMPHASIS,
		"cells": cells.duplicate(),
		"fade_in_duration": 0.24,
		"duration": 1.0
	}

static func split_effect(tree_cells: Array, bridge_cells: Array, delayed_water_cells: Array = []) -> Dictionary:
	var split_visual := effect("split", tree_cells, bridge_cells)
	split_visual["reveal_texts"] = ["溪", "树", "木"]
	split_visual["delayed_water_cells"] = delayed_water_cells.duplicate()
	return split_visual

static func relocate_effect(source_cells: Array, target_cells: Array, deferred_remove_at: Array, deferred_spawn: Array) -> Dictionary:
	return {
		"type": "bridge_tree_relocate",
		"source_cells": source_cells.duplicate(),
		"target_cells": target_cells.duplicate(),
		"deferred_remove_at": deferred_remove_at.duplicate(),
		"deferred_spawn": deferred_spawn.duplicate(true),
		"fade_out_duration": 0.55,
		"fade_in_duration": 0.4
	}
