extends Node2D

const GridWorld = preload("res://scripts/grid_world.gd")
const LevelLoader = preload("res://scripts/level_loader.gd")
const HelmetR1 = preload("res://levels/helmet/helmet_r1.gd")
const PageCamera = preload("res://scripts/page_camera.gd")
const PrecisionMovement = preload("res://scripts/precision_movement.gd")
const DemoRunner = preload("res://scripts/demo_runner.gd")
const OriginalFont = preload("res://Fonts/Zpix.tres")

const MOVE_REPEAT_INTERVAL := 0.28
const FAST_MOVE_REPEAT_INTERVAL := 0.12
const WORD_FONT_SIZE := 42

var world := GridWorld.new()
var page_camera := PageCamera.new()
var demo := DemoRunner.new()
var entity_labels: Dictionary = {}
var player_label: Label
var map_layer: Node2D
var demo_timer: Timer
var held_move_directions: Array[Vector2i] = []
var move_repeat_elapsed := 0.0

func _ready() -> void:
	world.load_level(HelmetR1.build_level())
	page_camera.sync_to_world(world)
	_build_scene()
	_refresh_view()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	var direction := _direction_from_key(key_event.keycode)
	if direction != Vector2i.ZERO:
		if key_event.echo:
			return
		_set_direction_held(direction, key_event.pressed)
		if key_event.pressed:
			move_repeat_elapsed = 0.0
			_apply_direction_step(direction)
		return
	if not PrecisionMovement.should_process_key_event(key_event.pressed, key_event.echo, direction):
		return
	if key_event.keycode == KEY_F5:
		demo.start()
		_run_demo_step()
		return
	match key_event.keycode:
		KEY_SPACE:
			_apply_result(world.interact_front())
		KEY_BACKSPACE:
			_apply_result(world.delete_front())
		KEY_TAB:
			_apply_result(world.split_front())

func _process(delta: float) -> void:
	var direction := _current_held_direction()
	if direction == Vector2i.ZERO:
		move_repeat_elapsed = 0.0
		return
	move_repeat_elapsed += delta
	var interval := FAST_MOVE_REPEAT_INTERVAL if Input.is_key_pressed(KEY_SHIFT) else MOVE_REPEAT_INTERVAL
	while move_repeat_elapsed >= interval:
		move_repeat_elapsed -= interval
		_apply_direction_step(direction)

func _build_scene() -> void:
	map_layer = Node2D.new()
	map_layer.name = "MapLayer"
	add_child(map_layer)
	player_label = _make_word_label("我", Color(0.92, 0.92, 0.92), Color(0.05, 0.05, 0.05))
	player_label.name = "Player"
	map_layer.add_child(player_label)
	demo_timer = Timer.new()
	demo_timer.wait_time = 0.55
	demo_timer.one_shot = true
	demo_timer.timeout.connect(_run_demo_step)
	add_child(demo_timer)
	_build_ui()

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "CanvasLayer"
	add_child(canvas)
	canvas.visible = false

func _refresh_view(_message := "") -> void:
	_sync_entity_labels()
	player_label.position = _grid_to_pixels(world.player_pos)
	player_label.move_to_front()
	page_camera.sync_to_world(world)
	map_layer.position = page_camera.offset_pixels()

func _sync_entity_labels() -> void:
	var alive := {}
	for entity in world.entities.values():
		alive[entity.id] = true
		var group: Node2D = entity_labels.get(entity.id)
		if not group:
			group = Node2D.new()
			entity_labels[entity.id] = group
			map_layer.add_child(group)
		group.position = _grid_to_pixels(entity.grid_pos)
		_sync_entity_label_group(group, entity)
	for id in entity_labels.keys():
		if not alive.has(id):
			entity_labels[id].queue_free()
			entity_labels.erase(id)

func _sync_entity_label_group(group: Node2D, entity) -> void:
	var text := str(entity.text)
	while group.get_child_count() > text.length():
		var child := group.get_child(group.get_child_count() - 1)
		group.remove_child(child)
		child.queue_free()
	while group.get_child_count() < text.length():
		group.add_child(_make_word_label(""))
	for i in range(text.length()):
		var label := group.get_child(i) as Label
		label.text = text.substr(i, 1)
		label.position = Vector2(i * world.cell_size, -2)
		label.size = Vector2(world.cell_size, world.cell_size + 4)
		label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.32) if entity.highlighted else Color.WHITE)

func _apply_result(result: Dictionary) -> void:
	_refresh_view(str(result.get("message", "")))

func _run_demo_step() -> void:
	var result := demo.step(world)
	_apply_result(result)
	if demo.running:
		demo_timer.start()

func _set_direction_held(direction: Vector2i, pressed: bool) -> void:
	held_move_directions.erase(direction)
	if pressed:
		held_move_directions.append(direction)

func _current_held_direction() -> Vector2i:
	if held_move_directions.is_empty():
		return Vector2i.ZERO
	return held_move_directions[held_move_directions.size() - 1]

func _apply_direction_step(direction: Vector2i) -> void:
	if Input.is_key_pressed(KEY_ALT):
		_apply_result(world.pull_front(direction))
	else:
		_apply_result(world.try_move_player(direction))

func _direction_from_key(keycode: Key) -> Vector2i:
	return PrecisionMovement.direction_from_keycode(keycode)

func _grid_to_pixels(pos: Vector2i) -> Vector2:
	return Vector2(pos.x * world.cell_size, pos.y * world.cell_size)

func _make_word_label(text: String, font_color := Color.WHITE, bg_color := Color.TRANSPARENT) -> Label:
	var label := Label.new()
	label.text = text
	label.size = Vector2(max(1, text.length()) * world.cell_size, world.cell_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_contents = false
	label.add_theme_font_size_override("font_size", WORD_FONT_SIZE)
	label.add_theme_font_override("font", OriginalFont)
	label.add_theme_color_override("font_color", font_color)
	if bg_color.a > 0.0:
		var style := StyleBoxFlat.new()
		style.bg_color = bg_color
		style.content_margin_left = 0
		style.content_margin_right = 0
		style.content_margin_top = 0
		style.content_margin_bottom = 0
		label.add_theme_stylebox_override("normal", style)
	return label
