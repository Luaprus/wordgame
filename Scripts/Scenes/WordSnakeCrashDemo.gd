extends Node2D

const CELL_SIZE := Vector2(60.0, 60.0)
const GRID_COLUMNS := 32
const GRID_ROWS := 18

@onready var _word := $Word
@onready var _word_sprite := $Word/WordSprite
@onready var _scatter := $Word/WordSnakeCrashScatter


func _ready() -> void:
	_word.position = _cell_to_origin(Vector2i(15, 9))
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
		_reset_word()
		await get_tree().create_timer(0.8).timeout
		await _scatter.crash()
		await get_tree().create_timer(0.7).timeout


func _reset_word() -> void:
	_word.visible = true
	_word_sprite.visible = true
	_word_sprite.position = Vector2(30, 30)
	_word_sprite.rotation_degrees = 0.0
	_word_sprite.modulate = Color.WHITE
	_word_sprite.scale = Vector2.ONE


func _cell_to_origin(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_SIZE
