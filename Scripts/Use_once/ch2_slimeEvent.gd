@tool
extends "../Event.gd"

const SLIME_MOVE_ANIMATION := preload("res://Scenes/Animations/slime_move.tres")
const SLIME_MOVE_SE_DIR := "res://Sounds/se/第二章 音效/"


func _ready():
	if Engine.is_editor_hint():
		return
	_ensure_slime_animation_player()


func move_straight(d):
	var moved = super.move_straight(d)
	if not moved:
		return false

	if $WordSprite.render_type != "sprite":
		$WordSprite.draw_text_to_sprite()
		await $WordSprite.draw_text_to_sprite_complete

	var r = "ABCD"[randi() % 4]
	Sound.play_se(SLIME_MOVE_SE_DIR + "SE_2_5_slime_move_" + r + ".wav")
	_ensure_slime_animation_player().play("slime_move")
	return true


func been_squeezed_when_overlap(from = 0):
	if can_pass(now_pos.x, now_pos.y, 6):
		move_straight(6)
	else:
		var e = Global.game_map.get_event_by_pos(now_pos + Vector2(1, 0))
		if not e:
			Global.game_map.player.move_straight(6)
			move_straight(6)
		elif has_node("../AnimationPlayer"):
			$"../AnimationPlayer".play("slime_squeeze")
			Sound.play_se("res://Sounds/se/slime_vanish_2.wav")


func _ensure_slime_animation_player() -> AnimationPlayer:
	var player: AnimationPlayer
	if has_node("AnimationPlayer"):
		player = $AnimationPlayer
	else:
		player = AnimationPlayer.new()
		player.name = "AnimationPlayer"
		add_child(player)

	if not player.has_animation("slime_move"):
		set_animation(player, "slime_move", SLIME_MOVE_ANIMATION)

	return player
