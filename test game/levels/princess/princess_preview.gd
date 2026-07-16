extends "res://scripts/main.gd"

const PrincessCage = preload("res://levels/princess/princess_cage.gd")

func _ready() -> void:
	current_level_index = -1
	intro_phase = "active"
	world.load_level(PrincessCage.build_level())
	world.set_input_locked(false)
	world.set_event_locked(false)
	world.update_page()
	page_camera.sync_to_world(world)
	_build_scene()
	_refresh_view()
