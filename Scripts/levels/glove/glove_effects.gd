extends RefCounted

const GloveLayouts = preload("res://scripts/levels/glove/glove_layouts.gd")

const GESTURE_SLOT_POS := GloveLayouts.GESTURE_SLOT_POS
const DELETE_NO_POS := Vector2i(6, 3)
const FAILURE_PLAYER_POS := Vector2i(20, 12)
const TRANSITION_PLAYER_POS := Vector2i(24, 5)
const TRANSITION_TRIGGER_POS := Vector2i(24, 5)
const TRACE_ANIMATION_PREFIX := "trace_anim:"
const TRACE_AUDIO_PREFIX := "trace_audio:"
const TRACE_ORIGIN := Vector2i(40, 40)
const FIGURE_THREE_WALL_CELLS: Array[Vector2i] = GloveLayouts.LIFELINE_WALL_CELLS
const DIALOGUE_POS := Vector2i(1, 8)
const DIALOGUE_INITIAL := "勇：别被一条线给困住了！"
const DIALOGUE_OPENING := "勇：上啊！"
const DIALOGUE_LIKE := "勇：加油！"

static func entity_configs() -> Dictionary:
	return {
		"掌": {
			"solid": true,
			"interact_text": "巨大手掌会随着句子改变手势。",
			"interact_effect": hand_interact_effect()
		},
		"剑": {
			"solid": true,
			"interact_text": "掌中剑藏在指头里。",
			"interact_effect": sword_interact_effect()
		},
		"线": {
			"solid": true,
			"interact_text": "逼退好手的生命线",
			"interact_effect": lifeline_interact_effect()
		},
		"线线": {
			"solid": true,
			"interact_text": "逼退好手的生命线",
			"interact_effect": lifeline_hint_interact_effect()
		},
		"赢": {"solid": true, "pushable": true},
		"不": {"solid": true, "pushable": true, "deletable": true},
		"二": {"solid": true, "pushable": true},
		"赞": {"solid": true, "pushable": true},
		"一": {"solid": true, "pushable": true},
		"零": {"solid": true, "pushable": true},
		"好": {"solid": true, "pushable": true},
		"爱": {"solid": true, "pushable": true},
		"勇": {"solid": true},
		"终": {"solid": true}
	}

static func final_hero_cell_config() -> Dictionary:
	return {
		"solid": true,
		"interact_text": "勇者似乎在等你。",
		"interact_effect": transition_out_effect()
	}

static func opening_interact_effect() -> Dictionary:
	return {
		"remove_texts": [DIALOGUE_INITIAL],
		"remove_at": GloveLayouts.LIFELINE_INSPECT_CELLS + [
			Vector2i(12, 13), Vector2i(13, 13), Vector2i(14, 13), Vector2i(15, 13),
			Vector2i(16, 13), Vector2i(17, 13), Vector2i(18, 13), Vector2i(19, 13)
		],
		"spawn": [
			{"text": DIALOGUE_OPENING, "pos": DIALOGUE_POS, "config": {"solid": false}},
			{"text": "逼退", "pos": Vector2i(12, 13), "config": {"solid": true}},
			{"text": "手的生命线", "pos": Vector2i(15, 13), "config": {"solid": true}},
			{"text": "好", "pos": GloveLayouts.GOOD_WORD_POS, "config": {"solid": true, "pushable": true}}
		],
		"last_message": "勇：别被一条线给困住了！"
	}

static func good_word_move_effects() -> Array[Dictionary]:
	var restore_wall: Array[Dictionary] = []
	for wall_cell in FIGURE_THREE_WALL_CELLS:
		restore_wall.append({"text": "掌", "pos": wall_cell, "config": {"solid": true}})
	return [
		{
			"text": "好",
			"from": GloveLayouts.GOOD_WORD_POS,
			"leaves_from": true,
			"effect": {
				"remove_at": FIGURE_THREE_WALL_CELLS,
				"last_message": "勇：上啊！"
			}
		},
		{
			"text": "好",
			"to": GloveLayouts.GOOD_WORD_POS,
			"effect": {
				"remove_at": FIGURE_THREE_WALL_CELLS,
				"spawn": restore_wall,
				"last_message": "逼退好手的生命线"
			}
		}
	]

static func gesture_slot_move_effects() -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	for mapping in _gesture_mappings():
		effects.append({
			"text": String(mapping.text),
			"to": GESTURE_SLOT_POS,
			"effect": _switch_hand_effect(String(mapping.state), String(mapping.message))
		})
	return effects

static func delete_word_effects() -> Array[Dictionary]:
	var effect := _switch_hand_effect("release", "巨大手掌已经放开。")
	effect["start_delete_visual"] = {
		"type": "delete_cut",
		"text": "不",
		"pos": DELETE_NO_POS
	}
	return [{
		"text": "不",
		"pos": DELETE_NO_POS,
		"effect": effect
	}]

static func release_preview_effect() -> Dictionary:
	var effect := _switch_hand_effect("release", "人工验收：五指张开", false)
	effect["remove_at"] = effect.get("remove_at", []) + [
		Vector2i(12, 13), Vector2i(13, 13), Vector2i(14, 13), Vector2i(15, 13),
		Vector2i(16, 13), Vector2i(17, 13), Vector2i(18, 13), Vector2i(19, 13)
	]
	effect["set_player_pos"] = Vector2i(24, 5)
	return effect

static func hand_interact_effect() -> Dictionary:
	return {
		"condition": {
			"pos": DELETE_NO_POS,
			"text": "不",
			"then": _gesture_switch_condition(0),
			"else": _switch_hand_effect("release", "巨大手掌已经放开。")
		}
	}

static func lifeline_interact_effect() -> Dictionary:
	return {
		"condition": {
			"pos": DELETE_NO_POS,
			"text": "不",
			"then": _lifeline_open_condition(0),
			"else": _open_lifeline_effect("巨掌放开后，生命线暴露了出来。")
		}
	}

static func lifeline_hint_interact_effect() -> Dictionary:
	return {
		"condition": {
			"pos": GloveLayouts.GOOD_WORD_POS,
			"text": "好",
			"then": {"last_message": "逼退好手的生命线"},
			"else": {
				"spawn": [
					{"text": "好", "pos": GloveLayouts.GOOD_WORD_POS, "config": {"solid": true, "pushable": true}}
				],
				"last_message": "逼退好手的生命线"
			}
		}
	}

static func transition_out_effect() -> Dictionary:
	return _append_runtime_trace({
		"clear_entities": true,
		"set_player_pos": TRANSITION_PLAYER_POS,
		"set_player_visible": false,
		"set_input_locked": true,
		"set_event_locked": true,
		"last_message": "巨掌迷宫暂时安静了下来。",
		"spawn_text": [
			{"text": "勇", "pos": Vector2i(1, 9), "config": {"solid": true}},
			{"text": "勇", "pos": Vector2i(1, 17), "config": {"solid": true}},
			{"text": "勇", "pos": Vector2i(24, 5), "config": {"solid": true}},
			{"text": "我", "pos": Vector2i(24, 6), "config": {"solid": true}}
		],
		"start_typewriter": {
			"lines": ["「果然有两把刷子，」", "「你，挺不简单的。」"],
			"pos": Vector2i(1, 3),
			"char_delay": 0.2,
			"config": {"solid": false},
			"after_effect": {
				"set_pending_interact_effect": _transition_dialogue_page_two(),
				"spawn_text": [{"text": "▽", "pos": Vector2i(11, 4), "config": {"solid": false}}]
			}
		}
	}, ["G-08"], ["GLOVE-AUD-007"])

static func _transition_dialogue_page_two() -> Dictionary:
	return {
		"clear_entities": true,
		"set_pending_interact_effect": _transition_dialogue_page_three(),
		"last_message": "尾声对白第二页",
		"spawn_text": _transition_role_text() + [
			{"text": "「你與我們都不同，」", "pos": Vector2i(1, 3), "as_chars": true, "config": {"solid": true}},
			{"text": "「也許是這樣的你，」", "pos": Vector2i(1, 4), "as_chars": true, "config": {"solid": true}},
			{"text": "「才能夠有所突破！」", "pos": Vector2i(1, 5), "as_chars": true, "config": {"solid": true}},
			{"text": "▽", "pos": Vector2i(11, 5), "config": {"solid": true}}
		]
	}

static func _transition_dialogue_page_three() -> Dictionary:
	return {
		"clear_entities": true,
		"set_pending_interact_effect": {
			"last_message": "进入第三章/16_添譜來堂_尾聲"
		},
		"last_message": "尾声对白第三页",
		"spawn_text": _transition_role_text() + [
			{"text": "「四三九七號勇者！」", "pos": Vector2i(1, 3), "as_chars": true, "config": {"solid": true}},
			{"text": "「請無畏地上前吧！」", "pos": Vector2i(1, 4), "as_chars": true, "config": {"solid": true}},
			{"text": "▽", "pos": Vector2i(11, 4), "config": {"solid": true}}
		]
	}

static func _transition_role_text() -> Array[Dictionary]:
	return [
		{"text": "勇", "pos": Vector2i(1, 9), "config": {"solid": true}},
		{"text": "勇", "pos": Vector2i(1, 17), "config": {"solid": true}},
		{"text": "勇", "pos": Vector2i(24, 5), "config": {"solid": true}},
		{"text": "我", "pos": Vector2i(24, 6), "config": {"solid": true}}
	]

static func sword_interact_effect() -> Dictionary:
	return {
		"condition": {
			"pos": GloveLayouts.HAND_ORIGIN + Vector2i(15, 0),
			"text": "掌",
			"then": {
				"condition": {
					"pos": GloveLayouts.HAND_ORIGIN + Vector2i(3, 0),
					"text": "掌",
					"then": {"last_message": "得先比出二的手势。"},
					"else": {
						"condition": {
							"pos": GloveLayouts.HAND_ORIGIN + Vector2i(19, 0),
							"text": "掌",
							"then": {"last_message": "得先比出二的手势。"},
							"else": _toggle_sword_anchor_effect()
						}
					}
				}
			},
			"else": {"last_message": "得先比出二的手势。"}
		}
	}

static func _gesture_switch_condition(index: int) -> Dictionary:
	var mappings := _gesture_mappings()
	if index >= mappings.size():
		return _switch_hand_effect("zero", "巨大手掌，是零的手势。")
	var mapping: Dictionary = mappings[index]
	return {
		"condition": {
			"pos": GESTURE_SLOT_POS,
			"text": String(mapping.text),
			"then": _switch_hand_effect(String(mapping.state), String(mapping.message)),
			"else": _gesture_switch_condition(index + 1)
		}
	}

static func _lifeline_open_condition(index: int) -> Dictionary:
	var open_words := [
		{"text": "好", "message": "好手逼退了生命线。"},
		{"text": "赞", "message": "好手逼退了生命线。"}
	]
	if index >= open_words.size():
		return _failure_effect()
	var mapping: Dictionary = open_words[index]
	return {
		"condition": {
			"pos": GESTURE_SLOT_POS,
			"text": String(mapping.text),
			"then": _open_lifeline_effect(String(mapping.message)),
			"else": _lifeline_open_condition(index + 1)
		}
	}

static func _switch_hand_effect(state_name: String, message: String, animate := true) -> Dictionary:
	var hand_effect := _hand_layout_effect(state_name, message)
	if not animate:
		return hand_effect
	hand_effect["set_input_locked"] = false
	return {
		"start_gesture_transition": {
			"switch_delay": 0.5,
			"duration": 1.0,
			"effect": hand_effect
		}
	}

static func _hand_layout_effect(state_name: String, message: String) -> Dictionary:
	var effect := {
		"remove_at": GloveLayouts.all_hand_cells(),
		"remove_texts": [DIALOGUE_INITIAL, DIALOGUE_OPENING, DIALOGUE_LIKE, "：改变手势，扭转守势！", "怜爱之深，", "责任之切，", "勇者之情。", "逼退", "手的生命线", "线", "线线"],
		"preserve_texts": ["赢", "不", "二", "赞", "一", "零", "好", "爱", "剑"],
		"spawn_text": GloveLayouts.hand_spawn_text(state_name),
		"last_message": message
	}
	effect["spawn"] = effect.get("spawn", [])
	if state_name == "like" or state_name == "release":
		if state_name == "like":
			effect["spawn"].append({"text": DIALOGUE_LIKE, "pos": DIALOGUE_POS, "config": {"solid": false}})
		else:
			effect["spawn"].append({"text": "：改变手势，扭转守势！", "pos": Vector2i(2, 16), "config": {"solid": false}})
		effect["spawn"].append({"text": "逼退", "pos": Vector2i(8, 13), "config": {"solid": true}})
		effect["spawn"].append({"text": "手的生命线", "pos": Vector2i(11, 13), "config": {"solid": true}})
	else:
		effect["spawn"].append({"text": "逼退", "pos": Vector2i(12, 13), "config": {"solid": true}})
		effect["spawn"].append({"text": "手的生命线", "pos": Vector2i(15, 13), "config": {"solid": true}})
		if state_name == "one":
			effect["spawn"].append({"text": "怜爱之深，", "pos": Vector2i(1, 12), "config": {"solid": false}})
			effect["spawn"].append({"text": "责任之切，", "pos": Vector2i(1, 13), "config": {"solid": false}})
			effect["spawn"].append({"text": "勇者之情。", "pos": Vector2i(1, 14), "config": {"solid": false}})
			effect["spawn"].append({"text": "：改变手势，扭转守势！", "pos": Vector2i(2, 16), "config": {"solid": false}})
		else:
			effect["spawn"].append({"text": DIALOGUE_OPENING, "pos": DIALOGUE_POS, "config": {"solid": false}})
	if not GloveLayouts.hand_cells(state_name).has(GloveLayouts.SWORD_SENTENCE_POS):
		effect["spawn"] = effect.get("spawn", [])
		effect["spawn"].append({"text": "剑", "pos": GloveLayouts.SWORD_SENTENCE_POS, "config": {"solid": true}})
	if _gesture_closes_lifeline(state_name):
		effect["remove_at"] = GloveLayouts.all_hand_cells() + [GloveLayouts.LIFELINE_POS]
		effect["spawn"] = effect.get("spawn", [])
		effect["spawn"].append({"text": "线", "pos": GloveLayouts.LIFELINE_POS})
	if state_name == "release":
		return _append_runtime_trace(effect, ["G-07"], ["GLOVE-AUD-006"])
	return _append_runtime_trace(effect, ["G-04", "G-05", "G-06"], ["GLOVE-AUD-003", "GLOVE-AUD-004", "GLOVE-AUD-005"])

static func _gesture_closes_lifeline(state_name: String) -> bool:
	return state_name in ["zero", "one", "two", "win"]

static func _open_lifeline_effect(message: String) -> Dictionary:
	return _append_runtime_trace({
		"remove_at": [GloveLayouts.LIFELINE_POS],
		"last_message": message
	}, ["G-02", "G-03"], ["GLOVE-AUD-001", "GLOVE-AUD-002"])

static func _toggle_sword_anchor_effect() -> Dictionary:
	return {
		"condition": {
			"pos": GloveLayouts.SWORD_LEFT_POS,
			"text": "剑",
			"then": {
				"remove_at": [GloveLayouts.SWORD_LEFT_POS, GloveLayouts.SWORD_RIGHT_POS],
				"spawn": [{"text": "剑", "pos": GloveLayouts.SWORD_RIGHT_POS}],
				"last_message": "二指伸直，掌中剑换到了右边。"
			},
			"else": {
				"remove_at": [GloveLayouts.SWORD_LEFT_POS, GloveLayouts.SWORD_RIGHT_POS],
				"spawn": [{"text": "剑", "pos": GloveLayouts.SWORD_LEFT_POS}],
				"last_message": "二指伸直，掌中剑换到了左边。"
			}
		}
	}

static func _failure_effect() -> Dictionary:
	return _append_runtime_trace({
		"clear_entities": true,
		"set_player_pos": FAILURE_PLAYER_POS,
		"set_player_visible": true,
		"set_input_locked": true,
		"set_pending_interact_effect": _reset_level_effect(),
		"last_message": "你被勇者包围了。",
		"spawn_text": [
			{"text": "勇勇勇", "pos": Vector2i(14, 9), "as_chars": true, "config": {"solid": true}},
			{"text": "勇勇勇", "pos": Vector2i(14, 10), "as_chars": true, "config": {"solid": true}},
			{"text": "勇勇勇", "pos": Vector2i(14, 11), "as_chars": true, "config": {"solid": true}},
			{"text": "被勇者包围了", "pos": Vector2i(10, 13), "as_chars": true, "config": {"solid": true}},
			{"text": "按互动重来", "pos": Vector2i(12, 14), "as_chars": true, "config": {"solid": true}}
		]
	}, ["G-08"], ["GLOVE-AUD-008"])

static func _reset_level_effect() -> Dictionary:
	return {
		"reset_level": true,
		"reset_player_pos": GloveLayouts.PLAYER_START
	}

static func _gesture_mappings() -> Array[Dictionary]:
	return [
		{"text": "好", "state": "like", "message": "巨大手掌，是好的手势。"},
		{"text": "赞", "state": "like", "message": "巨大手掌，是赞的手势。"},
		{"text": "一", "state": "one", "message": "巨大手掌，是一的手势。"},
		{"text": "二", "state": "two", "message": "巨大手掌，是二的手势。"},
		{"text": "赢", "state": "win", "message": "巨大手掌，是赢的手势。"},
		{"text": "爱", "state": "love", "message": "巨大手掌，是爱的手势。"},
		{"text": "零", "state": "zero", "message": "巨大手掌，是零的手势。"}
	]

static func _append_runtime_trace(effect: Dictionary, animation_ids: Array[String], audio_ids: Array[String]) -> Dictionary:
	var next_effect := effect.duplicate(true)
	var spawn_entries: Array = next_effect.get("spawn", []).duplicate(true)
	var trace_offset := 0
	for animation_id in animation_ids:
		spawn_entries.append({
			"text": TRACE_ANIMATION_PREFIX + animation_id,
			"pos": TRACE_ORIGIN + Vector2i(0, trace_offset),
			"config": {"solid": false}
		})
		trace_offset += 1
	for audio_id in audio_ids:
		spawn_entries.append({
			"text": TRACE_AUDIO_PREFIX + audio_id,
			"pos": TRACE_ORIGIN + Vector2i(0, trace_offset),
			"config": {"solid": false}
		})
		trace_offset += 1
	next_effect["spawn"] = spawn_entries
	return next_effect
