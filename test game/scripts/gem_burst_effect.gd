extends Node2D

const TAU_SPEED := TAU * 0.78 * 0.8
const DISTANCE_PHASE := 0.72

var _elapsed := 0.0
var _origin := Vector2.ZERO
var _cell_size := 60.0
var _active := false

func _ready() -> void:
	set_process(false)

func play_at(origin: Vector2, cell_size: float, _duration := 0.78, _seed_value := 1947) -> void:
	_origin = origin
	_cell_size = maxf(cell_size, 1.0)
	_elapsed = 0.0
	_active = true
	set_process(true)

func stop() -> void:
	_active = false
	_elapsed = 0.0
	set_process(false)

func _process(delta: float) -> void:
	_elapsed = fmod(_elapsed + delta, 10.0)

func color_for_position(position: Vector2, base_color: Color) -> Color:
	if not _active:
		return base_color
	var distance_in_cells: float = position.distance_to(_origin) / _cell_size
	var phase: float = _elapsed * TAU_SPEED - distance_in_cells * DISTANCE_PHASE
	var wave: float = 0.5 + 0.5 * sin(phase)
	var pulse: float = pow(wave, 1.55)
	var target_color := Color(0.42, 1.0, 1.0, base_color.a)
	return base_color.lerp(target_color, 0.28 + pulse * 0.62)
