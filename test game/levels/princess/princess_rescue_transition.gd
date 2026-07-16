extends RefCounted

const LEVEL_NAME := "公主获救后"
const SCREEN_SIZE := Vector2i(32, 18)
const FRAME_COLOR := Color(0.92, 0.92, 0.92, 1.0)
const FLOWER_COLOR := Color(0.62, 0.16, 0.22, 1.0)
const HAIR_COLOR := Color(0.52, 0.36, 0.12, 1.0)
const FACE_COLOR := Color(0.74, 0.74, 0.74, 1.0)
const PRINCESS_COLOR := Color(0.20, 0.55, 0.22, 1.0)
const LIP_COLOR := Color(0.68, 0.26, 0.64, 1.0)
const CLOTH_BLUE := Color(0.24, 0.22, 0.80, 1.0)
const CLOTH_RED := Color(0.65, 0.20, 0.25, 1.0)

static func build_level() -> Dictionary:
	return {
		"name": LEVEL_NAME,
		"screen_size": SCREEN_SIZE,
		"bounded": true,
		"allow_edge_transition": false,
		"player_start": Vector2i(0, 17),
		"player_visible": false,
		"player_input_locked": true,
		"player_event_locked": true,
		"rows": _blank_rows(),
		"initial_spawn": _text_layout()
	}

static func _text_layout() -> Array:
	var entries: Array = []
	_add(entries, "框", [
		Vector2i(22, 1), Vector2i(23, 1), Vector2i(24, 1), Vector2i(25, 1), Vector2i(26, 1), Vector2i(27, 1), Vector2i(28, 1),
		Vector2i(21, 2), Vector2i(29, 2),
		Vector2i(20, 3), Vector2i(30, 3),
		Vector2i(19, 4), Vector2i(29, 4),
		Vector2i(18, 5), Vector2i(19, 5), Vector2i(20, 5), Vector2i(21, 5), Vector2i(22, 5), Vector2i(23, 5), Vector2i(24, 5), Vector2i(25, 5), Vector2i(26, 5), Vector2i(27, 5), Vector2i(28, 5)
	], FRAME_COLOR)
	_add(entries, "讠", [Vector2i(22, 3), Vector2i(26, 3)], FRAME_COLOR)
	_add(entries, "身", [Vector2i(23, 3), Vector2i(27, 3)], FRAME_COLOR)
	_add(entries, "才", [Vector2i(24, 3), Vector2i(28, 3)], FRAME_COLOR)
	_add(entries, "花", [Vector2i(15, 6)], FLOWER_COLOR)
	_add(entries, "花", [Vector2i(14, 7), Vector2i(15, 7), Vector2i(16, 7), Vector2i(18, 7)], FLOWER_COLOR)
	_add(entries, "发", [Vector2i(17, 7)], HAIR_COLOR)
	_add(entries, "发", [Vector2i(14, 8), Vector2i(16, 8)], HAIR_COLOR)
	_add(entries, "花", [Vector2i(15, 8), Vector2i(17, 8), Vector2i(18, 8), Vector2i(19, 8)], FLOWER_COLOR)
	_add(entries, "发", [Vector2i(13, 9), Vector2i(14, 9), Vector2i(15, 9), Vector2i(17, 9), Vector2i(19, 9)], HAIR_COLOR)
	_add(entries, "脸", [Vector2i(16, 9)], FACE_COLOR)
	_add(entries, "花", [Vector2i(18, 9)], FLOWER_COLOR)
	_add(entries, "发", [Vector2i(13, 10), Vector2i(14, 10), Vector2i(18, 10), Vector2i(19, 10)], HAIR_COLOR)
	_add(entries, "公", [Vector2i(15, 10)], PRINCESS_COLOR)
	_add(entries, "脸", [Vector2i(16, 10)], FACE_COLOR)
	_add(entries, "主", [Vector2i(17, 10)], PRINCESS_COLOR)
	_add(entries, "发", [Vector2i(13, 11), Vector2i(19, 11)], HAIR_COLOR)
	_add(entries, "脸", [Vector2i(14, 11), Vector2i(15, 11), Vector2i(17, 11), Vector2i(18, 11)], FACE_COLOR)
	_add(entries, "鼻", [Vector2i(16, 11)], FACE_COLOR)
	_add(entries, "发", [Vector2i(13, 12), Vector2i(19, 12)], HAIR_COLOR)
	_add(entries, "红", [Vector2i(14, 12), Vector2i(18, 12)], LIP_COLOR)
	_add(entries, "嘴", [Vector2i(15, 12), Vector2i(16, 12), Vector2i(17, 12)], FACE_COLOR)
	_add(entries, "发", [Vector2i(12, 13), Vector2i(13, 13), Vector2i(14, 13), Vector2i(18, 13), Vector2i(19, 13), Vector2i(20, 13)], HAIR_COLOR)
	_add(entries, "脸", [Vector2i(15, 13), Vector2i(16, 13), Vector2i(17, 13)], FACE_COLOR)
	_add(entries, "发", [Vector2i(12, 14), Vector2i(20, 14)], HAIR_COLOR)
	_add(entries, "制", [Vector2i(13, 14), Vector2i(14, 14), Vector2i(15, 14), Vector2i(17, 14), Vector2i(18, 14), Vector2i(19, 14)], CLOTH_BLUE)
	_add(entries, "脸", [Vector2i(16, 14)], FACE_COLOR)
	_add(entries, "制", [Vector2i(12, 15), Vector2i(13, 15), Vector2i(15, 15), Vector2i(17, 15), Vector2i(19, 15), Vector2i(20, 15)], CLOTH_BLUE)
	_add(entries, "制", [Vector2i(14, 15), Vector2i(18, 15)], CLOTH_RED)
	_add(entries, "制", [Vector2i(16, 15)], FACE_COLOR)
	_add(entries, "制", [Vector2i(12, 16), Vector2i(13, 16), Vector2i(14, 16), Vector2i(17, 16), Vector2i(20, 16)], CLOTH_BLUE)
	_add(entries, "制", [Vector2i(15, 16), Vector2i(16, 16), Vector2i(18, 16), Vector2i(19, 16)], CLOTH_RED)
	return entries

static func _add(entries: Array, text: String, positions: Array, color: Color) -> void:
	for pos in positions:
		entries.append({
			"text": text,
			"pos": pos,
			"config": {"solid": false, "pushable": false, "splittable": false, "visual_color": color}
		})

static func _blank_rows() -> Array:
	var rows: Array = []
	for _y in range(SCREEN_SIZE.y):
		rows.append("                                ")
	return rows
