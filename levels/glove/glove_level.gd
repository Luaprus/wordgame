extends RefCounted

const GloveLayouts = preload("res://scripts/levels/glove/glove_layouts.gd")
const GloveEffects = preload("res://scripts/levels/glove/glove_effects.gd")

const LEVEL_NAME := "手套关 巨掌迷宫"

static func build_level() -> Dictionary:
	var cell_configs := GloveLayouts.pushable_cell_configs()
	cell_configs[Vector2i(24, 4)] = GloveEffects.final_hero_cell_config()
	return {
		"name": LEVEL_NAME,
		"screen_size": Vector2i(32, 18),
		"bounded": true,
		"allow_edge_transition": false,
		"player_start": GloveLayouts.PLAYER_START,
		"player_facing": Vector2i.RIGHT,
		"player_text": "我",
		"push_keeps_player_in_place": true,
		"push_recovery_duration": 0.05,
		"passable_text_by_player": {"我": ["线线"]},
		"rows": GloveLayouts.build_rows(),
		"initial_spawn": [
			{"text": "勇：别被一条线给困住了！", "pos": Vector2i(1, 8), "config": {"solid": false}}
		],
		"entities": GloveEffects.entity_configs(),
		"cell_entity_configs": cell_configs,
		"initial_interact_effect": GloveEffects.opening_interact_effect(),
		"initial_visual_effect": {"type": "glove_acquire", "lock_input": true},
		"entity_move_effects": GloveEffects.good_word_move_effects() + GloveEffects.gesture_slot_move_effects(),
		"entity_delete_effects": GloveEffects.delete_word_effects(),
		"step_effects": [
			{
				"pos": GloveEffects.TRANSITION_TRIGGER_POS,
				"condition": {
					"present_text_at": {"pos": GloveLayouts.SWORD_RIGHT_POS, "text": "剑"},
					"absent_text_at": {"pos": GloveLayouts.SWORD_LEFT_POS, "text": "剑"}
				},
				"effect": GloveEffects.transition_out_effect()
			}
		]
	}
