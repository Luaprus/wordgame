extends CanvasLayer

func refresh_screen_light():
	match int(Global.settings.light_level):
		0:
			$"螢幕整體暗度調整".color = Color(0, 0, 0, 0.4)
		1:
			$"螢幕整體暗度調整".color = Color(0, 0, 0, 0.2)
		2:
			$"螢幕整體暗度調整".color = Color(0, 0, 0, 0)


@onready var animation_player = $AnimationPlayer




	





	







	
	




	





	


	
func fade_transition_scene(scene, fade_time = 1):
	var pt = Time.get_ticks_msec()
	Load.preload_scene(scene)
	
	Global.game_pause()
	InputSystem.lock()
	
	$FadePanel.visible = true

	var colors = [Color("#000000ff"), Color("#00000000")]
	var tween = create_tween()
	tween.tween_property($FadePanel, "modulate", colors[0], fade_time).from($FadePanel.modulate).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func():
		Load.change_scene_to_file(scene)
		var tween_out = create_tween()
		tween_out.tween_property($FadePanel, "modulate", colors[1], fade_time).from($FadePanel.modulate).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		tween_out.finished.connect(func():
			$FadePanel.visible = false
			InputSystem.unlock()
			Global.game_resume()
			var nt = Time.get_ticks_msec()
			print("all_change_scene_time: ", nt - pt)
		)
	)
	return tween

func fade_fast_transition_scene(scene):
	fade_transition_scene(scene, 0.5)
	

func fade_white_transition_scene(scene):
	var pt = Time.get_ticks_msec()
	Load.preload_scene(scene)
	
	Global.game_pause()
	InputSystem.lock()
	$FadePanel.visible = true
	$FadePanel.modulate = Color("#ffffff00")

	var colors = [Color("#ffffffff"), Color("#ffffff00")]
	var tween = create_tween()
	tween.tween_property($FadePanel, "modulate", colors[0], 1).from($FadePanel.modulate).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func():
		Load.change_scene_to_file(scene)
		var tween_out = create_tween()
		tween_out.tween_property($FadePanel, "modulate", colors[1], 1).from($FadePanel.modulate).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		tween_out.finished.connect(func():
			$FadePanel.visible = false
			$FadePanel.modulate = Color("#00000000")
			InputSystem.unlock()
			Global.game_resume()
			var nt = Time.get_ticks_msec()
			print("all_change_scene_time: ", nt - pt)
		)
	)
	return tween

func whirl_transition_scene(scene):
	Load.preload_scene(scene)
	
	Sound.play_se("res://Sounds/se/twist_long_1.wav")
	
	Global.game_pause()
	





	
	$ScreenEffect2.visible = true
	$ScreenEffect2/EffectPlayer.play("whirl")
	

	


	
	

	get_tree().create_timer(0.5).timeout.connect(func(): pass, CONNECT_ONE_SHOT)
	
	
	$FadePanel.visible = true
	animation_player.play("FadeOut")
	InputSystem.lock()


	$ScreenEffect2/EffectPlayer.animation_finished.connect(func(_anim_name = ""): pass, CONNECT_ONE_SHOT)







	Load.change_scene_to_file(scene)




	
	





	
	$ScreenEffect2/EffectPlayer.play_backwards("whirl")

	animation_player.play("FadeIn")
	
	$ScreenEffect2/EffectPlayer.animation_finished.connect(func(_anim_name = ""): pass, CONNECT_ONE_SHOT)
	
	InputSystem.unlock()
	$FadePanel.visible = false
	
	$ScreenEffect2.visible = false
	
	Global.game_resume()
	
	
func start_shake(f = 20.0, d = 0.5):
	$ShakeEffect.material.set_shader_parameter("frequency", f)
	$ShakeEffect.material.set_shader_parameter("depth", d)
	$ShakeEffect.visible = true

func stop_shake():
	$ShakeEffect.visible = false
	
	
func show_black_bar():
	$"上下橫條".visible = true

func hide_black_bar():
	$"上下橫條".visible = false
	
func show_save_hint():
	$"上下橫條/提示區/存檔提示/AnimationPlayer".play("show_hint")
	
var is_esc_hint_active = false
var will_esc_hint_hide = false
func show_esc_hint():
	if is_esc_hint_active:
		return
	$"上下橫條/提示區/esc提示/AnimationPlayer".play("show_hint")
	is_esc_hint_active = true
	print("show_hint")
	
func hide_esc_hint():
	if not is_esc_hint_active:
		return
	$"上下橫條/提示區/esc提示/AnimationPlayer".play("hide_hint")
	is_esc_hint_active = false
	print("hide_hint")

func hide_esc_hint_after_a_while():
	if not is_esc_hint_active:
		return
	if will_esc_hint_hide:
		return
	print("hide_hint_after_a_while")
	will_esc_hint_hide = true
	await get_tree().create_timer(5).timeout
	will_esc_hint_hide = false
	hide_esc_hint()
	
func show_esc_menu_hint():
	$"上下橫條/Esc介面提示區/刪字".visible = Global.player_status.get("has_backspace_power", false)
	$"上下橫條/Esc介面提示區/推字".visible = Global.player_status.get("has_push_power", false)
	$"上下橫條/Esc介面提示區/拉字".visible = Global.player_status.get("has_push_power", false)
	$"上下橫條/Esc介面提示區/拆字".visible = Global.player_status.get("has_split_power", false)
	$"上下橫條/Esc介面提示區/繁簡".visible = not Global.player_status.get("has_ctrl_z_power", false) and Global.settings.has_ts_mode
	$"上下橫條/Esc介面提示區/重置＆繁簡".visible = Global.player_status.get("has_ctrl_z_power", false)
	
	for ani in get_tree().get_nodes_in_group("hint_ani"):
		ani.seek(0, true)
		ani.play()
	
	if not Global.settings.has_ts_mode:
		$"上下橫條/Esc介面提示區/重置＆繁簡/AnimationPlayer".seek(0, true)
		$"上下橫條/Esc介面提示區/重置＆繁簡/AnimationPlayer".stop()
	else:
		$"上下橫條/Esc介面提示區/重置＆繁簡/AnimationPlayer".play()
	
	if OS.get_name() == "OSX":
		$"上下橫條/Esc介面提示區/重置＆繁簡/重置/重置_win".visible = false
		$"上下橫條/Esc介面提示區/重置＆繁簡/重置/重置_mac".visible = true
		$"上下橫條/Esc介面提示區/拉字/拉字_win".visible = false
		$"上下橫條/Esc介面提示區/拉字/拉字_mac".visible = true
	else:
		$"上下橫條/Esc介面提示區/重置＆繁簡/重置/重置_win".visible = true
		$"上下橫條/Esc介面提示區/重置＆繁簡/重置/重置_mac".visible = false
		$"上下橫條/Esc介面提示區/拉字/拉字_win".visible = true
		$"上下橫條/Esc介面提示區/拉字/拉字_mac".visible = false
	
	if Global.player_status.has_split_power:
		$"上下橫條/Esc介面提示區/推字/推字-08".visible = false
		$"上下橫條/Esc介面提示區/推字/推字組字-03".visible = true
		$"上下橫條/Esc介面提示區/推字/方向鍵".position.x = 360
		$"上下橫條/Esc介面提示區/拉字".position.x = 1200
	else:
		$"上下橫條/Esc介面提示區/推字/推字-08".visible = true
		$"上下橫條/Esc介面提示區/推字/推字組字-03".visible = false
		$"上下橫條/Esc介面提示區/推字/方向鍵".position.x = 180
		$"上下橫條/Esc介面提示區/拉字".position.x = 1020
		
	$"上下橫條/Esc介面提示區/AnimationPlayer".play("show_hint")
	
func hide_esc_menu_hint():
	$"上下橫條/Esc介面提示區/AnimationPlayer".play("hide_hint")
	


func fade_black_screen(switch):
	if switch:
		$FadePanel.visible = true
		animation_player.play("FadeOut")
		await animation_player.animation_finished
	else:
		animation_player.play("FadeIn")
		await animation_player.animation_finished
		$FadePanel.visible = false
		
var is_fading_screen = false
func fade_screen(color, time_sec = 1):
	is_fading_screen = true
	
	color = Color(color)
	

	$FadePanel.visible = true
	
	var tween = create_tween()
	tween.tween_property($FadePanel, "modulate", color, time_sec).from($FadePanel.modulate).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func():
		if color.a == 0:
			$FadePanel.visible = false
		is_fading_screen = false
	)
	return tween

signal done
func cut_screen_effect(video_path):
	var img = get_viewport().get_texture().get_image()
	await get_tree().process_frame
	await get_tree().process_frame
	img.flip_y()
	
	var tex = ImageTexture.create_from_image(img)
	
	var cut_screen = load("res://Scenes/Animations/CutScreen.tscn").instantiate()
	cut_screen.texture = tex
	
	var layer = CanvasLayer.new()
	layer.layer = 30
	
	get_tree().get_root().add_child(layer)
	layer.add_child(cut_screen)
	
	var video = get_tree().get_root().get_node(video_path)
	video.visible = true
	video.play()

	cut_screen.get_node("AnimationPlayer").play("cut")
	
	await video.finished
	layer.queue_free()
	
	emit_signal("done")

func recover_cut_screen_effect(video_path):
	
	
	var cut_screen = load("res://Scenes/Animations/CutScreen.tscn").instantiate()
	
	
	var layer = CanvasLayer.new()
	layer.layer = 30
	
	get_tree().get_root().add_child(layer)
	layer.add_child(cut_screen)

	cut_screen.get_node("AnimationPlayer").play("recover")
	
	await cut_screen.get_node("AnimationPlayer").animation_finished
	
	var video = get_tree().get_root().get_node(video_path)
	video.visible = false
	
	layer.queue_free()
	
	emit_signal("done")
