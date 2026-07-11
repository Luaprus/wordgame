extends Control

const VIDEO_PATH := "res://Sprites/ch3_glove/u_glove.ogv"
const PUT_ON_SE_PATH := "res://Sounds/se/第三章 音效/SE_3_19_glove_put_on.wav"
const MELODY_PATH := "res://Sounds/se/MEL/MEL_3_19.1_gloves.wav"
const ORIGINAL_VIDEO_SIZE := Vector2(1920, 1080)

var _video: VideoStreamPlayer
var _put_on: AudioStreamPlayer
var _melody: AudioStreamPlayer
var _running := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_screen()
	_build_audio()
	call_deferred("_play")


func _build_screen() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color.BLACK
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_video = VideoStreamPlayer.new()
	_video.name = "VideoStreamPlayer"
	_video.stream = load(VIDEO_PATH)
	_video.position = Vector2.ZERO
	_video.size = ORIGINAL_VIDEO_SIZE
	_video.set("expand", false)
	_video.visible = false
	add_child(_video)


func _build_audio() -> void:
	_put_on = _make_audio_player("GlovePutOn", PUT_ON_SE_PATH, 0.0)
	_melody = _make_audio_player("DurlGlovesMelody", MELODY_PATH, 5.0)


func _make_audio_player(node_name: String, path: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.stream = load(path)
	player.volume_db = volume_db
	player.bus = _bus_or_master("SE")
	add_child(player)
	return player


func _bus_or_master(bus_name: String) -> String:
	return bus_name if AudioServer.get_bus_index(bus_name) >= 0 else "Master"


func _play() -> void:
	if _running:
		return

	_running = true
	_video.stop()
	_video.visible = true
	_play_audio(_put_on)
	await _wait_frames(30)
	_play_audio(_melody)
	_video.play()

	if _video.stream:
		await _video.finished

	_video.visible = false
	_running = false


func _play_audio(player: AudioStreamPlayer) -> void:
	player.stop()
	if player.stream:
		player.play()


func _wait_frames(frame_count: int) -> void:
	for _i in range(frame_count):
		await get_tree().process_frame
