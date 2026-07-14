extends Node2D

const GLOW_SPEED := TAU * 0.72

var _lights: Array = []
var _elapsed := 0.0
var _cell_size := 60.0
var _font: Font
var _glow_texture: GradientTexture2D
var _glow_sprites: Array[Sprite2D] = []

func _ready() -> void:
	_glow_texture = _create_glow_texture()
	set_process(false)

func sync_lights(entries: Array, cell_size: float, font: Font) -> void:
	_lights = entries.duplicate(true)
	_cell_size = maxf(cell_size, 1.0)
	_font = font
	if _glow_texture == null:
		_glow_texture = _create_glow_texture()
	_ensure_glow_sprites(_lights.size())
	for i in range(_lights.size()):
		var sprite: Sprite2D = _glow_sprites[i]
		var position: Vector2 = _lights[i].get("position", Vector2.ZERO)
		sprite.position = position + Vector2(_cell_size * 0.5, _cell_size * 0.46)
		sprite.visible = true
	for i in range(_lights.size(), _glow_sprites.size()):
		_glow_sprites[i].visible = false
	set_process(not _lights.is_empty())
	queue_redraw()

func clear() -> void:
	_lights.clear()
	for sprite in _glow_sprites:
		sprite.visible = false
	set_process(false)
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed = fmod(_elapsed + delta, 10.0)
	for i in range(_lights.size()):
		var phase_offset: float = float(_lights[i].get("phase_offset", 0.0))
		var phase: float = _elapsed * GLOW_SPEED + phase_offset
		var wave: float = 0.5 + 0.5 * sin(phase)
		var pulse: float = pow(wave, 1.25)
		var sprite: Sprite2D = _glow_sprites[i]
		sprite.scale = Vector2.ONE * (_cell_size * (1.55 + pulse * 0.18) / 128.0)
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.9 + pulse * 0.1)
	queue_redraw()

func _ensure_glow_sprites(required_count: int) -> void:
	while _glow_sprites.size() < required_count:
		var sprite := Sprite2D.new()
		sprite.texture = _glow_texture
		sprite.z_index = 0
		add_child(sprite)
		_glow_sprites.append(sprite)

func _create_glow_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.72, 0.98, 1.0, 0.44),
		Color(0.56, 0.93, 1.0, 0.17),
		Color(0.40, 0.82, 1.0, 0.0)
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.32, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture

func _draw() -> void:
	if _font == null:
		return
	for entry in _lights:
		var position: Vector2 = entry.get("position", Vector2.ZERO)
		var phase_offset: float = float(entry.get("phase_offset", 0.0))
		var phase: float = _elapsed * GLOW_SPEED + phase_offset
		var wave: float = 0.5 + 0.5 * sin(phase)
		var pulse: float = pow(wave, 1.25)
		var baseline := position + Vector2(0.0, _cell_size - 8.0)
		var far_color := Color(0.48, 0.86, 1.0, 0.045 + pulse * 0.055)
		var glow_color := Color(0.58, 0.92, 1.0, 0.08 + pulse * 0.10)
		var mid_color := Color(0.72, 0.96, 1.0, 0.14 + pulse * 0.16)
		var near_color := Color(0.86, 0.99, 1.0, 0.23 + pulse * 0.20)
		# Low-opacity full glyphs add a soft bloom without hard geometric edges.
		draw_string(_font, baseline + Vector2(0.0, 5.0), "光", HORIZONTAL_ALIGNMENT_CENTER, _cell_size, 70, far_color)
		draw_string(_font, baseline + Vector2(0.0, 3.0), "光", HORIZONTAL_ALIGNMENT_CENTER, _cell_size, 60, glow_color)
		draw_string(_font, baseline + Vector2(0.0, 1.0), "光", HORIZONTAL_ALIGNMENT_CENTER, _cell_size, 51, mid_color)
		draw_string(_font, baseline, "光", HORIZONTAL_ALIGNMENT_CENTER, _cell_size, 46, near_color)
