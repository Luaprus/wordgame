extends "res://scripts/main.gd"

func _ready() -> void:
	highlight_visual_config = load_highlight_visual_config()
	_load_level_index(3, {
		"player_pos": Vector2i(23, 9),
		"player_text": "我",
		"player_facing": Vector2i.RIGHT
	})
	world.apply_preview_effect(HelmetR3._loose_bridge_effect())
	world.visual_effect_requests.clear()
	world.update_page()
	_build_scene()
	_refresh_view()
