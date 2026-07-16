extends "res://scripts/main.gd"

const PrincessRescueTransition = preload("res://levels/princess/princess_rescue_transition.gd")

func _ready() -> void:
	current_level_index = -1
	intro_phase = "active"
	world.load_level(PrincessRescueTransition.build_level())
	world.update_page()
	page_camera.sync_to_world(world)
	_build_scene()
	_refresh_view()
