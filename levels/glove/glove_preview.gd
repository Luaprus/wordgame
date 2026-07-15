extends Node2D

const GridWorld = preload("res://scripts/grid_world.gd")
const GloveLevel = preload("res://levels/glove/glove_level.gd")
const GloveLayouts = preload("res://scripts/levels/glove/glove_layouts.gd")
const GloveEffects = preload("res://scripts/levels/glove/glove_effects.gd")
const GloveLoopingPrompt = preload("res://scripts/levels/glove/glove_looping_prompt.gd")
const GloveRouteRunner = preload("res://scripts/levels/glove/glove_route_runner.gd")
const PageCamera = preload("res://scripts/page_camera.gd")
const PrecisionMovement = preload("res://scripts/precision_movement.gd")
const PlayerDirectionMarker = preload("res://scripts/player_moving/player_direction_marker.gd")
const SmoothGridMover = preload("res://scripts/smooth_grid_mover.gd")
const PullParticleEffect = preload("res://scripts/pull_particle_effect.gd")
const OriginalFont = preload("res://Fonts/Zpix.tres")
const PushEffectTexture = preload("res://assets/animations/push/u_glove_S.png")
const PlayerIdleTexture = preload("res://assets/player/me_default.png")
const PlayerWalkTexture = preload("res://assets/player/me_walk.png")

const MOVE_REPEAT_INTERVAL := 0.28
const FAST_MOVE_REPEAT_INTERVAL := 0.12
const GLOVE_GAMEPLAY_FONT_SIZE := 54
const GLOVE_GAMEPLAY_LINE_SPACING := 0
const WORD_FONT_SIZE := GLOVE_GAMEPLAY_FONT_SIZE
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
const STARTUP_SKIP_ACQUISITION_ARG := "--glove-skip-acquisition"
const MAIN_SCENE_PATH := "res://Main.tscn"
const RETURN_TO_MAIN_SHORTCUT_KEY := KEY_ESCAPE
const GESTURE_TRANSITION_SWITCH_SECONDS := 0.5
const GESTURE_FLASH_PEAK_ALPHA := 0.3
const GLOVE_ACQUIRE_VIDEO_PATH := "res://assets/video/glove_acquire.ogv"
const GLOVE_PUT_ON_SOUND_PATH := "res://assets/audio/glove_put_on.wav"
const GLOVE_MELODY_SOUND_PATH := "res://assets/audio/glove_melody.wav"
const DELETE_CUT_SOUND_PATH := "res://assets/audio/delete_cut.wav"
const DELETE_CUT_DURATION := 1.15
const ACQUIRE_DIALOGUE_TEXT := "不知道该如何使用这力量，又该承担怎样的责任。\n我犹豫地向前踏出了一步。勇者的觉悟不言自明。"
const ACQUIRE_DIALOGUE_CHAR_DELAY := 0.1
const ACQUIRE_TUTORIAL_TEXT := "「找出该被搬移的文字，用『方向键』推动看看文\n字吧。展现出勇者该有的觉悟，只在一步之遥。」"
const HERO_QUOTE_TEXT := "勇者说：「你已经学会了使用这股力量，\n现在你把剑给我，继续向前完成勇者试炼吧」"
const HERO_QUOTE_STEP := 60.0
const HERO_QUOTE_GRID_ORIGIN := Vector2(300, 300)
const HERO_QUOTE_GRID_ORIGIN_CELL := Vector2i(5, 5)
const HERO_EXIT_FLASH_DURATION := 1.0
const GESTURE_INTRO_FALL_DURATION := 0.9
const GESTURE_INTRO_REVEAL_DURATION := 0.7
const GESTURE_INTRO_SWAP_INTERVAL := 0.075
const GESTURE_INTRO_SWAP_DURATION := 0.18
const GESTURE_INTRO_START_OFFSET_Y := -780.0
const PUSH_FLASH_FRAME_LOCAL_X := [-18.5, -20.0, -27.5, -38.5, -45.5, -50.0, -55.0, -58.0, -60.0, -61.0, -61.5, -62.0, -64.5, -65.0, -68.0, -68.0]
const PLAYER_WALK_FRAME_TIME := 0.055
const PLAYER_WALK_VISUAL_TIME := 0.12
const PLAYER_MOVE_REPEAT_TIME := 0.12
const PLAYER_BLOCKED_RETRY_TIME := 0.12
const INTRO_GRID_X_STEP := 600.0 / 11.0
const INTRO_TEXT_ORIGIN := Vector2i(4, 8)
const INTRO_PLAYER_START := Vector2i(4, 9)
const INTRO_NO_START := Vector2i(4, 8)
const INTRO_NO_TARGET := Vector2i(4, 9)
const INTRO_NO_FINAL_TARGET := Vector2i(3, 10)
const INTRO_COMPLETION_DELAY := 0.3
const INTRO_COMPLETION_SHAKE_DURATION := 0.5
const INTRO_TOP_REMAINDER := "知道该如何使用这力量，又该承担怎样的责任。"
const INTRO_BOTTOM_REMAINDER := "犹豫地向前踏出了一步。勇者的觉悟不言自明。"
const INTRO_BOTTOM_REWRITE := [
	"相信自己能够扛起重担，将艰难噩耗化为冲劲，",
	"留下一丝遗憾，为荒腔走板的世界开启改变契机。"
]
const INTRO_TOP_REWRITE := [
	"「当文字不小心陷在死角里，用『ＡＬＴ』加方向",
	"键先拉回正道再说吧！不过这比推动费劲多了。」"
]
const INTRO_BRAVE_QUOTE := [
	"「这份觉悟够清楚，但这样子就算是勇者了吗？谁",
	"知道你是不是碰巧蒙到？你最好再进一步发挥！」"
]

var world := GridWorld.new()
var page_camera := PageCamera.new()
var route_runner := GloveRouteRunner.new()
var player_mover := SmoothGridMover.new()
var entity_movers: Dictionary = {}
var entity_labels: Dictionary = {}
var player_label: Label
var player_sprite: Sprite2D
var map_layer: Node2D
var glove_effect_layer: Node2D
var glove_pull_particles: Node2D
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
var player_walk_visual_timers: Dictionary = {}
var player_walk_frame_timers: Dictionary = {}
var player_move_repeat_timer := 0.0
var player_blocked_retry_timer := 0.0
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
var like_loop_prompt := GloveLoopingPrompt.new("加油！")
var like_loop_prefix: Label
var like_loop_labels: Array[Label] = []
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
var acquisition_dialogue_label: Label
var acquisition_dialogue_indicator: Label
var acquisition_dialogue_active := false
var acquisition_dialogue_elapsed := 0.0
var acquisition_dialogue_index := 0
var acquisition_tutorial_label: Label
var acquisition_tutorial_active := false
var acquisition_tutorial_elapsed := 0.0
var acquisition_tutorial_index := 0
var intro_world := GridWorld.new()
var intro_active := false
var intro_quote_started := false
var intro_bottom_rewrite_started := false
var intro_top_rewrite_started := false
var intro_completed := false
var intro_completion_pending := false
var intro_completion_elapsed := 0.0
var intro_effect_elapsed := 0.0
var intro_layer: Node2D
var intro_top_remainder: Label
var intro_bottom_remainder: Label
var intro_player: Label
var intro_player_mover := SmoothGridMover.new()
var intro_player_visual_ready := false
var intro_entity_labels: Dictionary = {}
var intro_entity_movers: Dictionary = {}
var intro_player_sprite: Sprite2D
var intro_glove_effect_layer: Node2D
var intro_glove_pull_particles: Node2D
var hero_quote_label: Label
var hero_quote_player: Label
var hero_quote_player_sprite: Sprite2D
var hero_quote_characters: Node2D
var hero_quote_player_mover := SmoothGridMover.new()
var hero_quote_active := false
var hero_quote_elapsed := 0.0
var hero_quote_index := 0
var hero_quote_player_active := false
var hero_quote_world := GridWorld.new()
var hero_quote_world_active := false
var hero_quote_entities: Node2D
var hero_quote_entity_labels: Dictionary = {}
var hero_quote_entity_movers: Dictionary = {}
var hero_quote_glove_effect_layer: Node2D
var hero_quote_glove_pull_particles: Node2D
var hero_exit_arrow: Label
var hero_exit_flash: ColorRect
var hero_exit_transition_active := false
var hero_exit_transition_elapsed := 0.0
var gesture_intro_world := GridWorld.new()
var gesture_intro_layer: CanvasLayer
var gesture_intro_hand_root: Node2D
var gesture_intro_word_root: Node2D
var gesture_intro_player: Label
var gesture_intro_active := false
var gesture_intro_reveal_started := false
var gesture_intro_swap_started := false
var gesture_intro_elapsed := 0.0
var gesture_intro_reveal_elapsed := 0.0
var gesture_intro_swap_elapsed := 0.0
var gesture_intro_next_diagonal := 0
var gesture_intro_last_diagonal := 0
var gesture_intro_hand_labels: Dictionary = {}
var gesture_intro_reveal_labels: Array[Label] = []
var gesture_intro_active_swaps: Array[Dictionary] = []
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
	apply_startup_skip_acquisition(startup_args)
	apply_startup_capture_args(startup_args)

func initialize_preview_world() -> void:
	world.load_level(GloveLevel.build_level())
	demo_entries.clear()
	demo_index = 0
	demo_running = false
	demo_paused = false
	held_move_directions.clear()
	move_repeat_elapsed = 0.0
	player_move_repeat_timer = 0.0
	player_blocked_retry_timer = 0.0
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
	_update_player_visual_animations(delta)
	if player_move_repeat_timer > 0.0:
		player_move_repeat_timer = maxf(player_move_repeat_timer - delta, 0.0)
	if player_blocked_retry_timer > 0.0:
		player_blocked_retry_timer = maxf(player_blocked_retry_timer - delta, 0.0)
	if intro_active:
		intro_world.advance_highlight_animation(delta)
	_advance_gesture_transition(delta)
	_advance_delete_cut(delta)
	_advance_acquisition_dialogue(delta)
	_advance_intro_typewriter(delta)
	_advance_intro_completion_transition(delta)
	_advance_hero_quote(delta)
	_advance_hero_exit_transition(delta)
	_advance_gesture_intro(delta)
	if brave_loop_prompt.advance(delta):
		_sync_brave_loop_prompt()
	if like_loop_prompt.advance(delta):
		_sync_like_loop_prompt()
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
	elif intro_active:
		move_repeat_elapsed += delta
		var intro_interval := FAST_MOVE_REPEAT_INTERVAL if Input.is_key_pressed(KEY_SHIFT) else MOVE_REPEAT_INTERVAL
		while move_repeat_elapsed >= intro_interval:
			move_repeat_elapsed -= intro_interval
			_apply_intro_direction_step(direction)
	elif hero_quote_active:
		if not hero_quote_player_active:
			move_repeat_elapsed = 0.0
		else:
			move_repeat_elapsed += delta
			var hero_interval := FAST_MOVE_REPEAT_INTERVAL if Input.is_key_pressed(KEY_SHIFT) else MOVE_REPEAT_INTERVAL
			while move_repeat_elapsed >= hero_interval:
				move_repeat_elapsed -= hero_interval
				_apply_hero_quote_direction_step(direction)
	else:
		if player_move_repeat_timer <= 0.0 and player_blocked_retry_timer <= 0.0:
			_apply_direction_step(direction)

	var changed := false
	if _player_visual_ready:
		var previous_player := player_mover.current_position
		player_mover.advance(delta)
		changed = changed or previous_player != player_mover.current_position
	if hero_quote_player_active:
		var previous_hero_player := hero_quote_player_mover.current_position
		hero_quote_player.position = hero_quote_player_mover.advance(delta)
		changed = changed or previous_hero_player != hero_quote_player_mover.current_position
	if hero_quote_world_active:
		for mover in hero_quote_entity_movers.values():
			var previous_hero_entity: Vector2 = mover.current_position
			mover.advance(delta)
			changed = changed or previous_hero_entity != mover.current_position
		_apply_hero_quote_visual_positions()
	if intro_active:
		if intro_player_visual_ready:
			var previous_intro_player := intro_player_mover.current_position
			intro_player.position = intro_player_mover.advance(delta)
			changed = changed or previous_intro_player != intro_player_mover.current_position
		for mover in intro_entity_movers.values():
			var previous_intro_entity: Vector2 = mover.current_position
			mover.advance(delta)
			changed = changed or previous_intro_entity != mover.current_position
		_apply_intro_visual_positions()
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
	if acquisition_dialogue_active or acquisition_tutorial_active:
		_handle_acquisition_dialogue_input(key_event)
		return
	if intro_active:
		_handle_intro_input(key_event)
		return
	if hero_quote_active:
		_handle_hero_quote_input(key_event)
		return
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
		if key_event.pressed and player_move_repeat_timer <= 0.0 and player_blocked_retry_timer <= 0.0:
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
	glove_effect_layer = Node2D.new()
	glove_effect_layer.name = "GloveInteractionEffectLayer"
	glove_effect_layer.z_index = 80
	map_layer.add_child(glove_effect_layer)
	glove_pull_particles = PullParticleEffect.new()
	glove_pull_particles.name = "GlovePullParticles"
	glove_pull_particles.z_index = 81
	glove_pull_particles.visible = false
	map_layer.add_child(glove_pull_particles)
	_build_brave_loop_prompt()
	_build_like_loop_prompt()
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
	_build_gesture_intro_overlay()
	delete_cut_sound = AudioStreamPlayer.new()
	delete_cut_sound.stream = load(DELETE_CUT_SOUND_PATH)
	add_child(delete_cut_sound)
	player_label = _make_word_label("我", Color(0.92, 0.92, 0.92), Color(0.05, 0.05, 0.05))
	player_label.name = "Player"
	map_layer.add_child(player_label)
	player_sprite = _attach_player_sprite(player_label, float(world.cell_size))
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
	_sync_like_loop_prompt()
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
		group.visible = not _is_looping_like_dialogue(entity)
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

func _build_like_loop_prompt() -> void:
	like_loop_prefix = _make_word_label("勇：")
	like_loop_prefix.name = "LikeLoopPromptPrefix"
	like_loop_prefix.position = _grid_to_pixels(Vector2i(1, 8))
	like_loop_prefix.visible = false
	map_layer.add_child(like_loop_prefix)
	for index in range(like_loop_prompt.text.length()):
		var label := _make_word_label("")
		label.name = "LikeLoopPrompt_%d" % index
		label.position = _grid_to_pixels(Vector2i(3 + index, 8))
		label.visible = false
		map_layer.add_child(label)
		like_loop_labels.append(label)

func _sync_like_loop_prompt() -> void:
	if like_loop_prefix == null:
		return
	var visible := _has_like_dialogue()
	like_loop_prefix.visible = visible
	var text := like_loop_prompt.visible_text()
	for index in range(like_loop_labels.size()):
		var label := like_loop_labels[index]
		label.visible = visible and index < text.length()
		label.text = text.substr(index, 1) if index < text.length() else ""

func _has_like_dialogue() -> bool:
	var dialogue = world.get_any_entity_at(Vector2i(1, 8))
	return dialogue != null and dialogue.text == GloveEffects.DIALOGUE_LIKE

func _is_looping_like_dialogue(entity) -> bool:
	return entity.grid_pos == Vector2i(1, 8) and entity.text == GloveEffects.DIALOGUE_LIKE

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
		var base_color := Color.WHITE
		if entity.highlighted:
			base_color = Color(1.0, 0.95, 0.32)
		var animated_color := base_color.lerp(Color(1.0, 0.78, 0.18), highlight_strength)
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
	acquisition_dialogue_label = Label.new()
	acquisition_dialogue_label.name = "AcquireDialogueLabel"
	acquisition_dialogue_label.position = Vector2(272, 572)
	acquisition_dialogue_label.size = Vector2(1700, 160)
	acquisition_dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	acquisition_dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	acquisition_dialogue_label.add_theme_font_override("font", OriginalFont)
	acquisition_dialogue_label.add_theme_font_size_override("font_size", GLOVE_GAMEPLAY_FONT_SIZE)
	acquisition_dialogue_label.add_theme_constant_override("line_spacing", GLOVE_GAMEPLAY_LINE_SPACING)
	acquisition_dialogue_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	acquisition_dialogue_label.visible = false
	acquisition_layer.add_child(acquisition_dialogue_label)
	acquisition_tutorial_label = Label.new()
	acquisition_tutorial_label.name = "AcquireTutorialLabel"
	acquisition_tutorial_label.position = Vector2(290, 314)
	acquisition_tutorial_label.size = Vector2(1700, 150)
	acquisition_tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	acquisition_tutorial_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	acquisition_tutorial_label.add_theme_font_override("font", OriginalFont)
	acquisition_tutorial_label.add_theme_font_size_override("font_size", GLOVE_GAMEPLAY_FONT_SIZE)
	acquisition_tutorial_label.add_theme_constant_override("line_spacing", GLOVE_GAMEPLAY_LINE_SPACING)
	acquisition_tutorial_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	acquisition_tutorial_label.visible = false
	acquisition_layer.add_child(acquisition_tutorial_label)
	intro_layer = Node2D.new()
	intro_layer.name = "GlovePushTutorialLayer"
	acquisition_layer.add_child(intro_layer)
	intro_glove_effect_layer = Node2D.new()
	intro_glove_effect_layer.name = "GlovePushTutorialEffectLayer"
	intro_glove_effect_layer.z_index = 80
	intro_layer.add_child(intro_glove_effect_layer)
	intro_glove_pull_particles = PullParticleEffect.new()
	intro_glove_pull_particles.name = "GlovePushTutorialPullParticles"
	intro_glove_pull_particles.z_index = 81
	intro_glove_pull_particles.visible = false
	intro_layer.add_child(intro_glove_pull_particles)
	intro_top_remainder = _make_intro_word_label(INTRO_TOP_REMAINDER)
	intro_top_remainder.position = _intro_grid_to_pixels(INTRO_NO_START + Vector2i.RIGHT)
	intro_top_remainder.visible = false
	intro_layer.add_child(intro_top_remainder)
	intro_bottom_remainder = _make_intro_word_label(INTRO_BOTTOM_REMAINDER)
	intro_bottom_remainder.position = _intro_grid_to_pixels(INTRO_PLAYER_START + Vector2i.RIGHT)
	intro_bottom_remainder.visible = false
	intro_layer.add_child(intro_bottom_remainder)
	intro_player = _make_intro_word_label("我")
	intro_player.name = "GlovePushTutorialPlayer"
	intro_player.position = _intro_grid_to_pixels(INTRO_PLAYER_START)
	intro_player.visible = false
	intro_layer.add_child(intro_player)
	intro_player_sprite = _attach_player_sprite(intro_player, 60.0)
	hero_quote_label = Label.new()
	hero_quote_label.name = "HeroQuoteLabel"
	hero_quote_label.position = HERO_QUOTE_GRID_ORIGIN
	hero_quote_label.size = Vector2(1300, 220)
	hero_quote_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hero_quote_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	hero_quote_label.add_theme_font_override("font", OriginalFont)
	hero_quote_label.add_theme_font_size_override("font_size", GLOVE_GAMEPLAY_FONT_SIZE)
	hero_quote_label.add_theme_constant_override("line_spacing", GLOVE_GAMEPLAY_LINE_SPACING)
	hero_quote_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	hero_quote_label.visible = false
	acquisition_layer.add_child(hero_quote_label)
	hero_quote_characters = Node2D.new()
	hero_quote_characters.name = "HeroQuoteCharacters"
	acquisition_layer.add_child(hero_quote_characters)
	hero_quote_entities = Node2D.new()
	hero_quote_entities.name = "HeroQuoteEntities"
	acquisition_layer.add_child(hero_quote_entities)
	hero_quote_glove_effect_layer = Node2D.new()
	hero_quote_glove_effect_layer.name = "HeroQuoteEffectLayer"
	hero_quote_glove_effect_layer.z_index = 80
	acquisition_layer.add_child(hero_quote_glove_effect_layer)
	hero_quote_glove_pull_particles = PullParticleEffect.new()
	hero_quote_glove_pull_particles.name = "HeroQuotePullParticles"
	hero_quote_glove_pull_particles.z_index = 81
	hero_quote_glove_pull_particles.visible = false
	acquisition_layer.add_child(hero_quote_glove_pull_particles)
	hero_quote_player = Label.new()
	hero_quote_player.name = "HeroQuotePlayer"
	hero_quote_player.text = "我"
	hero_quote_player.position = _hero_quote_cell_for_index(HERO_QUOTE_TEXT.find("我"))
	hero_quote_player.size = Vector2(HERO_QUOTE_STEP, HERO_QUOTE_STEP)
	hero_quote_player.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_quote_player.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hero_quote_player.add_theme_font_override("font", OriginalFont)
	hero_quote_player.add_theme_font_size_override("font_size", GLOVE_GAMEPLAY_FONT_SIZE)
	hero_quote_player.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	hero_quote_player.visible = false
	acquisition_layer.add_child(hero_quote_player)
	hero_quote_player_sprite = _attach_player_sprite(hero_quote_player, HERO_QUOTE_STEP)
	hero_exit_arrow = Label.new()
	hero_exit_arrow.name = "HeroQuoteExitArrow"
	hero_exit_arrow.text = "->"
	hero_exit_arrow.position = Vector2(1710, 900)
	hero_exit_arrow.size = Vector2(150, 80)
	hero_exit_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_exit_arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hero_exit_arrow.add_theme_font_override("font", OriginalFont)
	hero_exit_arrow.add_theme_font_size_override("font_size", GLOVE_GAMEPLAY_FONT_SIZE)
	hero_exit_arrow.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	hero_exit_arrow.visible = false
	acquisition_layer.add_child(hero_exit_arrow)
	hero_exit_flash = ColorRect.new()
	hero_exit_flash.name = "HeroQuoteExitFlash"
	hero_exit_flash.color = Color(1.0, 1.0, 1.0, 0.0)
	hero_exit_flash.size = Vector2(1920, 1080)
	hero_exit_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_exit_flash.visible = false
	acquisition_layer.add_child(hero_exit_flash)
	acquisition_dialogue_indicator = Label.new()
	acquisition_dialogue_indicator.name = "AcquireDialogueContinue"
	acquisition_dialogue_indicator.text = "▽"
	acquisition_dialogue_indicator.position = Vector2(1510, 315)
	acquisition_dialogue_indicator.size = Vector2(54, 70)
	acquisition_dialogue_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	acquisition_dialogue_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	acquisition_dialogue_indicator.add_theme_font_override("font", OriginalFont)
	acquisition_dialogue_indicator.add_theme_font_size_override("font_size", GLOVE_GAMEPLAY_FONT_SIZE)
	acquisition_dialogue_indicator.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	acquisition_dialogue_indicator.visible = false
	acquisition_layer.add_child(acquisition_dialogue_indicator)

func _build_gesture_intro_overlay() -> void:
	gesture_intro_layer = CanvasLayer.new()
	gesture_intro_layer.name = "GloveGestureIntroLayer"
	gesture_intro_layer.layer = 140
	gesture_intro_layer.visible = false
	add_child(gesture_intro_layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color.BLACK
	backdrop.size = Vector2(1920, 1080)
	gesture_intro_layer.add_child(backdrop)
	gesture_intro_hand_root = Node2D.new()
	gesture_intro_hand_root.name = "GestureIntroHand"
	gesture_intro_layer.add_child(gesture_intro_hand_root)
	gesture_intro_word_root = Node2D.new()
	gesture_intro_word_root.name = "GestureIntroWords"
	gesture_intro_layer.add_child(gesture_intro_word_root)
	gesture_intro_player = _make_word_label("我")
	gesture_intro_player.name = "GestureIntroPlayer"
	gesture_intro_player.position = _grid_to_pixels(GloveLayouts.PLAYER_START)
	gesture_intro_player.visible = false
	gesture_intro_word_root.add_child(gesture_intro_player)

func _gesture_intro_initial_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in GloveLayouts.hand_cells("zero"):
		if cell.y <= 9:
			cells.append(cell)
	return cells

func _gesture_intro_remaining_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in GloveLayouts.hand_cells("zero"):
		if cell.y > 9:
			cells.append(cell)
	return cells

func _start_gesture_level_intro() -> void:
	if gesture_intro_active:
		return
	gesture_intro_active = true
	gesture_intro_reveal_started = false
	gesture_intro_swap_started = false
	gesture_intro_elapsed = 0.0
	gesture_intro_reveal_elapsed = 0.0
	gesture_intro_swap_elapsed = 0.0
	gesture_intro_hand_labels.clear()
	gesture_intro_reveal_labels.clear()
	gesture_intro_active_swaps.clear()
	for child in gesture_intro_hand_root.get_children():
		child.queue_free()
	for child in gesture_intro_word_root.get_children():
		if child != gesture_intro_player:
			child.queue_free()
	gesture_intro_hand_root.position = Vector2(0.0, GESTURE_INTRO_START_OFFSET_Y)
	gesture_intro_player.visible = false
	gesture_intro_layer.visible = true
	map_layer.visible = false
	world.player_input_locked = true
	world.player_event_locked = true
	var initial_cells := _gesture_intro_initial_cells()
	var initial_spawn: Array[Dictionary] = []
	for cell in initial_cells:
		initial_spawn.append({"text": "堂", "pos": cell, "config": {"solid": true}})
	gesture_intro_world.load_level({
		"name": "手势关开场",
		"screen_size": Vector2i(32, 18),
		"bounded": true,
		"allow_edge_transition": false,
		"player_start": GloveLayouts.PLAYER_START,
		"player_facing": Vector2i.RIGHT,
		"player_text": "我",
		"player_input_locked": true,
		"rows": [],
		"initial_spawn": initial_spawn
	})
	for cell in initial_cells:
		var label := _make_gesture_intro_word_label("堂", cell)
		gesture_intro_hand_root.add_child(label)
		gesture_intro_hand_labels[cell] = label

func _make_gesture_intro_word_label(text: String, cell: Vector2i) -> Label:
	var label := _make_word_label(text)
	label.position = _grid_to_pixels(cell)
	label.name = "GestureIntro_%s_%s_%s" % [text, cell.x, cell.y]
	return label

func _start_gesture_intro_reveal() -> void:
	gesture_intro_reveal_started = true
	gesture_intro_reveal_elapsed = 0.0
	for cell in _gesture_intro_remaining_cells():
		gesture_intro_world.add_entity("堂", cell, {"solid": true})
		var label := _make_gesture_intro_word_label("堂", cell)
		label.modulate.a = 0.0
		gesture_intro_hand_root.add_child(label)
		gesture_intro_hand_labels[cell] = label
		gesture_intro_reveal_labels.append(label)
	var subtitle := "俯瞰这一个巨大手掌，是零的手势"
	for index in range(subtitle.length()):
		var cell := GloveLayouts.BOTTOM_LINE.pos + Vector2i(index, 0)
		gesture_intro_world.add_entity(subtitle.substr(index, 1), cell, {"solid": true})
		var label := _make_gesture_intro_word_label(subtitle.substr(index, 1), cell)
		label.modulate.a = 0.0
		gesture_intro_word_root.add_child(label)
		gesture_intro_reveal_labels.append(label)
	gesture_intro_player.modulate.a = 0.0
	gesture_intro_player.visible = true
	gesture_intro_reveal_labels.append(gesture_intro_player)

func _start_gesture_intro_swap() -> void:
	gesture_intro_swap_started = true
	gesture_intro_swap_elapsed = 0.0
	var cells := GloveLayouts.hand_cells("zero")
	gesture_intro_next_diagonal = 1000
	gesture_intro_last_diagonal = -1000
	for cell in cells:
		gesture_intro_next_diagonal = mini(gesture_intro_next_diagonal, cell.x + cell.y)
		gesture_intro_last_diagonal = maxi(gesture_intro_last_diagonal, cell.x + cell.y)
	_start_gesture_intro_swap_wave()

func _start_gesture_intro_swap_wave() -> void:
	if gesture_intro_next_diagonal > gesture_intro_last_diagonal:
		return
	for cell in GloveLayouts.hand_cells("zero"):
		if cell.x + cell.y != gesture_intro_next_diagonal:
			continue
		var old_label: Label = gesture_intro_hand_labels.get(cell)
		if old_label == null:
			continue
		var new_label := _make_gesture_intro_word_label("掌", cell + Vector2i.DOWN)
		gesture_intro_hand_root.add_child(new_label)
		gesture_intro_active_swaps.append({"cell": cell, "old": old_label, "new": new_label, "elapsed": 0.0})
	gesture_intro_next_diagonal += 1

func _advance_gesture_intro(delta: float) -> void:
	if not gesture_intro_active:
		return
	if not gesture_intro_reveal_started:
		gesture_intro_elapsed += delta
		var landing_progress := clampf(gesture_intro_elapsed / GESTURE_INTRO_FALL_DURATION, 0.0, 1.0)
		gesture_intro_hand_root.position.y = _gesture_intro_landing_y(landing_progress)
		if landing_progress >= 1.0:
			gesture_intro_hand_root.position.y = 0.0
			_start_gesture_intro_reveal()
		return
	if not gesture_intro_swap_started:
		gesture_intro_reveal_elapsed += delta
		var reveal_progress := clampf(gesture_intro_reveal_elapsed / GESTURE_INTRO_REVEAL_DURATION, 0.0, 1.0)
		for label in gesture_intro_reveal_labels:
			label.modulate.a = reveal_progress
		if reveal_progress >= 1.0:
			_start_gesture_intro_swap()
		return
	gesture_intro_swap_elapsed += delta
	while gesture_intro_swap_elapsed >= GESTURE_INTRO_SWAP_INTERVAL:
		gesture_intro_swap_elapsed -= GESTURE_INTRO_SWAP_INTERVAL
		_start_gesture_intro_swap_wave()
	for index in range(gesture_intro_active_swaps.size() - 1, -1, -1):
		var swap: Dictionary = gesture_intro_active_swaps[index]
		swap.elapsed = float(swap.elapsed) + delta
		var progress := clampf(float(swap.elapsed) / GESTURE_INTRO_SWAP_DURATION, 0.0, 1.0)
		var cell: Vector2i = swap.cell
		var old_label: Label = swap.old
		var new_label: Label = swap.new
		old_label.position = _grid_to_pixels(cell) + Vector2(0.0, -world.cell_size * progress)
		new_label.position = _grid_to_pixels(cell) + Vector2(0.0, world.cell_size * (1.0 - progress))
		if progress < 1.0:
			gesture_intro_active_swaps[index] = swap
			continue
		old_label.queue_free()
		gesture_intro_hand_labels[cell] = new_label
		var old_entity = gesture_intro_world.get_entity_at(cell)
		if old_entity != null:
			gesture_intro_world.entities.erase(old_entity.id)
		gesture_intro_world.add_entity("掌", cell, {"solid": true})
		gesture_intro_active_swaps.remove_at(index)
	if gesture_intro_next_diagonal > gesture_intro_last_diagonal and gesture_intro_active_swaps.is_empty():
		_finish_gesture_level_intro()

func _gesture_intro_landing_y(progress: float) -> float:
	if progress < 0.68:
		return lerpf(GESTURE_INTRO_START_OFFSET_Y, 72.0, ease(progress / 0.68, 2.2))
	if progress < 0.86:
		return lerpf(72.0, -22.0, (progress - 0.68) / 0.18)
	return lerpf(-22.0, 0.0, (progress - 0.86) / 0.14)

func _finish_gesture_level_intro() -> void:
	gesture_intro_active = false
	gesture_intro_layer.visible = false
	map_layer.visible = true
	world.player_input_locked = false
	world.player_event_locked = false
	_refresh_view()

func _consume_visual_effect_request() -> void:
	for raw_request in world.consume_visual_effects():
		var request: Dictionary = raw_request
		match str(request.get("type", "")):
			"player_push_flash":
				_play_glove_push_flash(request)
			"pull_particles":
				_play_glove_pull_particles(request)
			"glove_acquire":
				_start_glove_acquisition()
			"delete_cut":
				_start_delete_cut(request)

func _play_glove_pull_particles(request: Dictionary) -> void:
	_play_glove_pull_particles_at(
		request,
		glove_pull_particles,
		_grid_to_pixels(request.get("origin_grid", Vector2i.ZERO)),
		float(world.cell_size)
	)

func _play_glove_pull_particles_at(request: Dictionary, particles: Node2D, origin: Vector2, cell_size: float) -> void:
	if particles == null:
		return
	particles.play_at(
		origin,
		cell_size,
		float(request.get("duration", 0.42)),
		int(request.get("seed", 2371))
	)

func _play_glove_push_flash(request: Dictionary) -> void:
	_play_glove_push_flash_at(
		request,
		glove_effect_layer,
		_grid_to_pixels(request.get("player_to", world.player_pos))
	)

func _play_glove_push_flash_at(request: Dictionary, effect_layer: Node2D, base_position: Vector2) -> void:
	if effect_layer == null or PushEffectTexture == null:
		return
	var direction: Vector2i = request.get("direction", Vector2i.ZERO)
	if direction == Vector2i.ZERO:
		return
	var sprite := Sprite2D.new()
	sprite.name = "PlayerPushFlash"
	sprite.texture = PushEffectTexture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.hframes = 10
	sprite.vframes = 2
	sprite.frame = 0
	sprite.centered = true
	sprite.rotation_degrees = _push_flash_rotation(direction)
	effect_layer.add_child(sprite)
	_set_glove_push_flash_progress(0.0, sprite, base_position, direction)
	var tween := create_tween()
	tween.tween_method(Callable(self, "_set_glove_push_flash_progress").bind(sprite, base_position, direction), 0.0, 1.0, 0.5)
	tween.tween_callback(Callable(sprite, "queue_free"))

func _set_glove_push_flash_progress(progress: float, sprite: Sprite2D, base_position: Vector2, direction: Vector2i) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	var frame := clampi(int(round(progress * 15.0)), 0, 15)
	sprite.frame = frame
	sprite.position = _glove_push_flash_position(base_position, direction, frame, progress)

func _glove_push_flash_position(base_position: Vector2, direction: Vector2i, frame: int, progress: float) -> Vector2:
	var local_x := float(PUSH_FLASH_FRAME_LOCAL_X[clampi(frame, 0, PUSH_FLASH_FRAME_LOCAL_X.size() - 1)])
	if direction == Vector2i.RIGHT:
		return base_position + Vector2(40.0 + progress * 4.0 - local_x, 30.0)
	if direction == Vector2i.LEFT:
		return base_position + Vector2(20.0 - progress * 4.0 + local_x, 30.0)
	if direction == Vector2i.DOWN:
		return base_position + Vector2(30.0, 40.0 + progress * 4.0 - local_x)
	return base_position + Vector2(30.0, 20.0 - progress * 4.0 + local_x)

func _push_flash_rotation(direction: Vector2i) -> float:
	if direction == Vector2i.RIGHT:
		return 0.0
	if direction == Vector2i.LEFT:
		return 180.0
	if direction == Vector2i.DOWN:
		return 90.0
	return 270.0

func _start_glove_acquisition() -> void:
	if glove_acquisition_active:
		return
	glove_acquisition_active = true
	acquisition_dialogue_active = false
	acquisition_tutorial_active = false
	hero_quote_active = false
	hero_quote_player_active = false
	acquisition_layer.visible = true
	acquisition_video.visible = false
	acquisition_dialogue_label.visible = false
	acquisition_tutorial_label.visible = false
	hero_quote_label.visible = false
	hero_quote_player.visible = false
	acquisition_dialogue_indicator.visible = false
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
	acquisition_video.visible = false
	acquisition_dialogue_active = true
	acquisition_dialogue_elapsed = 0.0
	acquisition_dialogue_index = 0
	acquisition_dialogue_label.text = ""
	acquisition_dialogue_label.visible = true
	acquisition_tutorial_label.visible = false
	acquisition_dialogue_indicator.visible = false

func _advance_acquisition_dialogue(delta: float) -> void:
	if acquisition_dialogue_active and acquisition_dialogue_index < ACQUIRE_DIALOGUE_TEXT.length():
		acquisition_dialogue_elapsed += delta
		while acquisition_dialogue_elapsed >= ACQUIRE_DIALOGUE_CHAR_DELAY and acquisition_dialogue_index < ACQUIRE_DIALOGUE_TEXT.length():
			acquisition_dialogue_elapsed -= ACQUIRE_DIALOGUE_CHAR_DELAY
			acquisition_dialogue_index += 1
			acquisition_dialogue_label.text = ACQUIRE_DIALOGUE_TEXT.left(acquisition_dialogue_index)
		if acquisition_dialogue_index >= ACQUIRE_DIALOGUE_TEXT.length():
			_start_acquisition_tutorial()
	if not acquisition_tutorial_active or acquisition_tutorial_index >= ACQUIRE_TUTORIAL_TEXT.length():
		return
	acquisition_tutorial_elapsed += delta
	while acquisition_tutorial_elapsed >= ACQUIRE_DIALOGUE_CHAR_DELAY and acquisition_tutorial_index < ACQUIRE_TUTORIAL_TEXT.length():
		acquisition_tutorial_elapsed -= ACQUIRE_DIALOGUE_CHAR_DELAY
		acquisition_tutorial_index += 1
		acquisition_tutorial_label.text = ACQUIRE_TUTORIAL_TEXT.left(acquisition_tutorial_index)
	if acquisition_tutorial_index >= ACQUIRE_TUTORIAL_TEXT.length():
		_start_intro_push_tutorial()

func _start_acquisition_tutorial() -> void:
	acquisition_dialogue_active = false
	acquisition_tutorial_active = true
	acquisition_tutorial_elapsed = 0.0
	acquisition_tutorial_index = 0
	acquisition_tutorial_label.text = ""
	acquisition_tutorial_label.visible = true
	acquisition_dialogue_indicator.visible = false

func _handle_acquisition_dialogue_input(key_event: InputEventKey) -> void:
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode != KEY_SPACE and key_event.keycode != KEY_ENTER:
		return
	if acquisition_dialogue_active and acquisition_dialogue_index < ACQUIRE_DIALOGUE_TEXT.length():
		acquisition_dialogue_index = ACQUIRE_DIALOGUE_TEXT.length()
		acquisition_dialogue_label.text = ACQUIRE_DIALOGUE_TEXT
		_start_acquisition_tutorial()
		return
	if acquisition_tutorial_active and acquisition_tutorial_index < ACQUIRE_TUTORIAL_TEXT.length():
		acquisition_tutorial_index = ACQUIRE_TUTORIAL_TEXT.length()
		acquisition_tutorial_label.text = ACQUIRE_TUTORIAL_TEXT
		_start_intro_push_tutorial()
		return
	if acquisition_tutorial_active:
		_start_intro_push_tutorial()
		return
	acquisition_dialogue_active = false
	acquisition_tutorial_active = false

func _start_intro_push_tutorial() -> void:
	if intro_active:
		return
	hero_quote_active = false
	hero_quote_player_active = false
	hero_quote_label.visible = false
	hero_quote_player.visible = false
	_clear_hero_quote_characters()
	intro_world.load_level({
		"name": "手套推动教学",
		"screen_size": Vector2i(32, 18),
		"bounded": true,
		"allow_edge_transition": false,
		"player_start": INTRO_PLAYER_START,
		"player_facing": Vector2i.DOWN,
		"player_text": "我",
		"rows": [],
		"initial_spawn": [
			{"text": "不", "pos": INTRO_NO_START, "config": {"solid": true, "pushable": true}},
			{"text": "「找出该被搬移的文字，用『方向键』推动看看文", "pos": Vector2i(4, 4), "config": {"solid": true, "pushable": false}},
			{"text": "字吧。展现出勇者该有的觉悟，只在一步之遥。」", "pos": Vector2i(4, 5), "config": {"solid": true, "pushable": false}},
			{"text": INTRO_TOP_REMAINDER, "pos": INTRO_NO_START + Vector2i.RIGHT, "config": {"solid": true, "pushable": false}},
			{"text": INTRO_BOTTOM_REMAINDER, "pos": INTRO_PLAYER_START + Vector2i.RIGHT, "config": {"solid": true, "pushable": false}}
		],
		"entity_move_effects": [
			{
				"text": "不",
				"from": INTRO_NO_START,
				"to": INTRO_NO_TARGET,
				"effect": {
					"remove_texts": [
						"「找出该被搬移的文字，用『方向键』推动看看文",
						"字吧。展现出勇者该有的觉悟，只在一步之遥。」"
					],
					"start_typewriter": {
						"lines": INTRO_BRAVE_QUOTE,
						"pos": Vector2i(4, 4),
						"char_delay": ACQUIRE_DIALOGUE_CHAR_DELAY,
						"config": {"solid": true, "pushable": false}
					}
				}
			}
		]
	})
	intro_active = true
	intro_quote_started = false
	intro_bottom_rewrite_started = false
	intro_top_rewrite_started = false
	intro_completed = false
	intro_completion_pending = false
	intro_completion_elapsed = 0.0
	intro_layer.position = Vector2.ZERO
	intro_effect_elapsed = 0.0
	intro_player_visual_ready = false
	intro_entity_labels.clear()
	intro_entity_movers.clear()
	held_move_directions.clear()
	move_repeat_elapsed = 0.0
	acquisition_dialogue_active = false
	acquisition_tutorial_active = false
	acquisition_dialogue_label.visible = false
	acquisition_tutorial_label.visible = false
	acquisition_dialogue_indicator.visible = false
	intro_top_remainder.visible = false
	intro_bottom_remainder.visible = false
	intro_player.visible = true
	_sync_intro_world_view()

func _handle_intro_input(key_event: InputEventKey) -> void:
	if intro_completion_pending:
		return
	if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
		if intro_quote_started and not intro_bottom_rewrite_started and not intro_world.has_pending_timed_effect():
			_start_intro_bottom_rewrite()
		return
	if intro_bottom_rewrite_started and intro_world.has_pending_timed_effect():
		return
	var direction := _direction_from_key(key_event.keycode)
	if direction == Vector2i.ZERO or key_event.echo:
		return
	_set_direction_held(direction, key_event.pressed)
	if not key_event.pressed:
		return
	move_repeat_elapsed = 0.0
	_apply_intro_direction_step(direction)

func _start_intro_bottom_rewrite() -> void:
	intro_bottom_rewrite_started = true
	intro_effect_elapsed = 0.0
	intro_bottom_remainder.visible = false
	intro_world._apply_map_effect({
		"remove_texts": [INTRO_BOTTOM_REMAINDER],
		"start_typewriter": {
			"lines": INTRO_BOTTOM_REWRITE,
			"pos": INTRO_NO_TARGET + Vector2i.RIGHT,
			"line_offsets": [Vector2i.ZERO, Vector2i.LEFT],
			"char_delay": ACQUIRE_DIALOGUE_CHAR_DELAY,
			"config": {"solid": true, "pushable": false}
		}
	})
	_sync_intro_world_view()

func _apply_intro_direction_step(direction: Vector2i) -> void:
	var result: Dictionary
	if Input.is_key_pressed(KEY_ALT):
		result = intro_world.pull_front(direction)
	else:
		result = intro_world.try_move_player(direction)
	if not bool(result.get("success", false)):
		return
	_sync_intro_world_view()
	_consume_intro_visual_effect_requests()
	_play_player_walk_visual(intro_player_sprite)
	if not intro_quote_started and _intro_no_reached_target():
		intro_quote_started = true
		acquisition_tutorial_label.visible = false
	_check_intro_completion()

func _intro_no_reached_target() -> bool:
	var no_word = intro_world.get_entity_at(INTRO_NO_TARGET)
	return no_word != null and no_word.text == "不"

func _check_intro_completion() -> void:
	if intro_completed or intro_completion_pending:
		return
	var no_word = intro_world.get_entity_at(INTRO_NO_FINAL_TARGET)
	if no_word == null or no_word.text != "不":
		return
	intro_completion_pending = true
	intro_completion_elapsed = 0.0
	intro_world.player_input_locked = true

func _advance_intro_completion_transition(delta: float) -> void:
	if not intro_completion_pending:
		return
	intro_completion_elapsed += maxf(delta, 0.0)
	if intro_completion_elapsed <= INTRO_COMPLETION_DELAY:
		return
	var shake_elapsed := intro_completion_elapsed - INTRO_COMPLETION_DELAY
	if shake_elapsed < INTRO_COMPLETION_SHAKE_DURATION:
		intro_layer.position = Vector2(
			sin(shake_elapsed * 90.0) * 10.0,
			cos(shake_elapsed * 73.0) * 8.0
		)
		return
	intro_completion_pending = false
	intro_completed = true
	intro_active = false
	held_move_directions.clear()
	move_repeat_elapsed = 0.0
	intro_layer.position = Vector2.ZERO
	intro_layer.visible = false
	_start_hero_quote()

func _advance_intro_typewriter(delta: float) -> void:
	if not intro_active or not intro_world.has_pending_timed_effect():
		return
	intro_effect_elapsed += delta
	while intro_world.has_pending_timed_effect() and intro_effect_elapsed >= intro_world.pending_timed_delay:
		intro_effect_elapsed -= intro_world.pending_timed_delay
		intro_world.resolve_pending_timed_effect()
		_sync_intro_world_view()
		if intro_bottom_rewrite_started and not intro_top_rewrite_started and not intro_world.has_pending_timed_effect():
			_start_intro_top_rewrite()
			return

func _start_intro_top_rewrite() -> void:
	intro_top_rewrite_started = true
	intro_effect_elapsed = 0.0
	for entity_id in intro_world.entities.keys():
		var entity = intro_world.entities.get(entity_id)
		if entity.grid_pos.y == 4 or entity.grid_pos.y == 5:
			intro_world.entities.erase(entity_id)
	intro_world._apply_map_effect({
		"start_typewriter": {
			"lines": INTRO_TOP_REWRITE,
			"pos": Vector2i(4, 4),
			"char_delay": ACQUIRE_DIALOGUE_CHAR_DELAY,
			"config": {"solid": true, "pushable": false}
		}
	})
	_sync_intro_world_view()

func _sync_intro_world_view() -> void:
	if not intro_active:
		return
	var player_target := _intro_grid_to_pixels(intro_world.player_pos)
	if not intro_player_visual_ready:
		intro_player_mover.snap_to(player_target)
		intro_player_visual_ready = true
	else:
		intro_player_mover.move_to(player_target, move_visual_duration)
	var alive := {}
	for entity in intro_world.entities.values():
		alive[entity.id] = true
		var label: Label = intro_entity_labels.get(entity.id)
		if label == null:
			label = _make_intro_word_label(entity.text)
			label.name = "GlovePushTutorialWord_%s" % entity.id
			intro_layer.add_child(label)
			intro_entity_labels[entity.id] = label
			var mover := SmoothGridMover.new()
			mover.snap_to(_intro_grid_to_pixels(entity.grid_pos))
			intro_entity_movers[entity.id] = mover
		else:
			label.text = entity.text
		var mover: SmoothGridMover = intro_entity_movers.get(entity.id)
		mover.move_to(_intro_grid_to_pixels(entity.grid_pos), move_visual_duration)
	for entity_id in intro_entity_labels.keys():
		if alive.has(entity_id):
			continue
		intro_entity_labels[entity_id].queue_free()
		intro_entity_labels.erase(entity_id)
		intro_entity_movers.erase(entity_id)
	_apply_intro_visual_positions()

func _consume_intro_visual_effect_requests() -> void:
	for raw_request in intro_world.consume_visual_effects():
		var request: Dictionary = raw_request
		match str(request.get("type", "")):
			"player_push_flash":
				_play_glove_push_flash_at(
					request,
					intro_glove_effect_layer,
					_intro_grid_to_pixels(request.get("player_to", intro_world.player_pos))
				)
			"pull_particles":
				_play_glove_pull_particles_at(
					request,
					intro_glove_pull_particles,
					_intro_grid_to_pixels(request.get("origin_grid", intro_world.player_pos)),
					60.0
				)

func _apply_intro_visual_positions() -> void:
	if not intro_active:
		return
	if intro_player_visual_ready:
		intro_player.position = intro_player_mover.current_position
	for entity_id in intro_entity_labels.keys():
		var mover: SmoothGridMover = intro_entity_movers.get(entity_id)
		intro_entity_labels[entity_id].position = mover.current_position

func _make_intro_word_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.size = Vector2(1800, 60) if text.length() > 1 else Vector2(60, 60)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", OriginalFont)
	label.add_theme_font_size_override("font_size", GLOVE_GAMEPLAY_FONT_SIZE)
	label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	return label

func _intro_grid_to_pixels(pos: Vector2i) -> Vector2:
	return Vector2(pos.x * INTRO_GRID_X_STEP, pos.y * 60)

func _start_hero_quote() -> void:
	acquisition_dialogue_active = false
	acquisition_tutorial_active = false
	hero_quote_active = true
	hero_quote_elapsed = 0.0
	hero_quote_index = 0
	hero_quote_player_active = false
	hero_quote_world_active = false
	hero_exit_transition_active = false
	hero_exit_transition_elapsed = 0.0
	acquisition_dialogue_label.visible = false
	acquisition_tutorial_label.visible = false
	acquisition_dialogue_indicator.visible = false
	hero_quote_label.text = ""
	hero_quote_label.visible = false
	_clear_hero_quote_characters()
	hero_quote_characters.visible = true
	_clear_hero_quote_entities()
	hero_exit_arrow.visible = false
	hero_exit_flash.visible = false
	hero_quote_player.position = _hero_quote_cell_for_index(HERO_QUOTE_TEXT.find("我"))
	hero_quote_player_mover.snap_to(hero_quote_player.position)
	hero_quote_player.visible = false

func _advance_hero_quote(delta: float) -> void:
	if not hero_quote_active or hero_quote_index >= HERO_QUOTE_TEXT.length():
		return
	hero_quote_elapsed += delta
	while hero_quote_elapsed >= ACQUIRE_DIALOGUE_CHAR_DELAY and hero_quote_index < HERO_QUOTE_TEXT.length():
		hero_quote_elapsed -= ACQUIRE_DIALOGUE_CHAR_DELAY
		_add_hero_quote_character(hero_quote_index)
		hero_quote_index += 1
		hero_quote_label.text = HERO_QUOTE_TEXT.left(hero_quote_index)
	if hero_quote_index >= HERO_QUOTE_TEXT.length():
		hero_quote_label.text = HERO_QUOTE_TEXT.replace("我", "　")
		var player_character = hero_quote_characters.get_node_or_null("HeroQuoteCharacter_%d" % HERO_QUOTE_TEXT.find("我"))
		if player_character:
			player_character.queue_free()
		hero_quote_player.position = _hero_quote_cell_for_index(HERO_QUOTE_TEXT.find("我"))
		hero_quote_player_mover.snap_to(hero_quote_player.position)
		hero_quote_player.visible = true
		hero_quote_player_active = true
		_build_hero_quote_world()

func _clear_hero_quote_characters() -> void:
	for character in hero_quote_characters.get_children():
		character.queue_free()

func _clear_hero_quote_entities() -> void:
	for entity_label in hero_quote_entity_labels.values():
		entity_label.queue_free()
	hero_quote_entity_labels.clear()
	hero_quote_entity_movers.clear()

func _build_hero_quote_world() -> void:
	var initial_spawn: Array[Dictionary] = []
	var player_index := HERO_QUOTE_TEXT.find("我")
	for index in range(HERO_QUOTE_TEXT.length()):
		var character := HERO_QUOTE_TEXT.substr(index, 1)
		if character == "\n" or index == player_index:
			continue
		initial_spawn.append({
			"text": character,
			"pos": _hero_quote_grid_cell_for_index(index),
			"config": {"solid": true, "pushable": false}
		})
	hero_quote_world.load_level({
		"name": "勇者台词",
		"screen_size": Vector2i(32, 18),
		"bounded": true,
		"allow_edge_transition": false,
		"player_start": _hero_quote_grid_cell_for_index(player_index),
		"player_facing": Vector2i.RIGHT,
		"player_text": "我",
		"rows": [],
		"initial_spawn": initial_spawn
	})
	hero_quote_world_active = true
	hero_quote_characters.visible = false
	hero_quote_player_mover.snap_to(_hero_quote_grid_to_pixels(hero_quote_world.player_pos))
	hero_quote_player.position = hero_quote_player_mover.current_position
	hero_exit_arrow.visible = true
	_sync_hero_quote_world_view()

func _sync_hero_quote_world_view() -> void:
	if not hero_quote_world_active:
		return
	var player_target := _hero_quote_grid_to_pixels(hero_quote_world.player_pos)
	hero_quote_player_mover.move_to(player_target, move_visual_duration)
	var alive := {}
	for entity in hero_quote_world.entities.values():
		alive[entity.id] = true
		var label: Label = hero_quote_entity_labels.get(entity.id)
		if label == null:
			label = _make_hero_quote_word_label(entity.text)
			label.name = "HeroQuoteEntity_%s" % entity.id
			hero_quote_entities.add_child(label)
			hero_quote_entity_labels[entity.id] = label
			var mover := SmoothGridMover.new()
			mover.snap_to(_hero_quote_grid_to_pixels(entity.grid_pos))
			hero_quote_entity_movers[entity.id] = mover
		var mover: SmoothGridMover = hero_quote_entity_movers.get(entity.id)
		mover.move_to(_hero_quote_grid_to_pixels(entity.grid_pos), move_visual_duration)
	for entity_id in hero_quote_entity_labels.keys():
		if alive.has(entity_id):
			continue
		hero_quote_entity_labels[entity_id].queue_free()
		hero_quote_entity_labels.erase(entity_id)
		hero_quote_entity_movers.erase(entity_id)
	_apply_hero_quote_visual_positions()

func _apply_hero_quote_visual_positions() -> void:
	if not hero_quote_world_active:
		return
	hero_quote_player.position = hero_quote_player_mover.current_position
	for entity_id in hero_quote_entity_labels.keys():
		var mover: SmoothGridMover = hero_quote_entity_movers.get(entity_id)
		hero_quote_entity_labels[entity_id].position = mover.current_position

func _make_hero_quote_word_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.size = Vector2(HERO_QUOTE_STEP, HERO_QUOTE_STEP)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", OriginalFont)
	label.add_theme_font_size_override("font_size", GLOVE_GAMEPLAY_FONT_SIZE)
	label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	return label

func _add_hero_quote_character(index: int) -> void:
	if index < 0 or index >= HERO_QUOTE_TEXT.length():
		return
	var character := HERO_QUOTE_TEXT.substr(index, 1)
	if character == "\n":
		return
	var label := Label.new()
	label.name = "HeroQuoteCharacter_%d" % index
	label.text = character
	label.position = _hero_quote_cell_for_index(index)
	label.size = Vector2(HERO_QUOTE_STEP, HERO_QUOTE_STEP)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", OriginalFont)
	label.add_theme_font_size_override("font_size", GLOVE_GAMEPLAY_FONT_SIZE)
	label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	hero_quote_characters.add_child(label)

func _hero_quote_cell_for_index(index: int) -> Vector2:
	return _hero_quote_grid_to_pixels(_hero_quote_grid_cell_for_index(index))

func _hero_quote_grid_cell_for_index(index: int) -> Vector2i:
	var column := 0
	var row := 0
	for character_index in range(index):
		if HERO_QUOTE_TEXT.substr(character_index, 1) == "\n":
			row += 1
			column = 0
		else:
			column += 1
	return HERO_QUOTE_GRID_ORIGIN_CELL + Vector2i(column, row)

func _hero_quote_grid_to_pixels(pos: Vector2i) -> Vector2:
	return Vector2(pos.x * HERO_QUOTE_STEP, pos.y * HERO_QUOTE_STEP)

func _handle_hero_quote_input(key_event: InputEventKey) -> void:
	if hero_exit_transition_active:
		return
	if not hero_quote_player_active:
		return
	var direction := _direction_from_key(key_event.keycode)
	if direction == Vector2i.ZERO or key_event.echo:
		return
	_set_direction_held(direction, key_event.pressed)
	if not key_event.pressed:
		return
	move_repeat_elapsed = 0.0
	_apply_hero_quote_direction_step(direction)

func _apply_hero_quote_direction_step(direction: Vector2i) -> void:
	if hero_quote_world_active:
		var result := hero_quote_world.try_move_player(direction)
		if not bool(result.get("success", false)):
			return
		_sync_hero_quote_world_view()
		_consume_hero_quote_visual_effect_requests()
		_play_player_walk_visual(hero_quote_player_sprite)
		if hero_quote_world.player_pos.x >= hero_quote_world.screen_size.x - 1:
			_start_hero_exit_transition()
		return
	var next_position := hero_quote_player_mover.current_position + Vector2(direction) * HERO_QUOTE_STEP
	if next_position.x < 0.0 or next_position.x > 1860.0 or next_position.y < 0.0 or next_position.y > 1020.0:
		return
	hero_quote_player_mover.move_to(next_position, move_visual_duration)

func _consume_hero_quote_visual_effect_requests() -> void:
	for raw_request in hero_quote_world.consume_visual_effects():
		var request: Dictionary = raw_request
		match str(request.get("type", "")):
			"player_push_flash":
				_play_glove_push_flash_at(
					request,
					hero_quote_glove_effect_layer,
					_hero_quote_grid_to_pixels(request.get("player_to", hero_quote_world.player_pos))
				)
			"pull_particles":
				_play_glove_pull_particles_at(
					request,
					hero_quote_glove_pull_particles,
					_hero_quote_grid_to_pixels(request.get("origin_grid", hero_quote_world.player_pos)),
					HERO_QUOTE_STEP
				)

func _start_hero_exit_transition() -> void:
	if hero_exit_transition_active:
		return
	hero_exit_transition_active = true
	hero_exit_transition_elapsed = 0.0
	hero_quote_world.player_input_locked = true
	hero_exit_arrow.visible = false
	hero_exit_flash.color.a = 0.0
	hero_exit_flash.visible = true

func _advance_hero_exit_transition(delta: float) -> void:
	if not hero_exit_transition_active:
		return
	hero_exit_transition_elapsed += maxf(delta, 0.0)
	var progress := clampf(hero_exit_transition_elapsed / HERO_EXIT_FLASH_DURATION, 0.0, 1.0)
	hero_exit_flash.color.a = sin(progress * PI) * 0.95
	if progress < 1.0:
		return
	hero_exit_transition_active = false
	hero_exit_flash.visible = false
	_enter_glove_gesture_level()

func _enter_glove_gesture_level() -> void:
	hero_quote_active = false
	hero_quote_player_active = false
	hero_quote_world_active = false
	hero_exit_arrow.visible = false
	hero_quote_player.visible = false
	hero_quote_entities.visible = false
	acquisition_layer.visible = false
	_start_gesture_level_intro()

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
	for index in range(held_move_directions.size() - 1, -1, -1):
		var direction := held_move_directions[index]
		if _is_direction_physically_held(direction):
			return direction
		held_move_directions.remove_at(index)
	return Vector2i.ZERO

func _is_direction_physically_held(direction: Vector2i) -> bool:
	match direction:
		Vector2i.RIGHT:
			return Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
		Vector2i.LEFT:
			return Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
		Vector2i.UP:
			return Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)
		Vector2i.DOWN:
			return Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)
	return false

func _apply_direction_step(direction: Vector2i) -> void:
	var result: Dictionary
	if Input.is_key_pressed(KEY_ALT):
		result = world.pull_front(direction)
	else:
		result = world.try_move_player(direction)
	player_move_repeat_timer = PLAYER_MOVE_REPEAT_TIME
	if not result.get("success", false):
		player_blocked_retry_timer = PLAYER_BLOCKED_RETRY_TIME
	_apply_result(result)
	if result.get("success", false):
		_play_player_walk_visual(player_sprite)
		_show_direction_marker(direction)

func _attach_player_sprite(player: Label, cell_size: float) -> Sprite2D:
	player.text = ""
	var sprite := Sprite2D.new()
	sprite.name = "PlayerVisual"
	sprite.position = Vector2.ONE * cell_size * 0.5
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player.add_child(sprite)
	_set_player_idle_visual(sprite)
	return sprite

func _play_player_walk_visual(sprite: Sprite2D) -> void:
	if sprite == null:
		return
	var sprite_id := sprite.get_instance_id()
	sprite.texture = PlayerWalkTexture
	sprite.hframes = 2
	sprite.vframes = 1
	sprite.frame = 0
	sprite.centered = true
	sprite.scale = Vector2.ONE
	sprite.modulate = Color.WHITE
	sprite.rotation = 0.0
	player_walk_visual_timers[sprite_id] = PLAYER_WALK_VISUAL_TIME
	player_walk_frame_timers[sprite_id] = 0.0

func _update_player_visual_animations(delta: float) -> void:
	for sprite_id_value in player_walk_visual_timers.keys():
		var sprite_id := int(sprite_id_value)
		var sprite := instance_from_id(sprite_id) as Sprite2D
		if sprite == null or not is_instance_valid(sprite):
			player_walk_visual_timers.erase(sprite_id)
			player_walk_frame_timers.erase(sprite_id)
			continue
		var remaining := maxf(float(player_walk_visual_timers[sprite_id]) - delta, 0.0)
		var frame_elapsed := float(player_walk_frame_timers.get(sprite_id, 0.0)) + delta
		if frame_elapsed >= PLAYER_WALK_FRAME_TIME:
			frame_elapsed = 0.0
			sprite.frame = 1 - sprite.frame
		player_walk_visual_timers[sprite_id] = remaining
		player_walk_frame_timers[sprite_id] = frame_elapsed
		if remaining <= 0.0:
			_set_player_idle_visual(sprite)

func _set_player_idle_visual(sprite: Sprite2D) -> void:
	if sprite == null:
		return
	var sprite_id := sprite.get_instance_id()
	player_walk_visual_timers.erase(sprite_id)
	player_walk_frame_timers.erase(sprite_id)
	sprite.texture = PlayerIdleTexture
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0
	sprite.centered = true
	sprite.scale = Vector2.ONE
	sprite.modulate = Color.WHITE
	sprite.rotation = 0.0

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
		match str(arg):
			STARTUP_DEBUG_ARG_PREFIX + "release":
				world.apply_preview_effect(GloveEffects.release_preview_effect())
				world.facing = Vector2i.UP
				_refresh_view()
			STARTUP_DEBUG_ARG_PREFIX + "gesture_intro":
				call_deferred("_start_gesture_level_intro")

func apply_startup_skip_acquisition(args: PackedStringArray) -> void:
	if not args.has(STARTUP_SKIP_ACQUISITION_ARG):
		return
	call_deferred("_finish_glove_acquisition")

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
