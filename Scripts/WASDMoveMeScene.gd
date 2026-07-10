extends Node2D

const CELL_SIZE := Vector2(60.0, 60.0)
const GRID_COLUMNS := 32
const GRID_ROWS := 18
const MOVE_TIME := 0.12
const WALK_FRAME_TIME := 0.055

const ME_DEFAULT_TEXTURE := preload("res://Sprites/me/me_default.png")
const ME_WALK_TEXTURE := preload("res://Sprites/me/me_walk.png")

@onready var _me: Sprite2D = $Me

var _cell := Vector2i(16, 9)
var _is_moving := false
var _arrival_tween: Tween
var _walk_frame_timer := 0.0


func _ready() -> void:
	_set_idle_sprite()
	_me.position = _cell_to_screen(_cell)
	queue_redraw()


func _process(delta: float) -> void:
	if not _is_moving:
		return

	_walk_frame_timer += delta
	if _walk_frame_timer >= WALK_FRAME_TIME:
		_walk_frame_timer = 0.0
		_me.frame = 1 - _me.frame


func _unhandled_input(event: InputEvent) -> void:
	if _is_moving or not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.physical_keycode:
		KEY_W:
			_try_move(Vector2i.UP)
		KEY_A:
			_try_move(Vector2i.LEFT)
		KEY_S:
			_try_move(Vector2i.DOWN)
		KEY_D:
			_try_move(Vector2i.RIGHT)


func _draw() -> void:
	var grid_size := Vector2(GRID_COLUMNS, GRID_ROWS) * CELL_SIZE
	draw_rect(Rect2(Vector2.ZERO, grid_size), Color("#080808"))

	for x in range(GRID_COLUMNS + 1):
		var px := float(x) * CELL_SIZE.x
		draw_line(Vector2(px, 0.0), Vector2(px, grid_size.y), Color(1.0, 1.0, 1.0, 0.08), 1.0)

	for y in range(GRID_ROWS + 1):
		var py := float(y) * CELL_SIZE.y
		draw_line(Vector2(0.0, py), Vector2(grid_size.x, py), Color(1.0, 1.0, 1.0, 0.08), 1.0)


func _try_move(direction: Vector2i) -> void:
	var next_cell := _cell + direction
	if next_cell.x < 0 or next_cell.y < 0 or next_cell.x >= GRID_COLUMNS or next_cell.y >= GRID_ROWS:
		_play_blocked_animation()
		return

	_cell = next_cell
	_is_moving = true
	_set_walk_sprite()

	var move_tween := create_tween()
	move_tween.tween_property(_me, "position", _cell_to_screen(_cell), MOVE_TIME).set_trans(Tween.TRANS_LINEAR)
	await move_tween.finished

	_is_moving = false
	_set_idle_sprite()


func _set_idle_sprite() -> void:
	_me.texture = ME_DEFAULT_TEXTURE
	_me.hframes = 1
	_me.vframes = 1
	_me.frame = 0
	_me.centered = true
	_walk_frame_timer = 0.0


func _set_walk_sprite() -> void:
	if is_instance_valid(_arrival_tween):
		_arrival_tween.kill()

	_me.texture = ME_WALK_TEXTURE
	_me.hframes = 2
	_me.vframes = 1
	_me.frame = 0
	_me.centered = true
	_me.scale = Vector2.ONE
	_me.modulate = Color.WHITE
	_me.rotation = 0.0
	_walk_frame_timer = 0.0


func _play_blocked_animation() -> void:
	if is_instance_valid(_arrival_tween):
		_arrival_tween.kill()

	_me.rotation = 0.0
	_arrival_tween = create_tween()
	_arrival_tween.tween_property(_me, "rotation", deg_to_rad(-5.0), 0.04)
	_arrival_tween.tween_property(_me, "rotation", deg_to_rad(5.0), 0.08)
	_arrival_tween.tween_property(_me, "rotation", 0.0, 0.04)


func _cell_to_screen(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_SIZE + CELL_SIZE / 2.0
