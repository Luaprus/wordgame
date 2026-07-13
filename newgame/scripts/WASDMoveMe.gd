extends Node2D

const WALK_FRAME_TIME := 0.055
const ME_DEFAULT_TEXTURE := preload("res://assets/player/me_default.png")
const ME_WALK_TEXTURE := preload("res://assets/player/me_walk.png")

@onready var _me: Sprite2D = $Me

var _is_moving := false
var _walk_frame_timer := 0.0


func _ready() -> void:
	_set_idle_sprite()


func _process(delta: float) -> void:
	if not _is_moving:
		return
	_walk_frame_timer += delta
	if _walk_frame_timer >= WALK_FRAME_TIME:
		_walk_frame_timer = 0.0
		_me.frame = 1 - _me.frame


func set_moving(moving: bool) -> void:
	if moving == _is_moving:
		return
	_is_moving = moving
	if _is_moving:
		_set_walk_sprite()
	else:
		_set_idle_sprite()


func _set_idle_sprite() -> void:
	_me.texture = ME_DEFAULT_TEXTURE
	_me.hframes = 1
	_me.vframes = 1
	_me.frame = 0
	_me.centered = true
	_walk_frame_timer = 0.0


func _set_walk_sprite() -> void:
	_me.texture = ME_WALK_TEXTURE
	_me.hframes = 2
	_me.vframes = 1
	_me.frame = 0
	_me.centered = true
	_walk_frame_timer = 0.0
