extends RefCounted

const LEVEL_NAME := "四目头盔 过河第二关"
const BridgeTreeVisuals = preload("res://levels/helmet/bridge_tree_visuals.gd")
const WordSplitVisuals = preload("res://scripts/word_split_visuals.gd")

static func build_level() -> Dictionary:
	return {
		"name": LEVEL_NAME,
		"screen_size": Vector2i(32, 18),
		"bounded": true,
		"player_start": Vector2i(6, 4),
		"player_facing": Vector2i(1, 0),
		"cell_entity_configs": {
			Vector2i(14, 3): {"pushable": true},
			Vector2i(15, 3): {"pushable": true, "interact_text": ""}
		},
		"rows": [
			"                     溪溪溪溪溪      ",
			"                     溪溪溪溪溪      ",
			"                     溪溪溪溪溪      ",
			"  一条溪水阻挡前路。旁边的乔木     溪溪溪溪溪      ",
			"  很好用， 感觉应该帮得上忙。     溪溪溪溪溪      ",
			"                     溪溪溪溪溪      ",
			"                     溪溪溪溪溪      ",
			"                     溪溪溪溪溪      ",
			"                   树 溪溪溪溪溪      ",
			"                  树树树溪溪溪溪溪      ",
			"                   木 溪溪溪溪溪      ",
			"                     溪溪溪溪溪      ",
			"                     溪溪溪溪溪      ",
			"                  溪溪溪溪溪溪溪溪      ",
			"                 溪溪溪溪溪溪溪溪溪      ",
			"                 溪溪溪溪溪溪溪溪       ",
			"                 溪溪溪溪溪          ",
			"                 溪溪溪溪溪          "
		],
		"entities": {
			"溪": {
				"solid": true,
				"interact_text": "无法跨越的湍急野溪，必须更努力造出路来。",
				"interact_effect": _creek_interact_effect()
			},
			"树": {
				"solid": true,
				"interact_text": "这乔木看起来很好用，小心点肯定帮得上忙。",
				"interact_caption_lines": ["这乔木看起来很好用，", "小心点肯定帮得上忙。"],
				"interact_caption_pos": Vector2i(2, 6),
				"interact_caption_solid": true
			},
			"木": {
				"solid": true,
				"interact_text": "这乔木看起来很好用，小心点肯定帮得上忙。",
				"interact_caption_lines": ["这乔木看起来很好用，", "小心点肯定帮得上忙。"],
				"interact_caption_pos": Vector2i(2, 6),
				"interact_caption_solid": true
			},
			"桥": {
				"solid": true,
				"pushable": true,
				"splittable": true
			}
		},
		"split_rules": {
			"桥": ["乔", "木"],
			"三": ["一", "二"]
		},
		"merge_rules": {
			"乔+木": "桥",
			"木+乔": "桥",
			"二+一": "三",
			"一+二": "三"
		},
		"merge_effects": {
			"乔+木": _bridge_merge_effect(),
			"木+乔": _bridge_merge_effect(),
			"二+一": _distance_solved_effect(),
			"一+二": _distance_solved_effect()
		},
		"split_effects": {
			"桥": _restore_initial_effect(),
			"三": _distance_unsolved_effect()
		}
	}

static func _tree_cells() -> Array[Vector2i]:
	return [
		Vector2i(19, 8),
		Vector2i(18, 9),
		Vector2i(19, 9),
		Vector2i(20, 9),
		Vector2i(19, 10)
	]

static func _creek_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(0, 13):
		for x in range(21, 26):
			cells.append(Vector2i(x, y))
	for x in range(18, 26):
		cells.append(Vector2i(x, 13))
	for x in range(17, 26):
		cells.append(Vector2i(x, 14))
	for x in range(17, 25):
		cells.append(Vector2i(x, 15))
	for y in [16, 17]:
		for x in range(17, 22):
			cells.append(Vector2i(x, y))
	return cells

static func _creek_cells_for_bridge(offset := 0) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var all_creek := _creek_cells()
	for cell in _bridge_cells(offset):
		if all_creek.has(cell) and not cells.has(cell):
			cells.append(cell)
	for x in range(20 + offset, 27 + offset):
		var road_cell := Vector2i(x, 9)
		if all_creek.has(road_cell) and not cells.has(road_cell):
			cells.append(road_cell)
	return cells

static func _bridge_cells(offset := 0) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [Vector2i(19 + offset, 7), Vector2i(27 + offset, 7)]
	for y in [8, 10]:
		for x in range(20 + offset, 27 + offset):
			cells.append(Vector2i(x, y))
	cells.append(Vector2i(19 + offset, 11))
	cells.append(Vector2i(27 + offset, 11))
	return cells

static func _all_dynamic_cells() -> Array[Vector2i]:
	var cells := _river_dynamic_cells()
	cells.append_array(_text_block_cells())
	return cells

static func _river_dynamic_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.append_array(_tree_cells())
	cells.append_array(_creek_cells())
	cells.append_array(_bridge_cells(-3))
	cells.append_array(_bridge_cells(0))
	cells.append_array(_bridge_cells(3))
	return cells

static func _text_block_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for text_config in _phase_one_text():
		cells.append_array(_occupied_text_cells(text_config))
	for text_config in _phase_two_text():
		cells.append_array(_occupied_text_cells(text_config))
	for text_config in _phase_one_text_without_distance_parts():
		cells.append_array(_occupied_text_cells(text_config))
	for text_config in _creek_hint_text():
		cells.append_array(_occupied_text_cells(text_config))
	return cells

static func _occupied_text_cells(text_config: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var text := str(text_config.get("text", ""))
	var pos: Vector2i = text_config.get("pos", Vector2i.ZERO)
	for i in range(text.length()):
		if text.substr(i, 1) != " ":
			var cell := pos + Vector2i(i, 0)
			if not cells.has(cell):
				cells.append(cell)
	return cells

static func _phase_one_text() -> Array[Dictionary]:
	return [
		{"text": "这桥 肯定帮得上忙。", "pos": Vector2i(2, 6), "as_chars": true, "config": {"solid": true}},
		{
			"text": "再往溪流靠近一大步，",
			"pos": Vector2i(2, 7),
			"as_chars": true,
			"config": {"solid": true},
			"cell_configs": {6: {"solid": true, "pushable": true}}
		},
		{
			"text": "离对岸就剩约二十尺。",
			"pos": Vector2i(2, 8),
			"as_chars": true,
			"config": {"solid": true},
			"cell_configs": {6: {"solid": true, "pushable": true}}
		},
		{"text": "搞定距离即解决问题。", "pos": Vector2i(2, 10), "as_chars": true, "config": {"solid": true}}
	]

static func _phase_two_text() -> Array[Dictionary]:
	return [
		{"text": "这桥 肯定帮得上忙。", "pos": Vector2i(2, 6), "as_chars": true, "config": {"solid": true}},
		{
			"text": "再往溪流靠近三大步，",
			"pos": Vector2i(2, 7),
			"as_chars": true,
			"config": {"solid": true},
			"cell_configs": {
				6: {
					"solid": true,
					"pushable": true,
					"splittable": true,
					"split_positions": [Vector2i(8, 7), Vector2i(8, 8)]
				}
			}
		},
		{"text": "离对岸就剩约 十尺。", "pos": Vector2i(2, 8), "as_chars": true, "config": {"solid": true}},
		{"text": "搞定距离即解决问题。", "pos": Vector2i(2, 10), "as_chars": true, "config": {"solid": true}}
	]

static func _phase_one_text_without_distance_parts() -> Array[Dictionary]:
	return [
		{"text": "这桥 肯定帮得上忙。", "pos": Vector2i(2, 6), "as_chars": true, "config": {"solid": true}},
		{"text": "再往溪流靠近 大步，", "pos": Vector2i(2, 7), "as_chars": true, "config": {"solid": true}},
		{"text": "离对岸就剩约 十尺。", "pos": Vector2i(2, 8), "as_chars": true, "config": {"solid": true}},
		{"text": "搞定距离即解决问题。", "pos": Vector2i(2, 10), "as_chars": true, "config": {"solid": true}}
	]

static func _creek_hint_text() -> Array[Dictionary]:
	return [
		{"text": "无法跨越的湍急野溪，", "pos": Vector2i(2, 12), "as_chars": true, "config": {"solid": true}},
		{"text": "必须更努力造出路来。", "pos": Vector2i(2, 13), "as_chars": true, "config": {"solid": true}}
	]

static func _creek_hint_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for text_config in _creek_hint_text():
		cells.append_array(_occupied_text_cells(text_config))
	return cells

static func _bridge_spawn(offset := 0, extra_config := {}) -> Array[Dictionary]:
	var spawn: Array[Dictionary] = []
	var base_config := {
		"solid": true,
		"pushable": false,
		"splittable": false
	}
	for key in extra_config.keys():
		base_config[key] = extra_config[key]
	for cell in _bridge_cells(offset):
		spawn.append({"text": "桥", "pos": cell, "config": base_config.duplicate()})
	return spawn

static func _creek_remainder_spawn(offset := 0) -> Array[Dictionary]:
	var spawn: Array[Dictionary] = []
	var cleared_cells := _creek_cells_for_bridge(offset)
	for cell in _creek_cells():
		if not cleared_cells.has(cell):
			spawn.append({"text": "溪", "pos": cell})
	return spawn

static func _creek_and_tree_spawn() -> Array[Dictionary]:
	var spawn: Array[Dictionary] = []
	for cell in _creek_cells():
		spawn.append({"text": "溪", "pos": cell})
	spawn.append({"text": "树", "pos": Vector2i(19, 8)})
	spawn.append({"text": "树", "pos": Vector2i(18, 9)})
	spawn.append({"text": "树", "pos": Vector2i(19, 9)})
	spawn.append({"text": "树", "pos": Vector2i(20, 9)})
	spawn.append({"text": "木", "pos": Vector2i(19, 10)})
	return spawn

static func _phase_one_bridge_interact_effect() -> Dictionary:
	return {
		"remove_at": _text_block_cells(),
		"spawn_text": _phase_one_text()
	}

static func _creek_interact_effect() -> Dictionary:
	return {
		"remove_at": _creek_hint_cells(),
		"spawn_text": _creek_hint_text()
	}

static func _hint_bridge_merge_replace() -> Dictionary:
	return {
		"from": "乔",
		"to": "桥",
		"pos": Vector2i(3, 6),
		"config": {"solid": true},
		"remove_on_replace": [Vector2i(4, 6)]
	}

static func _hint_bridge_split_replace() -> Dictionary:
	return {
		"from": "桥",
		"to": "乔",
		"pos": Vector2i(3, 6),
		"config": {"solid": true},
		"spawn_on_replace": [
			{"text": "木", "pos": Vector2i(4, 6), "config": {"solid": true}}
		]
	}

static func _phase_one_bridge_spawn(include_text_effect := true) -> Array[Dictionary]:
	var bridge_config := {}
	if include_text_effect:
		bridge_config = {
			"interact_text": "这桥肯定帮得上忙。再往溪流靠近一大步，离对岸就剩约二十尺。搞定距离即解决问题。",
			"interact_effect": _phase_one_bridge_interact_effect()
		}
	return _bridge_spawn(-3, bridge_config)

static func _bridge_merge_effect() -> Dictionary:
	return {
		"condition": {
			"pos": Vector2i(8, 7),
			"text": "三",
			"then": _bridge_phase_two_remerge_effect(),
			"else": _bridge_phase_one_effect()
		}
	}

static func _bridge_phase_one_effect() -> Dictionary:
	var spawn := _creek_remainder_spawn(-3)
	spawn.append_array(_phase_one_bridge_spawn())
	return {
		"remove_at": _river_dynamic_cells(),
		"visual_effect": BridgeTreeVisuals.merge_effect(_tree_cells(), _bridge_cells(-3), {}, _creek_cells_for_bridge(-3)),
		"replace_text": [_hint_bridge_merge_replace()],
		"spawn": spawn
	}

static func _bridge_phase_two_remerge_effect() -> Dictionary:
	var spawn := _creek_remainder_spawn(0)
	spawn.append_array(_bridge_spawn(0))
	return {
		"remove_at": _river_dynamic_cells(),
		"visual_effect": BridgeTreeVisuals.merge_effect(_tree_cells(), _bridge_cells(0), {}, _creek_cells_for_bridge(0)),
		"replace_text": [_hint_bridge_merge_replace()],
		"spawn": spawn
	}

static func _distance_unsolved_effect() -> Dictionary:
	var spawn := _creek_remainder_spawn(-3)
	spawn.append_array(_phase_one_bridge_spawn())
	return {
		"remove_at": _all_dynamic_cells(),
		"spawn": spawn,
		"spawn_text": _phase_one_text_without_distance_parts()
	}

static func _distance_solved_effect() -> Dictionary:
	var spawn := _creek_remainder_spawn(0)
	spawn.append_array(_bridge_spawn(0))
	return {
		"remove_at": _all_dynamic_cells(),
		"visual_effect": BridgeTreeVisuals.key_info_emphasis([
			Vector2i(7, 7),
			Vector2i(8, 7),
			Vector2i(9, 7),
			Vector2i(10, 7)
		]),
		"spawn": spawn,
		"spawn_text": _phase_two_text()
	}

static func _restore_initial_effect() -> Dictionary:
	return {
		"condition": {
			"pos": Vector2i(8, 7),
			"text": "三",
			"then": _restore_initial_effect_at(0),
			"else": _restore_initial_effect_at(-3)
		}
	}

static func _restore_initial_effect_at(offset: int) -> Dictionary:
	return {
		"remove_at": _river_dynamic_cells(),
		"visual_effects": [
			BridgeTreeVisuals.split_effect(
				_tree_cells(),
				_bridge_cells(offset),
				_creek_cells_for_bridge(offset)
			),
			WordSplitVisuals.effect("桥", ["乔", "木"])
		],
		"replace_text": [_hint_bridge_split_replace()],
		"spawn": _creek_and_tree_spawn()
	}
