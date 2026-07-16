extends RefCounted

const LEVEL_NAME := "神器大厅"
const SCREEN_SIZE := Vector2i(32, 18)
const ENTRY_POS := Vector2i(0, 15)
const SWORD_GATE_POS := Vector2i(6, 12)
const HAND_GATE_POS := Vector2i(16, 12)
const HELMET_GATE_POS := Vector2i(26, 12)
const HAND_DESC_POS := Vector2i(13, 15)
const HAND_NOT_POS := HAND_DESC_POS + Vector2i(3, 0)
const HELMET_DESC_POS := Vector2i(23, 15)
const SWORD_SCENE_PATH := "res://scenes/Maps/第二章/05_聖劍寶庫_復刻.tscn"
const HAND_SCENE_PATH := "res://levels/glove/glove_preview.tscn"
const HELMET_LEVEL_INDEX := 1
const RETURN_POET_START := Vector2i(0, 15)
const RETURN_POET_POS := Vector2i(2, 15)
const RETURN_SPEAKER_POS := RETURN_POET_POS + Vector2i.RIGHT
const RETURN_DIALOGUE_POS := RETURN_SPEAKER_POS + Vector2i.RIGHT
const RETURN_ROAD_TOP_POS := Vector2i(27, 14)
const RETURN_ROAD_BOTTOM_POS := Vector2i(27, 17)
const RETURN_ROAD_TEXT := "路路路路路"
const RETURN_POET_STEP_DELAY := 0.12
const RETURN_ROAD_DELAY := 1.0
const RED := Color(0.95, 0.12, 0.12, 1.0)

static func build_level() -> Dictionary:
	return {
		"name": LEVEL_NAME,
		"screen_size": SCREEN_SIZE,
		"bounded": true,
		"allow_edge_transition": true,
		"edge_transition_rows": [15, 16],
		"player_start": ENTRY_POS,
		"player_facing": Vector2i.RIGHT,
		"passable_text_by_player": {},
		"rows": _hall_rows(),
		"entities": {
		"门": {"solid": true, "pushable": false, "splittable": false},
		"盔": {"solid": true, "pushable": false, "splittable": false},
		"头": {"solid": true, "pushable": false, "splittable": false},
			"塔": {"solid": true, "pushable": false, "splittable": false},
			"柄": {"solid": true, "pushable": false, "splittable": false},
			"剑": {"solid": true, "pushable": false, "splittable": false},
			"手": {"solid": true, "pushable": false, "splittable": false},
			"套": {"solid": true, "pushable": false, "splittable": false},
			"目": {"solid": true, "pushable": false, "splittable": false}
		},
		"cell_entity_configs": _cell_configs(),
		"entity_delete_effects": [
			{"text": "不", "pos": HAND_NOT_POS, "effect": _open_hand_gate_effect()}
		],
		"entity_move_effects": [
			{
				"text": "盔",
				"to": HAND_DESC_POS,
				"effect": {
					"condition": {
						"pos": HAND_NOT_POS,
						"text": "不",
						"then": {},
						"else": _open_helmet_gate_effect()
					}
				}
			}
		],
		"step_effects": [
			{
				"pos": HELMET_GATE_POS,
				"condition": {
					"present_text_at": {"pos": HELMET_GATE_POS, "text": "门"},
					"absent_text_at": {"pos": RETURN_POET_POS, "text": "诗"}
				},
				"effect": {}
			}
		]
	}

static func _cell_configs() -> Dictionary:
	return {
		SWORD_GATE_POS: _open_gate_cell_config(SWORD_GATE_POS),
		HAND_GATE_POS: _open_gate_cell_config(HAND_GATE_POS),
		HELMET_GATE_POS: _open_gate_cell_config(HELMET_GATE_POS),
		Vector2i(5, 4): {"visual_color": RED},
		Vector2i(4, 5): {"visual_color": RED},
		Vector2i(5, 5): {"visual_color": RED},
		Vector2i(15, 5): {"visual_color": RED},
		Vector2i(16, 5): {"visual_color": RED},
		Vector2i(17, 5): {"visual_color": RED},
		Vector2i(15, 6): {"visual_color": RED},
		Vector2i(16, 6): {"visual_color": RED},
		Vector2i(17, 6): {"visual_color": RED},
		Vector2i(25, 2): {"visual_color": RED},
		Vector2i(27, 2): {"visual_color": RED},
		Vector2i(25, 3): {"visual_color": RED},
		Vector2i(27, 3): {"visual_color": RED}
	}

static func _open_gate_cell_config(gate_pos: Vector2i) -> Dictionary:
	return {
		"solid": true,
		"pushable": false,
		"splittable": false,
		"interact_text": " ",
		"interact_effect": _open_gate_visual_effect(gate_pos)
	}

static func _open_gate_visual_effect(gate_pos: Vector2i) -> Dictionary:
	var after_open_interact_text := ""
	var after_open_interact_effect: Dictionary = {}
	if gate_pos == SWORD_GATE_POS:
		after_open_interact_text = " "
		after_open_interact_effect = {"scene_path": SWORD_SCENE_PATH}
	if gate_pos == HAND_GATE_POS:
		after_open_interact_text = " "
		after_open_interact_effect = {"scene_path": HAND_SCENE_PATH}
	if gate_pos == HELMET_GATE_POS:
		after_open_interact_text = " "
		after_open_interact_effect = {"level_index": HELMET_LEVEL_INDEX}
	var effect := {
		"set_matching_config": [
			{
				"positions": [gate_pos],
				"texts": ["门"],
				"config": {
					"solid": true,
					"pushable": false,
					"splittable": false,
					"visual_style": "hall_door_open",
					"interact_text": after_open_interact_text,
					"interact_effect": after_open_interact_effect
				}
			}
		],
		"visual_effect": {
			"type": "hall_door_open",
			"cell": gate_pos,
			"source_text": "门",
			"traditional_text": "門"
		}
	}
	return effect

static func _show_hand_description_effect() -> Dictionary:
	return {
		"set_matching_config": [
			{
				"positions": [HAND_GATE_POS],
				"texts": ["门"],
				"config": {"interact_text": "", "interact_effect": {}}
			}
		],
		"spawn_text": [
			{
				"text": "手之门不会开",
				"pos": HAND_DESC_POS,
				"as_chars": true,
				"config": _description_config(),
				"cell_configs": {
					0: {"solid": true, "pushable": true},
					3: {"solid": true, "deletable": true}
				}
			}
		]
	}

static func _show_helmet_description_effect() -> Dictionary:
	return {
		"set_matching_config": [
			{
				"positions": [HELMET_GATE_POS],
				"texts": ["门"],
				"config": {"interact_text": "", "interact_effect": {}}
			}
		],
		"spawn_text": [
			{
				"text": "盔之门无法打开",
				"pos": HELMET_DESC_POS,
				"as_chars": true,
				"config": _description_config(),
				"cell_configs": {
					0: {"solid": true, "pushable": true}
				}
			}
		]
	}

static func _open_hand_gate_effect() -> Dictionary:
	return {
		"remove_matching": [{"positions": [HAND_GATE_POS], "texts": ["门"]}],
		"spawn": [{"text": "门", "pos": HAND_GATE_POS, "config": _open_gate_cell_config(HAND_GATE_POS)}],
		"last_message": "手之门会开。"
	}

static func _open_helmet_gate_effect() -> Dictionary:
	return {
		"remove_matching": [{"positions": [HELMET_GATE_POS], "texts": ["门"]}],
		"spawn": [{"text": "门", "pos": HELMET_GATE_POS, "config": _open_gate_cell_config(HELMET_GATE_POS)}],
		"last_message": "盔之门会开。"
	}

static func _begin_return_to_hall_effect() -> Dictionary:
	return {
		"remove_at": _return_description_cells(),
		"remove_matching": [{"temporary_description": true}],
		"spawn": [
			{"text": "诗", "pos": RETURN_POET_START, "config": {"solid": true, "pushable": false, "splittable": false}}
		],
		"set_input_locked": true,
		"set_event_locked": true,
		"set_pending_timed_effect": _return_poet_walk_effect(RETURN_POET_START.x),
		"pending_timed_delay": RETURN_POET_STEP_DELAY,
		"last_message": "诗人回到了大厅。"
	}

static func _return_poet_walk_effect(current_x: int) -> Dictionary:
	if current_x >= RETURN_POET_POS.x:
		return _show_return_dialogue_effect()
	return {
		"move_entities": [
			{"from": Vector2i(current_x, RETURN_POET_POS.y), "to": Vector2i(current_x + 1, RETURN_POET_POS.y)}
		],
		"set_pending_timed_effect": _return_poet_walk_effect(current_x + 1),
		"pending_timed_delay": RETURN_POET_STEP_DELAY
	}

static func _show_return_dialogue_effect() -> Dictionary:
	return {
		"spawn_text": [
			{"text": "：", "pos": RETURN_SPEAKER_POS, "config": _description_config()},
			{"text": "「你已经拿到了全部神器，」", "pos": RETURN_DIALOGUE_POS, "as_chars": true, "config": _description_config()},
			{"text": "「继续前进拯救公主吧！」", "pos": RETURN_DIALOGUE_POS + Vector2i(0, 1), "as_chars": true, "config": _description_config()}
		],
		"set_pending_timed_effect": _reveal_return_road_effect(),
		"pending_timed_delay": RETURN_ROAD_DELAY,
		"last_message": "你已经拿到了全部神器。"
	}

static func _reveal_return_road_effect() -> Dictionary:
	return {
		"spawn_text": [
			{"text": RETURN_ROAD_TEXT, "pos": RETURN_ROAD_TOP_POS, "as_chars": true, "config": {"solid": false, "pushable": false, "splittable": false}},
			{"text": RETURN_ROAD_TEXT, "pos": RETURN_ROAD_BOTTOM_POS, "as_chars": true, "config": {"solid": false, "pushable": false, "splittable": false}}
		],
		"set_input_locked": false,
		"set_event_locked": false,
		"last_message": "前方的路出现了。"
	}

static func _description_config() -> Dictionary:
	return {"solid": true, "pushable": false, "splittable": false, "temporary_description": true}

static func _hall_rows() -> Array:
	var rows := _blank_rows()
	_put_many(rows, [Vector2i(3, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(4, 4), Vector2i(3, 5), Vector2i(3, 6)], "柄")
	_put_many(rows, [Vector2i(5, 4), Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 6), Vector2i(7, 7), Vector2i(8, 8), Vector2i(9, 9), Vector2i(6, 10)], "剑")
	_put_many(rows, [Vector2i(6, 7), Vector2i(6, 8), Vector2i(5, 9), Vector2i(6, 9), Vector2i(7, 9), Vector2i(5, 10), Vector2i(7, 10), Vector2i(5, 11), Vector2i(7, 11), Vector2i(5, 12), Vector2i(7, 12)], "塔")
	_put(rows, Vector2i(6, 10), "剑")
	_put(rows, Vector2i(6, 11), "之")
	_put(rows, SWORD_GATE_POS, "门")

	_put_many(rows, [
		Vector2i(16, 1),
		Vector2i(15, 2), Vector2i(16, 2), Vector2i(17, 2),
		Vector2i(13, 3), Vector2i(15, 3), Vector2i(16, 3), Vector2i(17, 3), Vector2i(18, 3),
		Vector2i(14, 4), Vector2i(15, 4), Vector2i(16, 4), Vector2i(17, 4), Vector2i(18, 4)
	], "手")
	_put_many(rows, [Vector2i(15, 5), Vector2i(16, 5), Vector2i(17, 5), Vector2i(15, 6), Vector2i(16, 6), Vector2i(17, 6)], "套")
	_put_many(rows, [Vector2i(16, 7), Vector2i(16, 8), Vector2i(15, 9), Vector2i(16, 9), Vector2i(17, 9), Vector2i(15, 10), Vector2i(17, 10), Vector2i(15, 11), Vector2i(17, 11), Vector2i(15, 12), Vector2i(17, 12)], "塔")
	_put(rows, Vector2i(16, 10), "手")
	_put(rows, Vector2i(16, 11), "之")
	_put(rows, HAND_GATE_POS, "门")

	# 头盔图案按行交替，四只红目保持在中间两行。
	_put(rows, Vector2i(26, 0), "盔")
	_put_row_pattern(rows, 1, 25, ["盔", "头", "盔"])
	_put_row_pattern(rows, 2, 24, ["盔", "", "盔", "", "盔"])
	_put_row_pattern(rows, 3, 24, ["头", "", "头", "", "头"])
	_put_row_pattern(rows, 4, 23, ["盔", "头", "盔", "头", "盔", "头", "盔"])
	_put_row_pattern(rows, 5, 23, ["", "盔", "头", "盔", "头", "盔", ""])
	_put(rows, Vector2i(26, 6), "盔")
	_put_many(rows, [Vector2i(25, 2), Vector2i(27, 2), Vector2i(25, 3), Vector2i(27, 3)], "目")
	_put_many(rows, [Vector2i(26, 7), Vector2i(26, 8), Vector2i(25, 9), Vector2i(26, 9), Vector2i(27, 9), Vector2i(25, 10), Vector2i(27, 10), Vector2i(25, 11), Vector2i(27, 11), Vector2i(25, 12), Vector2i(27, 12)], "塔")
	_put(rows, Vector2i(26, 10), "盔")
	_put(rows, Vector2i(26, 11), "之")
	_put(rows, HELMET_GATE_POS, "门")
	return rows

static func _blank_rows() -> Array:
	var rows: Array = []
	for _y in range(SCREEN_SIZE.y):
		rows.append("                                ")
	return rows

static func _put_many(rows: Array, positions: Array, text: String) -> void:
	for pos in positions:
		_put(rows, pos, text)

static func _put_alternating(rows: Array, positions: Array, first_text: String, second_text: String) -> void:
	for index in range(positions.size()):
		_put(rows, positions[index], first_text if index % 2 == 0 else second_text)

static func _put_row_pattern(rows: Array, y: int, start_x: int, pattern: Array[String]) -> void:
	for index in range(pattern.size()):
		if not pattern[index].is_empty():
			_put(rows, Vector2i(start_x + index, y), pattern[index])

static func _put(rows: Array, pos: Vector2i, text: String) -> void:
	var line := str(rows[pos.y])
	rows[pos.y] = line.substr(0, pos.x) + text + line.substr(pos.x + text.length())

static func _text_cells(pos: Vector2i, text: String) -> Array:
	var cells: Array = []
	for index in range(text.length()):
		cells.append(pos + Vector2i(index, 0))
	return cells

static func _return_description_cells() -> Array:
	var cells := _text_cells(HAND_DESC_POS + Vector2i.LEFT, " 手之门不会开")
	cells.append_array(_text_cells(HELMET_DESC_POS, "盔之门无法打开"))
	return cells
