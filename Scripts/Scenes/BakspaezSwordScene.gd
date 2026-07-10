extends Control

const VIDEO_PATH := "res://Sprites/ch2_sword/u_sword.ogv"
const BIG_SWING_SE_PATH := "res://Sounds/se/ch2_sword/SE_2_23_sword_big_swing_B.wav"
const MELODY_PATH := "res://Sounds/se/ch2_sword/MEL_2_24_sword.wav"
const MAX_PLAY_SECONDS := 28.0

var _video: VideoStreamPlayer
var _swing: AudioStreamPlayer
var _melody: AudioStreamPlayer
var _fade: ColorRect
var _message: Label
var _running := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_screen()
	_build_audio()
	call_deferred("_play")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not _running:
		_play()


func _build_screen() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color.BLACK
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_video = VideoStreamPlayer.new()
	_video.name = "HolySwordVideo"
	_video.stream = load(VIDEO_PATH)
	_video.set_anchors_preset(Control.PRESET_FULL_RECT)
	_video.offset_left = 0
	_video.offset_top = 0
	_video.offset_right = 0
	_video.offset_bottom = 0
	_video.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_video.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_video.set("expand", true)
	add_child(_video)

	_message = Label.new()
	_message.name = "FallbackMessage"
	_message.visible = false
	_message.text = "Cannot play res://Sprites/ch2_sword/u_sword.ogv"
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override("font_size", 28)
	_message.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72, 1.0))
	_message.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_message)

	_fade = ColorRect.new()
	_fade.name = "Fade"
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


func _build_audio() -> void:
	_swing = _make_audio_player("SwordBigSwing", BIG_SWING_SE_PATH)
	_melody = _make_audio_player("SwordMelody", MELODY_PATH)


func _make_audio_player(node_name: String, path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.stream = load(path)
	player.bus = _bus_or_master("SE")
	add_child(player)
	return player


func _bus_or_master(bus_name: String) -> String:
	return bus_name if AudioServer.get_bus_index(bus_name) >= 0 else "Master"


func _play() -> void:
	_running = true
	_message.visible = false
	_video.stop()

	await _fade_to(1.0, 0.0)
	await get_tree().create_timer(0.35).timeout
	_play_audio(_swing)
	_play_audio(_melody)

	_video.play()
	await _fade_to(0.0, 0.25)
	await get_tree().create_timer(0.25).timeout

	if not _video.is_playing():
		_message.visible = true
		_running = false
		return

	var elapsed := 0.0
	while _video.is_playing() and elapsed < MAX_PLAY_SECONDS:
		elapsed += get_process_delta_time()
		await get_tree().process_frame

	await _fade_to(1.0, 0.35)
	_video.stop()
	_running = false


func _play_audio(player: AudioStreamPlayer) -> void:
	player.stop()
	if player.stream:
		player.play()


func _fade_to(alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, duration)
	await tween.finished
