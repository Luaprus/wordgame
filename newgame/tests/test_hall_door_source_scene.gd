extends SceneTree

const HallDoorOpenScene = preload("res://scenes/animations/hall_door_open.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var door_instance: Node2D = HallDoorOpenScene.instantiate() as Node2D
	if door_instance == null:
		push_error("hall door source scene did not instantiate")
		quit(1)
		return
	root.add_child(door_instance)
	var animation_player: AnimationPlayer = door_instance.get_node("AnimationPlayer") as AnimationPlayer
	var door_sprite: Sprite2D = door_instance.get_node("DoorSprite") as Sprite2D
	if animation_player == null or door_sprite == null:
		push_error("hall door source scene is missing animation nodes")
		quit(1)
		return
	if not animation_player.has_animation("open") or door_sprite.hframes != 10 or door_sprite.vframes != 3:
		push_error("hall door source scene does not match the imported source animation")
		quit(1)
		return
	animation_player.play("open")
	await animation_player.animation_finished
	if door_sprite.frame != 29:
		push_error("hall door open animation did not reach source frame 29")
		quit(1)
		return
	print("hall door source scene test passed")
	quit(0)
