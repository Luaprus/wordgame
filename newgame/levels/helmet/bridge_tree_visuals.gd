extends RefCounted

static func effect(mode: String, tree_cells: Array, bridge_cells: Array) -> Dictionary:
	return {
		"type": "bridge_tree_transition",
		"mode": mode,
		"tree_cells": tree_cells.duplicate(),
		"bridge_cells": bridge_cells.duplicate(),
		"tree_fade_duration": 0.7,
		"tree_fade_in_duration": 0.8,
		"bridge_step_delay": 0.16,
		"bridge_fade_duration": 0.32
	}

static func merge_effect(tree_cells: Array, bridge_cells: Array) -> Dictionary:
	return effect("merge", tree_cells, bridge_cells)

static func split_effect(tree_cells: Array, bridge_cells: Array, delayed_water_cells: Array = []) -> Dictionary:
	var split_visual := effect("split", tree_cells, bridge_cells)
	split_visual["reveal_texts"] = ["溪", "树", "木"]
	split_visual["delayed_water_cells"] = delayed_water_cells.duplicate()
	return split_visual
