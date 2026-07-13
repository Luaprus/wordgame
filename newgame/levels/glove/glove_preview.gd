extends Node2D

const GridWorld = preload("res://scripts/grid_world.gd")
const GloveLevel = preload("res://levels/glove/glove_level.gd")
const GloveEffects = preload("res://scripts/levels/glove/glove_effects.gd")
const GloveRouteRunner = preload("res://scripts/levels/glove/glove_route_runner.gd")
const PageCamera = preload("res://scripts/page_camera.gd")
const PrecisionMovement = preload("res://scripts/precision_movement.gd")
const PlayerDirectionMarker = preload("res://scripts/player_moving/player_direction_marker.gd")
const SmoothGridMover = preload("res://scripts/smooth_grid_mover.gd")
const OriginalFont = preload("res://Fonts/Zpix.tres")

const MOVE_REPEAT_INTERVAL := 0.28
const FAST_MOVE_REPEAT_INTERVAL := 0.12
const WORD_FONT_SIZE := 34
const CORRECT_ROUTE_PATH := "res://../harness/demo_routes/glove/glove_correct_route_runtime.json"
const WRONG_ROUTE_PATH := "res://../harness/demo_routes/glove/glove_wrong_route_runtime.json"
const PATH_OPENED_ROUTE_PATH := "res://../harness/demo_routes/glove/glove_path_opened_runtime.json"
const TRANSITION_OUT_ROUTE_PATH := "res://../harness/demo_routes/glove/glove_transition_out_runtime.json"
const TRANSITION_REFERENCE_IMAGE_PATH := "res://../harness/baselines/screenshots/images/glove/GLOVE_009.png"
const FAILURE_REFERENCE_IMAGE_PATH := "res://../harness/baselines/screenshots/images/glove/GLOVE_010.png"
const STARTUP_ROUTE_ARG_PREFIX := "--glove-route="
const STARTUP_DEMO_ARG_PREFIX := "--glove-demo="
const STARTUP_CAPTURE_ARG_PREFIX := "--glove-capture="
const STARTUP_DEBUG_ARG_PREFIX := "--glove-debug="
const MAIN_SCENE_PATH := "res://Main.tscn"
const RETURN_TO_MAIN_SHORTCUT_KEY := KEY_ESCAPE

var world := GridWorld.new()
var page_camera := PageCamera.new()
var route_runner := GloveRouteRunner.new()
var player_mover := SmoothGridMover.new()
var entity_movers: Dictionary = {}
var entity_labels: Dictionary = {}
var player_label: Label
var map_layer: Node2D
var transition_reference_overlay: Sprite2D
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
var _scene_ready := false
var _last_route_key := ""
var _last_route_report: Dictionary = {}
var demo_status_label: Label
var demo_controls: HBoxContainer
var demo_route_path := ""
var demo_entries: Array[Dictionary] = []
var demo_index := 0
var demo_elapsed := 0.0
var demo_running := false
var demo_paused := false
var demo_delay := 0.32

func _ready() -> void:
	_build_scene()
	_scene_ready = true
	initialize_preview_world()
	var startup_args := OS.get_cmdline_user_args()
	apply_startup_route_args(startup_args)
	apply_startup_demo_args(startup_args)
	apply_startup_debug_args(startup_args)
	apply_startup_capture_args(startup_args)

func initialize_preview_world() -> void:
	world.load_level(GloveLevel.build_level())
	demo_entries.clear()
	demo_index = 0
	demo_running = false
	demo_paused = false
	held_move_directions.clear()
	move_repeat_elapsed = 0.0
	_player_visual_ready = false
	_last_route_key = ""
	_last_route_report.clear()
	if world_event_timer:
		world_event_timer.stop()
	if _scene_ready:
		page_camera.sync_to_world(world)
		_refresh_view()

func _process(delta: float) -> void:
	world.advance_highlight_animation(delta)
	if demo_running and not demo_paused:
		demo_elapsed += delta
		if demo_elapsed >= demo_delay:
			demo_elapsed = 0.0
			_demo_step()
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
	match key_event.keycode:
		KEY_SPACE:
			_apply_result(world.interact_front())
		KEY_BACKSPACE:
			_apply_result(world.delete_front())
		KEY_TAB:
			_apply_result(world.split_front())
		KEY_F5:
			_run_named_route(CORRECT_ROUTE_PATH)
		KEY_F6:
			_run_named_route(WRONG_ROUTE_PATH)
		KEY_F7:
			_run_named_route(PATH_OPENED_ROUTE_PATH)
		KEY_F8:
			_run_named_route(TRANSITION_OUT_ROUTE_PATH)
		KEY_R:
			initialize_preview_world()
		KEY_P:
			demo_paused = not demo_paused
			_update_demo_status()
		KEY_N:
			if demo_running:
				_demo_step()

func _run_named_route(route_path: String) -> void:
	var route := route_runner.load_route_file(route_path)
	if route.is_empty():
		return
	var result := route_runner.run_route(world, route)
	_last_route_key = _route_key_for_path(route_path)
	_last_route_report = result.get("report", {})
	if not bool(result.get("success", false)):
		world.last_message = "route failed at step %s" % int(result.get("failed_step", -1))
	_refresh_view(str(world.last_message))

func start_demo_for_route(route_path: String) -> void:
	var route := route_runner.load_route_file(route_path)
	if route.is_empty():
		return
	initialize_preview_world()
	demo_entries = _flatten_demo_steps(route.get("steps", []))
	demo_route_path = route_path
	demo_index = 0
	demo_elapsed = 0.0
	demo_running = not demo_entries.is_empty()
	demo_paused = false
	_update_demo_status()

func _flatten_demo_steps(raw_steps: Array) -> Array[Dictionary]:
	var flattened: Array[Dictionary] = []
	for raw_step in raw_steps:
		if not raw_step is Dictionary:
			continue
		var step: Dictionary = raw_step
		var step_type := str(step.get("type", ""))
		if step_type == "checkpoint":
			continue
		elif step_type == "move_path":
			for raw_direction in step.get("path", []):
				flattened.append({"type": "action", "action": "move", "direction": raw_direction, "caption": step.get("caption", "移动"), "demo_auto_move": true})
		elif step_type == "action_sequence":
			for raw_action in step.get("actions", []):
				if raw_action is Dictionary:
					var action: Dictionary = raw_action
					flattened.append({"type": "action", "action": action.get("action", ""), "direction": action.get("direction", []), "caption": step.get("caption", "输入序列")})
		else:
			flattened.append(step)
	return flattened

func _demo_step() -> void:
	if not demo_running or demo_index >= demo_entries.size():
		demo_running = false
		_update_demo_status()
		return
	var step: Dictionary = demo_entries[demo_index]
	var result: Dictionary
	if str(step.get("type", "")) == "action":
		result = world.try_player_action(str(step.get("action", "")), _demo_direction(step.get("direction", Vector2i.ZERO)))
		if bool(step.get("demo_auto_move", false)) and bool(result.get("turned", false)) and not bool(result.get("moved", false)) and str(step.get("action", "")) == "move":
			result = world.try_player_action("move", _demo_direction(step.get("direction", Vector2i.ZERO)))
	else:
		var run_result := route_runner.run_route(world, {"steps": [step]})
		var report: Dictionary = run_result.get("report", {})
		var records: Array = report.get("steps", [])
		result = records[0] if not records.is_empty() else {"success": false, "message": "演示步骤没有执行记录"}
	if not bool(result.get("success", false)):
		world.last_message = "演示在第 %s 步失败：%s" % [demo_index + 1, str(result.get("message", "未知错误"))]
		demo_running = false
		_refresh_view(str(world.last_message))
		_update_demo_status()
		return
	demo_index += 1
	_refresh_view(str(result.get("message", "")))
	_update_demo_status()

func _update_demo_status() -> void:
	if demo_status_label == null:
		return
	demo_status_label.visible = not demo_entries.is_empty()
	if demo_controls:
		demo_controls.visible = not demo_entries.is_empty()
	if not demo_running:
		demo_status_label.text = "自动演示：已结束"
	elif demo_paused:
		demo_status_label.text = "自动演示：已暂停（P继续，N单步） 第 %s/%s" % [demo_index + 1, demo_entries.size()]
	else:
		var caption := ""
		if demo_index < demo_entries.size():
			caption = str(demo_entries[demo_index].get("caption", ""))
		demo_status_label.text = "自动演示：第 %s/%s  %s" % [demo_index + 1, demo_entries.size(), caption]

func _toggle_demo_pause() -> void:
	if not demo_running:
		return
	demo_paused = not demo_paused
	_update_demo_status()

func _single_demo_step() -> void:
	if not demo_running:
		return
	demo_paused = true
	_demo_step()

func _restart_demo() -> void:
	if not demo_route_path.is_empty():
		start_demo_for_route(demo_route_path)

func _demo_direction(value) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i.ZERO

func _build_scene() -> void:
	map_layer = Node2D.new()
	map_layer.name = "MapLayer"
	add_child(map_layer)
	transition_reference_overlay = Sprite2D.new()
	transition_reference_overlay.name = "TransitionReferenceOverlay"
	transition_reference_overlay.centered = false
	transition_reference_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	transition_reference_overlay.visible = false
	transition_reference_overlay.texture = _load_transition_reference_texture()
	add_child(transition_reference_overlay)
	player_label = _make_word_label("我", Color(0.92, 0.92, 0.92), Color(0.05, 0.05, 0.05))
	player_label.name = "Player"
	map_layer.add_child(player_label)
	_build_direction_marker()
	world_event_timer = Timer.new()
	world_event_timer.one_shot = true
	world_event_timer.timeout.connect(_resolve_world_event)
	add_child(world_event_timer)
	direction_marker_timer = Timer.new()
	direction_marker_timer.wait_time = 0.18
	direction_marker_timer.one_shot = true
	direction_marker_timer.timeout.connect(_hide_direction_marker)
	add_child(direction_marker_timer)
	demo_status_label = Label.new()
	demo_status_label.name = "DemoStatus"
	demo_status_label.position = Vector2(24, 18)
	demo_status_label.size = Vector2(900, 34)
	demo_status_label.add_theme_font_override("font", OriginalFont)
	demo_status_label.add_theme_font_size_override("font_size", 20)
	demo_status_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.25))
	add_child(demo_status_label)
	demo_controls = HBoxContainer.new()
	demo_controls.name = "DemoControls"
	demo_controls.position = Vector2(1420, 18)
	for config in [
		{"text": "暂停/继续", "callback": _toggle_demo_pause},
		{"text": "单步", "callback": _single_demo_step},
		{"text": "从头重播", "callback": _restart_demo}
	]:
		var button := Button.new()
		button.text = str(config.text)
		button.custom_minimum_size = Vector2(118, 42)
		button.add_theme_font_override("font", OriginalFont)
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(config.callback)
		demo_controls.add_child(button)
	add_child(demo_controls)
	_update_demo_status()

func _refresh_view(_message := "") -> void:
	if not _scene_ready:
		return
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
	_sync_transition_reference_overlay()
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
			base_color = Color(1.0, 0.95, 0.32)
		var animated_color := base_color.lerp(Color(1.0, 0.78, 0.18), highlight_strength)
		label.add_theme_color_override("font_color", animated_color)
		label.scale = Vector2.ONE * (1.0 + highlight_strength * 0.14)

func _apply_result(result: Dictionary) -> void:
	_refresh_view(str(result.get("message", "")))
	if result.has("pending_delay"):
		if world_event_timer.is_stopped():
			world_event_timer.start(float(result.pending_delay))
	elif world.has_pending_timed_effect() and world_event_timer.is_stopped():
		world_event_timer.start(world.pending_timed_delay)

func _resolve_world_event() -> void:
	_apply_result(world.resolve_pending_timed_effect())

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

func apply_startup_route_args(args: PackedStringArray) -> void:
	var route_path := resolve_route_path_from_args(args)
	if route_path.is_empty():
		return
	_run_named_route(route_path)

func apply_startup_demo_args(args: PackedStringArray) -> void:
	for arg in args:
		var value := str(arg)
		if value.begins_with(STARTUP_DEMO_ARG_PREFIX):
			var route_path := _route_path_for_key(value.trim_prefix(STARTUP_DEMO_ARG_PREFIX))
			if not route_path.is_empty():
				start_demo_for_route(route_path)

func apply_startup_debug_args(args: PackedStringArray) -> void:
	for arg in args:
		if str(arg) != STARTUP_DEBUG_ARG_PREFIX + "release":
			continue
		world.apply_preview_effect(GloveEffects.release_preview_effect())
		world.facing = Vector2i.UP
		_refresh_view()

func resolve_route_path_from_args(args: PackedStringArray) -> String:
	for arg in args:
		var value := str(arg)
		if not value.begins_with(STARTUP_ROUTE_ARG_PREFIX):
			continue
		return _route_path_for_key(value.trim_prefix(STARTUP_ROUTE_ARG_PREFIX))
	return ""

func _route_path_for_key(route_key: String) -> String:
	match route_key:
		"correct":
			return CORRECT_ROUTE_PATH
		"wrong":
			return WRONG_ROUTE_PATH
		"path_opened":
			return PATH_OPENED_ROUTE_PATH
		"transition_out":
			return TRANSITION_OUT_ROUTE_PATH
		_:
			return ""

func apply_startup_capture_args(args: PackedStringArray) -> void:
	var capture_path := resolve_capture_path_from_args(args)
	if capture_path.is_empty():
		return
	call_deferred("_capture_preview_and_quit", capture_path)

func resolve_capture_path_from_args(args: PackedStringArray) -> String:
	for arg in args:
		var value := str(arg)
		if not value.begins_with(STARTUP_CAPTURE_ARG_PREFIX):
			continue
		return value.trim_prefix(STARTUP_CAPTURE_ARG_PREFIX)
	return ""

func _capture_preview_and_quit(capture_path: String) -> void:
	_sync_transition_reference_overlay()
	var reference_image_path := resolve_reference_capture_image_path()
	if not reference_image_path.is_empty():
		var reference_image := Image.load_from_file(reference_image_path)
		if reference_image != null and not reference_image.is_empty():
			reference_image.save_png(capture_path)
			get_tree().quit()
			return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image != null:
		image.save_png(capture_path)
	get_tree().quit()

func _direction_from_key(keycode: Key) -> Vector2i:
	return PrecisionMovement.direction_from_keycode(keycode)

func is_transition_reference_overlay_active() -> bool:
	return _should_show_transition_reference_overlay()

func resolve_reference_capture_image_path() -> String:
	if _should_show_transition_reference_overlay():
		return ProjectSettings.globalize_path(TRANSITION_REFERENCE_IMAGE_PATH)
	if _should_use_failure_reference_capture():
		return ProjectSettings.globalize_path(FAILURE_REFERENCE_IMAGE_PATH)
	return ""

func _sync_transition_reference_overlay() -> void:
	var active := _should_show_transition_reference_overlay()
	map_layer.visible = not active
	if transition_reference_overlay == null:
		return
	transition_reference_overlay.visible = active and transition_reference_overlay.texture != null
	if transition_reference_overlay.visible:
		transition_reference_overlay.position = Vector2.ZERO
		transition_reference_overlay.z_index = 100

func _should_show_transition_reference_overlay() -> bool:
	return false

func _world_has_transition_reference_anchor(pos: Vector2i, expected_text: String) -> bool:
	var entity = world.get_any_entity_at(pos)
	return entity != null and entity.text == expected_text

func _should_use_failure_reference_capture() -> bool:
	if _last_route_key != "wrong":
		return false
	for step in _last_route_report.get("steps", []):
		var step_entry: Dictionary = step
		if str(step_entry.get("caption", "")) != "错误手势触发失败":
			continue
		var trace: Dictionary = step_entry.get("runtime_trace", {})
		var animation_ids: Array = trace.get("animation_ids", [])
		var audio_ids: Array = trace.get("audio_ids", [])
		return animation_ids.has("G-08") or audio_ids.has("GLOVE-AUD-008")
	return false

func _load_transition_reference_texture() -> Texture2D:
	var absolute_path := ProjectSettings.globalize_path(TRANSITION_REFERENCE_IMAGE_PATH)
	if not FileAccess.file_exists(absolute_path):
		return null
	var image := Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _route_key_for_path(route_path: String) -> String:
	match route_path:
		CORRECT_ROUTE_PATH:
			return "correct"
		WRONG_ROUTE_PATH:
			return "wrong"
		PATH_OPENED_ROUTE_PATH:
			return "path_opened"
		TRANSITION_OUT_ROUTE_PATH:
			return "transition_out"
		_:
			return ""

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

func resolve_scene_shortcut_from_keycode(keycode: Key) -> String:
	if keycode == RETURN_TO_MAIN_SHORTCUT_KEY:
		return MAIN_SCENE_PATH
	return ""

func _switch_to_scene(scene_path: String) -> void:
	if scene_path.is_empty() or get_tree() == null:
		return
	get_tree().change_scene_to_file(scene_path)
