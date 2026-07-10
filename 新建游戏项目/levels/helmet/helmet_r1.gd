extends RefCounted

const LEVEL_NAME := "四目头盔 过河第一关"

static func build_level() -> Dictionary:
	return {
		"name": LEVEL_NAME,
		"screen_size": Vector2i(32, 18),
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
			"  很结实，我感觉应该帮得上忙。     溪溪溪溪溪      ",
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
				"interact_text": "无法跨越的湍急野溪，必须想办法造一条路。",
				"interact_caption_lines": ["无法跨越的湍急野溪，", "必须想办法造一条路。"],
				"interact_caption_pos": Vector2i(2, 9),
				"interact_caption_solid": false
			},
			"树": {
				"solid": true,
				"interact_text": "这乔木看起来很结实，肯定能够帮得上忙吧。",
				"interact_caption_lines": ["这乔木看起来很结实，", "肯定能够帮得上忙吧。"],
				"interact_caption_pos": Vector2i(2, 6),
				"interact_caption_solid": false
			},
			"木": {
				"solid": true,
				"interact_text": "这乔木看起来很结实，肯定能够帮得上忙吧。",
				"interact_caption_lines": ["这乔木看起来很结实，", "肯定能够帮得上忙吧。"],
				"interact_caption_pos": Vector2i(2, 6),
				"interact_caption_solid": false
			},
			"桥": {
				"solid": true,
				"pushable": true,
				"splittable": true
			}
		},
		"split_rules": {"桥": ["乔", "木"]},
		"merge_rules": {"乔+木": "桥", "木+乔": "桥"},
		"merge_effects": {
			"乔+木": _bridge_merge_effect(),
			"木+乔": _bridge_merge_effect()
		},
		"split_effects": {"桥": _bridge_split_effect()}
	}

static func _tree_cells() -> Array[Vector2i]:
	return [
		Vector2i(19, 8),
		Vector2i(18, 9),
		Vector2i(19, 9),
		Vector2i(20, 9),
		Vector2i(19, 10)
	]

static func _creek_replaced_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in [9, 10, 11]:
		for x in range(21, 26):
			cells.append(Vector2i(x, y))
	return cells

static func _river_bridge_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = [Vector2i(19, 8), Vector2i(27, 8)]
	for y in [9, 11]:
		for x in range(20, 27):
			cells.append(Vector2i(x, y))
	cells.append(Vector2i(19, 11))
	cells.append(Vector2i(27, 11))
	return cells

static func _bridge_merge_effect() -> Dictionary:
	var remove_at: Array[Vector2i] = []
	remove_at.append_array(_tree_cells())
	remove_at.append_array(_creek_replaced_cells())
	remove_at.append_array(_river_bridge_cells())
	var spawn := []
	for cell in _river_bridge_cells():
		spawn.append({"text": "桥", "pos": cell, "config": {"solid": true, "pushable": false, "splittable": false}})
	return {
		"remove_at": remove_at,
		"replace_text": [
			{
				"from": "这乔木看起来很结实，",
				"to": "这桥看起来很结实，",
				"pos": Vector2i(2, 6),
				"config": {"solid": false}
			}
		],
		"spawn": spawn
	}

static func _bridge_split_effect() -> Dictionary:
	var spawn := []
	for cell in _creek_replaced_cells():
		spawn.append({"text": "溪", "pos": cell})
	spawn.append({"text": "树", "pos": Vector2i(19, 8)})
	spawn.append({"text": "树", "pos": Vector2i(18, 9)})
	spawn.append({"text": "树", "pos": Vector2i(19, 9)})
	spawn.append({"text": "树", "pos": Vector2i(20, 9)})
	spawn.append({"text": "木", "pos": Vector2i(19, 10)})
	return {
		"remove_at": _river_bridge_cells(),
		"replace_text": [
			{
				"from": "这桥看起来很结实，",
				"to": "这乔木看起来很结实，",
				"pos": Vector2i(2, 6),
				"config": {"solid": false}
			}
		],
		"spawn": spawn
	}
