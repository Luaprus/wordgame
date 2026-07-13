extends "res://Scripts/Scenes/AcquisitionPreviewBase.gd"

const PREVIEW_TITLE := "貝克思貝斯之劍 取得動畫"
const PREVIEW_KEYWORDS := PackedStringArray([
	"获取动画",
	"取得動畫",
	"圣剑",
	"聖劍",
	"贝克斯贝斯之剑",
	"貝克思貝斯之劍",
	"backspace",
	"剑",
	"劍",
])
const SOURCE_MAP := "D:/文字游戏/Scenes/Maps/第二章/05_聖劍寶庫.tscn"
const SWORD_SWING_SE := "res://Sounds/se/第二章 音效/SE_2_23_sword_big_swing_B.wav"
const SWORD_MEL_SE := "res://Sounds/se/MEL/MEL_2_24_sword.wav"

@onready var ui_layer = $UI
@onready var video_player = $VideoStreamPlayer


func _ready() -> void:
	super._ready()
	setup_preview(PREVIEW_TITLE, PREVIEW_KEYWORDS, SOURCE_MAP)
	call_deferred("_play_sequence")


func _play_sequence() -> void:
	Sound.play_se(SWORD_SWING_SE)
	await get_tree().create_timer(0.15).timeout
	Sound.play_se(SWORD_MEL_SE)
	await get_tree().create_timer(0.15).timeout

	var video_path := root_relative_path(video_player)
	await ui_layer.cut_screen_effect(video_path)
	await get_tree().create_timer(0.2).timeout
	await ui_layer.recover_cut_screen_effect(video_path)
