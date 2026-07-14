extends RefCounted

var _sticky_switches: Dictionary = {}
var _sticky_variables: Dictionary = {}
var _last_state := {
	"switches": {},
	"variables": {}
}

func reset() -> void:
	_sticky_switches.clear()
	_sticky_variables.clear()
	_last_state = {
		"switches": {},
		"variables": {}
	}

func get_state() -> Dictionary:
	return {
		"switches": _last_state.get("switches", {}).duplicate(true),
		"variables": _last_state.get("variables", {}).duplicate(true)
	}

func evaluate(entities: Dictionary, sentence_rules: Dictionary, get_entity_at: Callable) -> Dictionary:
	var matches := {}
	var highlighted: Array[Vector2i] = []
	var transient_switches: Dictionary = {}
	var transient_variables: Dictionary = {}
	for sentence_key in sentence_rules.keys():
		var sentence := str(sentence_key)
		var config: Dictionary = sentence_rules[sentence_key]
		var direction := str(config.get("direction", "horizontal"))
		var cells := _find_sentence_cells(sentence, direction, entities, get_entity_at)
		if cells.is_empty():
			continue
		matches[sentence] = {
			"message": str(config.get("message", "")),
			"cells": cells,
			"config": config
		}
		highlighted.append_array(cells)
		if bool(config.get("persist_state_on_miss", false)):
			_apply_assignments(_sticky_switches, config.get("set_switches", {}))
			_apply_assignments(_sticky_variables, config.get("set_variables", {}))
		else:
			_apply_assignments(transient_switches, config.get("set_switches", {}))
			_apply_assignments(transient_variables, config.get("set_variables", {}))
	var switches := _sticky_switches.duplicate(true)
	var variables := _sticky_variables.duplicate(true)
	_apply_assignments(switches, transient_switches)
	_apply_assignments(variables, transient_variables)
	_last_state = {
		"switches": switches,
		"variables": variables
	}
	return {
		"matches": matches,
		"highlighted_cells": highlighted,
		"state": get_state()
	}

func _apply_assignments(target: Dictionary, assignments) -> void:
	var values: Dictionary = assignments if assignments is Dictionary else {}
	for key in values.keys():
		target[str(key)] = values[key]

func _find_sentence_cells(sentence: String, direction: String, entities: Dictionary, get_entity_at: Callable) -> Array[Vector2i]:
	var step := Vector2i.RIGHT
	if direction == "vertical":
		step = Vector2i.DOWN
	for entity in entities.values():
		for cell in entity.cells:
			var cells := _match_from_cell(sentence, cell, step, get_entity_at)
			if not cells.is_empty():
				return cells
	return []

func _match_from_cell(sentence: String, start: Vector2i, step: Vector2i, get_entity_at: Callable) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for index in range(sentence.length()):
		var pos := start + (step * index)
		var entity = get_entity_at.call(pos)
		if entity == null:
			return []
		if _char_at_cell(entity, pos) != sentence.substr(index, 1):
			return []
		cells.append(pos)
	return cells

func _char_at_cell(entity, pos: Vector2i) -> String:
	var cell_index: int = entity.cells.find(pos)
	if cell_index < 0 or cell_index >= entity.text.length():
		return ""
	return entity.text.substr(cell_index, 1)
