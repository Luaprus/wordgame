extends RefCounted

const LEVEL_NAME := "四目头盔 教学"
const SCREEN_SIZE := Vector2i(32, 18)
const WordSplitVisuals = preload("res://scripts/word_split_visuals.gd")

const HE_POS := Vector2i(17, 14)
const SPLIT_HUMAN_POS := HE_POS
const SPLIT_YE_POS := HE_POS + Vector2i.DOWN
const PROMPT_YE_POS := Vector2i(13, 15)
const PROMPT_HUMAN_POS := Vector2i(22, 15)
const STACKED_HUMAN_POS := PROMPT_YE_POS + Vector2i.DOWN
const RESTORED_HE_POS := PROMPT_YE_POS + Vector2i.UP
const PUSH_HINT_POS := Vector2i(6, 17)
const EXIT_BLOCKERS := [Vector2i(31, 14), Vector2i(31, 15)]
const HELMET_POS := Vector2i(15, 1)
const HELMET_LANDED_POS := Vector2i(15, 12)
const EQUIP_TEXT_POS := HELMET_LANDED_POS + Vector2i.LEFT * 2
const EQUIP_PLAYER_POS := EQUIP_TEXT_POS + Vector2i.LEFT
const POST_HELMET_TEXT_POS := Vector2i(5, 14)
const POST_HELMET_PLAYER_POS := POST_HELMET_TEXT_POS + Vector2i.DOWN
const POST_HELMET_POEM_POS := POST_HELMET_TEXT_POS + Vector2i(16, 0)
const MENTOR_TEXT_POS := Vector2i(6, 14)
const MENTOR_PLAYER_POS := Vector2i(17, 13)
const WATCH_TEXT_POS := Vector2i(5, 14)
const WATCH_PLAYER_POS := WATCH_TEXT_POS + Vector2i(9, 0)
const WATCH_HE_POS := WATCH_TEXT_POS + Vector2i(12, 0)
const SPLIT_CONCEPT_TEXT_POS := Vector2i(5, 14)
const INTRO_PLAYER_POS := Vector2i(23, 12)
const INTRO_TEXT_POS := Vector2i(5, 14)
const MIRROR_POS := Vector2i(13, 15)
const LIGHT_STEP_DELAY := 0.2
const LIGHT_SETTLE_DELAY := 2.0
const LIGHT_PATH := [
	Vector2i(23, 4),
	Vector2i(22, 5),
	Vector2i(21, 6),
	Vector2i(20, 7),
	Vector2i(19, 8),
	Vector2i(18, 9),
	Vector2i(17, 10),
	Vector2i(16, 11),
	Vector2i(15, 12),
	Vector2i(14, 13),
	Vector2i(13, 14),
	Vector2i(12, 15)
]
const REFLECTION_LIGHT_STEPS := [
	[Vector2i(12, 13), Vector2i(14, 13)],
	[Vector2i(11, 12), Vector2i(15, 12)]
]
const DOWN_RIGHT_RAY_LIMIT := 6
const UP_LEFT_RAY_LIMIT := 6
const BEAM_ONLY_DESCRIPTION_CELLS := [Vector2i(13, 14)]
const FINAL_MAGIC_LIGHT_POS := INTRO_TEXT_POS + Vector2i(15, 1)
const VAULT_BLUE := Color(0.0, 0.58, 0.62, 1.0)
const HELMET_VIDEO_PATH := "res://assets/video/u_helmet.ogv"
const HELMET_RING_CELLS := [
	Vector2i(14, 0), Vector2i(15, 0), Vector2i(16, 0), Vector2i(17, 0),
	Vector2i(13, 1), Vector2i(14, 1), Vector2i(17, 1), Vector2i(18, 1),
	Vector2i(12, 2), Vector2i(13, 2), Vector2i(14, 2), Vector2i(17, 2), Vector2i(18, 2), Vector2i(19, 2)
]

static func build_level() -> Dictionary:
	return {
		"name": LEVEL_NAME,
		"screen_size": SCREEN_SIZE,
		"bounded": true,
		"player_start": INTRO_PLAYER_POS,
		"player_facing": Vector2i.DOWN,
		"player_input_locked": true,
		"rows": _intro_rows(),
		"initial_timed_effect": _intro_light_effect(0),
		"initial_timed_delay": LIGHT_STEP_DELAY,
		"cell_entity_configs": {
			HE_POS: {
				"solid": true,
				"pushable": true,
				"splittable": true,
				"split_positions": [SPLIT_HUMAN_POS, SPLIT_YE_POS]
			}
		},
		"entities": {
			"宝": {"visual_color": VAULT_BLUE},
			"石": {"visual_color": VAULT_BLUE},
			"人": {"solid": true, "pushable": true},
			"也": {"solid": true, "pushable": true},
			"他": {"solid": true, "pushable": true, "splittable": true}
		},
		"split_rules": {
			"他": ["人", "也"]
		},
		"split_effects": {
			"他": _split_he_effect()
		},
		"merge_rules": {
			"人+也": "他",
			"也+人": "他"
		},
		"merge_effects": {
			"人+也": _restore_he_effect(),
			"也+人": _restore_he_effect()
		},
		"entity_move_effects": {
			"镜": _mirror_move_effects()
		},
		"pullable_texts": ["镜"],
		"step_effects": [
			{
				"pos": STACKED_HUMAN_POS + Vector2i.DOWN,
				"condition": {
					"present_text_at": {"pos": PROMPT_YE_POS, "text": "也"},
					"present_text_at_2": {"pos": STACKED_HUMAN_POS, "text": "人"},
					"absent_text_at": {"pos": PUSH_HINT_POS, "text": "「"}
				},
				"effect": {
					"spawn_text": _push_hint_text()
				}
			}
		]
	}

static func _intro_rows() -> Array:
	var rows := _blank_rows()
	_put_treasure_vault(rows)
	_put_text(rows, HELMET_POS, "头盔")
	return rows

static func _intro_light_effect(index: int) -> Dictionary:
	var pos: Vector2i = LIGHT_PATH[index]
	var effect := {
		"remove_at": [pos],
		"spawn_text": [
		{
			"text": "光",
			"pos": pos,
			"as_chars": true,
			"config": {"solid": false, "visual_color": Color.WHITE}
		}
		]
	}
	if index + 1 < LIGHT_PATH.size():
		effect["set_pending_timed_effect"] = _intro_light_effect(index + 1)
		effect["pending_timed_delay"] = LIGHT_STEP_DELAY
	else:
		effect["set_pending_timed_effect"] = _intro_description_and_reflection_effect()
		effect["pending_timed_delay"] = LIGHT_SETTLE_DELAY
	return effect

static func _intro_description_and_reflection_effect() -> Dictionary:
	return {
		"remove_at": [LIGHT_PATH[-1]],
		"spawn_text": _intro_description_text(),
		"set_pending_timed_effect": _reflection_light_effect(0),
		"pending_timed_delay": LIGHT_STEP_DELAY
	}

static func _reflection_light_effect(index: int) -> Dictionary:
	var effect := {
		"spawn_text": _reflection_light_text(index)
	}
	if index + 1 < REFLECTION_LIGHT_STEPS.size():
		effect["set_pending_timed_effect"] = _reflection_light_effect(index + 1)
		effect["pending_timed_delay"] = LIGHT_STEP_DELAY
	else:
		effect["set_input_locked"] = false
	return effect

static func _reflection_light_text(index: int) -> Array:
	var spawn := []
	for pos in REFLECTION_LIGHT_STEPS[index]:
		spawn.append({
			"text": "光",
			"pos": pos,
			"as_chars": true,
			"config": {"solid": false, "visual_color": Color.WHITE}
		})
	return spawn

static func _intro_description_text() -> Array:
	return [
		{
			"text": "宝石璀璨而透亮，光泽不寻常的止滑纹形成封印，",
			"pos": INTRO_TEXT_POS,
			"as_chars": true,
			"config": {"solid": true, "visual_color": Color.WHITE}
		},
		{
			"text": "像符咒护卫的反射镜，四周魔力流动，护住头盔。",
			"pos": INTRO_TEXT_POS + Vector2i.DOWN,
			"as_chars": true,
			"config": {"solid": true, "visual_color": Color.WHITE},
			"cell_configs": {
				8: {"pushable": true}
			}
		}
	]

static func _mirror_move_effects() -> Dictionary:
	var entries := []
	for y in range(SCREEN_SIZE.y):
		for x in range(SCREEN_SIZE.x):
			var pos := Vector2i(x, y)
			entries.append({
				"pos": pos,
				"effect": _mirror_light_effect(pos)
			})
	return {
		"by_target": entries,
		"default": _mirror_light_effect(Vector2i(-99, -99))
	}

static func _mirror_light_effect(mirror_pos: Vector2i) -> Dictionary:
	var light_positions := []
	for pos in _incoming_light_path_for_mirror(mirror_pos):
		light_positions.append(pos)
	for pos in _reflection_path_for_mirror(mirror_pos):
		light_positions.append(pos)
	var spawn := _dynamic_intro_description_text(light_positions, mirror_pos)
	for pos in light_positions:
		spawn.append(_light_spawn(pos))
	var effect := {
		"remove_matching": [
			{
				"positions": _intro_description_cells(),
				"texts": _intro_description_chars_without_mirror()
			},
			{
				"texts": ["光"],
				"solid": false
			}
		],
		"spawn_text": spawn
	}
	if _forms_magic_flow_text(light_positions):
		effect["set_input_locked"] = true
		effect["set_event_locked"] = true
		effect["set_pending_timed_effect"] = _helmet_success_shake_effect(0)
		effect["pending_timed_delay"] = 0.25
	return effect

static func _incoming_light_path_for_mirror(mirror_pos: Vector2i) -> Array:
	var end_index := LIGHT_PATH.size()
	var block_index := LIGHT_PATH.find(mirror_pos)
	if block_index >= 0:
		end_index = block_index
	else:
		var right_light_index := LIGHT_PATH.find(mirror_pos + Vector2i.RIGHT)
		var upper_light_index := LIGHT_PATH.find(mirror_pos + Vector2i.UP)
		if right_light_index >= 0:
			end_index = right_light_index + 1
		elif upper_light_index >= 0:
			end_index = upper_light_index + 1
	var path := []
	for i in range(end_index):
		path.append(LIGHT_PATH[i])
	return path

static func _reflection_path_for_mirror(mirror_pos: Vector2i) -> Array:
	var light_cells := _reflectable_light_cells()
	if light_cells.has(mirror_pos):
		return []
	var light_to_right := mirror_pos + Vector2i.RIGHT
	if light_cells.has(light_to_right):
		return _ray_positions(light_to_right + Vector2i(1, 1), Vector2i(1, 1), DOWN_RIGHT_RAY_LIMIT)
	var light_above := mirror_pos + Vector2i.UP
	if light_cells.has(light_above):
		return _ray_positions(light_above + Vector2i(-1, -1), Vector2i(-1, -1), UP_LEFT_RAY_LIMIT)
	return []

static func _reflectable_light_cells() -> Array:
	var cells := []
	for pos in LIGHT_PATH:
		cells.append(pos)
	return cells

static func _ray_positions(start: Vector2i, direction: Vector2i, limit: int) -> Array:
	var positions := []
	var pos := start
	for _i in range(limit):
		if pos.x < 0 or pos.y < 0 or pos.x >= SCREEN_SIZE.x or pos.y >= SCREEN_SIZE.y:
			break
		if direction.y > 0 and pos.y > INTRO_TEXT_POS.y + 1:
			break
		if _is_treasure_cell(pos):
			break
		positions.append(pos)
		pos += direction
	return positions

static func _is_treasure_cell(pos: Vector2i) -> bool:
	var rows := _intro_rows()
	if pos.y < 0 or pos.y >= rows.size():
		return false
	var line := str(rows[pos.y])
	if pos.x < 0 or pos.x >= line.length():
		return false
	return ["宝", "石"].has(line.substr(pos.x, 1))

static func _light_spawn(pos: Vector2i) -> Dictionary:
	return _overlay_spawn("光", pos)

static func _overlay_spawn(text: String, pos: Vector2i) -> Dictionary:
	return {
		"text": text,
		"pos": pos,
		"as_chars": true,
		"config": {"solid": false, "visual_color": Color.WHITE}
	}

static func _forms_magic_flow_text(light_positions: Array) -> bool:
	return light_positions.has(FINAL_MAGIC_LIGHT_POS)

static func _helmet_success_shake_effect(index: int) -> Dictionary:
	var rotations := [5.0, -5.0, 3.0, 0.0]
	var effect := {
		"remove_at": _intro_scene_cells(),
		"remove_matching": [
			{
				"texts": ["光"],
				"solid": false
			},
			{
				"texts": ["镜"]
			}
		],
		"spawn_text": _restore_light_covered_treasure_text(),
		"set_matching_config": [
			{
				"positions": HELMET_RING_CELLS,
				"texts": ["宝", "石"],
				"config": {"visual_rotation_degrees": rotations[index]}
			}
		]
	}
	if index + 1 < rotations.size():
		effect["set_pending_timed_effect"] = _helmet_success_shake_effect(index + 1)
		effect["pending_timed_delay"] = 0.12
	else:
		effect["set_pending_timed_effect"] = _helmet_fall_effect(HELMET_POS.y)
		effect["pending_timed_delay"] = 0.16
	return effect

static func _helmet_fall_effect(current_y: int) -> Dictionary:
	var next_y := current_y + 1
	var effect := {
		"move_entities": [
			{
				"from": Vector2i(HELMET_POS.x, current_y),
				"to": Vector2i(HELMET_POS.x, next_y),
				"config": {"visual_color": Color.WHITE}
			},
			{
				"from": Vector2i(HELMET_POS.x + 1, current_y),
				"to": Vector2i(HELMET_POS.x + 1, next_y),
				"config": {"visual_color": Color.WHITE}
			}
		]
	}
	if next_y < HELMET_LANDED_POS.y:
		effect["set_pending_timed_effect"] = _helmet_fall_effect(next_y)
		effect["pending_timed_delay"] = 0.1
	else:
		effect["set_pending_timed_effect"] = _helmet_walk_to_equip_effect()
		effect["pending_timed_delay"] = 0.18
	return effect

static func _helmet_walk_to_equip_effect() -> Dictionary:
	return {
		"move_player_toward": {
			"target": EQUIP_PLAYER_POS,
			"step_delay": 0.12,
			"then": _helmet_equip_prompt_effect()
		}
	}

static func _helmet_equip_prompt_effect() -> Dictionary:
	return {
		"spawn_text": [
			{
				"text": "戴上",
				"pos": EQUIP_TEXT_POS,
				"as_chars": true,
				"config": {"solid": true, "visual_color": Color.WHITE}
			}
		],
		"set_pending_timed_effect": {
			"play_fullscreen_video": {
				"path": HELMET_VIDEO_PATH,
				"on_finished": _post_helmet_first_page_effect()
			}
		},
		"pending_timed_delay": 0.45
	}

static func _post_helmet_first_page_effect() -> Dictionary:
	return {
		"remove_at": _helmet_landed_cells() + _equip_text_cells(),
		"set_player_pos": POST_HELMET_PLAYER_POS,
		"set_player_visible": true,
		"set_input_locked": false,
		"set_event_locked": false,
		"spawn_text": _restore_all_light_covered_treasure_text() + _post_helmet_first_page_text(),
		"set_pending_interact_effect": _post_helmet_mentor_page_effect()
	}

static func _post_helmet_first_page_text() -> Array:
	return [
		{
			"text": "戴上四目头盔之后，只觉得画面变得诗情画意了，",
			"pos": POST_HELMET_TEXT_POS,
			"as_chars": true,
			"config": {"solid": true, "visual_color": Color.WHITE}
		},
		{
			"text": "在一时之间，却还是无法体会这件圣器的力量。▼",
			"pos": POST_HELMET_PLAYER_POS + Vector2i.RIGHT,
			"as_chars": true,
			"config": {"solid": true, "visual_color": Color.WHITE}
		}
	]

static func _post_helmet_mentor_page_effect() -> Dictionary:
	return {
		"remove_at": _post_helmet_first_page_cells_except_poem(),
		"set_player_pos": MENTOR_PLAYER_POS,
		"set_player_visible": false,
		"spawn_text": _restore_all_light_covered_treasure_text() + _post_helmet_mentor_page_text(),
		"set_pending_interact_effect": _post_helmet_watch_page_effect()
	}

static func _post_helmet_mentor_page_text() -> Array:
	return [
		{
			"text": "「唉，看来还是得教一下才行，」",
			"pos": MENTOR_TEXT_POS,
			"as_chars": true,
			"config": {"solid": true, "visual_color": Color.WHITE}
		},
		{
			"text": "人皱着眉说：",
			"pos": POST_HELMET_POEM_POS + Vector2i.RIGHT,
			"as_chars": true,
			"config": {"solid": true, "visual_color": Color.WHITE}
		},
		{
			"text": "「就让为师跟你说一说，这头盔的奥妙所在吧。」▼",
			"pos": MENTOR_TEXT_POS + Vector2i.DOWN,
			"as_chars": true,
			"config": {"solid": true, "visual_color": Color.WHITE}
		}
	]

static func _post_helmet_watch_page_effect() -> Dictionary:
	return {
		"remove_at": _post_helmet_scene_cells(),
		"set_player_pos": WATCH_PLAYER_POS,
		"set_player_visible": true,
		"set_input_locked": false,
		"set_event_locked": false,
		"spawn_text": _restore_all_light_covered_treasure_text() + _watch_page_text()
	}

static func _watch_page_text() -> Array:
	return [
		{
			"text": "「这样吧，你先看着",
			"pos": WATCH_TEXT_POS,
			"as_chars": true,
			"config": {"solid": true, "visual_color": Color.WHITE}
		},
		{
			"text": "。」他说。",
			"pos": WATCH_PLAYER_POS + Vector2i.RIGHT,
			"as_chars": true,
			"config": {"solid": true, "visual_color": Color.WHITE},
			"cell_configs": {
				2: {
					"interact_text": "他说。",
					"interact_effect": _split_concept_page_effect()
				}
			}
		},
		{
			"text": "「没错！就是这样开始的。来吧，等什么呢？」",
			"pos": WATCH_TEXT_POS + Vector2i.DOWN,
			"as_chars": true,
			"config": {"solid": true, "visual_color": Color.WHITE}
		}
	]

static func _split_concept_page_effect() -> Dictionary:
	return {
		"remove_at": _post_helmet_scene_cells(),
		"set_player_pos": Vector2i(17, 13),
		"spawn_text": _restore_all_light_covered_treasure_text() + _split_concept_page_text(),
		"set_pending_interact_effect": _start_split_tutorial_effect()
	}

static func _split_concept_page_text() -> Array:
	return [
		{
			"text": "「跟删去文字相去不远。」他说。",
			"pos": SPLIT_CONCEPT_TEXT_POS,
			"as_chars": true,
			"config": {"solid": true, "visual_color": Color.WHITE}
		},
		{
			"text": "「将『分裂』的意念聚集在眼前……」▼",
			"pos": SPLIT_CONCEPT_TEXT_POS + Vector2i.DOWN,
			"as_chars": true,
			"config": {"solid": true, "visual_color": Color.WHITE}
		}
	]

static func _dynamic_intro_description_text(light_positions: Array, mirror_pos: Vector2i) -> Array:
	var spawn := []
	var lines := [
		{"text": "宝石璀璨而透亮，光泽不寻常的止滑纹形成封印，", "pos": INTRO_TEXT_POS},
		{"text": "像符咒护卫的反射镜，四周魔力流动，护住头盔。", "pos": INTRO_TEXT_POS + Vector2i.DOWN}
	]
	for line_config in lines:
		var text := str(line_config.text)
		var origin: Vector2i = line_config.pos
		for i in range(text.length()):
			var cell := origin + Vector2i(i, 0)
			if cell == MIRROR_POS or cell == mirror_pos or light_positions.has(cell):
				continue
			if BEAM_ONLY_DESCRIPTION_CELLS.has(cell):
				continue
			var ch := text.substr(i, 1)
			if ch == " ":
				continue
			spawn.append({
				"text": ch,
				"pos": cell,
				"as_chars": true,
				"config": {"solid": true, "visual_color": Color.WHITE}
			})
	return spawn

static func _intro_description_cells() -> Array:
	var cells := []
	for text_config in _intro_description_text():
		cells.append_array(_text_cells(text_config.pos, str(text_config.text)))
	return cells

static func _intro_description_chars_without_mirror() -> Array:
	var chars := []
	for text_config in _intro_description_text():
		var text := str(text_config.text)
		for i in range(text.length()):
			var ch := text.substr(i, 1)
			if ch == " " or ch == "镜" or chars.has(ch):
				continue
			chars.append(ch)
	return chars

static func _intro_scene_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.append_array(LIGHT_PATH)
	for step in REFLECTION_LIGHT_STEPS:
		for pos in step:
			cells.append(pos)
	for text_config in _intro_description_text():
		cells.append_array(_text_cells(text_config.pos, str(text_config.text)))
	return cells

static func _start_split_tutorial_effect() -> Dictionary:
	return {
		"remove_at": _intro_scene_cells() + _post_helmet_scene_cells(),
		"set_player_pos": HE_POS + Vector2i.UP,
		"set_player_visible": true,
		"set_input_locked": false,
		"spawn_text": _restore_all_light_covered_treasure_text() + _initial_tutorial_text()
	}

static func _initial_tutorial_text() -> Array:
	return [
		{
			"text": "「跟删去文字相去不远。」他说。",
			"pos": SPLIT_CONCEPT_TEXT_POS,
			"as_chars": true,
			"config": {"solid": true}
		},
		{
			"text": "「专心看，运用『TAB』的力量……」",
			"pos": SPLIT_CONCEPT_TEXT_POS + Vector2i.DOWN,
			"as_chars": true,
			"config": {"solid": true}
		}
	]

static func _split_he_effect() -> Dictionary:
	return {
		"remove_at": _post_helmet_scene_cells() + _initial_text_cells(),
		"visual_effect": WordSplitVisuals.effect("他", ["人", "也"]),
		"set_pending_timed_effect": {
			"spawn_text": _split_flash_text(),
			"set_pending_interact_effect": _show_rebuild_prompt_effect()
		},
		"pending_timed_delay": 1.0
	}

static func _restore_he_effect() -> Dictionary:
	var remove_at: Array[Vector2i] = []
	for cell in _split_scene_cells():
		if cell != PROMPT_YE_POS:
			remove_at.append(cell)
	return {
		"remove_at": remove_at,
		"move_entities": [
			{
				"from": PROMPT_YE_POS,
				"to": PROMPT_YE_POS,
				"config": {"pushable": false, "splittable": false}
			}
		],
		"set_pending_timed_effect": _move_restored_he_up_effect(),
		"pending_timed_delay": 0.18
	}

static func _show_rebuild_prompt_effect() -> Dictionary:
	return {
		"remove_at": _split_flash_cells() + [SPLIT_HUMAN_POS, SPLIT_YE_POS],
		"spawn_text": _split_context_text()
	}

static func _split_flash_text() -> Array:
	return [
		{
			"text": "光芒猛烈绽放，一眨眼间诗",
			"pos": Vector2i(5, 14),
			"as_chars": true,
			"config": {"solid": true}
		},
		{
			"text": "便失去了形体。",
			"pos": Vector2i(18, 14),
			"as_chars": true,
			"config": {"solid": true}
		},
		{
			"text": "看似平凡的四目头盔，竟然",
			"pos": Vector2i(5, 15),
			"as_chars": true,
			"config": {"solid": true}
		},
		{
			"text": "如此了得。▼",
			"pos": Vector2i(18, 15),
			"as_chars": true,
			"config": {"solid": true}
		}
	]

static func _split_context_text() -> Array:
	return [
		{
			"text": "看了看戴着杜尔手套的手，心想：",
			"pos": Vector2i(5, 14),
			"as_chars": true,
			"config": {"solid": true}
		},
		{
			"text": "「用点力气，应该也能找回原本的那个人吧。」",
			"pos": Vector2i(5, 15),
			"as_chars": true,
			"config": {"solid": true}
		}
	]

static func _push_hint_text() -> Array:
	return [
		{
			"text": "「用力往上！」我心里的声音这么说。",
			"pos": PUSH_HINT_POS,
			"as_chars": true,
			"config": {"solid": true}
		}
	]

static func _move_restored_he_up_effect() -> Dictionary:
	return {
		"move_entities": [
			{
				"from": PROMPT_YE_POS,
				"to": RESTORED_HE_POS,
				"config": {"pushable": false, "splittable": false}
			}
		],
		"set_pending_timed_effect": {
			"spawn_text": _restored_text(),
			"set_pending_interact_effect": _open_exit_after_space_effect()
		},
		"pending_timed_delay": 0.22
	}

static func _restored_text() -> Array:
	return [
		{
			"text": "「很好，勇者。」",
			"pos": Vector2i(5, 14),
			"as_chars": true,
			"config": {"solid": true, "pushable": false, "splittable": false}
		},
		{
			"text": "恢复了诗人的样貌，",
			"pos": Vector2i(14, 14),
			"as_chars": true,
			"config": {"solid": true, "pushable": false, "splittable": false}
		},
		{
			"text": "继续往前走吧。▼",
			"pos": Vector2i(5, 15),
			"as_chars": true,
			"config": {"solid": true, "pushable": false, "splittable": false}
		}
	]

static func _open_exit_after_space_effect() -> Dictionary:
	return {
		"set_pending_timed_effect": {
			"remove_at": EXIT_BLOCKERS
		},
		"pending_timed_delay": 1.0
	}

static func _initial_text_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.append_array(_text_cells(SPLIT_CONCEPT_TEXT_POS, "「跟删去文字相去不远。」他说。"))
	cells.append_array(_text_cells(SPLIT_CONCEPT_TEXT_POS + Vector2i.DOWN, "「专心看，运用『TAB』的力量……」"))
	return cells

static func _split_scene_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for text_config in _split_context_text():
		cells.append_array(_text_cells(text_config.pos, str(text_config.text)))
	for text_config in _split_flash_text():
		cells.append_array(_text_cells(text_config.pos, str(text_config.text)))
	for text_config in _push_hint_text():
		cells.append_array(_text_cells(text_config.pos, str(text_config.text)))
	for text_config in _restored_text():
		cells.append_array(_text_cells(text_config.pos, str(text_config.text)))
	return cells

static func _split_flash_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for text_config in _split_flash_text():
		cells.append_array(_text_cells(text_config.pos, str(text_config.text)))
	return cells

static func _helmet_landed_cells() -> Array[Vector2i]:
	return [HELMET_LANDED_POS, HELMET_LANDED_POS + Vector2i.RIGHT]

static func _equip_text_cells() -> Array[Vector2i]:
	return _text_cells(EQUIP_TEXT_POS, "戴上")

static func _post_helmet_scene_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for text_config in _post_helmet_first_page_text():
		cells.append_array(_text_cells(text_config.pos, str(text_config.text)))
	for text_config in _post_helmet_mentor_page_text():
		cells.append_array(_text_cells(text_config.pos, str(text_config.text)))
	cells.append_array(_text_cells(WATCH_TEXT_POS, "「这样吧，你先看着我。」他说。"))
	cells.append_array(_text_cells(WATCH_TEXT_POS + Vector2i.DOWN, "「没错！就是这样开始的。来吧，等什么呢？」"))
	cells.append_array(_text_cells(SPLIT_CONCEPT_TEXT_POS, "「跟删去文字相去不远。」他说。"))
	cells.append_array(_text_cells(SPLIT_CONCEPT_TEXT_POS + Vector2i.DOWN, "「将『分裂』的意念聚集在眼前……」▼"))
	return cells

static func _post_helmet_first_page_cells_except_poem() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for text_config in _post_helmet_first_page_text():
		for cell in _text_cells(text_config.pos, str(text_config.text)):
			if cell != POST_HELMET_POEM_POS:
				cells.append(cell)
	return cells

static func _restore_light_covered_treasure_text() -> Array:
	var spawn := []
	var rows := _intro_rows()
	for i in range(5, LIGHT_PATH.size()):
		var pos: Vector2i = LIGHT_PATH[i]
		var ch := str(rows[pos.y]).substr(pos.x, 1)
		if not ["宝", "石"].has(ch):
			continue
		spawn.append({
			"text": ch,
			"pos": pos,
			"as_chars": true,
			"config": {"solid": true, "visual_color": VAULT_BLUE}
		})
	return spawn

static func _restore_all_light_covered_treasure_text() -> Array:
	var spawn := []
	var rows := _intro_rows()
	for pos in LIGHT_PATH:
		var ch := str(rows[pos.y]).substr(pos.x, 1)
		if not ["宝", "石"].has(ch):
			continue
		spawn.append({
			"text": ch,
			"pos": pos,
			"as_chars": true,
			"config": {"solid": true, "visual_color": VAULT_BLUE}
		})
	return spawn

static func _blank_rows() -> Array:
	var rows: Array = []
	for _y in range(SCREEN_SIZE.y):
		rows.append("                                ")
	return rows

static func _put_treasure_vault(rows: Array) -> void:
	var source_rows := [
		"＿＿＿＿＿＿＿＿＿＿＿＿＿＿石寶寶石",
		"＿＿＿＿＿＿＿＿＿＿＿寶寶石寶＿＿寶石寶寶",
		"＿＿＿＿＿＿＿＿寶寶寶石石寶石寶寶石寶石石寶寶寶",
		"＿＿＿＿＿＿寶寶寶石石石寶石石寶寶石石寶石石石＿寶寶",
		"＿＿＿＿寶寶石寶石石石石寶石石寶寶石石寶石石＿＿＿石寶寶",
		"＿＿＿寶石石寶石石石石寶石石石寶寶石石石寶石石＿石寶石石寶",
		"＿＿寶石石石寶石石石石寶石石石寶寶石石石寶石石石石寶石石石寶",
		"＿＿寶石石寶石石石石石寶石石石寶寶石石石寶石石石石石寶石石寶",
		"＿寶石石石寶石石石石寶石石石石寶寶石石石石寶石石石石寶石石石寶",
		"＿寶石石寶石石石石石寶石石石石寶寶石石石石寶石石石石石寶石石寶",
		"寶石石石寶石石石石石寶寶寶寶寶寶寶寶寶寶寶寶石石石石石寶石石石寶",
		"寶石石石寶石寶寶寶寶寶＿＿＿＿＿＿＿＿＿＿寶寶寶寶寶石寶石石石寶",
		"寶石石寶寶寶＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿寶寶寶石石寶",
		"寶寶寶＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿寶寶寶",
		"寶＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿寶",
		"寶＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿寶",
		"＿寶寶＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿寶寶",
		"＿＿＿寶寶寶＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿寶寶寶"
	]
	for y in range(source_rows.size()):
		var source_line := str(source_rows[y])
		for x in range(source_line.length()):
			var ch := source_line.substr(x, 1)
			if ch == "＿":
				continue
			if ch == "寶":
				ch = "宝"
			_put_text(rows, Vector2i(x, y), ch)

static func _put_text(rows: Array, pos: Vector2i, text: String) -> void:
	var line := str(rows[pos.y])
	rows[pos.y] = line.substr(0, pos.x) + text + line.substr(pos.x + text.length())

static func _text_cells(pos: Vector2i, text: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i in range(text.length()):
		if text.substr(i, 1) == " ":
			continue
		cells.append(pos + Vector2i(i, 0))
	return cells
