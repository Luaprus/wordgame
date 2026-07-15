extends RefCounted

const LEVEL_NAME := "序章 诗人开场"
const SCREEN_SIZE := Vector2i(32, 18)
const POET_START := Vector2i(0, 5)
const POET_POS := Vector2i(4, 5)
const SPEAKER_MARK_POS := POET_POS + Vector2i.RIGHT
const DIALOGUE_POS := SPEAKER_MARK_POS + Vector2i.RIGHT
const ROAD_TOP_POS := Vector2i(26, 12)
const ROAD_BOTTOM_POS := Vector2i(26, 16)
const ROAD_TEXT := "路路路路路路"
const STEP_DELAY := 0.12
const ROAD_REVEAL_DELAY := 1.0

const DIALOGUES := [
	"「我是一名诗人，就由我来给你讲述这个故事，」",
	"「这是一个勇者拯救公主的故事，」",
	"「为了拯救公主，勇者必须要拿到三件神器，」"
]
const FOURTH_PREFIX := "「故事便从这里开始，"
const FOURTH_SUFFIX := "们相信勇者一定可以成功。」"
const PLAYER_POS := Vector2i(16, 5)

static func build_level() -> Dictionary:
	return {
		"name": LEVEL_NAME,
		"screen_size": SCREEN_SIZE,
		"bounded": true,
		"player_start": PLAYER_POS,
		"player_facing": Vector2i.RIGHT,
		"player_visible": false,
		"player_input_locked": true,
		"player_event_locked": true,
		"rows": _blank_rows(),
		"entities": {
			"诗": {"solid": true, "pushable": false, "splittable": false},
			"：": _caption_config(),
			"路": {"solid": false, "pushable": false, "splittable": false}
		},
		"initial_spawn": [
			{"text": "诗", "pos": POET_START, "config": {"solid": true, "pushable": false, "splittable": false}}
		],
		"initial_timed_effect": _poet_walk_effect(POET_START.x),
		"initial_timed_delay": STEP_DELAY
	}

static func _blank_rows() -> Array:
	var rows: Array = []
	for _y in range(SCREEN_SIZE.y):
		rows.append("                                ")
	return rows

static func _poet_walk_effect(current_x: int) -> Dictionary:
	if current_x >= POET_POS.x:
		return _show_dialogue_effect(1)
	return {
		"move_entities": [
			{"from": Vector2i(current_x, POET_POS.y), "to": Vector2i(current_x + 1, POET_POS.y)}
		],
		"set_pending_timed_effect": _poet_walk_effect(current_x + 1),
		"pending_timed_delay": STEP_DELAY
	}

static func _show_dialogue_effect(page: int) -> Dictionary:
	var effect := {
		"set_input_locked": true,
		"set_event_locked": true,
		"last_message": "诗人开场第%d句" % page,
		"spawn_text": _dialogue_spawn(page)
	}
	if page > 1:
		effect["remove_at"] = _dialogue_cells(page - 1)
	if page == 1:
		effect["spawn_text"].append({"text": "：", "pos": SPEAKER_MARK_POS, "config": _caption_config()})
	if page < 4:
		effect["set_pending_interact_effect"] = _show_dialogue_effect(page + 1)
	else:
		effect["set_player_visible"] = true
		effect["set_player_pos"] = PLAYER_POS
		effect["set_pending_timed_effect"] = _road_reveal_effect()
		effect["pending_timed_delay"] = ROAD_REVEAL_DELAY
	return effect

static func _dialogue_spawn(page: int) -> Array:
	if page <= 3:
		var text := str(DIALOGUES[page - 1])
		return [
			{"text": text, "pos": DIALOGUE_POS, "as_chars": true, "config": _caption_config()},
			{"text": "▼", "pos": DIALOGUE_POS + Vector2i(text.length(), 0), "config": _caption_config()}
		]
	return [
		{"text": FOURTH_PREFIX, "pos": DIALOGUE_POS, "as_chars": true, "config": _caption_config()},
		{"text": FOURTH_SUFFIX, "pos": PLAYER_POS + Vector2i.RIGHT, "as_chars": true, "config": _caption_config()}
	]

static func _dialogue_cells(page: int) -> Array:
	var text := str(DIALOGUES[page - 1])
	var cells: Array = []
	for index in range(text.length() + 1):
		cells.append(DIALOGUE_POS + Vector2i(index, 0))
	return cells

static func _road_reveal_effect() -> Dictionary:
	return {
		"set_input_locked": false,
		"set_event_locked": false,
		"last_message": "道路出现了。",
		"spawn_text": [
			{"text": ROAD_TEXT, "pos": ROAD_TOP_POS, "as_chars": true, "config": {"solid": false, "pushable": false, "splittable": false}},
			{"text": ROAD_TEXT, "pos": ROAD_BOTTOM_POS, "as_chars": true, "config": {"solid": false, "pushable": false, "splittable": false}}
		]
	}

static func _caption_config() -> Dictionary:
	return {"solid": true, "pushable": false, "splittable": false}
