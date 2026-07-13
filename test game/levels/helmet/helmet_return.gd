extends RefCounted

const LEVEL_NAME := "四目头盔 找回自己"
const SCREEN_SIZE := Vector2i(32, 18)

static func build_level() -> Dictionary:
	return {
		"name": LEVEL_NAME,
		"screen_size": SCREEN_SIZE,
		"bounded": true,
		"player_start": Vector2i(7, 12),
		"player_facing": Vector2i(1, 0),
		"player_text": "鹅",
		"rows": _initial_rows(),
		"entities": {
			"鸟": {"solid": true}
		},
		"player_split_rules": {
			"鹅": "我"
		},
		"player_split_effects": {
			"鹅": {
				"spawn_behind_player": [
					{
						"text": "鸟",
						"config": {"solid": true},
						"timed_move_left": {"delay": 1.0, "step_delay": 0.12, "to_x": -3}
					}
				]
			}
		}
	}

static func _initial_rows() -> Array:
	var rows: Array = []
	for _y in range(SCREEN_SIZE.y):
		rows.append("                                ")
	_put_text(rows, Vector2i(1, 3), "再一次运用四目头盔的力量，")
	_put_text(rows, Vector2i(1, 4), "应该就能够找回原本的自己。")
	return rows

static func _put_text(rows: Array, pos: Vector2i, text: String) -> void:
	var line := str(rows[pos.y])
	rows[pos.y] = line.substr(0, pos.x) + text + line.substr(pos.x + text.length())
