extends RefCounted

const WordSplitVisuals = preload("res://scripts/word_split_visuals.gd")

const LEVEL_NAME := "公主牢笼"
const SCREEN_SIZE := Vector2i(32, 18)
const ENTRY_POS := Vector2i(0, 16)
const PRINCESS_COLOR := Color(0.20, 0.55, 0.22, 1.0)
const DESCRIPTION_POS := Vector2i(10, 10)
const DESCRIPTION_LINES := [
	"眼前的球形大牢笼十分醒目",
	"精神涣散的公主被扣押其中",
	"大门紧锁故任何人不能靠近"
]
const NOT_POS := DESCRIPTION_POS + Vector2i(8, 2)
const BALL_POS := DESCRIPTION_POS + Vector2i(3, 0)
const AWAKE_POS := DESCRIPTION_POS + Vector2i(10, 0)
const HUAN_POS := DESCRIPTION_POS + Vector2i(2, 1)
const PRINCESS_WORD_POS := DESCRIPTION_POS + Vector2i(5, 1)
const KOU_POS := DESCRIPTION_POS + Vector2i(8, 1)
const GU_POS := DESCRIPTION_POS + Vector2i(4, 2)
const PRINCESS_ESCAPE_POS := Vector2i(15, 6)
const CAPTION_BOTTOM_POS := Vector2i(17, 16)
const CAPTION_QUOTE_Y := 0
const CAGE_PRINCESS_POS := Vector2i(15, 3)
const CAGE_PLAYER_POS := CAGE_PRINCESS_POS
const FAILURE_TEXT := "我将永远被困在这牢笼里，度过我的余生"
const FAILURE_TEXT_POS := Vector2i(6, 9)

static func build_level() -> Dictionary:
	return {
		"name": LEVEL_NAME,
		"screen_size": SCREEN_SIZE,
		"bounded": true,
		"allow_edge_transition": false,
		"preserve_merge_split_positions": false,
		"animate_all_word_merges": true,
		"player_start": ENTRY_POS,
		"player_facing": Vector2i.RIGHT,
		"rows": _cage_rows(),
		"split_rules": {
			"球": ["王", "求"],
			"醒": ["酉", "星"],
			"星": ["生", "日"],
			"涣": ["水", "奂"],
			"扣": ["手", "口"],
			"故": ["古", "攵"],
			"唤": ["口", "奂"],
			"换": ["手", "奂"],
			"救": ["求", "攵"],
			"酒": ["水", "酉"]
		},
		"split_effects": _split_effects(),
		"merge_rules": _merge_rules(),
		"sentence_rules": _sentence_rules(),
		"entity_delete_effects": [
			{
				"text": "不",
				"pos": NOT_POS,
				"effect": _delete_not_effect()
			}
		],
		"entities": {
			"笼": {"solid": true, "pushable": false, "splittable": false},
			"公": {"solid": true, "pushable": false, "splittable": false},
			"主": {"solid": true, "pushable": false, "splittable": false}
		},
		"cell_entity_configs": {
			Vector2i(15, 3): {"visual_color": PRINCESS_COLOR},
			Vector2i(16, 3): {"visual_color": PRINCESS_COLOR},
			NOT_POS: {"deletable": true}
		}
	}

static func _delete_not_effect() -> Dictionary:
	return {
		"set_input_locked": true,
		"set_event_locked": true,
		"visual_effect": {
			"type": "backspace_cut",
			"text": "不",
			"pos": NOT_POS,
			"angle_degrees": 45.0
		},
		"set_pending_timed_effect": _reduce_description_effect(),
		"pending_timed_delay": 1.0,
		"last_message": "文字开始发生变化。"
	}

static func _reduce_description_effect() -> Dictionary:
	return {
		"remove_at": _non_preserved_description_cells(),
		"move_entities": [
			{"from": BALL_POS, "to": BALL_POS + Vector2i(-1, -1), "config": _pushable_word_config()},
			{"from": AWAKE_POS, "to": AWAKE_POS + Vector2i(1, -1), "config": _pushable_word_config()},
			{"from": HUAN_POS, "to": HUAN_POS + Vector2i.LEFT, "config": _pushable_word_config()},
			{"from": PRINCESS_WORD_POS, "to": PRINCESS_WORD_POS, "config": _fixed_word_config()},
			{"from": PRINCESS_WORD_POS + Vector2i.RIGHT, "to": PRINCESS_WORD_POS + Vector2i.RIGHT, "config": _fixed_word_config()},
			{"from": KOU_POS, "to": KOU_POS + Vector2i.RIGHT, "config": _pushable_word_config()},
			{"from": GU_POS, "to": GU_POS + Vector2i.DOWN, "config": _pushable_word_config()}
		],
		"set_input_locked": false,
		"set_event_locked": false,
		"last_message": "剩余的文字浮现出来。"
	}

static func _pushable_word_config() -> Dictionary:
	return {"solid": true, "pushable": true, "splittable": true}

static func _fixed_word_config() -> Dictionary:
	return {"solid": true, "pushable": false, "splittable": false}

static func _merge_rules() -> Dictionary:
	return {
		"王+求": "球", "求+王": "球",
		"酉+星": "醒", "星+酉": "醒",
		"生+日": "星", "日+生": "星",
		"水+奂": "涣", "奂+水": "涣",
		"手+口": "扣", "口+手": "扣",
		"古+攵": "故", "攵+古": "故",
		"口+奂": "唤", "奂+口": "唤",
		"手+奂": "换", "奂+手": "换",
		"求+攵": "救", "攵+求": "救",
		"水+酉": "酒", "酉+水": "酒"
	}

static func _split_effects() -> Dictionary:
	var effects := {}
	var rules := {
		"球": ["王", "求"],
		"醒": ["酉", "星"],
		"星": ["生", "日"],
		"涣": ["水", "奂"],
		"扣": ["手", "口"],
		"故": ["古", "攵"],
		"唤": ["口", "奂"],
		"换": ["手", "奂"],
		"救": ["求", "攵"],
		"酒": ["水", "酉"]
	}
	for source_text in rules:
		effects[source_text] = {"visual_effect": _split_visual_for(source_text, rules[source_text])}
	return effects

static func _split_visual_for(source_text: String, parts: Array) -> Dictionary:
	match source_text:
		"球":
			return WordSplitVisuals.effect(source_text, parts, {
				"part_jump_heights": [34.0, 34.0],
				"part_delays": [0.0, 0.0],
				"move_duration": 0.56,
				"square_color": Color(1.0, 0.88, 0.42, 1.0),
				"particle_color": Color(1.0, 0.94, 0.68, 1.0)
			})
		"扣":
			return WordSplitVisuals.effect(source_text, parts, {
				"part_jump_heights": [0.0, 0.0],
				"part_delays": [0.0, 0.08],
				"move_duration": 0.42,
				"square_alpha": 0.30,
				"particle_duration": 0.28
			})
		"故":
			return WordSplitVisuals.effect(source_text, parts, {
				"part_jump_heights": [36.0, -14.0],
				"part_delays": [0.0, 0.10],
				"move_duration": 0.58,
				"square_color": Color(1.0, 0.72, 0.34, 1.0),
				"particle_color": Color(1.0, 0.80, 0.48, 1.0)
			})
		"醒":
			return WordSplitVisuals.effect(source_text, parts, {
				"part_jump_heights": [18.0, 48.0],
				"part_delays": [0.08, 0.0],
				"move_duration": 0.64,
				"settle_duration": 0.22,
				"square_color": Color(0.82, 0.90, 1.0, 1.0),
				"particle_color": Color(0.88, 0.94, 1.0, 1.0)
			})
		"涣":
			return WordSplitVisuals.effect(source_text, parts, {
				"part_jump_heights": [52.0, 16.0],
				"part_delays": [0.0, 0.14],
				"move_duration": 0.62,
				"square_alpha": 0.34,
				"square_color": Color(0.38, 0.86, 1.0, 1.0),
				"particle_color": Color(0.50, 0.92, 1.0, 1.0)
			})
		_:
			return WordSplitVisuals.effect(source_text, parts)

static func _sentence_rules() -> Dictionary:
	return {
		"救公主": {
			"required_player_at": {"text": "我", "anchor": "first", "offset": Vector2i.LEFT},
			"on_match_effect": _rescue_princess_effect()
		},
		"换公主": {
			"required_player_at": {"text": "我", "anchor": "first", "offset": Vector2i.LEFT},
			"on_match_effect": _swap_princess_failure_effect(
				[CAGE_PRINCESS_POS + Vector2i.RIGHT, CAGE_PRINCESS_POS],
				[Vector2i.ZERO, Vector2i.LEFT]
			)
		},
		"公主换": {
			"required_player_at": {"text": "我", "anchor": "last", "offset": Vector2i.RIGHT},
			"on_match_effect": _swap_princess_failure_effect(
				[CAGE_PRINCESS_POS, CAGE_PRINCESS_POS + Vector2i.RIGHT],
				[Vector2i.ZERO, Vector2i.RIGHT]
			)
		},
		"唤公主": _caption_rule("我尝试唤醒公主，但公主没有反应", CAPTION_BOTTOM_POS, "first", Vector2i.LEFT),
		"唤醒公主": _caption_rule("公主醒了过来，满怀希望地看着你", CAPTION_BOTTOM_POS, "first", Vector2i.LEFT),
		"公主唤": _quote_caption_rule("「勇者，救我！」", "last", Vector2i.RIGHT),
		"公主唤醒": _quote_caption_rule("「醒醒！别做梦了」", "last", Vector2i.RIGHT),
		"公主救": _quote_caption_rule("「你认真的吗？」", "last", Vector2i.RIGHT),
		"公主生日": _quote_caption_rule("「谢谢你来给我过生日」"),
		"生日": _quote_caption_rule("「祝你生日快乐~」", "first", Vector2i.LEFT),
		"求公主": _quote_caption_rule("「求我也解决不了任何问题」", "first", Vector2i.LEFT),
		"公主求": _quote_caption_rule("「求你一定要想办法放我出去」", "last", Vector2i.RIGHT)
	}

static func _quote_caption_rule(message: String, anchor := "", offset := Vector2i.ZERO) -> Dictionary:
	return _caption_rule(message, quote_caption_pos(message), anchor, offset)

static func quote_caption_pos(message: String) -> Vector2i:
	return Vector2i(SCREEN_SIZE.x - message.length(), CAPTION_QUOTE_Y)

static func _caption_rule(message: String, caption_pos: Vector2i, anchor := "", offset := Vector2i.ZERO) -> Dictionary:
	var rule := {
		"message": message,
		"caption_pos": caption_pos,
		"caption_solid": false,
		"remove_caption_on_miss": true
	}
	if not anchor.is_empty():
		rule["required_player_at"] = {"text": "我", "anchor": anchor, "offset": offset}
	return rule

static func _rescue_princess_effect() -> Dictionary:
	return {
		"set_input_locked": true,
		"set_event_locked": true,
		"remove_matching": [
			{"positions": [Vector2i(15, 3), Vector2i(16, 3), PRINCESS_ESCAPE_POS, PRINCESS_ESCAPE_POS + Vector2i.RIGHT], "texts": ["公", "主"]}
		],
		"spawn": [
			{"text": "公", "pos": PRINCESS_ESCAPE_POS, "config": _rescued_princess_config()},
			{"text": "主", "pos": PRINCESS_ESCAPE_POS + Vector2i.RIGHT, "config": _rescued_princess_config()}
		],
		"set_pending_timed_effect": _clear_after_rescue_effect(),
		"pending_timed_delay": 1.0
	}

static func _clear_after_rescue_effect() -> Dictionary:
	return {
		"preserve_texts": ["笼"],
		"preserve_persistent_entities": true,
		"clear_entities": true,
		"set_input_locked": false,
		"set_event_locked": false
	}

static func _rescued_princess_config() -> Dictionary:
	return {
		"solid": true,
		"pushable": false,
		"splittable": false,
		"persistent": true,
		"visual_color": PRINCESS_COLOR,
		"interact_text": "公主向你点了点头。",
		"interact_effect": {
			"set_input_locked": true,
			"set_event_locked": true,
			"visual_effect": {
				"type": "black_screen_transition",
				"duration": 1.0,
				"target_scene_path": "res://levels/princess/princess_rescue_preview.tscn"
			}
		}
	}

static func _swap_princess_failure_effect(source_positions: Array, target_offsets: Array) -> Dictionary:
	return {
		"set_input_locked": true,
		"set_event_locked": true,
		"swap_player_with_entities": {
			"positions": source_positions,
			"target_offsets": target_offsets,
			"player_target": CAGE_PLAYER_POS,
			"config": {
				"solid": true,
				"pushable": false,
				"splittable": false,
				"persistent": true,
				"visual_color": PRINCESS_COLOR
			}
		},
		"set_pending_timed_effect": {
			"preserve_texts": ["笼"],
			"preserve_persistent_entities": true,
			"clear_entities": true,
			"set_pending_timed_effect": _show_failure_text_effect(),
			"pending_timed_delay": 1.0,
			"set_input_locked": true,
			"set_event_locked": true
		},
		"pending_timed_delay": 1.0,
		"last_message": "公主和你交换了位置。"
	}

static func _show_failure_text_effect() -> Dictionary:
	return {
		"spawn_text": [{
			"text": FAILURE_TEXT,
			"pos": FAILURE_TEXT_POS,
			"config": {"solid": false, "pushable": false, "splittable": false}
		}],
		"set_pending_interact_effect": {"reset_level": true},
		"set_input_locked": true,
		"set_event_locked": true
	}

static func _cage_rows() -> Array:
	var rows := _blank_rows()
	_put_many(rows, [Vector2i(15, 0), Vector2i(16, 0)], "笼")
	_put_many(rows, [Vector2i(14, 1), Vector2i(17, 1)], "笼")
	_put_many(rows, [Vector2i(13, 2), Vector2i(15, 2), Vector2i(16, 2), Vector2i(18, 2)], "笼")
	_put_many(rows, [Vector2i(13, 3), Vector2i(18, 3)], "笼")
	_put(rows, Vector2i(15, 3), "公")
	_put(rows, Vector2i(16, 3), "主")
	_put_many(rows, [Vector2i(14, 4), Vector2i(17, 4)], "笼")
	_put_many(rows, [Vector2i(15, 5), Vector2i(16, 5)], "笼")
	for line_index in range(DESCRIPTION_LINES.size()):
		_put_text(rows, DESCRIPTION_POS + Vector2i(0, line_index), DESCRIPTION_LINES[line_index])
	return rows

static func _blank_rows() -> Array:
	var rows: Array = []
	for _y in range(SCREEN_SIZE.y):
		rows.append("                                ")
	return rows

static func _put_many(rows: Array, positions: Array, text: String) -> void:
	for pos in positions:
		_put(rows, pos, text)

static func _put_text(rows: Array, pos: Vector2i, text: String) -> void:
	for index in range(text.length()):
		_put(rows, pos + Vector2i(index, 0), text.substr(index, 1))

static func _put(rows: Array, pos: Vector2i, text: String) -> void:
	var line := str(rows[pos.y])
	rows[pos.y] = line.substr(0, pos.x) + text + line.substr(pos.x + text.length())

static func _description_cells() -> Array:
	var cells: Array = []
	for line_index in range(DESCRIPTION_LINES.size()):
		for char_index in range(DESCRIPTION_LINES[line_index].length()):
			cells.append(DESCRIPTION_POS + Vector2i(char_index, line_index))
	return cells

static func _non_preserved_description_cells() -> Array:
	var preserved := [BALL_POS, AWAKE_POS, HUAN_POS, PRINCESS_WORD_POS, PRINCESS_WORD_POS + Vector2i.RIGHT, KOU_POS, GU_POS]
	var cells: Array = []
	for pos in _description_cells():
		if not preserved.has(pos):
			cells.append(pos)
	return cells
