extends RefCounted

const LEVEL_NAME := "四目头盔 过河第三关"
const BridgeTreeVisuals = preload("res://levels/helmet/bridge_tree_visuals.gd")
const LOOSE_BRIDGE_SHAKE_AMPLITUDE := 1.5
const LOOSE_BRIDGE_SHAKE_SPEED := TAU * 1.35
const LOOSE_BRIDGE_CORNER_INDICES := [0, 1, 16, 17]
const BRIDGE_COLLAPSE_PLAYER_CELL := Vector2i(23, 9)

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
				"interact_text": "无法跨越的湍急野溪，而桥下的乱石河水难撑得起沉甸甸的重量。",
				"interact_effect": _creek_interact_effect()
			},
			"树": {
				"solid": true,
				"interact_text": "这乔木看起来很好用，感觉应该帮得上忙。",
				"interact_effect": _tree_interact_effect()
			},
			"木": {
				"solid": true,
				"interact_text": "这乔木看起来很好用，感觉应该帮得上忙。",
				"interact_effect": _tree_interact_effect()
			},
			"桥": {"solid": true, "pushable": true, "splittable": true},
			"滩": {"solid": true, "pushable": true, "splittable": true}
		},
		"split_rules": {
			"桥": ["乔", "木"],
			"滩": ["水", "难"]
		},
		"merge_rules": {
			"乔+木": "桥",
			"木+乔": "桥",
			"水+难": "滩",
			"难+水": "滩"
		},
		"merge_effects": {
			"乔+木": _bridge_merge_effect(),
			"木+乔": _bridge_merge_effect(),
			"水+难": _shore_merge_effect(),
			"难+水": _shore_merge_effect()
		},
		"split_effects": {
			"桥": _bridge_split_effect(),
			"滩": _shore_split_effect()
		},
		"step_effects": [
			{
				"pos": BRIDGE_COLLAPSE_PLAYER_CELL,
				"condition": {"absent_text_at": {"pos": Vector2i(10, 10), "text": "滩"}},
				"delay_seconds": 0.35,
				"lock_input": true,
				"effect": _bridge_collapse_effect()
			}
		]
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

static func _creek_cells_for_bridge() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var all_creek := _creek_cells()
	for cell in _bridge_cells():
		if all_creek.has(cell) and not cells.has(cell):
			cells.append(cell)
	for x in range(20, 27):
		var road_cell := Vector2i(x, 9)
		if all_creek.has(road_cell) and not cells.has(road_cell):
			cells.append(road_cell)
	return cells

static func _bridge_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = [Vector2i(19, 7), Vector2i(27, 7)]
	for y in [8, 10]:
		for x in range(20, 27):
			cells.append(Vector2i(x, y))
	cells.append(Vector2i(19, 11))
	cells.append(Vector2i(27, 11))
	return cells

static func _bridge_collapse_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in [8, 10]:
		for x in range(21, 26):
			cells.append(Vector2i(x, y))
	return cells

static func _river_dynamic_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.append_array(_tree_cells())
	cells.append_array(_creek_cells())
	cells.append_array(_bridge_cells())
	return cells

static func _all_dynamic_cells() -> Array[Vector2i]:
	var cells := _river_dynamic_cells()
	cells.append_array(_hint_text_cells())
	cells.append_array(_fall_prompt_cells())
	return cells

static func _hint_text_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for text_config in _tree_hint_text():
		cells.append_array(_occupied_text_cells(text_config))
	for text_config in _bridge_hint_text():
		cells.append_array(_occupied_text_cells(text_config))
	for text_config in _creek_hint_text():
		cells.append_array(_occupied_text_cells(text_config))
	for text_config in _creek_hint_text_without_water_parts():
		cells.append_array(_occupied_text_cells(text_config))
	return cells

static func _creek_hint_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for text_config in _creek_hint_text():
		cells.append_array(_occupied_text_cells(text_config))
	for text_config in _creek_hint_text_without_water_parts():
		cells.append_array(_occupied_text_cells(text_config))
	return cells

static func _creek_hint_cells_except_shore() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in _creek_hint_cells():
		if cell != Vector2i(10, 10):
			cells.append(cell)
	return cells

static func _fall_prompt_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for text_config in _fall_prompt_text():
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

static func _bridge_hint_text() -> Array[Dictionary]:
	return [
		{"text": "这桥 看起来很好用，", "pos": Vector2i(2, 6), "as_chars": true, "config": {"solid": true}},
		{"text": "小心点肯定帮得上忙。", "pos": Vector2i(2, 7), "as_chars": true, "config": {"solid": true}}
	]

static func _tree_hint_text() -> Array[Dictionary]:
	return [
		{"text": "这乔木看起来很好用，", "pos": Vector2i(2, 6), "as_chars": true, "config": {"solid": true}},
		{"text": "感觉应该帮得上忙。", "pos": Vector2i(2, 7), "as_chars": true, "config": {"solid": true}}
	]

static func _creek_hint_text() -> Array[Dictionary]:
	return [
		{"text": "无法跨越的湍急野溪，", "pos": Vector2i(2, 9), "as_chars": true, "config": {"solid": true}},
		{
			"text": "而桥 下的乱石河水难",
			"pos": Vector2i(2, 10),
			"as_chars": true,
			"config": {"solid": true},
			"cell_configs": {
				8: {"solid": true, "pushable": true},
				9: {"solid": true, "pushable": true}
			}
		},
		{"text": "撑得起沉甸甸的重量。", "pos": Vector2i(2, 11), "as_chars": true, "config": {"solid": true}}
	]

static func _creek_hint_text_without_water_parts() -> Array[Dictionary]:
	return [
		{"text": "无法跨越的湍急野溪，", "pos": Vector2i(2, 9), "as_chars": true, "config": {"solid": true}},
		{"text": "而桥 下的乱石河  ", "pos": Vector2i(2, 10), "as_chars": true, "config": {"solid": true}},
		{"text": "撑得起沉甸甸的重量。", "pos": Vector2i(2, 11), "as_chars": true, "config": {"solid": true}}
	]

static func _fall_prompt_text() -> Array[Dictionary]:
	return [
		{"text": "我果然成了桥的不可承受之重，", "pos": Vector2i(2, 13), "as_chars": true, "config": {"solid": true}},
		{"text": "怀着懊悔的心，在湍流中没顶。▼", "pos": Vector2i(2, 14), "as_chars": true, "config": {"solid": true}}
	]

static func _death_screen_text() -> Array[Dictionary]:
	return [
		{"text": "淹", "pos": Vector2i(23, 10), "config": {"solid": true}},
		{"text": "死", "pos": Vector2i(23, 11), "config": {"solid": true}},
		{"text": "了", "pos": Vector2i(23, 12), "config": {"solid": true}},
		{"text": "。", "pos": Vector2i(23, 14), "config": {"solid": true}}
	]

static func _straight_bridge_spawn() -> Array[Dictionary]:
	return _bridge_spawn(false)

static func _loose_bridge_spawn() -> Array[Dictionary]:
	return _bridge_spawn(true)

static func _bridge_spawn(loose := false) -> Array[Dictionary]:
	var spawn: Array[Dictionary] = []
	var rotations := [-8.0, 9.0, -6.0, 7.0, -4.0, 6.0, -9.0, 8.0, -7.0, 5.0, -5.0, 7.0, -8.0, 6.0, -6.0, 8.0]
	var index := 0
	for cell in _bridge_cells():
		var config := {"solid": true, "pushable": false, "splittable": false}
		if loose:
			config["visual_rotation_degrees"] = rotations[index % rotations.size()]
			if not LOOSE_BRIDGE_CORNER_INDICES.has(index):
				config["visual_horizontal_shake_amplitude"] = LOOSE_BRIDGE_SHAKE_AMPLITUDE
				config["visual_horizontal_shake_speed"] = LOOSE_BRIDGE_SHAKE_SPEED
				config["visual_horizontal_shake_phase"] = float(index % 4) * PI * 0.5
		spawn.append({"text": "桥", "pos": cell, "config": config})
		index += 1
	return spawn

static func _creek_remainder_spawn() -> Array[Dictionary]:
	var spawn: Array[Dictionary] = []
	var cleared_cells := _creek_cells_for_bridge()
	for cell in _creek_cells():
		if not cleared_cells.has(cell):
			spawn.append({"text": "溪", "pos": cell, "config": _creek_with_hint_config()})
	return spawn

static func _creek_spawn() -> Array[Dictionary]:
	var spawn: Array[Dictionary] = []
	for cell in _creek_cells():
		spawn.append({"text": "溪", "pos": cell})
	return spawn

static func _creek_and_tree_spawn() -> Array[Dictionary]:
	var spawn := _creek_spawn()
	spawn.append({"text": "树", "pos": Vector2i(19, 8)})
	spawn.append({"text": "树", "pos": Vector2i(18, 9)})
	spawn.append({"text": "树", "pos": Vector2i(19, 9)})
	spawn.append({"text": "树", "pos": Vector2i(20, 9)})
	spawn.append({"text": "木", "pos": Vector2i(19, 10)})
	return spawn

static func _bridge_interact_effect() -> Dictionary:
	return {
		"remove_at": _bridge_hint_variant_cells(),
		"spawn_text": _bridge_hint_text()
	}

static func _tree_interact_effect() -> Dictionary:
	return {
		"remove_at": _bridge_hint_variant_cells(),
		"spawn_text": _tree_hint_text()
	}

static func _creek_interact_effect() -> Dictionary:
	return {
		"remove_at": _creek_hint_cells(),
		"spawn_text": _creek_hint_text()
	}

static func _creek_with_hint_config() -> Dictionary:
	return {
		"interact_text": "无法跨越的湍急野溪，而桥下的乱石河水难撑得起沉甸甸的重量。",
		"interact_effect": _creek_interact_effect()
	}

static func _occupied_hint_cells(text_configs: Array[Dictionary]) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for text_config in text_configs:
		cells.append_array(_occupied_text_cells(text_config))
	return cells

static func _bridge_hint_variant_cells() -> Array[Vector2i]:
	var cells := _occupied_hint_cells(_tree_hint_text())
	cells.append_array(_occupied_hint_cells(_bridge_hint_text()))
	return cells

static func _loose_bridge_with_hint_config() -> Dictionary:
	return {
		"interact_text": "这桥松松垮垮，恐怕难承其重。",
		"interact_effect": _bridge_interact_effect()
	}

static func _hint_bridge_merge_replace() -> Dictionary:
	return {
		"from": "乔",
		"to": "桥",
		"pos": Vector2i(3, 6),
		"config": {"solid": true},
		"remove_on_replace": [Vector2i(4, 6)]
	}

static func _hint_tree_phrase_merge_replace() -> Dictionary:
	return {
		"from": "乔",
		"to": "桥",
		"pos": Vector2i(3, 6),
		"config": {"solid": true},
		"remove_on_replace": [Vector2i(4, 6)]
	}

static func _creek_hint_bridge_merge_replace() -> Dictionary:
	return {
		"from": "乔",
		"to": "桥",
		"pos": Vector2i(3, 10),
		"config": {"solid": true},
		"remove_on_replace": [Vector2i(4, 10)]
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

static func _hint_tree_phrase_split_replace() -> Dictionary:
	return {
		"from": "桥",
		"to": "乔",
		"pos": Vector2i(3, 6),
		"config": {"solid": true},
		"spawn_on_replace": [
			{"text": "木", "pos": Vector2i(4, 6), "config": {"solid": true}}
		]
	}

static func _creek_hint_bridge_split_replace() -> Dictionary:
	return {
		"from": "桥",
		"to": "乔",
		"pos": Vector2i(3, 10),
		"config": {"solid": true},
		"spawn_on_replace": [
			{"text": "木", "pos": Vector2i(4, 10), "config": {"solid": true}}
		]
	}

static func _hint_bridge_merge_replaces() -> Array[Dictionary]:
	return [_hint_bridge_merge_replace(), _hint_tree_phrase_merge_replace(), _creek_hint_bridge_merge_replace()]

static func _hint_bridge_split_replaces() -> Array[Dictionary]:
	return [_hint_bridge_split_replace(), _hint_tree_phrase_split_replace(), _creek_hint_bridge_split_replace()]

static func _bridge_merge_effect() -> Dictionary:
	return {
		"condition": {
			"pos": Vector2i(10, 10),
			"text": "滩",
			"then": _stable_bridge_effect(),
			"else": _loose_bridge_effect()
		}
	}

static func _loose_bridge_effect() -> Dictionary:
	var spawn := _creek_remainder_spawn()
	var loose_bridge := _loose_bridge_spawn()
	for entry in loose_bridge:
		var config: Dictionary = entry.config
		for key in _loose_bridge_with_hint_config().keys():
			config[key] = _loose_bridge_with_hint_config()[key]
		entry.config = config
	spawn.append_array(loose_bridge)
	return {
		"remove_at": _river_dynamic_cells(),
		"visual_effect": BridgeTreeVisuals.merge_effect(_tree_cells(), _bridge_cells()),
		"replace_text": _hint_bridge_merge_replaces(),
		"spawn": spawn
	}

static func _stable_bridge_effect() -> Dictionary:
	var spawn := _creek_remainder_spawn()
	spawn.append_array(_straight_bridge_spawn())
	return {
		"remove_at": _river_dynamic_cells(),
		"visual_effect": BridgeTreeVisuals.merge_effect(_tree_cells(), _bridge_cells()),
		"replace_text": _hint_bridge_merge_replaces(),
		"spawn": spawn
	}

static func _shore_merge_effect() -> Dictionary:
	var spawn := _creek_remainder_spawn()
	spawn.append_array(_straight_bridge_spawn())
	var remove_at := _river_dynamic_cells()
	remove_at.append_array(_creek_hint_cells_except_shore())
	return {
		"remove_at": remove_at,
		"replace_text": _hint_bridge_merge_replaces(),
		"spawn": spawn,
		"spawn_text": _creek_hint_text_without_water_parts()
	}

static func _shore_split_effect() -> Dictionary:
	var spawn := _creek_remainder_spawn()
	var loose_bridge := _loose_bridge_spawn()
	for entry in loose_bridge:
		var config: Dictionary = entry.config
		for key in _loose_bridge_with_hint_config().keys():
			config[key] = _loose_bridge_with_hint_config()[key]
		entry.config = config
	spawn.append_array(loose_bridge)
	var remove_at := _river_dynamic_cells()
	remove_at.append_array(_creek_hint_cells())
	return {
		"remove_at": remove_at,
		"spawn": spawn,
		"spawn_text": _creek_hint_text_without_water_parts()
	}

static func _bridge_split_effect() -> Dictionary:
	return {
		"remove_at": _river_dynamic_cells(),
		"visual_effect": BridgeTreeVisuals.split_effect(_tree_cells(), _bridge_cells(), _creek_cells_for_bridge()),
		"replace_text": _hint_bridge_split_replaces(),
		"spawn": _creek_and_tree_spawn()
	}

static func _fall_prompt_effect() -> Dictionary:
	return {
		"remove_at": _all_dynamic_cells(),
		"spawn": _creek_spawn(),
		"spawn_text": _fall_prompt_text(),
		"set_player_visible": false,
		"set_input_locked": false,
		"set_pending_interact_effect": _death_screen_effect()
	}

static func _bridge_collapse_effect() -> Dictionary:
	return {
		"set_input_locked": true,
		"set_event_locked": true,
		"visual_effect": {
			"type": "bridge_collapse_sequence",
			"fall_bridge_cells": _bridge_collapse_cells(),
			"player_cell": BRIDGE_COLLAPSE_PLAYER_CELL,
			"final_effect": _bridge_collapse_final_effect()
		}
	}

static func _bridge_collapse_final_effect() -> Dictionary:
	return {
		"remove_at": _all_dynamic_cells(),
		"spawn": _creek_spawn(),
		"spawn_text": _fall_prompt_text(),
		"set_player_visible": false,
		"set_input_locked": false,
		"set_event_locked": false,
		"set_pending_interact_effect": _death_screen_effect()
	}

static func _death_screen_effect() -> Dictionary:
	return {
		"clear_entities": true,
		"set_player_pos": Vector2i(23, 9),
		"set_player_visible": true,
		"set_input_locked": true,
		"set_pending_interact_effect": _reset_level_effect(),
		"spawn_text": _death_screen_text()
	}

static func _reset_level_effect() -> Dictionary:
	return {"reset_level": true, "reset_player_pos": Vector2i(6, 4)}
