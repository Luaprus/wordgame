extends "res://scripts/main.gd"

const HallLevel = preload("res://levels/hall/artifact_hall.gd")

func _ready() -> void:
	highlight_visual_config = load_highlight_visual_config()
	_visual_effect_generation += 1
	key_info_emphasis_played = false
	current_level_index = -1
	world.load_level(HallLevel.build_level())
	# The hall is a playable entry scene, not the helmet tutorial reveal sequence.
	intro_phase = "active"
	world.set_input_locked(false)
	world.set_event_locked(false)
	world.update_page()
	page_camera.sync_to_world(world)
	_build_scene()
	_refresh_view()
