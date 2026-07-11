extends Node2D

const CELL_SIZE := Vector2(60.0, 60.0)
const GRID_COLUMNS := 32
const GRID_ROWS := 18

@onready var _slime := $Slime
@onready var _animation_player := $Slime/AnimationPlayer

var _points := [
	Vector2i(8, 10),
	Vector2i(9, 10),
	Vector2i(10, 10),
	Vector2i(10, 9),
	Vector2i(9, 9),
	Vector2i(8, 9),
]
var _point_index := 0


func _ready() -> void:
	_slime.position = _cell_to_origin(_points[0])
	queue_redraw()
	call_deferred("_loop")


func _draw() -> void:
	var grid_size := Vector2(GRID_COLUMNS, GRID_ROWS) * CELL_SIZE
	draw_rect(Rect2(Vector2.ZERO, grid_size), Color("#080808"))

	for x in range(GRID_COLUMNS + 1):
		var px := float(x) * CELL_SIZE.x
		draw_line(Vector2(px, 0.0), Vector2(px, grid_size.y), Color(1.0, 1.0, 1.0, 0.08), 1.0)

	for y in range(GRID_ROWS + 1):
		var py := float(y) * CELL_SIZE.y
		draw_line(Vector2(0.0, py), Vector2(grid_size.x, py), Color(1.0, 1.0, 1.0, 0.08), 1.0)


func _loop() -> void:
	while is_inside_tree():
		var next_index := (_point_index + 1) % _points.size()
		_animation_player.stop()
		_animation_player.play("slime_move")

		var tween := create_tween()
		tween.tween_property(_slime, "position", _cell_to_origin(_points[next_index]), 0.35).set_trans(Tween.TRANS_LINEAR)
		await tween.finished

		_point_index = next_index
		await get_tree().create_timer(0.35).timeout


func _cell_to_origin(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_SIZE
