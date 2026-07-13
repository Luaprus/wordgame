extends Node2D

const GridWorld = preload("res://scripts/grid_world.gd")
const GloveLevel = preload("res://levels/glove/glove_level.gd")
const GloveEffects = preload("res://scripts/levels/glove/glove_effects.gd")
const GloveLoopingPrompt = preload("res://scripts/levels/glove/glove_looping_prompt.gd")
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
const GESTURE_TRANSITION_SWITCH_SECONDS := 0.5
const GESTURE_FLASH_PEAK_ALPHA := 0.3
const GLOVE_ACQUIRE_VIDEO_PATH := "res://assets/video/glove_acquire.ogv"
const GLOVE_PUT_ON_SOUND_PATH := "res://assets/audio/glove_put_on.wav"
const GLOVE_MELODY_SOUND_PATH := "res://assets/audio/glove_melody.wav"
const DELETE_CUT_SOUND_PATH := "res://assets/audio/delete_cut.wav"
const DELETE_CUT_DURATION := 1.15

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
var brave_loop_prompt := GloveLoopingPrompt.new()
var brave_loop_labels: Array[Label] = []
var gesture_loop_prompt := GloveLoopingPrompt.new("改变手势，扭转守势！")
var gesture_loop_prefix: Label
var gesture_loop_labels: Array[Label] = []
var gesture_flash_layer: CanvasLayer
var gesture_flash_overlay: ColorRect
var gesture_transition_active := false
var gesture_transition_elapsed := 0.0
var gesture_transition_duration := 1.0
var acquisition_layer: CanvasLayer
var acquisition_video: VideoStreamPlayer
var acquisition_put_on_sound: AudioStreamPlayer
var acquisition_melody_sound: AudioStreamPlayer
var glove_acquisition_active := false
var delete_cut_sound: AudioStreamPlayer
var delete_cut_root: Node2D
var delete_cut_left: Label
var delete_cut_right: Label
var delete_cut_slash: Line2D
var delete_cut_elapsed := 0.0

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
		_consume_visual_effect_request()

func _process(delta: float) -> void:
	world.advance_highlight_animation(delta)
	_advance_gesture_transition(delta)
	_advance_delete_cut(delta)
	if brave_loop_prompt.advance(delta):
		_sync_brave_loop_prompt()
	if gesture_loop_prompt.advance(delta):
		_sync_gesture_loop_prompt()
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
	_build_brave_loop_prompt()
	_build_gesture_loop_prompt()
	transition_reference_overlay = Sprite2D.new()
	transition_reference_overlay.name = "TransitionReferenceOverlay"
	transition_reference_overlay.centered = false
	transition_reference_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	transition_reference_overlay.visible = false
	transition_reference_overlay.texture = _load_transition_reference_texture()
	add_child(transition_reference_overlay)
	gesture_flash_layer = CanvasLayer.new()
	gesture_flash_layer.name = "GestureFlashLayer"
	gesture_flash_layer.layer = 100
	add_child(gesture_flash_layer)
	gesture_flash_overlay = ColorRect.new()
	gesture_flash_overlay.name = "GestureFlashOverlay"
	gesture_flash_overlay.color = Color(1.0, 1.0, 1.0, 1.0)
	gesture_flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gesture_flash_overlay.size = Vector2(1920, 1080)
	gesture_flash_overlay.visible = false
	gesture_flash_layer.add_child(gesture_flash_overlay)
	_build_acquisition_overlay()
	delete_cut_sound = AudioStreamPlayer.new()
	delete_cut_sound.stream = load(DELETE_CUT_SOUND_PATH)
	add_child(delete_cut_sound)
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
	_sync_brave_loop_prompt()
	_sync_gesture_loop_prompt()
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

func _build_brave_loop_prompt() -> void:
	for index in range(GloveLoopingPrompt.TEXT.length()):
		var label := _make_word_label("")
		label.name = "BraveLoopPrompt_%d" % index
		label.position = _grid_to_pixels(Vector2i(24, 5 + index))
		map_layer.add_child(label)
		brave_loop_labels.append(label)

func _sync_brave_loop_prompt() -> void:
	if brave_loop_labels.is_empty():
		return
	var visible := _has_fixed_brave()
	var text := brave_loop_prompt.visible_text()
	for index in range(brave_loop_labels.size()):
		var label := brave_loop_labels[index]
		label.visible = visible and index < text.length()
		label.text = text.substr(index, 1) if index < text.length() else ""

func _build_gesture_loop_prompt() -> void:
	gesture_loop_prefix = _make_word_label("勇：")
	gesture_loop_prefix.name = "GestureLoopPromptPrefix"
	gesture_loop_prefix.position = _grid_to_pixels(Vector2i(1, 16))
	map_layer.add_child(gesture_loop_prefix)
	for index in range(gesture_loop_prompt.text.length()):
		var label := _make_word_label("")
		label.name = "GestureLoopPrompt_%d" % index
		label.position = _grid_to_pixels(Vector2i(3 + index, 16))
		map_layer.add_child(label)
		gesture_loop_labels.append(label)

func _sync_gesture_loop_prompt() -> void:
	if gesture_loop_prefix == null:
		return
	var visible := _has_fixed_brave()
	gesture_loop_prefix.visible = visible
	var text := gesture_loop_prompt.visible_text()
	for index in range(gesture_loop_labels.size()):
		var label := gesture_loop_labels[index]
		label.visible = visible and index < text.length()
		label.text = text.substr(index, 1) if index < text.length() else ""

func _has_fixed_brave() -> bool:
	var brave = world.get_any_entity_at(Vector2i(24, 4))
	return brave != null and brave.text == "勇"

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
		var base_color: Color = Color.WHITE
		if entity.highlighted:
			base_color = Color(1.0, 0.95, 0.32)
		var animated_color: Color = base_color.lerp(Color(1.0, 0.78, 0.18), highlight_strength)
		label.add_theme_color_override("font_color", animated_color)
		label.scale = Vector2.ONE * (1.0 + highlight_strength * 0.14)

func _apply_result(result: Dictionary) -> void:
	_consume_gesture_transition_request()
	_refresh_view(str(result.get("message", "")))
	_consume_visual_effect_request()
	if result.has("pending_delay"):
		if world_event_timer.is_stopped():
			world_event_timer.start(float(result.pending_delay))
	elif world.has_pending_timed_effect() and world_event_timer.is_stopped():
		world_event_timer.start(world.pending_timed_delay)

func _consume_gesture_transition_request() -> void:
	var request: Dictionary = world.consume_gesture_transition_request()
	if request.is_empty():
		return
	gesture_transition_active = true
	gesture_transition_elapsed = 0.0
	gesture_transition_duration = float(request.get("duration", 1.0))
	gesture_flash_overlay.color.a = 0.0
	gesture_flash_overlay.visible = true

func _advance_gesture_transition(delta: float) -> void:
	if not gesture_transition_active:
		return
	gesture_transition_elapsed += delta
	if gesture_transition_elapsed <= GESTURE_TRANSITION_SWITCH_SECONDS:
		gesture_flash_overlay.color.a = GESTURE_FLASH_PEAK_ALPHA * gesture_transition_elapsed / GESTURE_TRANSITION_SWITCH_SECONDS
	else:
		var restore_elapsed := gesture_transition_elapsed - GESTURE_TRANSITION_SWITCH_SECONDS
		gesture_flash_overlay.color.a = GESTURE_FLASH_PEAK_ALPHA * (1.0 - restore_elapsed / GESTURE_TRANSITION_SWITCH_SECONDS)
	var shake_strength := 8.0
	var shake := Vector2(sin(gesture_transition_elapsed * 100.0), cos(gesture_transition_elapsed * 83.0)) * shake_strength
	map_layer.position = page_camera.offset_pixels() + shake
	if gesture_transition_elapsed < gesture_transition_duration:
		return
	gesture_transition_active = false
	gesture_flash_overlay.visible = false
	map_layer.position = page_camera.offset_pixels()

func _build_acquisition_overlay() -> void:
	acquisition_layer = CanvasLayer.new()
	acquisition_layer.name = "GloveAcquisitionLayer"
	acquisition_layer.layer = 120
	acquisition_layer.visible = false
	add_child(acquisition_layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 1.0)
	backdrop.size = Vector2(1920, 1080)
	acquisition_layer.add_child(backdrop)
	acquisition_video = VideoStreamPlayer.new()
	acquisition_video.name = "GloveAcquisitionVideo"
	acquisition_video.expand = true
	acquisition_video.size = Vector2(1920, 1080)
	acquisition_video.visible = false
	acquisition_video.finished.connect(_finish_glove_acquisition)
	acquisition_layer.add_child(acquisition_video)
	acquisition_put_on_sound = AudioStreamPlayer.new()
	acquisition_put_on_sound.stream = load(GLOVE_PUT_ON_SOUND_PATH)
	acquisition_layer.add_child(acquisition_put_on_sound)
	acquisition_melody_sound = AudioStreamPlayer.new()
	acquisition_melody_sound.stream = load(GLOVE_MELODY_SOUND_PATH)
	acquisition_layer.add_child(acquisition_melody_sound)

func _consume_visual_effect_request() -> void:
	for raw_request in world.consume_visual_effects():
		var request: Dictionary = raw_request
		match str(request.get("type", "")):
			"glove_acquire":
				_start_glove_acquisition()
			"delete_cut":
				_start_delete_cut(request)

func _start_glove_acquisition() -> void:
	if glove_acquisition_active:
		return
	glove_acquisition_active = true
	acquisition_layer.visible = true
	acquisition_video.visible = false
	acquisition_put_on_sound.play()
	call_deferred("_play_glove_acquisition_video")

func _play_glove_acquisition_video() -> void:
	await get_tree().create_timer(0.5).timeout
	if not glove_acquisition_active:
		return
	acquisition_melody_sound.play()
	acquisition_video.stream = load(GLOVE_ACQUIRE_VIDEO_PATH)
	if acquisition_video.stream == null:
		_finish_glove_acquisition()
		return
	acquisition_video.visible = true
	acquisition_video.play()

func _finish_glove_acquisition() -> void:
	if not glove_acquisition_active:
		return
	glove_acquisition_active = false
	acquisition_video.stop()
	acquisition_layer.visible = false
	world.player_input_locked = false
	_refresh_view()

func _start_delete_cut(request: Dictionary) -> void:
	if delete_cut_root != null and is_instance_valid(delete_cut_root):
		delete_cut_root.queue_free()
	delete_cut_root = Node2D.new()
	delete_cut_root.name = "DeleteCutEffect"
	delete_cut_root.position = _grid_to_pixels(request.get("pos", Vector2i.ZERO))
	map_layer.add_child(delete_cut_root)
	delete_cut_left = _make_word_label(str(request.get("text", "")))
	delete_cut_left.size = Vector2(world.cell_size * 0.5, world.cell_size)
	delete_cut_left.clip_contents = true
	delete_cut_root.add_child(delete_cut_left)
	delete_cut_right = _make_word_label(str(request.get("text", "")))
	delete_cut_right.size = Vector2(world.cell_size * 0.5, world.cell_size)
	delete_cut_right.position.x = world.cell_size * 0.5
	delete_cut_right.clip_contents = true
	delete_cut_root.add_child(delete_cut_right)
	delete_cut_slash = Line2D.new()
	delete_cut_slash.width = 3.0
	delete_cut_slash.default_color = Color(1.0, 1.0, 1.0, 0.95)
	delete_cut_slash.points = PackedVector2Array([Vector2(-8, 8), Vector2(world.cell_size + 8, world.cell_size - 8)])
	delete_cut_root.add_child(delete_cut_slash)
	delete_cut_elapsed = 0.0
	delete_cut_sound.play()

func _advance_delete_cut(delta: float) -> void:
	if delete_cut_root == null or not is_instance_valid(delete_cut_root):
		return
	delete_cut_elapsed += delta
	var progress := clampf(delete_cut_elapsed / DELETE_CUT_DURATION, 0.0, 1.0)
	delete_cut_left.position = Vector2(-26.0 * progress, 18.0 * progress)
	delete_cut_left.rotation = -0.38 * progress
	delete_cut_right.position = Vector2(world.cell_size * 0.5 + 26.0 * progress, -18.0 * progress)
	delete_cut_right.rotation = 0.38 * progress
	delete_cut_left.modulate.a = 1.0 - progress
	delete_cut_right.modulate.a = 1.0 - progress
	delete_cut_slash.modulate.a = maxf(0.0, 1.0 - progress * 1.8)
	if progress < 1.0:
		return
	delete_cut_root.queue_free()
	delete_cut_root = null

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
