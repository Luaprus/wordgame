extends Node2D

const FONT := preload("res://Fonts/Zpix-v3.1.6.ttf")
const SplitBaseTexture := preload("res://assets/animations/split/base_white.png")
const SplitParticleTexture := preload("res://assets/animations/split/unzip_split.png")
const CELL_SIZE := 60.0
const GRID_COLUMNS := 32
const GRID_ROWS := 18
const WORD_FONT_SIZE := 56

@export var source_cell := Vector2i(14, 8)
@export var part_cells := [Vector2i(14, 8), Vector2i(15, 8)]
@export var source_text := "桥"
@export var part_texts := ["乔", "木"]
@export var jump_height := 30.0
@export var part_jump_heights := [30.0, 0.0]
@export var move_duration := 0.5
@export var settle_duration := 0.18
@export var loop_delay := 0.8

const SQUARE_COLOR := Color(0.96, 0.92, 0.62, 1.0)
const SQUARE_ALPHA := 0.42

var _source_label: Label
var _part_labels: Array[Label] = []
var _effect_layer: Node2D

func _ready() -> void:
	queue_redraw()
	_effect_layer = Node2D.new()
	_effect_layer.name = "EffectLayer"
	add_child(_effect_layer)
	_source_label = _make_word_label(source_text)
	_source_label.position = _grid_to_pixels(source_cell)
	add_child(_source_label)
	for i in range(part_texts.size()):
		var label := _make_word_label(part_texts[i])
		label.position = _grid_to_pixels(part_cells[i])
		label.modulate.a = 0.0
		add_child(label)
		_part_labels.append(label)
	call_deferred("_loop_preview")

func _draw() -> void:
	var grid_size := Vector2(GRID_COLUMNS * CELL_SIZE, GRID_ROWS * CELL_SIZE)
	draw_rect(Rect2(Vector2.ZERO, grid_size), Color("#080808"))
	for x in range(GRID_COLUMNS + 1):
		var px := float(x) * CELL_SIZE
		draw_line(Vector2(px, 0.0), Vector2(px, grid_size.y), Color(1.0, 1.0, 1.0, 0.08), 1.0)
	for y in range(GRID_ROWS + 1):
		var py := float(y) * CELL_SIZE
		draw_line(Vector2(0.0, py), Vector2(grid_size.x, py), Color(1.0, 1.0, 1.0, 0.08), 1.0)

func _loop_preview() -> void:
	while is_inside_tree():
		await _play_preview_once()
		await get_tree().create_timer(loop_delay).timeout

func _play_preview_once() -> void:
	_source_label.visible = true
	_source_label.modulate = Color.WHITE
	for label in _part_labels:
		label.modulate.a = 0.0
		label.visible = true

	var source_position := _grid_to_pixels(source_cell)
	var source_overlay := _build_source_overlay(source_position)
	var part_overlays := _build_part_overlays(source_position)
	var particle := _build_particle_overlay(source_position)
	_effect_layer.add_child(source_overlay)
	for overlay in part_overlays:
		_effect_layer.add_child(overlay)
	_effect_layer.add_child(particle)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(source_overlay, "modulate:a", 0.0, 0.08).set_delay(0.06)
	for overlay in part_overlays:
		tween.tween_property(overlay, "modulate:a", 1.0, 0.06)
	for i in range(part_overlays.size()):
		var overlay: Node2D = part_overlays[i]
		var target_position := _grid_to_pixels(part_cells[i])
		var part_jump_height := 0.0
		if i < part_jump_heights.size():
			part_jump_height = float(part_jump_heights[i])
		tween.tween_method(
			Callable(self, "_set_overlay_progress").bind(overlay, source_position, target_position, part_jump_height),
			0.0,
			1.0,
			move_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(particle, "modulate:a", 0.0, 0.4)
	tween.tween_property(particle, "frame", 14, 0.4).from(0)
	await tween.finished

	_source_label.visible = false
	for i in range(_part_labels.size()):
		_part_labels[i].modulate.a = 1.0
		_part_labels[i].position = _grid_to_pixels(part_cells[i])

	var settle_tween := create_tween()
	settle_tween.set_parallel(true)
	settle_tween.tween_property(source_overlay, "modulate:a", 0.0, settle_duration)
	for overlay in part_overlays:
		settle_tween.tween_property(overlay, "modulate:a", 0.0, settle_duration)
	await settle_tween.finished

	source_overlay.queue_free()
	for overlay in part_overlays:
		overlay.queue_free()
	particle.queue_free()

func _build_source_overlay(source_position: Vector2) -> Node2D:
	var overlay := Node2D.new()
	overlay.position = source_position
	overlay.z_index = 10
	var square := Sprite2D.new()
	square.texture = SplitBaseTexture
	square.position = Vector2(CELL_SIZE, CELL_SIZE) * 0.5
	square.modulate = Color(SQUARE_COLOR.r, SQUARE_COLOR.g, SQUARE_COLOR.b, SQUARE_ALPHA)
	overlay.add_child(square)
	var label := _make_word_label(source_text)
	label.position = Vector2(0, -2)
	overlay.add_child(label)
	return overlay

func _build_part_overlays(source_position: Vector2) -> Array[Node2D]:
	var overlays: Array[Node2D] = []
	for text in part_texts:
		var overlay := Node2D.new()
		overlay.position = source_position
		overlay.z_index = 11
		overlay.modulate.a = 0.0
		var label := _make_word_label(text)
		label.position = Vector2(0, -2)
		overlay.add_child(label)
		overlays.append(overlay)
	return overlays

func _build_particle_overlay(source_position: Vector2) -> Sprite2D:
	var particle := Sprite2D.new()
	particle.texture = SplitParticleTexture
	particle.hframes = 5
	particle.vframes = 3
	particle.frame = 0
	particle.position = source_position + Vector2(CELL_SIZE, CELL_SIZE) * 0.5
	particle.z_index = 12
	return particle

func _set_overlay_progress(progress: float, overlay: Node2D, start: Vector2, finish: Vector2, part_jump_height: float) -> void:
	var position := start.lerp(finish, progress)
	position.y -= sin(progress * PI) * part_jump_height
	overlay.position = position

func _grid_to_pixels(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)

func _make_word_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.size = Vector2(CELL_SIZE, CELL_SIZE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_contents = false
	label.add_theme_font_size_override("font_size", WORD_FONT_SIZE)
	label.add_theme_font_override("font", FONT)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label
