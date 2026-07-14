extends RefCounted

const LEVEL_NAME := "四目头盔 过河第六关"
const SCREEN_SIZE := Vector2i(32, 18)

static func build_level() -> Dictionary:
	return {
		"name": LEVEL_NAME,
		"screen_size": SCREEN_SIZE,
		"bounded": true,
		"player_start": Vector2i(3, 4),
		"player_facing": Vector2i(1, 0),
		"rows": _initial_rows(),
		"entities": {
			"溪": {
				"solid": true,
				"interact_text": "是绝路吗？一筹莫展。看着水面上的雁鸭群，脑中竟浮现一个想法：不如改变自己吧！",
				"interact_effect": _creek_interact_effect()
			},
			"鸟": {"solid": true}
		},
		"player_merge_rules": {
			"我+鸟": "鹅",
			"鸟+我": "鹅"
		},
		"player_merge_effects": {
			"我+鸟": _goose_effect(),
			"鸟+我": _goose_effect()
		},
		"passable_text_by_player": {
			"鹅": ["溪"]
		},
		"player_water_animation": {
			"player_text": "鹅",
			"water_text": "溪",
			"submerge_offset": 30.0,
			"jump_height": 30.0,
			"enter_duration": 0.5,
			"exit_duration": 0.3
		}
	}

static func _initial_rows() -> Array:
	var rows: Array = []
	for _y in range(SCREEN_SIZE.y):
		rows.append("                                ")
	_put_text(rows, Vector2i(2, 3), "一条溪水阻挡前路。四顾茫然，")
	_put_text(rows, Vector2i(2, 4), "在我眼前这鸟不生蛋的鬼地方。")
	for cell in _creek_cells():
		_put_text(rows, cell, "溪")
	return rows

static func _put_text(rows: Array, pos: Vector2i, text: String) -> void:
	var line := str(rows[pos.y])
	rows[pos.y] = line.substr(0, pos.x) + text + line.substr(pos.x + text.length())

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

static func _creek_hint_text() -> Array[Dictionary]:
	return [
		{"text": "是绝路吗？一筹莫展。", "pos": Vector2i(2, 7), "as_chars": true, "config": {"solid": true}},
		{"text": "看着水面上的雁鸭群，", "pos": Vector2i(2, 9), "as_chars": true, "config": {"solid": true}},
		{"text": "脑中竟浮现一个想法：", "pos": Vector2i(2, 10), "as_chars": true, "config": {"solid": true}},
		{"text": "「不如改变自己吧！」", "pos": Vector2i(2, 11), "as_chars": true, "config": {"solid": true}}
	]

static func _creek_hint_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
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

static func _creek_interact_effect() -> Dictionary:
	return {
		"remove_at": _creek_hint_cells(),
		"spawn_text": _creek_hint_text()
	}

static func _goose_effect() -> Dictionary:
	return {"set_player_text": "鹅"}
