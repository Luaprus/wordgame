extends RefCounted

const LEVEL_NAME := "四目头盔 过河第五关"
const SCREEN_SIZE := Vector2i(32, 18)

static func build_level() -> Dictionary:
	return {
		"name": LEVEL_NAME,
		"screen_size": SCREEN_SIZE,
		"bounded": true,
		"player_start": Vector2i(6, 4),
		"player_facing": Vector2i(1, 0),
		"cell_entity_configs": {
			Vector2i(14, 3): {"pushable": true},
			Vector2i(15, 3): {"pushable": true, "interact_text": ""}
		},
		"rows": _initial_rows(),
		"entities": {
			"溪": {
				"solid": true,
				"interact_text": "无法跨越的湍急野溪。植草木自然地生长着，河面就落在古水位上。",
				"interact_effect": _creek_interact_effect()
			},
			"树": {
				"solid": true,
				"interact_text": "这乔木虽然还算堪用，可惜过河还是差了点。",
				"interact_effect": _tree_interact_effect()
			},
			"木": {
				"solid": true,
				"interact_text": "这乔木虽然还算堪用，可惜过河还是差了点。",
				"interact_effect": _tree_interact_effect()
			},
			"桥": {"solid": true, "pushable": true, "splittable": true},
			"植": {"solid": true, "pushable": true, "splittable": true},
			"古": {"solid": true, "pushable": true},
			"枯": {"solid": true, "pushable": true, "splittable": true},
			"直": {"solid": true, "pushable": true}
		},
		"split_rules": {
			"桥": ["乔", "木"],
			"植": ["木", "直"],
			"枯": ["木", "古"]
		},
		"merge_rules": {
			"乔+木": "桥",
			"木+乔": "桥",
			"木+古": "枯",
			"古+木": "枯"
		},
		"merge_effects": {
			"乔+木": _bridge_merge_effect(),
			"木+乔": _bridge_merge_effect(),
			"木+古": _dry_river_effect(),
			"古+木": _dry_river_effect()
		},
		"split_effects": {
			"桥": _bridge_split_effect(),
			"植": {},
			"枯": _restore_water_effect()
		}
	}

static func _initial_rows() -> Array:
	var rows: Array = []
	for _y in range(SCREEN_SIZE.y):
		rows.append("                                ")
	_put_text(rows, Vector2i(2, 3), "一条溪水阻挡前路。旁边的乔木")
	_put_text(rows, Vector2i(2, 4), "很实在，我感觉应该帮得上忙。")
	for cell in _creek_cells():
		_put_text(rows, cell, "溪")
	for cell in _tree_cells():
		_put_text(rows, cell, "木" if cell == Vector2i(19, 10) else "树")
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

static func _high_water_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(0, 15):
		cells.append(Vector2i(25, y))
	return cells

static func _creek_cells_for_blocked_bridge() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var all_creek := _creek_cells()
	for cell in _bridge_cells():
		if all_creek.has(cell) and not cells.has(cell):
			cells.append(cell)
	for x in range(21, 25):
		var road_cell := Vector2i(x, 9)
		if all_creek.has(road_cell) and not cells.has(road_cell):
			cells.append(road_cell)
	return cells

static func _creek_cells_for_open_bridge() -> Array[Vector2i]:
	var cells := _creek_cells_for_blocked_bridge()
	for cell in _high_water_cells():
		if not cells.has(cell):
			cells.append(cell)
	return cells

static func _bridge_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = [Vector2i(20, 7), Vector2i(25, 7)]
	for y in [8, 10]:
		for x in range(21, 25):
			cells.append(Vector2i(x, y))
	cells.append(Vector2i(20, 11))
	cells.append(Vector2i(25, 11))
	return cells

static func _river_dynamic_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.append_array(_tree_cells())
	cells.append_array(_creek_cells())
	cells.append_array(_bridge_cells())
	return cells

static func _hint_text_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for text_config in _tree_hint_text():
		cells.append_array(_occupied_text_cells(text_config))
	for text_config in _bridge_hint_text():
		cells.append_array(_occupied_text_cells(text_config))
	for text_config in _creek_hint_text():
		cells.append_array(_occupied_text_cells(text_config))
	for text_config in _dry_creek_hint_text():
		cells.append_array(_occupied_text_cells(text_config))
	for text_config in _split_creek_hint_text_without_merge_parts():
		cells.append_array(_occupied_text_cells(text_config))
	return cells

static func _creek_hint_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for text_config in _creek_hint_text():
		cells.append_array(_occupied_text_cells(text_config))
	for text_config in _dry_creek_hint_text():
		cells.append_array(_occupied_text_cells(text_config))
	for text_config in _split_creek_hint_text_without_merge_parts():
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

static func _solid_text_config() -> Dictionary:
	return {"solid": true, "pushable": false, "splittable": false}

static func _bridge_hint_text() -> Array[Dictionary]:
	return [
		{"text": "这桥 虽然还算堪用，", "pos": Vector2i(2, 7), "as_chars": true, "config": _solid_text_config()},
		{"text": "可惜过河还是差了点。", "pos": Vector2i(2, 8), "as_chars": true, "config": _solid_text_config()}
	]

static func _tree_hint_text() -> Array[Dictionary]:
	return [
		{"text": "这乔木虽然还算堪用，", "pos": Vector2i(2, 7), "as_chars": true, "config": _solid_text_config()},
		{"text": "可惜过河还是差了点。", "pos": Vector2i(2, 8), "as_chars": true, "config": _solid_text_config()}
	]

static func _creek_hint_text() -> Array[Dictionary]:
	return [
		{"text": "无法跨越的湍急野溪。", "pos": Vector2i(2, 10), "as_chars": true, "config": _solid_text_config()},
		{
			"text": "植草木自然地生长着，",
			"pos": Vector2i(2, 11),
			"as_chars": true,
			"config": _solid_text_config(),
			"cell_configs": {
				0: {"solid": true, "pushable": true, "splittable": true, "split_positions": [Vector2i(1, 11), Vector2i(2, 11)]}
			}
		},
		{
			"text": "河面就落在古水位上。",
			"pos": Vector2i(2, 12),
			"as_chars": true,
			"config": _solid_text_config(),
			"cell_configs": {5: {"solid": true, "pushable": true}}
		}
	]

static func _dry_creek_hint_text() -> Array[Dictionary]:
	return [
		{"text": "无法跨越的湍急野溪。", "pos": Vector2i(2, 10), "as_chars": true, "config": _solid_text_config()},
		{"text": "  直草木自然地生长着，", "pos": Vector2i(0, 11), "as_chars": true, "config": _solid_text_config()},
		{
			"text": "河面就落在枯水位上。",
			"pos": Vector2i(2, 12),
			"as_chars": true,
			"config": _solid_text_config(),
			"cell_configs": {
				5: {"solid": true, "pushable": true, "splittable": true, "split_positions": [Vector2i(7, 13), Vector2i(7, 12)]}
			}
		}
	]

static func _split_creek_hint_text_without_merge_parts() -> Array[Dictionary]:
	return [
		{"text": "无法跨越的湍急野溪。", "pos": Vector2i(2, 10), "as_chars": true, "config": _solid_text_config()},
		{"text": "  直草木自然地生长着，", "pos": Vector2i(0, 11), "as_chars": true, "config": _solid_text_config()},
		{"text": "河面就落在 水位上。", "pos": Vector2i(2, 12), "as_chars": true, "config": _solid_text_config()}
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

static func _creek_interact_effect() -> Dictionary:
	return {
		"remove_at": _creek_hint_cells(),
		"spawn_text": _creek_hint_text()
	}

static func _creek_with_hint_config() -> Dictionary:
	return {
		"interact_text": "无法跨越的湍急野溪。植草木自然地生长着，河面就落在古水位上。",
		"interact_effect": _creek_interact_effect()
	}

static func _bridge_with_hint_config() -> Dictionary:
	return {
		"solid": true,
		"pushable": false,
		"splittable": false,
		"interact_text": "这桥虽然还算堪用，可惜过河还是差了点。",
		"interact_effect": _bridge_interact_effect()
	}

static func _bridge_spawn() -> Array[Dictionary]:
	var spawn: Array[Dictionary] = []
	for cell in _bridge_cells():
		spawn.append({"text": "桥", "pos": cell, "config": _bridge_with_hint_config()})
	return spawn

static func _creek_remainder_spawn(open := false) -> Array[Dictionary]:
	var spawn: Array[Dictionary] = []
	var cleared_cells := _creek_cells_for_open_bridge() if open else _creek_cells_for_blocked_bridge()
	for cell in _creek_cells():
		if not cleared_cells.has(cell):
			spawn.append({"text": "溪", "pos": cell, "config": _creek_with_hint_config()})
	return spawn

static func _creek_and_tree_spawn(open := false) -> Array[Dictionary]:
	var spawn: Array[Dictionary] = []
	for cell in _creek_cells():
		if open and _high_water_cells().has(cell):
			continue
		spawn.append({"text": "溪", "pos": cell})
	spawn.append({"text": "树", "pos": Vector2i(19, 8)})
	spawn.append({"text": "树", "pos": Vector2i(18, 9)})
	spawn.append({"text": "树", "pos": Vector2i(19, 9)})
	spawn.append({"text": "树", "pos": Vector2i(20, 9)})
	spawn.append({"text": "木", "pos": Vector2i(19, 10)})
	return spawn

static func _hint_bridge_merge_replace() -> Dictionary:
	return {
		"from": "乔",
		"to": "桥",
		"pos": Vector2i(3, 7),
		"config": _solid_text_config(),
		"remove_on_replace": [Vector2i(4, 7)]
	}

static func _hint_bridge_split_replace() -> Dictionary:
	return {
		"from": "桥",
		"to": "乔",
		"pos": Vector2i(3, 7),
		"config": _solid_text_config(),
		"spawn_on_replace": [
			{"text": "木", "pos": Vector2i(4, 7), "config": _solid_text_config()}
		]
	}

static func _bridge_merge_effect() -> Dictionary:
	return {
		"condition": {
			"pos": Vector2i(7, 12),
			"text": "枯",
			"then": _bridge_merge_open_effect(),
			"else": _bridge_merge_blocked_effect()
		}
	}

static func _bridge_merge_blocked_effect() -> Dictionary:
	var spawn := _creek_remainder_spawn(false)
	spawn.append_array(_bridge_spawn())
	return {
		"remove_at": _river_dynamic_cells(),
		"replace_text": [_hint_bridge_merge_replace()],
		"spawn": spawn
	}

static func _bridge_merge_open_effect() -> Dictionary:
	var spawn := _creek_remainder_spawn(true)
	spawn.append_array(_bridge_spawn())
	return {
		"remove_at": _river_dynamic_cells(),
		"replace_text": [_hint_bridge_merge_replace()],
		"spawn": spawn
	}

static func _bridge_split_effect() -> Dictionary:
	return {
		"condition": {
			"pos": Vector2i(7, 12),
			"text": "枯",
			"then": _bridge_split_open_effect(),
			"else": _bridge_split_blocked_effect()
		}
	}

static func _bridge_split_blocked_effect() -> Dictionary:
	return {
		"remove_at": _river_dynamic_cells(),
		"replace_text": [_hint_bridge_split_replace()],
		"spawn": _creek_and_tree_spawn(false)
	}

static func _bridge_split_open_effect() -> Dictionary:
	return {
		"remove_at": _river_dynamic_cells(),
		"replace_text": [_hint_bridge_split_replace()],
		"spawn": _creek_and_tree_spawn(true)
	}

static func _dry_river_effect() -> Dictionary:
	return {
		"condition": {
			"pos": Vector2i(14, 3),
			"text": "桥",
			"then": _dry_with_bridge_effect(),
			"else": _dry_without_bridge_effect()
		}
	}

static func _dry_with_bridge_effect() -> Dictionary:
	var spawn := _creek_remainder_spawn(true)
	spawn.append_array(_bridge_spawn())
	var remove_at := _river_dynamic_cells()
	remove_at.append_array(_creek_hint_cells())
	return {
		"remove_at": remove_at,
		"spawn": spawn,
		"spawn_text": _dry_creek_hint_text()
	}

static func _dry_without_bridge_effect() -> Dictionary:
	var remove_at := _river_dynamic_cells()
	remove_at.append_array(_creek_hint_cells())
	return {
		"remove_at": remove_at,
		"spawn": _creek_and_tree_spawn(true),
		"spawn_text": _dry_creek_hint_text()
	}

static func _restore_water_effect() -> Dictionary:
	return {
		"condition": {
			"pos": Vector2i(14, 3),
			"text": "桥",
			"then": _restore_water_with_bridge_effect(),
			"else": _restore_water_without_bridge_effect()
		}
	}

static func _restore_water_with_bridge_effect() -> Dictionary:
	var spawn := _creek_remainder_spawn(false)
	spawn.append_array(_bridge_spawn())
	var remove_at := _river_dynamic_cells()
	remove_at.append_array(_creek_hint_cells())
	return {
		"remove_at": remove_at,
		"spawn": spawn,
		"spawn_text": _split_creek_hint_text_without_merge_parts()
	}

static func _restore_water_without_bridge_effect() -> Dictionary:
	var remove_at := _river_dynamic_cells()
	remove_at.append_array(_creek_hint_cells())
	return {
		"remove_at": remove_at,
		"spawn": _creek_and_tree_spawn(false),
		"spawn_text": _split_creek_hint_text_without_merge_parts()
	}
