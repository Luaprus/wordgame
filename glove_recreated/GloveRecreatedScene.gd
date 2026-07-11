extends Control

const REFERENCE_PATH := "res://glove_recreated/glove_reference.png"
const GLOVE_MELODY_PATH := "res://Sounds/se/MEL/MEL_3_19.1_gloves.wav"
const GLOVE_SE_PATH := "res://Sounds/se/第三章 音效/SE_3_19_glove_put_on.wav"

const FRAME_A_REGION := Rect2(120, 110, 560, 680)
const FRAME_B_REGION := Rect2(795, 105, 560, 680)
const MAX_PLAY_SECONDS := 4.2

const MAIN_SHADER := """
shader_type canvas_item;
uniform float cutoff : hint_range(0.0, 0.3) = 0.06;

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	float strength = max(max(src.r, src.g), src.b);
	float alpha = smoothstep(cutoff, cutoff + 0.08, strength);
	COLOR = vec4(src.rgb, alpha);
}
"""

const GLOW_SHADER := """
shader_type canvas_item;
render_mode blend_add;
uniform float cutoff : hint_range(0.0, 0.3) = 0.06;
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 0.35);

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	float strength = max(max(src.r, src.g), src.b);
	float alpha = smoothstep(cutoff, cutoff + 0.1, strength);
	COLOR = vec4(glow_color.rgb, alpha * glow_color.a);
}
"""

var _stage: Node2D
var _frame_a: Node2D
var _frame_b: Node2D
var _fade: ColorRect
var _message: Label
var _melody: AudioStreamPlayer
var _sfx: AudioStreamPlayer
var _running := false
var _reference_texture: Texture2D


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_scene()
	_build_audio()
	call_deferred("_play")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _stage != null:
		_center_stage()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not _running:
		_play()


func _build_scene() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color.BLACK
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_stage = Node2D.new()
	_stage.name = "Stage"
	add_child(_stage)

	_frame_a = _make_frame_group("FrameA", FRAME_A_REGION)
	_frame_b = _make_frame_group("FrameB", FRAME_B_REGION)
	_stage.add_child(_frame_a)
	_stage.add_child(_frame_b)

	_message = Label.new()
	_message.name = "Hint"
	_message.text = "Press Enter to replay"
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override("font_size", 26)
	_message.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	_message.anchor_left = 0.0
	_message.anchor_top = 1.0
	_message.anchor_right = 1.0
	_message.anchor_bottom = 1.0
	_message.offset_top = -80.0
	_message.offset_bottom = -24.0
	add_child(_message)

	_fade = ColorRect.new()
	_fade.name = "Fade"
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)

	_center_stage()
	_reset_pose()


func _build_audio() -> void:
	_melody = _make_audio_player("GloveMelody", GLOVE_MELODY_PATH)
	_sfx = _make_audio_player("GloveEquip", GLOVE_SE_PATH)


func _make_audio_player(node_name: String, path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.stream = load(path)
	player.bus = _bus_or_master("SE")
	add_child(player)
	return player


func _bus_or_master(bus_name: String) -> String:
	return bus_name if AudioServer.get_bus_index(bus_name) >= 0 else "Master"


func _center_stage() -> void:
	_stage.position = size * 0.5


func _make_frame_group(name: String, region: Rect2) -> Node2D:
	var group := Node2D.new()
	group.name = name

	var glow := Sprite2D.new()
	glow.name = "Glow"
	glow.texture = _atlas_from_region(region)
	glow.centered = true
	glow.scale = Vector2(1.06, 1.06)
	glow.material = _shader_material(GLOW_SHADER)
	group.add_child(glow)

	var main := Sprite2D.new()
	main.name = "Main"
	main.texture = _atlas_from_region(region)
	main.centered = true
	main.material = _shader_material(MAIN_SHADER)
	group.add_child(main)

	return group


func _atlas_from_region(region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = _load_reference_texture()
	atlas.region = region
	atlas.filter_clip = true
	return atlas


func _load_reference_texture() -> Texture2D:
	if _reference_texture != null:
		return _reference_texture
	var image := Image.load_from_file(REFERENCE_PATH)
	_reference_texture = ImageTexture.create_from_image(image)
	return _reference_texture


func _shader_material(shader_code: String) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = shader_code
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _reset_pose() -> void:
	_set_group_alpha(_frame_a, 1.0)
	_set_group_alpha(_frame_b, 0.0)

	_frame_a.position = Vector2(-28, 24)
	_frame_b.position = Vector2(18, -10)
	_frame_a.scale = Vector2.ONE * 0.94
	_frame_b.scale = Vector2.ONE * 1.03
	_frame_a.rotation_degrees = -3.0
	_frame_b.rotation_degrees = 2.0


func _play() -> void:
	_running = true
	_reset_pose()
	_play_audio(_sfx)
	_play_audio(_melody)
	await _fade_to(0.0, 0.25)
	await _animate_sequence()
	await _fade_to(1.0, 0.35)
	_running = false


func _animate_sequence() -> void:
	var elapsed := 0.0
	while elapsed < MAX_PLAY_SECONDS:
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(_frame_a, "modulate:a", 0.0, 0.22)
		tween.tween_property(_frame_b, "modulate:a", 1.0, 0.22)
		tween.tween_property(_frame_a, "position", Vector2(-42, 34), 0.22).set_trans(Tween.TRANS_SINE)
		tween.tween_property(_frame_b, "position", Vector2(0, 8), 0.22).set_trans(Tween.TRANS_SINE)
		tween.tween_property(_frame_a, "scale", Vector2.ONE * 0.9, 0.22).set_trans(Tween.TRANS_SINE)
		tween.tween_property(_frame_b, "scale", Vector2.ONE * 1.0, 0.22).set_trans(Tween.TRANS_SINE)
		tween.tween_property(_frame_a, "rotation_degrees", -6.0, 0.22)
		tween.tween_property(_frame_b, "rotation_degrees", 0.0, 0.22)
		await tween.finished
		elapsed += 0.22
		if elapsed >= MAX_PLAY_SECONDS:
			break

		var tween_back := create_tween()
		tween_back.set_parallel(true)
		tween_back.tween_property(_frame_a, "modulate:a", 1.0, 0.22)
		tween_back.tween_property(_frame_b, "modulate:a", 0.0, 0.22)
		tween_back.tween_property(_frame_a, "position", Vector2(-28, 24), 0.22).set_trans(Tween.TRANS_SINE)
		tween_back.tween_property(_frame_b, "position", Vector2(18, -10), 0.22).set_trans(Tween.TRANS_SINE)
		tween_back.tween_property(_frame_a, "scale", Vector2.ONE * 0.94, 0.22).set_trans(Tween.TRANS_SINE)
		tween_back.tween_property(_frame_b, "scale", Vector2.ONE * 1.03, 0.22).set_trans(Tween.TRANS_SINE)
		tween_back.tween_property(_frame_a, "rotation_degrees", -3.0, 0.22)
		tween_back.tween_property(_frame_b, "rotation_degrees", 2.0, 0.22)
		await tween_back.finished
		elapsed += 0.22


func _set_group_alpha(group: Node2D, value: float) -> void:
	group.modulate.a = value


func _play_audio(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.stop()
	if player.stream:
		player.play()


func _fade_to(alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, duration)
	await tween.finished
