extends "res://Scripts/Scenes/AcquisitionPreviewBase.gd"

const PREVIEW_TITLE := "四目頭盔 取得動畫"
const PREVIEW_KEYWORDS := PackedStringArray([
	"获取动画",
	"取得動畫",
	"头盔",
	"頭盔",
	"四目头盔",
	"四目頭盔",
	"helmet",
	"four eye helmet",
])
const SOURCE_MAP := "D:/文字游戏/Scenes/Maps/第四章/12_寶庫_穹頂.tscn"
const HELMET_DROP_SE := "res://Sounds/se/第四章 音效/SE_4_32_helmet_drop_D.wav"
const HELMET_PUT_ON_SE := "res://Sounds/se/第四章 音效/SE_4_33_helmet_put_on_B.wav"
const HELMET_MEL_SE := "res://Sounds/se/MEL/MEL_4_33.1_helmet.wav"

@onready var helmet_drop_scene = $HelmetDropScene
@onready var helmet_drop_animation = $HelmetDropScene/MainMap/AnimationPlayer
@onready var split_sprite = $HelmetDropScene/SplitScreen/sprite
@onready var split_animation = $HelmetDropScene/SplitScreen/sprite/AnimationPlayer
@onready var helmet_video = $HelmetDropScene/MainMap/影片/VideoStreamPlayer


func _ready() -> void:
	super._ready()
	setup_preview(PREVIEW_TITLE, PREVIEW_KEYWORDS, SOURCE_MAP)
	call_deferred("_play_sequence")


func _play_sequence() -> void:
	helmet_drop_animation.play("HelmetDrop")
	await get_tree().create_timer(1.5).timeout
	Sound.play_se(HELMET_DROP_SE)
	await get_tree().create_timer(2.0).timeout
	Sound.play_se(HELMET_PUT_ON_SE)
	await get_tree().create_timer(1.5).timeout
	Sound.play_se(HELMET_MEL_SE)
	await _split_screen_effect()


func _split_screen_effect() -> void:
	var img := get_viewport().get_texture().get_image()
	await get_tree().process_frame
	await get_tree().process_frame
	img.flip_y()

	split_sprite.texture = ImageTexture.create_from_image(img)
	split_sprite.visible = true

	helmet_video.visible = true
	helmet_video.play()
	split_animation.play("start")

	await helmet_video.finished
	await get_tree().create_timer(1.0).timeout

	split_animation.play("end")
	await split_animation.animation_finished

	helmet_video.visible = false
	split_sprite.visible = false
