extends "res://scripts/main.gd"

const HallLevel = preload("res://levels/hall/artifact_hall.gd")

func _ready() -> void:
	highlight_visual_config = load_highlight_visual_config()
	intro_phase = "active"
	current_level_index = -1
	world.load_level(HallLevel.build_level())
	world.update_page()
	page_camera.sync_to_world(world)
	_build_scene()
	_refresh_view()
