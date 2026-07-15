extends RefCounted

const BridgeTreeVisuals = preload("res://levels/helmet/bridge_tree_visuals.gd")
const WordSplitVisuals = preload("res://scripts/word_split_visuals.gd")

const LEVEL_NAME := "四目头盔 过河第四关"
const SCREEN_SIZE := Vector2i(32, 18)

static func build_level() -> Dictionary:
	return {
		"name": LEVEL_NAME,
		"screen_size": SCREEN_SIZE,
		"bounded": true,
		"player_start": Vector2i(7, 5),
		"player_facing": Vector2i(1, 0),
		"cell_entity_configs": _cell_configs(),
		"rows": _initial_rows(),
		"entities": {
			"溪": {
				"solid": true,
				"interact_text": "无法跨越的湍急野溪，需要建造出正确的路。",
				"interact_effect": _creek_interact_effect()
			},
			"树": {
				"solid": true,
				"interact_text": "这乔木看起来很好用，用心点肯定帮得上忙。",
				"interact_effect": _tree_interact_effect()
			},
			"木": {
				"solid": true,
				"interact_text": "这乔木看起来很好用，用心点肯定帮得上忙。",
				"interact_effect": _tree_interact_effect()
			},
			"桥": {"solid": true, "pushable": true, "splittable": true}
		},
		"split_rules": {"桥": ["乔", "木"]},
		"merge_rules": {"乔+木": "桥", "木+乔": "桥"},
		"merge_effects": {
			"乔+木": _bridge_merge_dispatch(),
			"木+乔": _bridge_merge_dispatch()
		},
		"split_effects": {"桥": _bridge_split_dispatch()}
	}

static func _cell_configs() -> Dictionary:
	var configs := {
		Vector2i(14, 3): {"pushable": true},
		Vector2i(15, 3): {"pushable": true, "interact_text": ""},
		Vector2i(14, 4): {
			"pushable": true,
			"splittable": true,
			"split_positions": [Vector2i(14, 4), Vector2i(15, 4)]
		}
	}
	for cell in _far_bridge_cells():
		configs[cell] = {"pushable": false, "splittable": false}
	return configs

static func _initial_rows() -> Array:
	var rows: Array = []
	for _y in range(SCREEN_SIZE.y):
		rows.append("                                ")
	_put_text(rows, Vector2i(2, 3), "一条溪水阻挡前路。旁边的乔木")
	_put_text(rows, Vector2i(2, 4), "很友善，硬是出现在对岸的桥")
	_put_text(rows, Vector2i(2, 5), "反而造成了我不必要的困扰……")
	for cell in _creek_cells():
		_put_text(rows, cell, "溪")
	for cell in _tree_cells():
		_put_text(rows, cell, "木" if cell == Vector2i(19, 10) else "树")
	for cell in _far_bridge_cells():
		_put_text(rows, cell, "桥")
	return rows

static func _put_text(rows: Array, pos: Vector2i, text: String) -> void:
	var line := str(rows[pos.y])
	rows[pos.y] = line.substr(0, pos.x) + text + line.substr(pos.x + text.length())

static func _tree_cells() -> Array[Vector2i]:
	return [
		Vector2i(19, 8),
		Vector2i(18, 9),
		Vector2i(19, 9),
		Vector2i(20, 9),
		Vector2i(19, 10)
	]

static func _far_tree_cells() -> Array[Vector2i]:
	return [
		Vector2i(30, 5),
		Vector2i(29, 6),
		Vector2i(30, 6),
		Vector2i(31, 6),
		Vector2i(30, 7)
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
	for cell in _near_bridge_cells():
		if all_creek.has(cell) and not cells.has(cell):
			cells.append(cell)
	for x in range(20, 27):
		var road_cell := Vector2i(x, 9)
		if all_creek.has(road_cell) and not cells.has(road_cell):
			cells.append(road_cell)
	return cells

static func _near_bridge_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = [Vector2i(19, 7), Vector2i(27, 7)]
	for y in [8, 10]:
		for x in range(20, 27):
			cells.append(Vector2i(x, y))
	cells.append(Vector2i(19, 11))
	cells.append(Vector2i(27, 11))
	return cells

static func _far_bridge_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = [
		Vector2i(27, 5),
		Vector2i(31, 5),
		Vector2i(27, 14),
		Vector2i(31, 14)
	]
	for y in range(6, 14):
		cells.append(Vector2i(28, y))
		cells.append(Vector2i(30, y))
	return cells

static func _near_dynamic_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.append_array(_tree_cells())
	cells.append_array(_creek_cells())
	cells.append_array(_near_bridge_cells())
	return cells

static func _far_dynamic_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.append_array(_far_bridge_cells())
	cells.append_array(_far_tree_cells())
	return cells

static func _hint_text_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for text_config in _tree_hint_text():
		cells.append_array(_occupied_text_cells(text_config))
	for text_config in _bridge_hint_text():
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

static func _bridge_hint_text() -> Array[Dictionary]:
	return [
		{"text": "这桥 看起来很好用，", "pos": Vector2i(2, 7), "as_chars": true, "config": {"solid": true}},
		{"text": "用心点肯定帮得上忙。", "pos": Vector2i(2, 8), "as_chars": true, "config": {"solid": true}}
	]

static func _tree_hint_text() -> Array[Dictionary]:
	return [
		{"text": "这乔木看起来很好用，", "pos": Vector2i(2, 7), "as_chars": true, "config": {"solid": true}},
		{"text": "用心点肯定帮得上忙。", "pos": Vector2i(2, 8), "as_chars": true, "config": {"solid": true}}
	]

static func _creek_hint_text() -> Array[Dictionary]:
	return [
		{"text": "无法跨越的湍急野溪，", "pos": Vector2i(2, 10), "as_chars": true, "config": {"solid": true}},
		{"text": "需要建造出正确的路。", "pos": Vector2i(2, 11), "as_chars": true, "config": {"solid": true}}
	]

static func _occupied_hint_cells(text_configs: Array[Dictionary]) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for text_config in text_configs:
		cells.append_array(_occupied_text_cells(text_config))
	return cells

static func _bridge_hint_variant_cells() -> Array[Vector2i]:
	var cells := _occupied_hint_cells(_tree_hint_text())
	cells.append_array(_occupied_hint_cells(_bridge_hint_text()))
	return cells

static func _creek_interact_effect() -> Dictionary:
	return {
		"remove_at": _occupied_hint_cells(_creek_hint_text()),
		"spawn_text": _creek_hint_text()
	}

static func _tree_interact_effect() -> Dictionary:
	return {
		"remove_at": _bridge_hint_variant_cells(),
		"spawn_text": _tree_hint_text()
	}

static func _bridge_interact_effect() -> Dictionary:
	return {
		"remove_at": _bridge_hint_variant_cells(),
		"spawn_text": _bridge_hint_text()
	}

static func _bridge_merge_dispatch() -> Dictionary:
	return {
		"by_target": [
			{"pos": Vector2i(14, 3), "effect": _near_bridge_merge_effect()},
			{"pos": Vector2i(15, 3), "effect": _near_bridge_merge_effect()},
			{"pos": Vector2i(14, 4), "effect": _far_bridge_merge_effect()},
			{"pos": Vector2i(15, 4), "effect": _far_bridge_merge_effect()}
		],
		"default": {}
	}

static func _bridge_split_dispatch() -> Dictionary:
	return {
		"by_target": [
			{"pos": Vector2i(14, 3), "effect": _near_bridge_split_effect()},
			{"pos": Vector2i(15, 3), "effect": _near_bridge_split_effect()},
			{"pos": Vector2i(14, 4), "effect": _far_bridge_split_effect()},
			{"pos": Vector2i(15, 4), "effect": _far_bridge_split_effect()}
		],
		"default": {}
	}

static func _near_bridge_spawn() -> Array[Dictionary]:
	var spawn: Array[Dictionary] = []
	var config := {
		"solid": true,
		"pushable": false,
		"splittable": false,
		"interact_text": "这桥看起来很好用，用心点肯定帮得上忙。",
		"interact_effect": _bridge_interact_effect()
	}
	for cell in _near_bridge_cells():
		spawn.append({"text": "桥", "pos": cell, "config": config.duplicate()})
	return spawn

static func _creek_remainder_spawn() -> Array[Dictionary]:
	var spawn: Array[Dictionary] = []
	var cleared_cells := _creek_cells_for_bridge()
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

static func _far_bridge_spawn() -> Array[Dictionary]:
	var spawn: Array[Dictionary] = []
	for cell in _far_bridge_cells():
		spawn.append({"text": "桥", "pos": cell, "config": {"solid": true, "pushable": false, "splittable": false}})
	return spawn

static func _far_tree_spawn() -> Array[Dictionary]:
	var spawn: Array[Dictionary] = []
	for cell in _far_tree_cells():
		spawn.append({"text": "木" if cell == Vector2i(30, 7) else "树", "pos": cell})
	return spawn

static func _hint_bridge_merge_replace() -> Dictionary:
	return {
		"from": "乔",
		"to": "桥",
		"pos": Vector2i(3, 7),
		"config": {"solid": true},
		"remove_on_replace": [Vector2i(4, 7)]
	}

static func _hint_bridge_split_replace() -> Dictionary:
	return {
		"from": "桥",
		"to": "乔",
		"pos": Vector2i(3, 7),
		"config": {"solid": true},
		"spawn_on_replace": [
			{"text": "木", "pos": Vector2i(4, 7), "config": {"solid": true}}
		]
	}

static func _near_bridge_merge_effect() -> Dictionary:
	var spawn := _creek_remainder_spawn()
	spawn.append_array(_near_bridge_spawn())
	return {
		"remove_at": _near_dynamic_cells(),
		"visual_effect": BridgeTreeVisuals.merge_effect(_tree_cells(), _near_bridge_cells()),
		"replace_text": [_hint_bridge_merge_replace()],
		"spawn": spawn
	}

static func _near_bridge_split_effect() -> Dictionary:
	return {
		"remove_at": _near_dynamic_cells(),
		"visual_effects": [
			BridgeTreeVisuals.split_effect(_tree_cells(), _near_bridge_cells(), _creek_cells_for_bridge()),
			WordSplitVisuals.effect("桥", ["乔", "木"])
		],
		"replace_text": [_hint_bridge_split_replace()],
		"spawn": _creek_and_tree_spawn()
	}

static func _far_bridge_split_effect() -> Dictionary:
	return {
		"remove_at": _far_dynamic_cells(),
		"visual_effects": [
			BridgeTreeVisuals.split_effect(_far_tree_cells(), _far_bridge_cells()),
			WordSplitVisuals.effect("桥", ["乔", "木"])
		],
		"spawn": _far_tree_spawn()
	}

static func _far_bridge_merge_effect() -> Dictionary:
	return {
		"remove_at": _far_dynamic_cells(),
		"visual_effect": BridgeTreeVisuals.merge_effect(_far_tree_cells(), _far_bridge_cells()),
		"spawn": _far_bridge_spawn()
	}
