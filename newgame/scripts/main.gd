extends Node2D

const GridWorld = preload("res://scripts/grid_world.gd")
const LevelLoader = preload("res://scripts/level_loader.gd")
const HelmetR1 = preload("res://levels/helmet/helmet_r1.gd")
const HelmetR2 = preload("res://levels/helmet/helmet_r2.gd")
const HelmetR3 = preload("res://levels/helmet/helmet_r3.gd")
const HelmetR4 = preload("res://levels/helmet/helmet_r4.gd")
const HelmetR5 = preload("res://levels/helmet/helmet_r5.gd")
const HelmetR6 = preload("res://levels/helmet/helmet_r6.gd")
const HelmetReturn = preload("res://levels/helmet/helmet_return.gd")
const PageCamera = preload("res://scripts/page_camera.gd")
const PrecisionMovement = preload("res://scripts/precision_movement.gd")
const DemoRunner = preload("res://scripts/demo_runner.gd")
const PlayerDirectionMarker = preload("res://scripts/player_moving/player_direction_marker.gd")
const SmoothGridMover = preload("res://scripts/smooth_grid_mover.gd")
const OriginalFont = preload("res://Fonts/Zpix.tres")

const MOVE_REPEAT_INTERVAL := 0.28
const FAST_MOVE_REPEAT_INTERVAL := 0.12
const WORD_FONT_SIZE := 42
const HIGHLIGHT_VISUAL_CONFIG_PATH := "res://assets/animations/highlight/highlight_visual_config.json"
const GLOVE_PREVIEW_SCENE_PATH := "res://levels/glove/glove_preview.tscn"
const STARTUP_ENTRY_ARG_PREFIX := "--entry="
const GLOVE_SCENE_SHORTCUT_KEY := KEY_F9
const LEVEL_SEQUENCE := [
	HelmetR1,
	HelmetR2,
	HelmetR3,
	HelmetR4,
	HelmetR5,
	HelmetR6,
	HelmetReturn
]

var world := GridWorld.new()
var page_camera := PageCamera.new()
var demo := DemoRunner.new()
var player_mover := SmoothGridMover.new()
var current_level_index := 0
var entity_movers: Dictionary = {}
var entity_labels: Dictionary = {}
var player_label: Label
var map_layer: Node2D
var demo_timer: Timer
var world_event_timer: Timer
var direction_marker: Node2D
var direction_marker_fill: Polygon2D
var direction_marker_outline: Line2D
var direction_marker_timer: Timer
var direction_marker_direction := Vector2i.ZERO
var held_move_directions: Array[Vector2i] = []
var move_repeat_elapsed := 0.0
var move_visual_duration := 0.12
var _player_visual_ready := false
var highlight_visual_config: Dictionary = {}

func _ready() -> void:
	var startup_scene_path := resolve_startup_scene_path(OS.get_cmdline_user_args())
	if not startup_scene_path.is_empty():
		call_deferred("_switch_to_scene", startup_scene_path)
		return
	highlight_visual_config = load_highlight_visual_config()
	_load_level_index(0)
	page_camera.sync_to_world(world)
	_build_scene()
	_refresh_view()

func _process(delta: float) -> void:
	world.advance_highlight_animation(delta)
	var direction := _current_held_direction()
	if direction == Vector2i.ZERO:
		move_repeat_elapsed = 0.0
	else:
		move_repeat_elapsed += delta
		var interval := FAST_MOVE_REPEAT_INTERVAL if Input.is_key_pressed(KEY_SHIFT) else MOVE_REPEAT_INTERVAL
		while move_repeat_elapsed >= interval:
			move_repeat_elapsed -= interval
			_apply_direction_step(direction)

	var changed := false
	if _player_visual_ready:
		var previous_player := player_mover.current_position
		player_mover.advance(delta)
		changed = changed or previous_player != player_mover.current_position
	for mover in entity_movers.values():
		var previous_position: Vector2 = mover.current_position
		mover.advance(delta)
		changed = changed or previous_position != mover.current_position
	if changed:
		_apply_visual_positions()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if key_event.pressed and not key_event.echo:
		var shortcut_scene_path := resolve_scene_shortcut_from_keycode(key_event.keycode)
		if not shortcut_scene_path.is_empty():
			call_deferred("_switch_to_scene", shortcut_scene_path)
			return
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

func _build_scene() -> void:
	map_layer = Node2D.new()
	map_layer.name = "MapLayer"
	add_child(map_layer)
	player_label = _make_word_label("我", Color(0.92, 0.92, 0.92), Color(0.05, 0.05, 0.05))
	player_label.name = "Player"
	map_layer.add_child(player_label)
	_build_direction_marker()
	demo_timer = Timer.new()
	demo_timer.wait_time = 0.55
	demo_timer.one_shot = true
	demo_timer.timeout.connect(_run_demo_step)
	add_child(demo_timer)
	world_event_timer = Timer.new()
	world_event_timer.one_shot = true
	world_event_timer.timeout.connect(_resolve_world_event)
	add_child(world_event_timer)
	direction_marker_timer = Timer.new()
	direction_marker_timer.wait_time = 0.18
	direction_marker_timer.one_shot = true
	direction_marker_timer.timeout.connect(_hide_direction_marker)
	add_child(direction_marker_timer)
	_build_ui()

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "CanvasLayer"
	add_child(canvas)
	canvas.visible = false

func _refresh_view(_message := "") -> void:
	_sync_entity_labels()
	_sync_direction_marker()
	player_label.text = world.player_text
	player_label.visible = world.player_visible
	page_camera.sync_to_world(world)
	map_layer.position = page_camera.offset_pixels()
	var player_target := _grid_to_pixels(world.player_pos)
	if not _player_visual_ready:
		player_mover.snap_to(player_target)
		_player_visual_ready = true
	else:
		player_mover.move_to(player_target, move_visual_duration)
	_apply_visual_positions()
	player_label.move_to_front()

func _sync_entity_labels() -> void:
	var alive := {}
	for entity in world.entities.values():
		alive[entity.id] = true
		var group: Node2D = entity_labels.get(entity.id)
		if not group:
			group = Node2D.new()
			entity_labels[entity.id] = group
			map_layer.add_child(group)
			var mover = SmoothGridMover.new()
			mover.snap_to(_grid_to_pixels(entity.grid_pos))
			entity_movers[entity.id] = mover
		var entity_mover = entity_movers.get(entity.id)
		entity_mover.move_to(_grid_to_pixels(entity.grid_pos), move_visual_duration)
		_sync_entity_label_group(group, entity)
	for id in entity_labels.keys():
		if not alive.has(id):
			entity_labels[id].queue_free()
			entity_labels.erase(id)
			entity_movers.erase(id)

func _apply_visual_positions() -> void:
	player_label.position = player_mover.current_position
	for id in entity_labels.keys():
		var mover = entity_movers.get(id)
		if mover:
			entity_labels[id].position = mover.current_position

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
		label.pivot_offset = label.size * 0.5
		var highlight_strength := world.get_highlight_animation_strength(entity.cells[i]) if i < entity.cells.size() else 0.0
		var base_color := Color.WHITE
		if entity.highlighted:
			base_color = _highlight_config_color("matched_color", Color(1.0, 0.95, 0.32))
		var animated_color := base_color.lerp(_highlight_config_color("accent_color", Color(1.0, 0.78, 0.18)), highlight_strength)
		label.add_theme_color_override("font_color", animated_color)
		var pulse_scale_max := float(highlight_visual_config.get("pulse_scale_max", 1.14))
		var pulse_scale := 1.0 + (highlight_strength * maxf(pulse_scale_max - 1.0, 0.0))
		label.scale = Vector2.ONE * pulse_scale

func _apply_result(result: Dictionary) -> void:
	if result.has("transition"):
		_handle_transition(result)
		return
	_refresh_view(str(result.get("message", "")))
	if result.has("pending_delay"):
		if world_event_timer.is_stopped():
			world_event_timer.start(float(result.pending_delay))
	elif world.has_pending_timed_effect() and world_event_timer.is_stopped():
		world_event_timer.start(world.pending_timed_delay)

func _handle_transition(result: Dictionary) -> void:
	if result.get("transition", "") != "next_level":
		_refresh_view(str(result.get("message", "")))
		return
	var next_index := current_level_index + 1
	if next_index >= LEVEL_SEQUENCE.size():
		_refresh_view()
		return
	var overrides := {}
	if current_level_index == 5:
		overrides = {
			"player_pos": Vector2i(0, int(result.get("exit_y", world.player_pos.y))),
			"player_text": "鹅",
			"player_facing": Vector2i.RIGHT
		}
	_load_level_index(next_index, overrides)
	_refresh_view()

func _load_level_index(index: int, overrides := {}) -> void:
	current_level_index = clampi(index, 0, LEVEL_SEQUENCE.size() - 1)
	world.load_level(LEVEL_SEQUENCE[current_level_index].build_level())
	if overrides.has("player_pos"):
		world.player_pos = overrides.player_pos
	if overrides.has("player_text"):
		world.player_text = str(overrides.player_text)
	if overrides.has("player_facing"):
		world.facing = overrides.player_facing
	world.update_page()
	held_move_directions.clear()
	move_repeat_elapsed = 0.0
	_player_visual_ready = false
	if world_event_timer:
		world_event_timer.stop()

func _resolve_world_event() -> void:
	_apply_result(world.resolve_pending_timed_effect())

func _run_demo_step() -> void:
	var result := demo.step(world)
	_apply_result(result)
	if demo.running:
		demo_timer.start()

func _build_direction_marker() -> void:
	direction_marker = Node2D.new()
	direction_marker.name = "PlayerDirectionMarker"
	direction_marker.visible = false
	map_layer.add_child(direction_marker)

	direction_marker_fill = Polygon2D.new()
	direction_marker_fill.color = Color(0.98, 0.87, 0.22, 0.95)
	direction_marker.add_child(direction_marker_fill)

	direction_marker_outline = Line2D.new()
	direction_marker_outline.width = 2.0
	direction_marker_outline.default_color = Color(0.06, 0.06, 0.06, 0.95)
	direction_marker.add_child(direction_marker_outline)

func _show_direction_marker(direction: Vector2i) -> void:
	if direction == Vector2i.ZERO:
		return
	direction_marker_direction = direction
	direction_marker.visible = true
	_sync_direction_marker()
	direction_marker_timer.start()

func _hide_direction_marker() -> void:
	direction_marker.visible = false

func _sync_direction_marker() -> void:
	if direction_marker == null or direction_marker_direction == Vector2i.ZERO:
		return
	var center := _grid_to_pixels(world.player_pos) + Vector2(world.cell_size * 0.5, world.cell_size * 0.5)
	var points := PlayerDirectionMarker.local_points(world.cell_size, direction_marker_direction)
	direction_marker.position = center + PlayerDirectionMarker.anchor_offset(world.cell_size, direction_marker_direction)
	direction_marker_fill.polygon = points
	var outline_points := PackedVector2Array(points)
	if not outline_points.is_empty():
		outline_points.append(outline_points[0])
	direction_marker_outline.points = outline_points

func _set_direction_held(direction: Vector2i, pressed: bool) -> void:
	held_move_directions.erase(direction)
	if pressed:
		held_move_directions.append(direction)

func _current_held_direction() -> Vector2i:
	if held_move_directions.is_empty():
		return Vector2i.ZERO
	return held_move_directions[held_move_directions.size() - 1]

func _apply_direction_step(direction: Vector2i) -> void:
	var result: Dictionary
	if Input.is_key_pressed(KEY_ALT):
		result = world.pull_front(direction)
	else:
		result = world.try_move_player(direction)
	_apply_result(result)
	if result.get("success", false):
		_show_direction_marker(direction)

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

func load_highlight_visual_config() -> Dictionary:
	var defaults := {
		"pulse_scale_max": 1.14,
		"accent_color": [1.0, 0.78, 0.18, 1.0],
		"matched_color": [1.0, 0.95, 0.32, 1.0]
	}
	if not FileAccess.file_exists(HIGHLIGHT_VISUAL_CONFIG_PATH):
		return defaults
	var config_file := FileAccess.open(HIGHLIGHT_VISUAL_CONFIG_PATH, FileAccess.READ)
	if config_file == null:
		return defaults
	var parsed = JSON.parse_string(config_file.get_as_text())
	if parsed is Dictionary:
		var merged := defaults.duplicate(true)
		for key in (parsed as Dictionary).keys():
			merged[key] = parsed[key]
		return merged
	return defaults

func _highlight_config_color(key: String, fallback: Color) -> Color:
	if highlight_visual_config.is_empty():
		highlight_visual_config = load_highlight_visual_config()
	var value = highlight_visual_config.get(key, [])
	if value is Array and value.size() >= 3:
		return Color(
			float(value[0]),
			float(value[1]),
			float(value[2]),
			float(value[3]) if value.size() >= 4 else 1.0
		)
	return fallback

func resolve_startup_scene_path(args: PackedStringArray) -> String:
	for arg in args:
		var value := str(arg)
		if not value.begins_with(STARTUP_ENTRY_ARG_PREFIX):
			continue
		return _entry_scene_path_for_key(value.trim_prefix(STARTUP_ENTRY_ARG_PREFIX))
	return ""

func resolve_scene_shortcut_from_keycode(keycode: Key) -> String:
	if keycode == GLOVE_SCENE_SHORTCUT_KEY:
		return GLOVE_PREVIEW_SCENE_PATH
	return ""

func _entry_scene_path_for_key(entry_key: String) -> String:
	match entry_key:
		"glove":
			return GLOVE_PREVIEW_SCENE_PATH
		_:
			return ""

func _switch_to_scene(scene_path: String) -> void:
	if scene_path.is_empty() or get_tree() == null:
		return
	get_tree().change_scene_to_file(scene_path)
