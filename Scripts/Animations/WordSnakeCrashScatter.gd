extends Node

signal crash_finished

const CRASH_SE_DIR := "res://Sounds/se/第二章 音效/"
const CRASH_SE_PREFIX := "SE_2_12_word_crash_"

@export var target_path: NodePath = NodePath("..")
@export var word_sprite_path: NodePath = NodePath("../WordSprite")
@export var remove_owner_after_crash := true
@export var play_sound := true
@export var duration := 1.0
@export var frames_per_second := 30.0

var _is_crashing := false


func been_snake_crash() -> void:
	await crash()


func crash() -> void:
	if _is_crashing:
		return

	var target_owner := _resolve_target_owner()
	var word_sprite := _resolve_word_sprite(target_owner)
	if word_sprite == null:
		return

	_is_crashing = true
	_prepare_owner(target_owner)
	_play_crash_sound()
	await _play_original_snake_crash(word_sprite)
	_finish_owner(target_owner, word_sprite)
	_is_crashing = false
	crash_finished.emit()


func _resolve_target_owner() -> Node:
	if target_path != NodePath("") and has_node(target_path):
		return get_node(target_path)
	return get_parent()


func _resolve_word_sprite(target_owner: Node) -> Node2D:
	if word_sprite_path != NodePath("") and has_node(word_sprite_path):
		return get_node(word_sprite_path) as Node2D
	if target_owner and target_owner.has_node("WordSprite"):
		return target_owner.get_node("WordSprite") as Node2D
	if target_owner is Node2D:
		return target_owner as Node2D
	return null


func _prepare_owner(target_owner: Node) -> void:
	if target_owner and target_owner.has_method("lock"):
		target_owner.lock()
	if target_owner and "can_push" in target_owner:
		target_owner.can_push = false


func _play_crash_sound() -> void:
	if not play_sound:
		return

	var sound := get_node_or_null("/root/Sound")
	if sound == null or not sound.has_method("play_se"):
		return

	var suffix := "ABCD"[randi() % 4]
	sound.play_se(CRASH_SE_DIR + CRASH_SE_PREFIX + suffix + ".wav", 0)


func _play_original_snake_crash(word_sprite: Node2D) -> void:
	var original_position: Vector2 = word_sprite.position
	var original_rotation: float = word_sprite.rotation_degrees
	var original_modulate: Color = word_sprite.modulate
	var rand_adjust := randf()
	var time := 0.0
	var step := 1.0 / frames_per_second

	while time < duration:
		var curve := pow(time * 15.0 - 5.0, 2.0) / 3.0 - 25.0 / 3.0
		var diff_point := Vector2(time * 15.0, curve) * 10.0
		var rand := sin(rand_adjust) * 43758.5453123
		rand -= floor(rand)
		rand = rand * 2.0 - 1.0

		var adjust := Vector2.ONE * (0.5 + rand / 2.0)
		var end_rotation := rand * 360.0
		var now_rotation := Vector2.ZERO.lerp(Vector2(end_rotation, 0.0), time).x
		var opacity := ease(1.0 - time, 0.2)

		word_sprite.position = original_position + diff_point * adjust
		word_sprite.rotation_degrees = original_rotation + now_rotation
		word_sprite.modulate = Color(original_modulate.r, original_modulate.g, original_modulate.b, original_modulate.a * opacity)

		await get_tree().process_frame
		time += step


func _finish_owner(target_owner: Node, word_sprite: Node2D) -> void:
	if not remove_owner_after_crash:
		return

	if target_owner and target_owner.has_method("exist"):
		target_owner.exist(false)
	elif target_owner is CanvasItem:
		(target_owner as CanvasItem).visible = false
	else:
		word_sprite.visible = false

	var game_map = get_node_or_null("/root/Global").game_map if get_node_or_null("/root/Global") else null
	if game_map and game_map.has_method("check_rule"):
		game_map.check_rule()
