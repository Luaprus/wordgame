extends Node2D

const BASE_RATIO := 0.28
const LENGTH_RATIO := 0.24
const GAP_RATIO := 0.12
const DIRECTION_NAMES := {
	2: "down",
	4: "left",
	6: "right",
	8: "up"
}

@export var cell_size := 60.0
@export var show_duration := 0.18
@export var use_auto_hide := false
@export var player_center := Vector2(30, 30)
@export var fill_color := Color(0.98, 0.87, 0.22, 0.95)
@export var outline_color := Color(0.06, 0.06, 0.06, 0.95)

var _fill: Polygon2D
var _outline: Line2D
var _timer: Timer


func _ready() -> void:
	visible = false
	z_index = 21
	z_as_relative = false
	_ensure_nodes()
	_apply_geometry()


func show_for_direction_code(direction_code: int) -> void:
	if not DIRECTION_NAMES.has(direction_code):
		return
	_ensure_nodes()
	_apply_geometry()
	var direction := _direction_code_to_vector(direction_code)
	position = player_center + direction * (cell_size * (0.5 + GAP_RATIO))
	rotation = direction.angle()
	modulate = Color(1, 1, 1, 1)
	visible = true
	if use_auto_hide and show_duration > 0.0:
		_timer.start(show_duration)
	else:
		_timer.stop()


func hide_marker() -> void:
	_hide_marker()


func _hide_marker() -> void:
	visible = false


func _ensure_nodes() -> void:
	if has_node("Fill"):
		_fill = $Fill
	else:
		_fill = Polygon2D.new()
		_fill.name = "Fill"
		add_child(_fill)

	if has_node("Outline"):
		_outline = $Outline
	else:
		_outline = Line2D.new()
		_outline.name = "Outline"
		add_child(_outline)

	if has_node("HideTimer"):
		_timer = $HideTimer
	else:
		_timer = Timer.new()
		_timer.name = "HideTimer"
		_timer.one_shot = true
		add_child(_timer)

	if not _timer.timeout.is_connected(_hide_marker):
		_timer.timeout.connect(_hide_marker)


func _apply_geometry() -> void:
	var points := _local_points()
	_fill.color = fill_color
	_fill.polygon = points

	_outline.default_color = outline_color
	_outline.width = 2.0
	var outline_points := PackedVector2Array(points)
	if not outline_points.is_empty():
		outline_points.append(outline_points[0])
	_outline.points = outline_points


func _local_points() -> PackedVector2Array:
	var half_base := cell_size * BASE_RATIO * 0.5
	var length := cell_size * LENGTH_RATIO
	return PackedVector2Array([
		Vector2(0, -half_base),
		Vector2(0, half_base),
		Vector2(length, 0)
	])


func _direction_code_to_vector(direction_code: int) -> Vector2:
	match direction_code:
		2:
			return Vector2.DOWN
		4:
			return Vector2.LEFT
		6:
			return Vector2.RIGHT
		8:
			return Vector2.UP
		_:
			return Vector2.ZERO
