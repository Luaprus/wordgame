extends "res://Scripts/Scenes/AcquisitionPreviewBase.gd"

const PREVIEW_TITLE := "杜爾手套 取得動畫"
const PREVIEW_KEYWORDS := PackedStringArray([
	"获取动画",
	"取得動畫",
	"手套",
	"杜尔手套",
	"杜爾手套",
	"durl gloves",
	"glove",
	"gloves",
])
const SOURCE_MAP := "D:/文字游戏/Scenes/Maps/第三章/04_手套教學.tscn"
const GLOVE_PUT_ON_SE := "res://Sounds/se/第三章 音效/SE_3_19_glove_put_on.wav"
const GLOVE_MEL_SE := "res://Sounds/se/MEL/MEL_3_19.1_gloves.wav"

@onready var video_player = $VideoStreamPlayer


func _ready() -> void:
	super._ready()
	setup_preview(PREVIEW_TITLE, PREVIEW_KEYWORDS, SOURCE_MAP)
	call_deferred("_play_sequence")


func _play_sequence() -> void:
	Sound.play_se(GLOVE_PUT_ON_SE)
	await get_tree().create_timer(0.5).timeout
	Sound.play_se(GLOVE_MEL_SE, 5)
	await _push_screen_effect()


func _push_screen_effect() -> void:
	var img := get_viewport().get_texture().get_image()
	await get_tree().process_frame
	await get_tree().process_frame
	img.flip_y()

	var tex := ImageTexture.create_from_image(img)
	var screen = load("res://Scenes/Animations/PushScreen.tscn").instantiate()
	screen.texture = tex
	screen.name = "screen"

	var layer := CanvasLayer.new()
	layer.layer = 30
	get_tree().get_root().add_child(layer)
	layer.add_child(screen)

	video_player.visible = true
	video_player.play()
	screen.get_node("AnimationPlayer").play("push_out")

	await video_player.finished
	screen.get_node("AnimationPlayer").play("push_in")
	await screen.get_node("AnimationPlayer").animation_finished

	video_player.visible = false
	layer.queue_free()
