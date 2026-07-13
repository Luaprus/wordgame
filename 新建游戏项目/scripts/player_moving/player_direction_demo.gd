extends Node2D

const PrecisionMovement = preload("res://scripts/precision_movement.gd")
const PlayerDirectionMarker = preload("res://scripts/player_moving/player_direction_marker.gd")

const CELL_SIZE := 60
const GRID_SIZE := Vector2i(9, 5)
const MARKER_DURATION := 0.18

var player_grid := Vector2i(GRID_SIZE.x / 2, GRID_SIZE.y / 2)
var player_label: Label
var title_label: Label
var hint_label: Label
var marker_root: Node2D
var marker_fill: Polygon2D
var marker_outline: Line2D
var marker_timer: Timer
var marker_direction := Vector2i.ZERO

func _ready() -> void:
	_build_scene()
	_sync_layout()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	var direction := PrecisionMovement.direction_from_keycode(key_event.keycode)
	if not PrecisionMovement.should_process_key_event(key_event.pressed, key_event.echo, direction):
		return
	if direction == Vector2i.ZERO:
		return
	var next_pos := Vector2i(
		clampi(player_grid.x + direction.x, 0, GRID_SIZE.x - 1),
		clampi(player_grid.y + direction.y, 0, GRID_SIZE.y - 1)
	)
	if next_pos == player_grid:
		return
	player_grid = next_pos
	_show_marker(direction)
	_sync_layout()

func _draw() -> void:
	var board := _board_rect()
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.05, 0.06, 0.08, 1.0), true)
	draw_rect(board, Color(0.11, 0.13, 0.16, 1.0), true)
	draw_rect(board, Color(0.79, 0.73, 0.52, 0.95), false, 2.0)

	for x in range(GRID_SIZE.x + 1):
		var from := board.position + Vector2(x * CELL_SIZE, 0)
		var to := board.position + Vector2(x * CELL_SIZE, board.size.y)
		draw_line(from, to, Color(0.28, 0.31, 0.36, 1.0), 1.0)

	for y in range(GRID_SIZE.y + 1):
		var from := board.position + Vector2(0, y * CELL_SIZE)
		var to := board.position + Vector2(board.size.x, y * CELL_SIZE)
		draw_line(from, to, Color(0.28, 0.31, 0.36, 1.0), 1.0)

func _build_scene() -> void:
	title_label = _make_label("Player Direction Demo", 26, Color(0.96, 0.93, 0.83))
	add_child(title_label)

	hint_label = _make_label("Arrow keys / WASD: move the player and preview the triangle marker", 16, Color(0.83, 0.86, 0.9))
	add_child(hint_label)

	player_label = _make_label("我", 44, Color(0.92, 0.92, 0.92), Color(0.05, 0.05, 0.05))
	player_label.name = "Player"
	player_label.size = Vector2(CELL_SIZE, CELL_SIZE)
	add_child(player_label)

	marker_root = Node2D.new()
	marker_root.name = "PlayerDirectionMarker"
	marker_root.visible = false
	add_child(marker_root)

	marker_fill = Polygon2D.new()
	marker_fill.color = Color(0.98, 0.87, 0.22, 0.95)
	marker_root.add_child(marker_fill)

	marker_outline = Line2D.new()
	marker_outline.width = 2.0
	marker_outline.default_color = Color(0.06, 0.06, 0.06, 0.95)
	marker_root.add_child(marker_outline)

	marker_timer = Timer.new()
	marker_timer.wait_time = MARKER_DURATION
	marker_timer.one_shot = true
	marker_timer.timeout.connect(_hide_marker)
	add_child(marker_timer)

func _sync_layout() -> void:
	var board := _board_rect()
	title_label.position = board.position + Vector2(0, -88)
	title_label.size = Vector2(board.size.x, 28)
	hint_label.position = board.position + Vector2(0, -48)
	hint_label.size = Vector2(board.size.x, 22)
	player_label.position = _grid_to_pixels(player_grid)
	_sync_marker()
	queue_redraw()

func _show_marker(direction: Vector2i) -> void:
	marker_direction = direction
	marker_root.visible = true
	_sync_marker()
	marker_timer.start()

func _hide_marker() -> void:
	marker_root.visible = false

func _sync_marker() -> void:
	if marker_direction == Vector2i.ZERO:
		return
	var center := _grid_to_pixels(player_grid) + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
	var points := PlayerDirectionMarker.local_points(CELL_SIZE, marker_direction)
	marker_root.position = center + PlayerDirectionMarker.anchor_offset(CELL_SIZE, marker_direction)
	marker_fill.polygon = points
	var outline_points := PackedVector2Array(points)
	if not outline_points.is_empty():
		outline_points.append(outline_points[0])
	marker_outline.points = outline_points

func _board_rect() -> Rect2:
	var size := Vector2(GRID_SIZE.x * CELL_SIZE, GRID_SIZE.y * CELL_SIZE)
	var top_left := (get_viewport_rect().size - size) * 0.5
	return Rect2(top_left, size)

func _grid_to_pixels(pos: Vector2i) -> Vector2:
	var board := _board_rect()
	return board.position + Vector2(pos.x * CELL_SIZE, pos.y * CELL_SIZE)

func _make_label(text: String, font_size: int, font_color: Color, bg_color := Color(0, 0, 0, 0)) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	label.add_theme_stylebox_override("normal", style)
	return label
