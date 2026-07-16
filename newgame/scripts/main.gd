extends Node2D

const GridWorld = preload("res://scripts/grid_world.gd")
const WordEntity = preload("res://scripts/word_entity.gd")
const LevelLoader = preload("res://scripts/level_loader.gd")
const ArtifactHall = preload("res://levels/hall/artifact_hall.gd")
const HelmetTutorial = preload("res://levels/helmet/helmet_tutorial.gd")
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
const GemBurstEffect = preload("res://scripts/gem_burst_effect.gd")
const LightGlowEffect = preload("res://scripts/light_glow_effect.gd")
const PullParticleEffect = preload("res://scripts/pull_particle_effect.gd")
const TreeSpriteScene = preload("res://scenes/animations/TreeSprite.tscn")
const SplitBaseTexture = preload("res://assets/animations/split/base_white.png")
const SplitParticleTexture = preload("res://assets/animations/split/unzip_split.png")
const BackspaceSplashTexture = preload("res://assets/sprites/backspace_splash/splash.png")
const BackspaceCutShader = preload("res://assets/shaders/cut2.gdshader")
const OriginalFont = preload("res://Fonts/Zpix-v3.1.6.ttf")
const PushEffectTexture = preload("res://assets/animations/push/u_glove_S.png")
const HallDoorOpenScene = preload("res://scenes/animations/hall_door_open.tscn")

const WORD_FONT_SIZE := 56
const GEM_COLOR := Color(0.0, 0.58, 0.62, 1.0)
const GEM_ORIGIN_GRID := Vector2(15.5, 15.5)
const GEM_REVEAL_SPEED := 8.0
const INTRO_PROMPT_HOLD := 0.65
const PLAYER_WALK_VISUAL_TIME := 0.12
const PLAYER_WALK_FRAME_TIME := 0.055
const PLAYER_MOVE_REPEAT_TIME := 0.12
const PLAYER_BLOCKED_RETRY_TIME := 0.12
const CREEK_WAVE_SPEED := TAU * 0.55
const CREEK_WAVE_AMPLITUDE := 4.0
const CREEK_MIN_X := 16
const BRIDGE_SHAKE_DEFAULT_SPEED := TAU * 1.35
const BRIDGE_COLLAPSE_SHAKE_AMPLITUDE := 12.0
const BRIDGE_COLLAPSE_SHAKE_CYCLES := 5.0
const BRIDGE_COLLAPSE_SHAKE_DURATION := 0.85
const BRIDGE_COLLAPSE_FALL_DISTANCE := 72.0
const BRIDGE_COLLAPSE_PLAYER_FALL_DISTANCE := 84.0
const BRIDGE_COLLAPSE_MASK_PADDING := 6.0
const PUSH_FLASH_FRAME_LOCAL_X := [-18.5, -20.0, -27.5, -38.5, -45.5, -50.0, -55.0, -58.0, -60.0, -61.0, -61.5, -62.0, -64.5, -65.0, -68.0, -68.0]
const BACKSPACE_CUT_ANGLE_DEGREES := 45.0
const BACKSPACE_CUT_MASK_EXTRA_X := 14.0
const BACKSPACE_CUT_DURATION := 1.15
const BRIDGE_MERGE_YELLOW := Color(1.0, 0.92, 0.22, 0.58)
const BRIDGE_MERGE_YELLOW_SOFT := Color(1.0, 0.92, 0.22, 0.16)
const KEY_INFO_EMPHASIS := "key_info_emphasis"
const RIVER_DEPTH_STEP := 10
const RIVER_PLAYER_DEPTH_OFFSET := 5
const HALL_DOOR_OPEN_DEPTH := 20
const HALL_DOOR_LEFT_X := -14.0
const HALL_DOOR_RIGHT_X := 34.0
const HALL_DOOR_FRAGMENT_WIDTH := 14.0
const HALL_DOOR_FINAL_SHIFT_X := -13.0
const HIGHLIGHT_VISUAL_CONFIG_PATH := "res://assets/animations/highlight/highlight_visual_config.json"
const GLOVE_PREVIEW_SCENE_PATH := "res://levels/glove/glove_preview.tscn"
const HALL_PREVIEW_SCENE_PATH := "res://levels/hall/artifact_hall_preview.tscn"
const HELMET_ACQUISITION_BGM_PATH := "res://assets/audio/bgm/ch4/BGM_4_29_vault_AB.ogg"
const SWORD_FLOW_SCENE_PATH := "res://scenes/Maps/第二章/05_聖劍寶庫_復刻.tscn"
const STARTUP_ENTRY_ARG_PREFIX := "--entry="
const SWORD_SCENE_SHORTCUT_KEY := KEY_F8
const GLOVE_SCENE_SHORTCUT_KEY := KEY_F9
const HALL_SCENE_SHORTCUT_KEY := KEY_F10
const LEVEL_SEQUENCE := [
	ArtifactHall,
	HelmetTutorial,
	HelmetR1,
	HelmetR2,
	HelmetR3,
	HelmetR4,
	HelmetR5,
	HelmetR6,
	HelmetReturn
]

@export var startup_level_index := 0
@export var startup_player_pos := Vector2i(-1, -1)
@export var startup_player_text := ""
@export var startup_player_facing := Vector2i.ZERO
@export var startup_bridge_collapse_preview := false

var world := GridWorld.new()
var page_camera := PageCamera.new()
var demo := DemoRunner.new()
var player_mover := SmoothGridMover.new()
var current_level_index := 0
var entity_movers: Dictionary = {}
var entity_labels: Dictionary = {}
var player_label: Label
var player_sprite: Sprite2D
var main_menu: Control
var map_layer: Node2D
var bridge_tree_effect_layer: Node2D
var demo_timer: Timer
var world_event_timer: Timer
var direction_marker: Node2D
var direction_marker_fill: Polygon2D
var direction_marker_outline: Line2D
var direction_marker_timer: Timer
var fullscreen_video_player: VideoStreamPlayer
var level_bgm_player: AudioStreamPlayer
var gem_burst_effect
var light_glow_effect
var pull_particle_effect
var direction_marker_direction := Vector2i.ZERO
var held_move_directions: Array[Vector2i] = []
var move_visual_duration := 0.12
var player_walk_visual_timer := 0.0
var player_walk_frame_timer := 0.0
var player_move_repeat_timer := 0.0
var player_blocked_retry_timer := 0.0
var _player_visual_ready := false
var _last_player_visible := true
var player_river_visual_offset := 0.0
var player_river_tween: Tween
var player_river_action_locked := false
var _visual_effect_generation := 0
var key_info_emphasis_played := false
var key_info_effect_active := false
var key_info_sequence_pending := false
var visual_sequence_has_key_info := false
var pre_key_visual_effects_active := 0
var pre_merge_push_effects_active := 0
var highlight_visual_config: Dictionary = {}
var gem_labels: Array = []
var intro_phase := "lights"
var intro_reveal_elapsed := 0.0
var intro_reveal_max_distance := 0.0
var creek_wave_elapsed := 0.0
var bridge_shake_elapsed := 0.0

func _ready() -> void:
	main_menu = get_node_or_null("MainMenu") as Control
	var startup_scene_path := resolve_startup_scene_path(OS.get_cmdline_user_args())
	if not startup_scene_path.is_empty():
		call_deferred("_switch_to_scene", startup_scene_path)
		return
	# Main.tscn is a menu entry scene; do not build the game world underneath it.
	if main_menu != null:
		return
	highlight_visual_config = load_highlight_visual_config()
	_load_level_index(startup_level_index, _startup_level_overrides())
	_apply_startup_preview_state()
	page_camera.sync_to_world(world)
	_build_scene()
	_refresh_view()

func _process(delta: float) -> void:
	if main_menu != null and is_instance_valid(main_menu) and main_menu.visible:
		return
	world.advance_highlight_animation(delta)
	_update_player_visual_animation(delta)
	if player_move_repeat_timer > 0.0:
		player_move_repeat_timer = maxf(player_move_repeat_timer - delta, 0.0)
	if player_blocked_retry_timer > 0.0:
		player_blocked_retry_timer = maxf(player_blocked_retry_timer - delta, 0.0)
	var direction := _current_held_direction()
	if not player_river_action_locked and direction != Vector2i.ZERO and player_move_repeat_timer <= 0.0 and player_blocked_retry_timer <= 0.0:
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
	creek_wave_elapsed = fmod(creek_wave_elapsed + delta, 10.0)
	bridge_shake_elapsed = fmod(bridge_shake_elapsed + delta, 10.0)
	_apply_visual_positions()
	_update_intro_sequence(delta)
	_update_gem_labels()

func _unhandled_input(event: InputEvent) -> void:
	if main_menu != null and is_instance_valid(main_menu) and main_menu.visible:
		return
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
		if not player_river_action_locked and key_event.pressed and player_move_repeat_timer <= 0.0 and player_blocked_retry_timer <= 0.0:
			_apply_direction_step(direction)
		return
	if not PrecisionMovement.should_process_key_event(key_event.pressed, key_event.echo, direction):
		return
	if player_river_action_locked:
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
	player_label = _make_word_label("", Color(0.92, 0.92, 0.92), Color.TRANSPARENT)
	player_label.name = "Player"
	player_label.pivot_offset = player_label.size * 0.5
	map_layer.add_child(player_label)
	_setup_player_sprite()
	_build_direction_marker()
	bridge_tree_effect_layer = Node2D.new()
	bridge_tree_effect_layer.name = "BridgeTreeEffectLayer"
	bridge_tree_effect_layer.z_index = 19
	map_layer.add_child(bridge_tree_effect_layer)
	light_glow_effect = LightGlowEffect.new()
	light_glow_effect.name = "LightGlowEffect"
	light_glow_effect.z_index = 9
	map_layer.add_child(light_glow_effect)
	gem_burst_effect = GemBurstEffect.new()
	gem_burst_effect.name = "GemBurstEffect"
	map_layer.add_child(gem_burst_effect)
	pull_particle_effect = PullParticleEffect.new()
	pull_particle_effect.name = "PullParticleEffect"
	pull_particle_effect.z_index = 18
	map_layer.add_child(pull_particle_effect)
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
	canvas.visible = true
	fullscreen_video_player = VideoStreamPlayer.new()
	fullscreen_video_player.name = "FullscreenVideoPlayer"
	fullscreen_video_player.visible = false
	fullscreen_video_player.expand = true
	fullscreen_video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	fullscreen_video_player.finished.connect(_on_fullscreen_video_finished)
	canvas.add_child(fullscreen_video_player)
	level_bgm_player = AudioStreamPlayer.new()
	level_bgm_player.name = "LevelBGM"
	level_bgm_player.bus = StringName("BGM") if AudioServer.get_bus_index("BGM") >= 0 else StringName("Master")
	canvas.add_child(level_bgm_player)
	_sync_level_bgm()

func _refresh_view(_message := "") -> void:
	_sync_entity_labels()
	_sync_direction_marker()
	player_label.text = "" if _uses_player_sprite() else world.player_text
	player_label.visible = world.player_visible
	_apply_intro_visibility()
	page_camera.sync_to_world(world)
	map_layer.position = page_camera.offset_pixels()
	var player_target := _grid_to_pixels(world.player_pos)
	var should_snap_player := not _player_visual_ready or (world.player_visible and not _last_player_visible)
	if should_snap_player:
		player_mover.snap_to(player_target)
		_player_visual_ready = true
	else:
		player_mover.move_to(player_target, move_visual_duration)
	_last_player_visible = world.player_visible
	_apply_visual_positions()
	_sync_player_depth()
	player_label.move_to_front()
	_start_pending_world_event()

func _setup_player_sprite() -> void:
	player_sprite = Sprite2D.new()
	player_sprite.name = "PlayerVisual"
	player_sprite.position = Vector2(world.cell_size, world.cell_size) * 0.5
	player_sprite.z_index = 1
	player_label.add_child(player_sprite)
	_set_player_idle_visual()

func _start_pending_world_event() -> void:
	if world_event_timer == null:
		return
	if world.has_pending_timed_effect() and world_event_timer.is_stopped():
		world_event_timer.start(world.pending_timed_delay)

func _sync_entity_labels() -> void:
	gem_labels.clear()
	intro_reveal_max_distance = 0.0
	var light_entries: Array = []
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
		group.rotation_degrees = entity.visual_rotation_degrees
		group.z_index = _entity_depth_for(entity)
		_sync_entity_label_group(group, entity)
		if entity.text == "光" and not entity.solid:
			light_entries.append({
				"position": entity_mover.current_position,
				"phase_offset": float(entity.grid_pos.x + entity.grid_pos.y) * 0.48
			})
		for i in range(entity.text.length()):
			var character: String = str(entity.text).substr(i, 1)
			if not _is_blue_gem_character(character, entity.visual_color):
				continue
			var label: Label = group.get_child(i) as Label
			var cell_center := _grid_to_pixels(entity.grid_pos + Vector2i(i, 0)) + Vector2(world.cell_size * 0.5, world.cell_size * 0.5)
			gem_labels.append({"label": label, "position": cell_center, "base_color": entity.visual_color})
			intro_reveal_max_distance = maxf(
				intro_reveal_max_distance,
				cell_center.distance_to(_grid_to_pixels_float(GEM_ORIGIN_GRID)) / float(world.cell_size)
			)
	for id in entity_labels.keys():
		if not alive.has(id):
			entity_labels[id].queue_free()
			entity_labels.erase(id)
			entity_movers.erase(id)
	if light_glow_effect:
		light_glow_effect.sync_lights(light_entries, float(world.cell_size), OriginalFont)

func _clear_entity_visuals() -> void:
	for group in entity_labels.values():
		if is_instance_valid(group):
			group.queue_free()
	entity_labels.clear()
	entity_movers.clear()
	gem_labels.clear()
	if gem_burst_effect:
		gem_burst_effect.stop()
	if light_glow_effect:
		light_glow_effect.clear()
	creek_wave_elapsed = 0.0

func _is_blue_gem_character(character: String, color: Color) -> bool:
	return (character == "宝" or character == "石") and color == GEM_COLOR

func _is_blue_gem_entity(entity) -> bool:
	var text := str(entity.text)
	for i in range(text.length()):
		if _is_blue_gem_character(text.substr(i, 1), entity.visual_color):
			return true
	return false

func _is_intro_prompt_entity(entity) -> bool:
	var prompt_cells: Array = HelmetTutorial._intro_description_cells()
	for cell in entity.cells:
		if prompt_cells.has(cell):
			return true
	return false

func _is_helmet_tutorial_level() -> bool:
	return current_level_index >= 0 and current_level_index < LEVEL_SEQUENCE.size() and LEVEL_SEQUENCE[current_level_index] == HelmetTutorial

func _apply_intro_visibility() -> void:
	for id in entity_labels.keys():
		var entity: WordEntity = world.entities.get(id)
		var group: Node2D = entity_labels.get(id)
		if entity == null or group == null:
			continue
		var visible := true
		var is_light := entity.text == "光" and not entity.solid
		var is_prompt := _is_intro_prompt_entity(entity)
		if intro_phase == "lights":
			visible = is_light
		elif intro_phase == "prompt":
			visible = is_light or is_prompt
		elif intro_phase == "gems":
			visible = _is_blue_gem_entity(entity) or is_light or is_prompt
		group.visible = visible
		for child in group.get_children():
			child.visible = visible and (intro_phase != "gems" or is_light or is_prompt)
	if player_label:
		player_label.visible = world.player_visible and intro_phase == "active"
		if player_sprite:
			player_sprite.visible = world.player_visible and intro_phase == "active" and _uses_player_sprite()

func _update_gem_labels() -> void:
	if gem_burst_effect == null:
		return
	for entry in gem_labels:
		var label: Label = entry.label
		var position: Vector2 = entry.position
		var base_color: Color = entry.base_color
		if intro_phase == "lights" or intro_phase == "prompt":
			label.visible = false
		elif intro_phase == "gems":
			var distance_in_cells: float = position.distance_to(_grid_to_pixels_float(GEM_ORIGIN_GRID)) / float(world.cell_size)
			label.visible = distance_in_cells <= intro_reveal_elapsed * GEM_REVEAL_SPEED
			label.add_theme_color_override("font_color", base_color)
		else:
			label.visible = true
			label.add_theme_color_override("font_color", gem_burst_effect.color_for_position(position, base_color))

func _update_intro_sequence(delta: float) -> void:
	if intro_phase == "prompt":
		intro_reveal_elapsed += delta
		if intro_reveal_elapsed >= INTRO_PROMPT_HOLD:
			_begin_gem_reveal()
		return
	if intro_phase != "gems":
		return
	intro_reveal_elapsed += delta
	var reveal_duration := intro_reveal_max_distance / GEM_REVEAL_SPEED + 0.18
	if intro_reveal_elapsed < reveal_duration:
		return
	intro_phase = "active"
	world.set_input_locked(false)
	world.set_event_locked(false)
	_refresh_view()
	_play_gem_burst_preview()

func _begin_gem_reveal() -> void:
	if not _is_helmet_tutorial_level() or intro_phase != "prompt":
		return
	var light_cells := _current_light_cells()
	world._apply_map_effect({
		"remove_matching": [{"positions": light_cells, "texts": ["宝", "石"], "solid": true}],
		"spawn_text": _restore_gems_without_light_overlap()
	})
	world.update_page()
	world.set_input_locked(true)
	world.set_event_locked(true)
	intro_phase = "gems"
	intro_reveal_elapsed = 0.0
	_refresh_view()

func _current_light_cells() -> Array:
	var light_cells: Array = []
	for entity in world.entities.values():
		if entity.text == "光" and not entity.solid:
			light_cells.append_array(entity.cells)
	return light_cells

func _restore_gems_without_light_overlap() -> Array:
	var light_cells := {}
	for cell in _current_light_cells():
		light_cells[cell] = true
	var restored: Array = []
	for spawn_config in HelmetTutorial._restore_all_light_covered_treasure_text():
		var entry: Dictionary = spawn_config
		var position: Vector2i = entry.get("pos", Vector2i.ZERO)
		if not light_cells.has(position):
			restored.append(entry)
	return restored

func _begin_intro_prompt() -> void:
	if not _is_helmet_tutorial_level() or intro_phase != "lights":
		return
	world.set_input_locked(true)
	world.set_event_locked(true)
	intro_phase = "prompt"
	intro_reveal_elapsed = 0.0
	_refresh_view()

func _apply_visual_positions() -> void:
	player_label.position = player_mover.current_position + Vector2(0.0, player_river_visual_offset)
	_sync_player_depth()
	for id in entity_labels.keys():
		var mover = entity_movers.get(id)
		if mover:
			var visual_position: Vector2 = mover.current_position
			var entity: WordEntity = world.entities.get(id)
			if _is_creek_visual_entity(entity):
				visual_position.y += _creek_wave_offset(entity)
			if _is_horizontal_shake_entity(entity):
				visual_position.x += _horizontal_shake_offset(entity)
			entity_labels[id].position = visual_position

func _is_creek_visual_entity(entity: WordEntity) -> bool:
	return current_level_index > 0 and entity != null and entity.text == "溪" and entity.grid_pos.x >= CREEK_MIN_X

func _entity_depth_for(entity: WordEntity) -> int:
	if _is_hall_door_open_entity(entity):
		return HALL_DOOR_OPEN_DEPTH
	if _is_creek_visual_entity(entity):
		return entity.grid_pos.y * RIVER_DEPTH_STEP
	return 10 if entity.text == "光" and not entity.solid else 0

func _sync_player_depth() -> void:
	if world.player_submerged:
		player_label.z_index = world.player_pos.y * RIVER_DEPTH_STEP + RIVER_PLAYER_DEPTH_OFFSET
	else:
		player_label.z_index = 0

func _creek_wave_offset(entity: WordEntity) -> float:
	var phase: float = creek_wave_elapsed * CREEK_WAVE_SPEED
	phase += float(entity.grid_pos.x) * 0.52
	phase += float(entity.grid_pos.y) * 0.16
	return sin(phase) * CREEK_WAVE_AMPLITUDE

func _is_horizontal_shake_entity(entity: WordEntity) -> bool:
	return entity != null and entity.visual_horizontal_shake_amplitude > 0.0

func _horizontal_shake_offset(entity: WordEntity) -> float:
	var speed: float = float(entity.visual_horizontal_shake_speed)
	if speed <= 0.0:
		speed = BRIDGE_SHAKE_DEFAULT_SPEED
	var phase: float = bridge_shake_elapsed * speed + float(entity.visual_horizontal_shake_phase)
	return sin(phase) * entity.visual_horizontal_shake_amplitude

func _sync_entity_label_group(group: Node2D, entity) -> void:
	if _is_tree_animated_entity(entity):
		_sync_tree_sprite_group(group)
		return
	if _is_hall_door_open_entity(entity):
		_sync_hall_door_open_group(group, entity)
		return

	var text := str(entity.text)
	for child in group.get_children():
		if child is Label:
			continue
		group.remove_child(child)
		child.queue_free()
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
		var base_color: Color = entity.visual_color
		if entity.highlighted:
			base_color = _highlight_config_color("matched_color", Color(1.0, 0.95, 0.32))
		var animated_color: Color = base_color.lerp(_highlight_config_color("accent_color", Color(1.0, 0.78, 0.18)), highlight_strength)
		label.add_theme_color_override("font_color", animated_color)
		var pulse_scale_max := float(highlight_visual_config.get("pulse_scale_max", 1.14))
		var pulse_scale := 1.0 + (highlight_strength * maxf(pulse_scale_max - 1.0, 0.0))
		label.scale = Vector2.ONE * pulse_scale

func _is_hall_door_open_entity(entity: WordEntity) -> bool:
	return entity != null and entity.text == "门" and entity.visual_style == "hall_door_open"

func _sync_hall_door_open_group(group: Node2D, entity: WordEntity) -> void:
	var left_label := group.get_node_or_null("HallDoorLeft") as Label
	var right_label := group.get_node_or_null("HallDoorRight") as Label
	if left_label == null or right_label == null or group.get_child_count() != 2:
		_clear_group_children(group)
		left_label = _make_half_cell_word_label("丨", HALL_DOOR_LEFT_X + HALL_DOOR_FINAL_SHIFT_X, "HallDoorLeft")
		right_label = _make_half_cell_word_label("亅", HALL_DOOR_RIGHT_X + HALL_DOOR_FINAL_SHIFT_X, "HallDoorRight")
		group.add_child(left_label)
		group.add_child(right_label)
	var highlight_strength := world.get_highlight_animation_strength(entity.grid_pos)
	var base_color: Color = entity.visual_color
	if entity.highlighted:
		base_color = _highlight_config_color("matched_color", Color(1.0, 0.95, 0.32))
	var animated_color: Color = base_color.lerp(_highlight_config_color("accent_color", Color(1.0, 0.78, 0.18)), highlight_strength)
	var pulse_scale_max := float(highlight_visual_config.get("pulse_scale_max", 1.14))
	var pulse_scale := 1.0 + (highlight_strength * maxf(pulse_scale_max - 1.0, 0.0))
	for label in [left_label, right_label]:
		if label == null:
			continue
		label.add_theme_color_override("font_color", animated_color)
		label.scale = Vector2.ONE * pulse_scale

func _make_half_cell_word_label(text: String, x_offset: float, node_name: String) -> Label:
	var label := _make_word_label(text)
	label.name = node_name
	label.position = Vector2(x_offset, -2.0)
	label.size = Vector2(HALL_DOOR_FRAGMENT_WIDTH, world.cell_size + 4.0)
	label.pivot_offset = label.size * 0.5
	label.add_theme_font_size_override("font_size", WORD_FONT_SIZE - 2)
	return label

func _clear_group_children(group: Node2D) -> void:
	for child in group.get_children():
		group.remove_child(child)
		child.queue_free()

func _is_tree_animated_entity(entity: WordEntity) -> bool:
	return entity != null and entity.text == "树"

func _sync_tree_sprite_group(group: Node2D) -> void:
	for child in group.get_children():
		if child.name == "TreeSprite":
			child.position = Vector2.ZERO
			child.scale = Vector2.ONE
			child.rotation = 0.0
			child.visible = true
			return
	for child in group.get_children():
		group.remove_child(child)
		child.queue_free()
	var tree_sprite := TreeSpriteScene.instantiate()
	tree_sprite.name = "TreeSprite"
	group.add_child(tree_sprite)

func _apply_result(result: Dictionary) -> void:
	if result.has("transition"):
		_handle_transition(result)
		return
	var visual_requests: Array = world.consume_visual_effects()
	var visual_contexts: Array = _prepare_visual_effect_contexts(visual_requests)
	_refresh_view(str(result.get("message", "")))
	_consume_visual_effects(visual_requests, visual_contexts)
	_consume_fullscreen_video_request()
	if not world.pending_scene_path.is_empty():
		var scene_path: String = world.pending_scene_path
		world.pending_scene_path = ""
		call_deferred("_switch_to_scene", scene_path)
		return
	if world.pending_level_index >= 0:
		var level_index: int = world.pending_level_index
		world.pending_level_index = -1
		call_deferred("_switch_to_level_index", level_index)
		return
	if _is_helmet_tutorial_level() and intro_phase == "lights" and result.get("success", false) and not world.has_pending_timed_effect():
		_begin_intro_prompt()
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
	if LEVEL_SEQUENCE[current_level_index] == HelmetR6:
		overrides = {
			"player_pos": Vector2i(0, int(result.get("exit_y", world.player_pos.y))),
			"player_text": "鹅",
			"player_facing": Vector2i.RIGHT
		}
	_load_level_index(next_index, overrides)
	_refresh_view()

func _consume_fullscreen_video_request() -> void:
	if world.fullscreen_video_request.is_empty():
		return
	var request := world.fullscreen_video_request.duplicate(true)
	world.fullscreen_video_request.clear()
	_play_fullscreen_video(str(request.get("path", "")))

func _consume_visual_effects(visual_requests: Array, visual_contexts: Array) -> void:
	var key_info_will_play := _visual_requests_include_key_info(visual_requests)
	var pre_key_effect_count := _count_pre_key_visual_effects(visual_requests)
	var pre_merge_push_count := _count_pre_merge_push_effects(visual_requests, pre_key_effect_count)
	var visual_sequence_will_run := key_info_will_play or pre_key_effect_count > 0 or pre_merge_push_count > 0
	if visual_sequence_will_run:
		key_info_sequence_pending = true
		visual_sequence_has_key_info = key_info_will_play
		pre_key_visual_effects_active = pre_key_effect_count
		pre_merge_push_effects_active = pre_merge_push_count
	for i in range(visual_requests.size()):
		var request: Dictionary = visual_requests[i]
		var effect_type := str(request.get("type", ""))
		var visual_context: Dictionary = visual_contexts[i] if i < visual_contexts.size() else {}
		if visual_sequence_will_run:
			if effect_type == "player_push_flash" and pre_merge_push_count > 0:
				call_deferred("_run_pre_merge_push_effect", request.duplicate(true), _visual_effect_generation)
				continue
			if effect_type == "word_merge_flash" or effect_type == "bridge_word_merge_flash" or effect_type == "word_split_transition":
				call_deferred("_run_pre_key_visual_effect", request.duplicate(true), visual_context, _visual_effect_generation)
				continue
			if effect_type == KEY_INFO_EMPHASIS:
				if key_info_will_play:
					call_deferred("_run_key_info_after_pre_effects", request.duplicate(true), _visual_effect_generation)
				continue
			if _is_key_info_driver(request):
				call_deferred("_run_bridge_tree_transition_after_pre_effects", request.duplicate(true), visual_context, _visual_effect_generation)
				continue
			call_deferred("_run_visual_effect_after_key_info", request.duplicate(true), visual_context, _visual_effect_generation)
			continue
		if effect_type == "gem_burst":
			if gem_burst_effect == null:
				continue
			var origin_grid: Vector2 = request.get("origin_grid", GEM_ORIGIN_GRID)
			gem_burst_effect.play_at(
				_grid_to_pixels_float(origin_grid),
				world.cell_size,
				float(request.get("duration", 0.78)),
				int(request.get("seed", 1947))
			)
			continue
		if effect_type == "pull_particles":
			if pull_particle_effect == null:
				continue
			var origin_grid: Vector2 = request.get("origin_grid", Vector2.ZERO)
			pull_particle_effect.play_at(
				_grid_to_pixels_float(origin_grid),
				float(world.cell_size),
				float(request.get("duration", 0.42)),
				int(request.get("seed", 2371))
			)
			continue
		if effect_type == "player_river_enter":
			_play_player_river_enter(request)
			continue
		if effect_type == "player_river_exit":
			_play_player_river_exit(request)
			continue
		if effect_type == "player_push_flash":
			_play_player_push_flash(request)
			continue
		if effect_type == "backspace_cut":
			call_deferred("_run_backspace_cut_effect", request.duplicate(true), _visual_effect_generation)
			continue
		if effect_type == "word_merge_flash" or effect_type == "bridge_word_merge_flash":
			call_deferred("_run_word_merge_flash", request.duplicate(true), _visual_effect_generation)
			continue
		if effect_type == "hall_door_open":
			call_deferred("_run_hall_door_open_source_effect", request.duplicate(true), _visual_effect_generation)
			continue
		if effect_type == "black_screen_transition":
			call_deferred("_run_black_screen_transition", request.duplicate(true))
			continue
		if effect_type == KEY_INFO_EMPHASIS:
			if not key_info_emphasis_played:
				key_info_emphasis_played = true
				call_deferred("_run_key_info_emphasis", request.duplicate(true), _visual_effect_generation)
			continue
		if effect_type == "bridge_tree_transition":
			call_deferred("_run_bridge_tree_transition", request.duplicate(true), visual_context, _visual_effect_generation)
			continue
		if effect_type == "bridge_tree_relocate":
			call_deferred("_run_bridge_tree_relocate", request.duplicate(true), _visual_effect_generation)
			continue
		if effect_type == "bridge_collapse_sequence":
			call_deferred("_run_bridge_collapse_sequence", request.duplicate(true), _visual_effect_generation)
		if effect_type == "word_split_transition":
			call_deferred("_run_word_split_transition", request.duplicate(true), visual_context, _visual_effect_generation)

func _run_backspace_cut_effect(request: Dictionary, generation: int) -> void:
	if generation != _visual_effect_generation or map_layer == null:
		return
	var text := str(request.get("text", ""))
	if text.is_empty():
		return
	var grid_pos: Vector2i = request.get("pos", Vector2i.ZERO)
	var cell_origin := _grid_to_pixels(grid_pos)
	var cell_size := Vector2(world.cell_size, world.cell_size)

	var mask := ColorRect.new()
	mask.name = "BackspaceCutMask"
	mask.position = cell_origin - Vector2(BACKSPACE_CUT_MASK_EXTRA_X, 0.0)
	mask.size = cell_size + Vector2(BACKSPACE_CUT_MASK_EXTRA_X * 2.0, 0.0)
	mask.color = Color.BLACK
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask.z_index = 70
	map_layer.add_child(mask)

	var word_viewport := _build_backspace_word_viewport(text)
	map_layer.add_child(word_viewport)
	await get_tree().process_frame
	if generation != _visual_effect_generation:
		mask.queue_free()
		word_viewport.queue_free()
		return

	var material := ShaderMaterial.new()
	material.shader = BackspaceCutShader
	material.set_shader_parameter("degree", float(request.get("angle_degrees", BACKSPACE_CUT_ANGLE_DEGREES)))
	material.set_shader_parameter("time", 0.0)

	var split_sprite := Sprite2D.new()
	split_sprite.name = "BackspaceCutWord"
	split_sprite.texture = word_viewport.get_texture()
	split_sprite.material = material
	split_sprite.centered = true
	split_sprite.position = cell_origin + cell_size * 0.5
	split_sprite.z_index = 72
	map_layer.add_child(split_sprite)

	var slash := Sprite2D.new()
	slash.name = "BackspaceCutSplash"
	slash.texture = BackspaceSplashTexture
	slash.hframes = 10
	slash.vframes = 2
	slash.frame = 0
	slash.z_index = 74
	slash.centered = true
	slash.position = cell_origin + cell_size * 0.5
	slash.rotation_degrees = float(request.get("angle_degrees", BACKSPACE_CUT_ANGLE_DEGREES))
	map_layer.add_child(slash)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(material, "shader_parameter/time", 1.0, BACKSPACE_CUT_DURATION).from(0.0)
	tween.tween_property(slash, "frame", 17, 0.5).from(0)
	tween.tween_property(split_sprite, "modulate:a", 0.18, 0.72).set_delay(0.28)
	await tween.finished
	if generation != _visual_effect_generation:
		mask.queue_free()
		word_viewport.queue_free()
		split_sprite.queue_free()
		slash.queue_free()
		return

	split_sprite.modulate.a = 0.0
	await get_tree().create_timer(0.08).timeout
	split_sprite.modulate.a = 0.26
	await get_tree().create_timer(0.08).timeout
	split_sprite.modulate.a = 0.48
	await get_tree().create_timer(0.06).timeout
	split_sprite.modulate.a = 0.16
	await get_tree().create_timer(0.08).timeout
	mask.queue_free()
	word_viewport.queue_free()
	split_sprite.queue_free()
	slash.queue_free()

func _build_backspace_word_viewport(text: String) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.name = "BackspaceWordViewport"
	viewport.size = Vector2i(world.cell_size, world.cell_size)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var rendered_label := _make_word_label(text, Color.WHITE)
	rendered_label.position = Vector2.ZERO
	rendered_label.size = Vector2(world.cell_size, world.cell_size)
	viewport.add_child(rendered_label)
	return viewport

func _visual_requests_include_key_info(visual_requests: Array) -> bool:
	if key_info_emphasis_played:
		return false
	for request_value in visual_requests:
		var request: Dictionary = request_value
		var effect_type := str(request.get("type", ""))
		if effect_type == KEY_INFO_EMPHASIS:
			return true
		if _is_key_info_driver(request):
			return true
	return false

func _is_key_info_driver(request: Dictionary) -> bool:
	if str(request.get("type", "")) != "bridge_tree_transition":
		return false
	if str(request.get("mode", "")) != "merge" or key_info_emphasis_played:
		return false
	var before_effect: Dictionary = request.get("before_effect", {})
	return not before_effect.is_empty()

func _count_pre_key_visual_effects(visual_requests: Array) -> int:
	var count := 0
	for request_value in visual_requests:
		var request: Dictionary = request_value
		var effect_type := str(request.get("type", ""))
		if effect_type == "word_merge_flash" or effect_type == "bridge_word_merge_flash" or effect_type == "word_split_transition":
			count += 1
	return count

func _count_pre_merge_push_effects(visual_requests: Array, merge_split_count: int) -> int:
	if merge_split_count <= 0:
		return 0
	var count := 0
	for request_value in visual_requests:
		var request: Dictionary = request_value
		if str(request.get("type", "")) == "player_push_flash":
			count += 1
	return count

func _run_pre_merge_push_effect(request: Dictionary, generation: int) -> void:
	if generation == _visual_effect_generation:
		await _play_player_push_flash(request)
	pre_merge_push_effects_active = maxi(pre_merge_push_effects_active - 1, 0)

func _run_pre_key_visual_effect(request: Dictionary, context: Dictionary, generation: int) -> void:
	var effect_type := str(request.get("type", ""))
	while pre_merge_push_effects_active > 0 and generation == _visual_effect_generation:
		await get_tree().process_frame
	if generation == _visual_effect_generation:
		if effect_type == "word_merge_flash" or effect_type == "bridge_word_merge_flash":
			await _run_word_merge_flash(request, generation)
		elif effect_type == "word_split_transition":
			await _run_word_split_transition(request, context, generation)
	pre_key_visual_effects_active = maxi(pre_key_visual_effects_active - 1, 0)
	if pre_key_visual_effects_active == 0 and not visual_sequence_has_key_info:
		key_info_sequence_pending = false

func _run_key_info_after_pre_effects(request: Dictionary, generation: int) -> void:
	while pre_key_visual_effects_active > 0 and generation == _visual_effect_generation:
		await get_tree().process_frame
	if generation != _visual_effect_generation:
		key_info_sequence_pending = false
		visual_sequence_has_key_info = false
		return
	key_info_emphasis_played = true
	key_info_effect_active = true
	await _run_key_info_emphasis(request, generation)
	key_info_sequence_pending = false
	visual_sequence_has_key_info = false

func _run_bridge_tree_transition_after_pre_effects(request: Dictionary, context: Dictionary, generation: int) -> void:
	while pre_key_visual_effects_active > 0 and generation == _visual_effect_generation:
		await get_tree().process_frame
	if generation != _visual_effect_generation:
		key_info_sequence_pending = false
		visual_sequence_has_key_info = false
		return
	_run_bridge_tree_transition(request, context, generation)

func _run_visual_effect_after_key_info(request: Dictionary, context: Dictionary, generation: int) -> void:
	while key_info_sequence_pending or key_info_effect_active:
		if generation != _visual_effect_generation:
			return
		await get_tree().process_frame
	if generation != _visual_effect_generation:
		return
	var effect_type := str(request.get("type", ""))
	if effect_type == "gem_burst":
		if gem_burst_effect == null:
			return
		var origin_grid: Vector2 = request.get("origin_grid", GEM_ORIGIN_GRID)
		gem_burst_effect.play_at(
			_grid_to_pixels_float(origin_grid),
			world.cell_size,
			float(request.get("duration", 0.78)),
			int(request.get("seed", 1947))
		)
	elif effect_type == "pull_particles":
		if pull_particle_effect == null:
			return
		var origin_grid: Vector2 = request.get("origin_grid", Vector2.ZERO)
		pull_particle_effect.play_at(
			_grid_to_pixels_float(origin_grid),
			float(world.cell_size),
			float(request.get("duration", 0.42)),
			int(request.get("seed", 2371))
		)
	elif effect_type == "player_river_enter":
		_play_player_river_enter(request)
	elif effect_type == "player_river_exit":
		_play_player_river_exit(request)
	elif effect_type == "player_push_flash":
		_play_player_push_flash(request)
	elif effect_type == "backspace_cut":
		call_deferred("_run_backspace_cut_effect", request.duplicate(true), generation)
	elif effect_type == "word_merge_flash" or effect_type == "bridge_word_merge_flash":
		call_deferred("_run_word_merge_flash", request.duplicate(true), generation)
	elif effect_type == "bridge_tree_transition":
		call_deferred("_run_bridge_tree_transition", request.duplicate(true), context, generation)
	elif effect_type == "bridge_tree_relocate":
		call_deferred("_run_bridge_tree_relocate", request.duplicate(true), generation)
	elif effect_type == "bridge_collapse_sequence":
		call_deferred("_run_bridge_collapse_sequence", request.duplicate(true), generation)
	elif effect_type == "word_split_transition":
		call_deferred("_run_word_split_transition", request.duplicate(true), context, generation)

func _prepare_visual_effect_contexts(visual_requests: Array) -> Array:
	var contexts: Array = []
	for request in visual_requests:
		var request_dict: Dictionary = request
		var effect_type := str(request_dict.get("type", ""))
		if effect_type != "bridge_tree_transition":
			if effect_type == "word_split_transition":
				contexts.append({
					"part_specs": _capture_visual_specs_for_cells(request_dict.get("part_cells", [])),
					"part_groups": _find_groups_for_cells(request_dict.get("part_cells", []))
				})
			else:
				contexts.append({})
			continue
		var context := {
			"tree_overlays": [],
			"bridge_overlays": []
		}
		var mode := str(request_dict.get("mode", ""))
		if mode == "merge":
			context["tree_overlays"] = _duplicate_groups_for_cells(request_dict.get("tree_cells", []))
		elif mode == "split":
			context["bridge_visual_specs"] = _capture_visual_specs_for_cells(request_dict.get("bridge_cells", []))
			context["reveal_cells"] = _capture_new_entity_cells(
				request_dict.get("reveal_texts", []),
				request_dict.get("delayed_water_cells", request_dict.get("bridge_cells", []))
			)
		contexts.append(context)
	return contexts

func _capture_new_entity_cells(texts: Array, delayed_water_cells: Array) -> Array:
	var cells: Array = []
	var seen_cells: Dictionary = {}
	for entity: WordEntity in world.entities.values():
		if entity_labels.has(entity.id) or not texts.has(entity.text):
			continue
		for cell in entity.cells:
			if entity.text == "溪" and not delayed_water_cells.has(cell):
				continue
			if seen_cells.has(cell):
				continue
			seen_cells[cell] = true
			cells.append(cell)
	return cells

func _capture_visual_specs_for_cells(cells: Array) -> Array:
	var specs: Array = []
	var seen_cells: Dictionary = {}
	for cell_value in cells:
		var cell: Vector2i = cell_value
		if seen_cells.has(cell):
			continue
		seen_cells[cell] = true
		var spec := {
			"position": _grid_to_pixels(cell),
			"rotation_degrees": 0.0,
			"text": "桥",
			"color": Color.WHITE
		}
		var group: Node2D = _find_group_for_cell(cell)
		if group == null:
			specs.append(spec)
			continue
		var entity: WordEntity = null
		for candidate: WordEntity in world.entities.values():
			if candidate.cells.has(cell) and entity_labels.has(candidate.id):
				entity = candidate
				break
		if entity == null:
			specs.append(spec)
			continue
		var cell_index: int = entity.cells.find(cell)
		var character: String = entity.text.substr(cell_index, 1) if cell_index >= 0 else entity.text
		spec["rotation_degrees"] = entity.visual_rotation_degrees
		spec["text"] = character
		spec["color"] = entity.visual_color
		specs.append(spec)
	return specs

func _build_visual_overlays(specs: Array) -> Array:
	var overlays: Array = []
	for spec_value in specs:
		var spec: Dictionary = spec_value
		var overlay := Node2D.new()
		overlay.position = spec.get("position", Vector2.ZERO)
		overlay.rotation_degrees = float(spec.get("rotation_degrees", 0.0))
		overlay.z_index = 40
		var visual_color: Color = spec.get("color", Color.WHITE)
		var label: Label = _make_word_label(str(spec.get("text", "桥")), visual_color)
		label.position = Vector2(0, -2)
		overlay.add_child(label)
		overlays.append(overlay)
	return overlays

func _duplicate_groups_for_cells(cells: Array) -> Array:
	var overlays: Array = []
	var seen_ids := {}
	for cell in cells:
		var group: Node2D = _find_group_for_cell(cell)
		if group == null:
			continue
		var instance_id: int = group.get_instance_id()
		if seen_ids.has(instance_id):
			continue
		seen_ids[instance_id] = true
		var overlay: Node2D = group.duplicate()
		overlay.z_index = 40
		overlays.append(overlay)
	return overlays

func _find_group_for_cell(cell: Vector2i) -> Node2D:
	for entity: WordEntity in world.entities.values():
		if not entity_labels.has(entity.id):
			continue
		if entity.cells.has(cell):
			return entity_labels[entity.id] as Node2D
	return null

func _find_groups_for_cells(cells: Array) -> Array:
	var groups: Array = []
	var seen_ids := {}
	for cell in cells:
		var group: Node2D = _find_group_for_cell(cell)
		if group == null:
			continue
		var instance_id: int = group.get_instance_id()
		if seen_ids.has(instance_id):
			continue
		seen_ids[instance_id] = true
		groups.append(group)
	return groups

func _find_groups_for_text_cells(cells: Array, text: String) -> Array:
	var groups: Array = []
	var seen_ids: Dictionary = {}
	for entity: WordEntity in world.entities.values():
		if entity.text != text or not entity_labels.has(entity.id):
			continue
		var matches_cell := false
		for cell in entity.cells:
			if cells.has(cell):
				matches_cell = true
				break
		if not matches_cell:
			continue
		var group: Node2D = entity_labels[entity.id]
		var instance_id: int = group.get_instance_id()
		if seen_ids.has(instance_id):
			continue
		seen_ids[instance_id] = true
		groups.append(group)
	return groups

func _run_bridge_tree_transition(request: Dictionary, context: Dictionary, generation: int) -> void:
	if generation != _visual_effect_generation or bridge_tree_effect_layer == null:
		return
	var mode := str(request.get("mode", ""))
	var tree_fade_duration := float(request.get("tree_fade_duration", 0.42))
	var creek_fade_duration := float(request.get("creek_fade_duration", 0.5))
	var tree_fade_in_duration := float(request.get("tree_fade_in_duration", 0.3))
	var bridge_step_delay := float(request.get("bridge_step_delay", 0.055))
	var bridge_fade_duration := float(request.get("bridge_fade_duration", 0.12))
	if mode == "merge":
		var merge_overlays: Array = context.get("tree_overlays", [])
		for overlay: Node2D in merge_overlays:
			if bridge_tree_effect_layer:
				bridge_tree_effect_layer.add_child(overlay)
				overlay.modulate.a = 1.0
		var before_effect: Dictionary = request.get("before_effect", {})
		if not before_effect.is_empty() and not key_info_emphasis_played:
			key_info_emphasis_played = true
			key_info_effect_active = true
			await _run_key_info_emphasis(before_effect, generation)
			key_info_sequence_pending = false
			if generation != _visual_effect_generation:
				_clear_effect_overlays(merge_overlays)
				return
		_prepare_deferred_bridge_merge_entities(request, generation)
		await _run_bridge_tree_merge_transition(request, context, generation, tree_fade_duration, creek_fade_duration, bridge_step_delay, bridge_fade_duration)
	elif mode == "split":
		await _run_bridge_tree_split_transition(request, context, generation, tree_fade_in_duration, bridge_step_delay, bridge_fade_duration)

func _prepare_deferred_bridge_merge_entities(request: Dictionary, generation: int) -> void:
	if generation != _visual_effect_generation:
		return
	var deferred_tree_remove_at: Array = request.get("deferred_tree_remove_at", [])
	if deferred_tree_remove_at.is_empty():
		return
	world.remove_entities_at(deferred_tree_remove_at)
	_refresh_view()

func _run_bridge_tree_merge_transition(request: Dictionary, context: Dictionary, generation: int, tree_fade_duration: float, creek_fade_duration: float, bridge_step_delay: float, bridge_fade_duration: float) -> void:
	var overlays: Array = context.get("tree_overlays", [])
	var tree_tween: Tween = null
	if not overlays.is_empty():
		tree_tween = create_tween()
		tree_tween.set_parallel(true)
		for overlay: Node2D in overlays:
			overlay.modulate.a = 1.0
			tree_tween.tween_property(overlay, "modulate:a", 0.0, tree_fade_duration)
	if tree_tween != null:
		await tree_tween.finished
	_clear_effect_overlays(overlays)
	var deferred_remove_at: Array = request.get("deferred_remove_at", [])
	var deferred_spawn: Array = request.get("deferred_spawn", [])
	var creek_fade_cells: Array = request.get("creek_fade_cells", deferred_remove_at)
	var creek_groups: Array = _find_groups_for_text_cells(creek_fade_cells, "溪")
	if not creek_groups.is_empty():
		var creek_tween := create_tween()
		creek_tween.set_parallel(true)
		for group: Node2D in creek_groups:
			creek_tween.tween_property(group, "modulate:a", 0.0, creek_fade_duration)
		await creek_tween.finished
		if generation != _visual_effect_generation:
			return
	world.remove_entities_at(deferred_remove_at)
	world.spawn_entities(deferred_spawn)
	_refresh_view()
	var bridge_groups: Array = _find_groups_for_cells(request.get("bridge_cells", []))
	_set_groups_alpha(bridge_groups, 0.0)
	var bridge_columns: Dictionary = _group_effect_targets_by_x(bridge_groups, not bool(request.get("reverse_split", false)))
	for x in bridge_columns.keys():
		if generation != _visual_effect_generation:
			return
		_tween_groups_alpha(bridge_columns[x], 1.0, bridge_fade_duration)
		await get_tree().create_timer(bridge_step_delay).timeout

func _run_key_info_emphasis(request: Dictionary, generation: int) -> void:
	if generation != _visual_effect_generation or bridge_tree_effect_layer == null:
		key_info_effect_active = false
		return
	var cells: Array = request.get("cells", [])
	if cells.is_empty():
		key_info_effect_active = false
		return
	var first_cell: Vector2i = cells[0]
	var cell_count: int = maxi(cells.size(), 1)
	var overlay := Node2D.new()
	overlay.name = "KeyInfoEmphasis"
	overlay.position = _grid_to_pixels(first_cell)
	overlay.z_index = 90
	var cell_width := float(world.cell_size)
	var box_width := cell_width * float(cell_count) + 8.0
	var box_height := float(world.cell_size) + 8.0
	var fill := ColorRect.new()
	fill.name = "KeyInfoFill"
	fill.position = Vector2(-4.0, -4.0)
	fill.size = Vector2(box_width, box_height)
	fill.color = Color(1.0, 1.0, 1.0, 0.14)
	overlay.add_child(fill)
	_add_key_info_strip(overlay, Vector2(-4.0, -4.0), Vector2(box_width, 2.0), "KeyInfoTop")
	_add_key_info_strip(overlay, Vector2(-4.0, box_height - 2.0), Vector2(box_width, 2.0), "KeyInfoBottom")
	_add_key_info_strip(overlay, Vector2(-4.0, -4.0), Vector2(2.0, box_height), "KeyInfoLeft")
	_add_key_info_strip(overlay, Vector2(box_width - 2.0, -4.0), Vector2(2.0, box_height), "KeyInfoRight")
	_add_key_info_strip(overlay, Vector2(-2.0, float(world.cell_size) + 5.0), Vector2(cell_width * float(cell_count) + 4.0, 3.0), "KeyInfoUnderline")
	bridge_tree_effect_layer.add_child(overlay)
	overlay.modulate.a = 0.0
	var fade_in_duration := float(request.get("fade_in_duration", 0.24))
	var display_duration := float(request.get("duration", 1.0))
	var intro_tween := create_tween()
	intro_tween.tween_property(overlay, "modulate:a", 1.0, fade_in_duration)
	intro_tween.tween_interval(display_duration)
	intro_tween.tween_property(overlay, "modulate:a", 0.0, 0.12)
	await intro_tween.finished
	if generation != _visual_effect_generation or not is_instance_valid(overlay):
		key_info_effect_active = false
		return
	_clear_effect_overlays([overlay])
	key_info_effect_active = false

func _run_bridge_tree_relocate(request: Dictionary, generation: int) -> void:
	if generation != _visual_effect_generation:
		return
	var source_cells: Array = request.get("source_cells", [])
	var target_cells: Array = request.get("target_cells", [])
	var fade_out_duration := float(request.get("fade_out_duration", 0.55))
	var fade_in_duration := float(request.get("fade_in_duration", 0.4))
	var source_groups: Array = _find_groups_for_cells(source_cells)
	if not source_groups.is_empty():
		var fade_out := create_tween()
		fade_out.set_parallel(true)
		for group in source_groups:
			fade_out.tween_property(group, "modulate:a", 0.0, fade_out_duration)
		await fade_out.finished
		if generation != _visual_effect_generation:
			return
	world.remove_entities_at(request.get("deferred_remove_at", []))
	world.spawn_entities(request.get("deferred_spawn", []))
	_refresh_view()
	var target_groups: Array = _find_groups_for_cells(target_cells)
	_set_groups_alpha(target_groups, 0.0)
	if target_groups.is_empty():
		return
	var fade_in := create_tween()
	fade_in.set_parallel(true)
	for group in target_groups:
		fade_in.tween_property(group, "modulate:a", 1.0, fade_in_duration)
	await fade_in.finished

func _add_key_info_strip(parent: Node2D, position: Vector2, size: Vector2, strip_name: String) -> void:
	var strip := ColorRect.new()
	strip.name = strip_name
	strip.position = position
	strip.size = size
	strip.color = Color(1.0, 1.0, 1.0, 0.78)
	parent.add_child(strip)

func _run_bridge_tree_split_transition(request: Dictionary, context: Dictionary, generation: int, tree_fade_in_duration: float, bridge_step_delay: float, bridge_fade_duration: float) -> void:
	_clear_key_info_emphasis()
	var overlays: Array = _build_visual_overlays(context.get("bridge_visual_specs", []))
	for overlay: Node2D in overlays:
		if bridge_tree_effect_layer:
			bridge_tree_effect_layer.add_child(overlay)
	_prepare_deferred_bridge_split_entities(request, context, generation)
	var reveal_groups: Array = _find_groups_for_cells(context.get("reveal_cells", []))
	_set_groups_alpha(reveal_groups, 0.0)
	var bridge_columns: Dictionary = _group_effect_targets_by_x(overlays, true)
	for x in bridge_columns.keys():
		if generation != _visual_effect_generation:
			_clear_effect_overlays(overlays)
			return
		_tween_groups_alpha(bridge_columns[x], 0.0, bridge_fade_duration)
		await get_tree().create_timer(bridge_step_delay).timeout
	_clear_effect_overlays(overlays)
	await get_tree().process_frame
	var reveal_tween := create_tween()
	reveal_tween.set_parallel(true)
	for group in reveal_groups:
		reveal_tween.tween_property(group, "modulate:a", 1.0, tree_fade_in_duration)
	await reveal_tween.finished

func _prepare_deferred_bridge_split_entities(request: Dictionary, context: Dictionary, generation: int) -> void:
	if generation != _visual_effect_generation:
		return
	var deferred_remove_at: Array = request.get("deferred_split_remove_at", [])
	var deferred_spawn: Array = request.get("deferred_split_spawn", [])
	if deferred_remove_at.is_empty() and deferred_spawn.is_empty():
		return
	world.remove_entities_at(deferred_remove_at)
	world.spawn_entities(deferred_spawn)
	_refresh_view()
	var reveal_cells: Array = context.get("reveal_cells", []).duplicate()
	var reveal_target_cells: Array = request.get("tree_cells", []).duplicate()
	for cell_value in request.get("delayed_water_cells", request.get("bridge_cells", [])):
		if not reveal_target_cells.has(cell_value):
			reveal_target_cells.append(cell_value)
	var reveal_texts: Array = request.get("reveal_texts", [])
	for entry_value in deferred_spawn:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		var text := str(entry.get("text", ""))
		if not entry.has("pos") or not reveal_texts.has(text):
			continue
		var pos: Vector2i = entry.pos
		for i in range(text.length()):
			var cell := pos + Vector2i(i, 0)
			if reveal_target_cells.has(cell) and not reveal_cells.has(cell):
				reveal_cells.append(cell)
	context["reveal_cells"] = reveal_cells

func _clear_key_info_emphasis() -> void:
	if bridge_tree_effect_layer == null:
		return
	for child in bridge_tree_effect_layer.get_children():
		if child.name == "KeyInfoEmphasis":
			child.queue_free()

func _run_bridge_collapse_sequence(request: Dictionary, generation: int) -> void:
	if generation != _visual_effect_generation or bridge_tree_effect_layer == null:
		return
	player_river_action_locked = true
	world.set_input_locked(true)
	world.set_event_locked(true)
	var fall_cells: Array = request.get("fall_bridge_cells", [])
	var bridge_groups: Array = _find_groups_for_cells(fall_cells)
	var backdrop_masks: Array = _build_bridge_collapse_backdrop_masks(fall_cells)
	for mask: ColorRect in backdrop_masks:
		bridge_tree_effect_layer.add_child(mask)
	var bridge_overlays: Array = _duplicate_groups_for_cells(fall_cells)
	for overlay: Node2D in bridge_overlays:
		overlay.z_index = 420
		bridge_tree_effect_layer.add_child(overlay)
	_set_groups_alpha(bridge_groups, 0.0)
	var player_overlay := _build_player_fall_overlay()
	if player_overlay != null:
		bridge_tree_effect_layer.add_child(player_overlay)
	if player_label:
		player_label.visible = false

	var base_positions: Array = []
	for overlay: Node2D in bridge_overlays:
		base_positions.append(overlay.position)
	var shake_tween := create_tween()
	shake_tween.tween_method(
		Callable(self, "_set_bridge_collapse_overlay_offsets").bind(bridge_overlays, base_positions),
		0.0,
		1.0,
		BRIDGE_COLLAPSE_SHAKE_DURATION
	)
	await shake_tween.finished
	if generation != _visual_effect_generation:
		_clear_effect_overlays(bridge_overlays)
		_clear_effect_overlays(backdrop_masks)
		if player_overlay:
			player_overlay.queue_free()
		_set_groups_alpha(bridge_groups, 1.0)
		player_river_action_locked = false
		return

	var fall_tween := create_tween()
	fall_tween.set_parallel(true)
	for i in range(bridge_overlays.size()):
		var overlay := bridge_overlays[i] as Node2D
		if overlay == null:
			continue
		var base_position: Vector2 = base_positions[i]
		fall_tween.tween_property(overlay, "position:y", base_position.y + BRIDGE_COLLAPSE_FALL_DISTANCE, 0.58).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fall_tween.tween_property(overlay, "rotation_degrees", overlay.rotation_degrees + float((i % 3) - 1) * 8.0, 0.58)
	await fall_tween.finished
	for overlay: Node2D in bridge_overlays:
		_add_half_black_mask(overlay)
	await get_tree().create_timer(0.18).timeout

	if player_overlay != null and is_instance_valid(player_overlay):
		var player_fall_tween := create_tween()
		player_fall_tween.set_parallel(true)
		player_fall_tween.tween_property(player_overlay, "position:y", player_overlay.position.y + BRIDGE_COLLAPSE_PLAYER_FALL_DISTANCE, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		player_fall_tween.tween_property(player_overlay, "rotation_degrees", -12.0, 0.5)
		await player_fall_tween.finished
		_clip_player_overlay_to_waterline(player_overlay)
	await get_tree().create_timer(0.12).timeout

	var fade_targets: Array = []
	fade_targets.append_array(bridge_overlays)
	if player_overlay != null:
		fade_targets.append(player_overlay)
	await _tween_canvas_items_alpha(fade_targets, 0.0, 0.45)

	var final_effect: Dictionary = request.get("final_effect", {})
	if not final_effect.is_empty():
		world.apply_preview_effect(final_effect)
		world.update_page()
		_refresh_view()
		var reveal_cells: Array = fall_cells.duplicate()
		var player_cell: Vector2i = request.get("player_cell", world.player_pos)
		if not reveal_cells.has(player_cell):
			reveal_cells.append(player_cell)
		var reveal_groups: Array = _find_groups_for_cells(reveal_cells)
		_set_groups_alpha(reveal_groups, 0.0)
		await _crossfade_canvas_items(backdrop_masks, reveal_groups, 0.7)

	_clear_effect_overlays(bridge_overlays)
	_clear_effect_overlays(backdrop_masks)
	if player_overlay != null and is_instance_valid(player_overlay):
		player_overlay.queue_free()
	player_river_action_locked = false

func _build_bridge_collapse_backdrop_masks(cells: Array) -> Array:
	var masks: Array = []
	for cell_value in cells:
		var cell: Vector2i = cell_value
		var mask := ColorRect.new()
		mask.name = "BridgeCollapseBackdropMask"
		mask.color = Color.BLACK
		mask.position = _grid_to_pixels(cell) - Vector2(BRIDGE_COLLAPSE_MASK_PADDING, BRIDGE_COLLAPSE_MASK_PADDING)
		mask.size = Vector2(
			float(world.cell_size) + BRIDGE_COLLAPSE_MASK_PADDING * 2.0,
			BRIDGE_COLLAPSE_FALL_DISTANCE + float(world.cell_size) + BRIDGE_COLLAPSE_MASK_PADDING * 2.0
		)
		mask.z_index = 400
		masks.append(mask)
	return masks

func _build_player_fall_overlay() -> Node2D:
	if player_label == null:
		return null
	var overlay := Node2D.new()
	overlay.name = "BridgeCollapsePlayerOverlay"
	overlay.position = player_label.position
	overlay.z_index = 700
	var clipper := Control.new()
	clipper.name = "PlayerClipper"
	clipper.size = Vector2(float(world.cell_size), float(world.cell_size))
	clipper.clip_contents = false
	var visual := player_label.duplicate() as Control
	if visual == null:
		return overlay
	visual.position = Vector2.ZERO
	visual.visible = true
	clipper.add_child(visual)
	overlay.add_child(clipper)
	return overlay

func _clip_player_overlay_to_waterline(player_overlay: Node2D) -> void:
	if player_overlay == null or not is_instance_valid(player_overlay):
		return
	var clipper := player_overlay.get_node_or_null("PlayerClipper") as Control
	if clipper == null:
		return
	clipper.clip_contents = true
	clipper.size = Vector2(float(world.cell_size), float(world.cell_size) * 0.5)

func _set_bridge_collapse_overlay_offsets(progress: float, overlays: Array, base_positions: Array) -> void:
	for i in range(overlays.size()):
		var overlay := overlays[i] as Node2D
		if overlay == null or not is_instance_valid(overlay):
			continue
		var base_position: Vector2 = base_positions[i]
		var phase := progress * TAU * BRIDGE_COLLAPSE_SHAKE_CYCLES + float(i) * 0.8
		overlay.position = base_position + Vector2(sin(phase) * BRIDGE_COLLAPSE_SHAKE_AMPLITUDE, 0.0)

func _add_half_black_mask(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
	var mask := ColorRect.new()
	mask.name = "HalfSubmergeMask"
	mask.color = Color.BLACK
	mask.position = Vector2(0.0, float(world.cell_size) * 0.5)
	mask.size = Vector2(float(world.cell_size), float(world.cell_size) * 0.55)
	mask.z_index = 100
	target.add_child(mask)

func _crossfade_canvas_items(fade_out_targets: Array, fade_in_targets: Array, duration: float) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	var has_tween := false
	for target in fade_out_targets:
		if target == null or not is_instance_valid(target):
			continue
		var canvas_item := target as CanvasItem
		if canvas_item == null:
			continue
		tween.tween_property(canvas_item, "modulate:a", 0.0, duration)
		has_tween = true
	for target in fade_in_targets:
		if target == null or not is_instance_valid(target):
			continue
		var canvas_item := target as CanvasItem
		if canvas_item == null:
			continue
		tween.tween_property(canvas_item, "modulate:a", 1.0, duration)
		has_tween = true
	if not has_tween:
		tween.kill()
		return
	await tween.finished

func _tween_canvas_items_alpha(targets: Array, alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	var has_tween := false
	for target in targets:
		if target == null or not is_instance_valid(target):
			continue
		var canvas_item := target as CanvasItem
		if canvas_item == null:
			continue
		tween.tween_property(canvas_item, "modulate:a", alpha, duration)
		has_tween = true
	if not has_tween:
		tween.kill()
		return
	await tween.finished

func _run_word_split_transition(request: Dictionary, context: Dictionary, generation: int) -> void:
	if generation != _visual_effect_generation or bridge_tree_effect_layer == null:
		return
	var part_specs: Array = context.get("part_specs", [])
	var part_groups: Array = context.get("part_groups", [])
	var part_cells: Array = request.get("part_cells", [])
	var part_texts: Array = request.get("part_texts", [])
	if part_specs.size() < 2 or part_cells.size() < 2:
		return
	var source_cell: Vector2i = request.get("source_cell", Vector2i.ZERO)
	var source_position := _grid_to_pixels(source_cell)
	var move_duration := float(request.get("move_duration", 0.5))
	var settle_duration := float(request.get("settle_duration", 0.18))
	var jump_height := float(request.get("jump_height", 30.0))
	var square_alpha := float(request.get("square_alpha", 0.5))
	var square_color: Color = request.get("square_color", Color(0.96, 0.92, 0.62, 1.0))
	var part_jump_heights: Array = request.get("part_jump_heights", [jump_height, 0.0])
	var part_delays: Array = request.get("part_delays", [0.0, 0.0])
	var source_fade_duration := float(request.get("source_fade_duration", 0.08))
	var part_fade_in_duration := float(request.get("part_fade_in_duration", 0.06))
	var particle_duration := float(request.get("particle_duration", 0.4))
	var particle_frame_count := int(request.get("particle_frame_count", 15))
	var particle_color: Color = request.get("particle_color", Color.WHITE)
	var source_overlay := _build_split_source_overlay(str(request.get("source_text", "")), source_position, square_color, square_alpha)
	var part_overlays := _build_split_part_overlays(part_specs, part_texts, source_position)
	var particle := _build_split_particle_overlay(source_position)
	if particle:
		particle.modulate = particle_color
	if source_overlay:
		bridge_tree_effect_layer.add_child(source_overlay)
	for overlay: Node2D in part_overlays:
		bridge_tree_effect_layer.add_child(overlay)
	if particle:
		bridge_tree_effect_layer.add_child(particle)
	_set_groups_alpha(part_groups, 0.0)
	var tween := create_tween()
	tween.set_parallel(true)
	if source_overlay:
		tween.tween_property(source_overlay, "modulate:a", 0.0, source_fade_duration).set_delay(part_fade_in_duration)
	for overlay: Node2D in part_overlays:
		tween.tween_property(overlay, "modulate:a", 1.0, part_fade_in_duration)
	for i in range(part_overlays.size()):
		var overlay: Node2D = part_overlays[i]
		if i >= part_cells.size():
			continue
		var target_position := _grid_to_pixels(part_cells[i])
		var part_jump_height := 0.0
		if i < part_jump_heights.size():
			part_jump_height = float(part_jump_heights[i])
		var part_delay := 0.0
		if i < part_delays.size():
			part_delay = float(part_delays[i])
		tween.tween_method(
			Callable(self, "_set_word_split_overlay_progress").bind(overlay, source_position, target_position, part_jump_height),
			0.0,
			1.0,
			move_duration
		).set_delay(part_delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if particle:
		tween.tween_property(particle, "modulate:a", 0.0, particle_duration)
		tween.tween_property(particle, "frame", maxi(0, particle_frame_count - 1), particle_duration).from(0)
	await tween.finished
	if generation != _visual_effect_generation:
		_clear_split_transition_nodes(source_overlay, part_overlays, particle)
		return
	var settle_tween := create_tween()
	settle_tween.set_parallel(true)
	if source_overlay:
		settle_tween.tween_property(source_overlay, "modulate:a", 0.0, settle_duration)
	for overlay: Node2D in part_overlays:
		settle_tween.tween_property(overlay, "modulate:a", 0.0, settle_duration)
	for group in part_groups:
		if group == null or not is_instance_valid(group):
			continue
		var canvas_item := group as CanvasItem
		if canvas_item == null:
			continue
		settle_tween.tween_property(canvas_item, "modulate:a", 1.0, settle_duration)
	await settle_tween.finished
	_clear_split_transition_nodes(source_overlay, part_overlays, particle)

func _build_split_source_overlay(source_text: String, source_position: Vector2, square_color: Color, square_alpha: float) -> Node2D:
	if source_text.is_empty():
		return null
	var overlay := Node2D.new()
	overlay.position = source_position
	overlay.z_index = 40
	var square := Sprite2D.new()
	square.texture = SplitBaseTexture
	square.position = Vector2(world.cell_size, world.cell_size) * 0.5
	square.modulate = Color(square_color.r, square_color.g, square_color.b, square_alpha)
	overlay.add_child(square)
	var label := _make_word_label(source_text)
	label.position = Vector2(0, -2)
	overlay.add_child(label)
	return overlay

func _build_split_part_overlays(part_specs: Array, part_texts: Array, source_position: Vector2) -> Array:
	var overlays: Array = []
	for index in range(part_specs.size()):
		var spec_value = part_specs[index]
		var spec: Dictionary = spec_value
		var overlay := Node2D.new()
		overlay.position = source_position
		overlay.z_index = 41
		overlay.modulate.a = 0.0
		var part_text := str(part_texts[index]) if index < part_texts.size() else str(spec.get("text", ""))
		var label := _make_word_label(part_text, spec.get("color", Color.WHITE))
		label.position = Vector2(0, -2)
		overlay.add_child(label)
		overlays.append(overlay)
	return overlays

func _build_split_particle_overlay(source_position: Vector2) -> Sprite2D:
	var particle := Sprite2D.new()
	particle.texture = SplitParticleTexture
	particle.hframes = 5
	particle.vframes = 3
	particle.frame = 0
	particle.position = source_position + Vector2(world.cell_size, world.cell_size) * 0.5
	particle.z_index = 42
	return particle

func _set_word_split_overlay_progress(progress: float, overlay: Node2D, start: Vector2, finish: Vector2, jump_height: float) -> void:
	if overlay == null or not is_instance_valid(overlay):
		return
	var position := start.lerp(finish, progress)
	position.y -= sin(progress * PI) * jump_height
	overlay.position = position

func _clear_split_transition_nodes(source_overlay: Node2D, part_overlays: Array, particle: Sprite2D) -> void:
	if source_overlay != null and is_instance_valid(source_overlay):
		source_overlay.queue_free()
	_clear_effect_overlays(part_overlays)
	if particle != null and is_instance_valid(particle):
		particle.queue_free()

func _play_player_river_enter(request: Dictionary) -> void:
	var submerge_offset := float(request.get("submerge_offset", world.cell_size * 0.5))
	var jump_height := float(request.get("jump_height", world.cell_size * 0.5))
	var duration := float(request.get("enter_duration", 0.5))
	var hold_time := minf(duration * 0.4, 0.2)
	var sink_time := maxf(duration - hold_time, 0.05)
	_start_player_river_tween()
	player_river_tween.tween_method(_set_player_river_visual_offset, player_river_visual_offset, -jump_height, hold_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	player_river_tween.tween_method(_set_player_river_visual_offset, -jump_height, submerge_offset, sink_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _play_player_river_exit(request: Dictionary) -> void:
	var submerge_offset := float(request.get("submerge_offset", world.cell_size * 0.5))
	var jump_height := float(request.get("jump_height", world.cell_size * 0.5))
	var duration := float(request.get("exit_duration", 0.3))
	var rise_time := maxf(duration * 0.45, 0.05)
	var hop_time := maxf(duration * 0.25, 0.05)
	var land_time := maxf(duration - rise_time - hop_time, 0.05)
	if player_river_visual_offset < submerge_offset:
		_set_player_river_visual_offset(submerge_offset)
	_start_player_river_tween()
	player_river_tween.tween_method(_set_player_river_visual_offset, player_river_visual_offset, 0.0, rise_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	player_river_tween.tween_method(_set_player_river_visual_offset, 0.0, -jump_height, hop_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	player_river_tween.tween_method(_set_player_river_visual_offset, -jump_height, 0.0, land_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _play_player_push_flash(request: Dictionary) -> void:
	if bridge_tree_effect_layer == null:
		return
	var direction: Vector2i = request.get("direction", Vector2i.ZERO)
	if direction == Vector2i.ZERO:
		return
	var player_to: Vector2i = request.get("player_to", world.player_pos)
	var sprite := Sprite2D.new()
	sprite.name = "PlayerPushFlash"
	sprite.texture = PushEffectTexture
	sprite.hframes = 10
	sprite.vframes = 2
	sprite.frame = 0
	sprite.centered = true
	sprite.z_index = 85
	sprite.rotation_degrees = _push_flash_rotation(direction)
	bridge_tree_effect_layer.add_child(sprite)
	var base_position := _grid_to_pixels(player_to)
	_set_push_flash_progress(0.0, sprite, base_position, direction)
	var tween := create_tween()
	tween.tween_method(Callable(self, "_set_push_flash_progress").bind(sprite, base_position, direction), 0.0, 1.0, 0.5)
	tween.tween_callback(Callable(sprite, "queue_free"))
	await tween.finished

func _run_hall_door_open_source_effect(request: Dictionary, generation: int) -> void:
	if generation != _visual_effect_generation or bridge_tree_effect_layer == null:
		return
	var cell: Vector2i = request.get("cell", Vector2i.ZERO)
	var opened_groups: Array = _find_groups_for_cells([cell])
	_set_groups_alpha(opened_groups, 0.0)
	var door_instance: Node2D = HallDoorOpenScene.instantiate() as Node2D
	if door_instance == null:
		_set_groups_alpha(opened_groups, 1.0)
		return
	door_instance.name = "HallDoorOpenSource"
	door_instance.position = _grid_to_pixels(cell)
	door_instance.z_index = 640
	bridge_tree_effect_layer.add_child(door_instance)
	var animation_player: AnimationPlayer = door_instance.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player == null:
		_set_groups_alpha(opened_groups, 1.0)
		_clear_effect_overlays([door_instance])
		return
	animation_player.play("open")
	await animation_player.animation_finished
	if generation != _visual_effect_generation:
		_set_groups_alpha(opened_groups, 1.0)
		_clear_effect_overlays([door_instance])
		return
	_set_groups_alpha(opened_groups, 1.0)
	_clear_effect_overlays([door_instance])

func _run_word_merge_flash(request: Dictionary, generation: int) -> void:
	if generation != _visual_effect_generation or bridge_tree_effect_layer == null:
		return
	var merged_pos: Vector2i = request.get("merged_pos", world.player_pos)
	var merged_group: Node2D = _find_group_for_cell(merged_pos)
	if merged_group:
		merged_group.modulate.a = 0.0
	var hide_player := bool(request.get("is_player_merge", false))
	if hide_player and player_label:
		player_label.modulate.a = 0.0
	var overlay := Node2D.new()
	overlay.name = "WordMergeFlash"
	overlay.position = _grid_to_pixels(merged_pos)
	overlay.z_index = 620
	bridge_tree_effect_layer.add_child(overlay)

	var pair_info := _build_word_merge_pair(
		str(request.get("left_text", request.get("first_text", "乔"))),
		str(request.get("right_text", request.get("second_text", "木"))),
		str(request.get("pair_layout", "horizontal"))
	)
	var pair_root: Node2D = pair_info.root
	var pair_labels: Array = pair_info.labels
	var pair_layout := str(pair_info.get("layout", "horizontal"))
	overlay.add_child(pair_root)
	var pop_info := _build_word_merge_pop(str(request.get("merged_text", "桥")))
	var pop_root: Node2D = pop_info.root
	var dots: Array = pop_info.dots
	pop_root.modulate.a = 0.0
	pop_root.position = Vector2(0.0, 8.0)
	pop_root.scale = Vector2(0.72, 0.72)
	overlay.add_child(pop_root)

	var compress_tween := create_tween()
	compress_tween.set_parallel(true)
	for label_value in pair_labels:
		var label := label_value as Label
		if label == null:
			continue
		if pair_layout == "vertical":
			label.scale.y = 0.76
			compress_tween.tween_property(label, "scale:y", 0.5, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		else:
			label.scale.x = 0.76
			compress_tween.tween_property(label, "scale:x", 0.5, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	compress_tween.tween_property(pair_root, "modulate:a", 1.0, 0.08)
	await compress_tween.finished

	if generation != _visual_effect_generation:
		if hide_player and player_label:
			player_label.modulate.a = 1.0
		_clear_effect_overlays([overlay])
		return
	await get_tree().create_timer(0.08).timeout

	var pop_tween := create_tween()
	pop_tween.set_parallel(true)
	pop_tween.tween_property(pair_root, "modulate:a", 0.0, 0.22)
	pop_tween.tween_property(pop_root, "modulate:a", 1.0, 0.08)
	pop_tween.tween_property(pop_root, "position:y", -8.0, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(pop_root, "scale", Vector2(1.14, 1.14), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for dot_value in dots:
		var dot := dot_value as Node2D
		if dot == null:
			continue
		dot.modulate.a = 0.0
		dot.scale = Vector2(0.2, 0.2)
		pop_tween.tween_property(dot, "modulate:a", 1.0, 0.1)
		pop_tween.tween_property(dot, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await pop_tween.finished

	if generation != _visual_effect_generation:
		if hide_player and player_label:
			player_label.modulate.a = 1.0
		_clear_effect_overlays([overlay])
		return
	var settle_tween := create_tween()
	settle_tween.set_parallel(true)
	settle_tween.tween_property(pop_root, "position", Vector2.ZERO, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	settle_tween.tween_property(pop_root, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for dot_value in dots:
		var dot := dot_value as Node2D
		if dot == null:
			continue
		var dot_direction := (dot.position - Vector2(world.cell_size * 0.5, world.cell_size * 0.5)).normalized()
		dot_direction = Vector2.RIGHT if dot_direction == Vector2.ZERO else dot_direction
		settle_tween.tween_property(dot, "position", dot.position + dot_direction * 32.0, 0.26)
		settle_tween.tween_property(dot, "modulate:a", 0.0, 0.22)
	await settle_tween.finished

	if merged_group and is_instance_valid(merged_group):
		merged_group.modulate.a = 1.0
	if hide_player and player_label:
		player_label.modulate.a = 1.0
	_clear_effect_overlays([overlay])

func _build_word_merge_pair(first_text: String, second_text: String, pair_layout := "horizontal") -> Dictionary:
	var root := Node2D.new()
	root.name = "WordMergePair"
	root.modulate.a = 0.96
	var fill := ColorRect.new()
	fill.name = "BridgeMergeFill"
	fill.color = BRIDGE_MERGE_YELLOW_SOFT
	fill.position = Vector2(5.0, 6.0)
	fill.size = Vector2(50.0, 48.0)
	fill.z_index = 0
	root.add_child(fill)
	_add_bridge_merge_frame(root)
	var first_label: Label
	var second_label: Label
	if pair_layout == "vertical":
		first_label = _make_half_height_merge_label(first_text, 0.0)
		second_label = _make_half_height_merge_label(second_text, 30.0)
	else:
		first_label = _make_half_width_merge_label(first_text, 0.0)
		second_label = _make_half_width_merge_label(second_text, 30.0)
	root.add_child(first_label)
	root.add_child(second_label)
	return {
		"root": root,
		"labels": [first_label, second_label],
		"layout": pair_layout
	}

func _make_half_width_merge_label(text: String, x_offset: float) -> Label:
	var label := _make_word_label(text, Color(0.76, 0.76, 0.62, 0.9))
	label.name = "BridgeMergeHalfWord"
	label.position = Vector2(x_offset, -2.0)
	label.scale = Vector2(0.5, 1.0)
	label.z_index = 2
	return label

func _make_half_height_merge_label(text: String, y_offset: float) -> Label:
	var label := _make_word_label(text, Color(0.76, 0.76, 0.62, 0.9))
	label.name = "BridgeMergeHalfWord"
	label.position = Vector2(0.0, y_offset - 2.0)
	label.scale = Vector2(1.0, 0.5)
	label.z_index = 2
	return label

func _add_bridge_merge_frame(root: Node2D) -> void:
	var rect := Rect2(Vector2(4.0, 5.0), Vector2(52.0, 50.0))
	var thickness := 3.0
	_add_bridge_merge_frame_strip(root, Vector2(rect.position.x, rect.position.y), Vector2(rect.size.x, thickness))
	_add_bridge_merge_frame_strip(root, Vector2(rect.position.x, rect.position.y + rect.size.y - thickness), Vector2(rect.size.x, thickness))
	_add_bridge_merge_frame_strip(root, Vector2(rect.position.x, rect.position.y), Vector2(thickness, rect.size.y))
	_add_bridge_merge_frame_strip(root, Vector2(rect.position.x + rect.size.x - thickness, rect.position.y), Vector2(thickness, rect.size.y))

func _add_bridge_merge_frame_strip(root: Node2D, strip_position: Vector2, strip_size: Vector2) -> void:
	var strip := ColorRect.new()
	strip.name = "BridgeMergeFrame"
	strip.color = BRIDGE_MERGE_YELLOW
	strip.position = strip_position
	strip.size = strip_size
	strip.z_index = 1
	root.add_child(strip)

func _build_word_merge_pop(text: String) -> Dictionary:
	var root := Node2D.new()
	root.name = "WordMergePop"
	var merged_label := _make_word_label(text)
	merged_label.name = "WordMergePopWord"
	merged_label.pivot_offset = Vector2(world.cell_size * 0.5, world.cell_size * 0.5)
	merged_label.z_index = 4
	root.add_child(merged_label)
	var dots: Array = []
	for dot_position in [Vector2(4.0, 10.0), Vector2(56.0, 9.0), Vector2(10.0, 53.0), Vector2(62.0, 46.0)]:
		var dot := _make_bridge_merge_dot(dot_position)
		root.add_child(dot)
		dots.append(dot)
	return {
		"root": root,
		"dots": dots
	}

func _make_bridge_merge_dot(dot_position: Vector2) -> Node2D:
	var dot := Polygon2D.new()
	dot.name = "BridgeMergeYellowDot"
	var points := PackedVector2Array()
	var radius := 4.0
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	dot.polygon = points
	dot.color = Color(1.0, 0.92, 0.22, 0.82)
	dot.position = dot_position
	dot.z_index = 5
	return dot

func _push_flash_rotation(direction: Vector2i) -> float:
	if direction == Vector2i.RIGHT:
		return 0.0
	if direction == Vector2i.LEFT:
		return 180.0
	if direction == Vector2i.DOWN:
		return 90.0
	return 270.0

func _set_push_flash_progress(progress: float, sprite: Sprite2D, base_position: Vector2, direction: Vector2i) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	var frame := clampi(int(round(progress * 15.0)), 0, 15)
	sprite.frame = frame
	sprite.position = _push_flash_position_for_frame(base_position, direction, frame, progress)

func _push_flash_position_for_frame(base_position: Vector2, direction: Vector2i, frame: int, progress: float) -> Vector2:
	var local_x := float(PUSH_FLASH_FRAME_LOCAL_X[clampi(frame, 0, PUSH_FLASH_FRAME_LOCAL_X.size() - 1)])
	if direction == Vector2i.RIGHT:
		var desired_center := 40.0 + progress * 4.0
		return base_position + Vector2(desired_center - local_x, 30.0)
	if direction == Vector2i.LEFT:
		var desired_center := 20.0 - progress * 4.0
		return base_position + Vector2(desired_center + local_x, 30.0)
	if direction == Vector2i.DOWN:
		var desired_center := 40.0 + progress * 4.0
		return base_position + Vector2(30.0, desired_center - local_x)
	var desired_center := 20.0 - progress * 4.0
	return base_position + Vector2(30.0, desired_center + local_x)

func _start_player_river_tween() -> void:
	if player_river_tween and player_river_tween.is_valid():
		player_river_tween.kill()
	player_river_tween = create_tween()
	player_river_action_locked = true
	player_river_tween.finished.connect(_unlock_player_river_action)

func _unlock_player_river_action() -> void:
	player_river_action_locked = false
	player_move_repeat_timer = PLAYER_MOVE_REPEAT_TIME

func _set_player_river_visual_offset(value: float) -> void:
	player_river_visual_offset = value
	_apply_visual_positions()

func _reset_player_river_visual() -> void:
	if player_river_tween and player_river_tween.is_valid():
		player_river_tween.kill()
	player_river_tween = null
	player_river_action_locked = false
	player_river_visual_offset = 0.0

func _group_effect_targets_by_x(targets: Array, descending := false) -> Dictionary:
	var grouped := {}
	var x_values: Array[int] = []
	for target in targets:
		if target == null or not is_instance_valid(target):
			continue
		var canvas_item: CanvasItem = target as CanvasItem
		if canvas_item == null:
			continue
		var grid_x := int(round(canvas_item.position.x / float(world.cell_size)))
		if not grouped.has(grid_x):
			grouped[grid_x] = []
			x_values.append(grid_x)
		grouped[grid_x].append(canvas_item)
	x_values.sort()
	if descending:
		x_values.reverse()
	var ordered := {}
	for grid_x in x_values:
		ordered[grid_x] = grouped[grid_x]
	return ordered

func _set_groups_alpha(groups: Array, alpha: float) -> void:
	for group in groups:
		if group == null or not is_instance_valid(group):
			continue
		var canvas_item: CanvasItem = group as CanvasItem
		if canvas_item == null:
			continue
		canvas_item.modulate.a = alpha

func _tween_groups_alpha(groups: Array, alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	for group in groups:
		if group == null or not is_instance_valid(group):
			continue
		var canvas_item: CanvasItem = group as CanvasItem
		if canvas_item == null:
			continue
		tween.tween_property(canvas_item, "modulate:a", alpha, duration)

func _clear_effect_overlays(overlays: Array) -> void:
	for overlay in overlays:
		if overlay != null and is_instance_valid(overlay):
			var node: Node = overlay as Node
			if node:
				node.queue_free()

func _play_gem_burst_preview() -> void:
	if not _is_helmet_tutorial_level() or gem_burst_effect == null:
		return
	gem_burst_effect.play_at(
		_grid_to_pixels_float(GEM_ORIGIN_GRID),
		world.cell_size,
		0.78,
		1947
	)

func _play_fullscreen_video(path: String) -> void:
	if fullscreen_video_player == null or path.is_empty():
		return
	var stream := load(path)
	if stream == null:
		push_warning("Fullscreen video not found: %s" % path)
		return
	fullscreen_video_player.stream = stream
	fullscreen_video_player.visible = true
	fullscreen_video_player.play()

func _on_fullscreen_video_finished() -> void:
	if fullscreen_video_player:
		fullscreen_video_player.stop()
		fullscreen_video_player.visible = false
	if world.has_fullscreen_video_finished_effect():
		_apply_result(world.resolve_fullscreen_video_finished_effect())

func _load_level_index(index: int, overrides := {}) -> void:
	current_level_index = clampi(index, 0, LEVEL_SEQUENCE.size() - 1)
	_visual_effect_generation += 1
	key_info_emphasis_played = false
	key_info_effect_active = false
	key_info_sequence_pending = false
	visual_sequence_has_key_info = false
	pre_key_visual_effects_active = 0
	pre_merge_push_effects_active = 0
	world.load_level(LEVEL_SEQUENCE[current_level_index].build_level())
	if overrides.has("player_pos"):
		world.player_pos = overrides.player_pos
	if overrides.has("player_text"):
		world.player_text = str(overrides.player_text)
	if overrides.has("player_facing"):
		world.facing = overrides.player_facing
	world.update_page()
	_clear_entity_visuals()
	_reset_player_river_visual()
	if _is_helmet_tutorial_level():
		intro_phase = "lights"
		intro_reveal_elapsed = 0.0
		intro_reveal_max_distance = 0.0
	else:
		intro_phase = "active"
	held_move_directions.clear()
	player_move_repeat_timer = 0.0
	player_blocked_retry_timer = 0.0
	player_walk_visual_timer = 0.0
	player_walk_frame_timer = 0.0
	_player_visual_ready = false
	_last_player_visible = world.player_visible
	if world_event_timer:
		world_event_timer.stop()
	if bridge_tree_effect_layer:
		for child in bridge_tree_effect_layer.get_children():
			child.queue_free()
	if player_sprite:
		_set_player_idle_visual()
	_sync_level_bgm()

func _sync_level_bgm() -> void:
	if level_bgm_player == null:
		return
	if not _is_helmet_tutorial_level():
		level_bgm_player.stop()
		return
	if level_bgm_player.playing and level_bgm_player.stream != null and level_bgm_player.stream.resource_path == HELMET_ACQUISITION_BGM_PATH:
		return
	if not ResourceLoader.exists(HELMET_ACQUISITION_BGM_PATH):
		return
	level_bgm_player.stream = load(HELMET_ACQUISITION_BGM_PATH)
	level_bgm_player.play()

func _startup_level_overrides() -> Dictionary:
	var overrides := {}
	if startup_player_pos.x >= 0 and startup_player_pos.y >= 0:
		overrides["player_pos"] = startup_player_pos
	if not startup_player_text.is_empty():
		overrides["player_text"] = startup_player_text
	if startup_player_facing != Vector2i.ZERO:
		overrides["player_facing"] = startup_player_facing
	return overrides

func _apply_startup_preview_state() -> void:
	if not startup_bridge_collapse_preview:
		return
	if current_level_index != 3:
		return
	world.apply_preview_effect(HelmetR3._loose_bridge_effect())
	world.visual_effect_requests.clear()
	world.update_page()

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
	if player_river_action_locked:
		return
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
		_play_player_walk_visual()
		_show_direction_marker(direction)

func _direction_from_key(keycode: Key) -> Vector2i:
	return PrecisionMovement.direction_from_keycode(keycode)

func _grid_to_pixels(pos: Vector2i) -> Vector2:
	return Vector2(pos.x * world.cell_size, pos.y * world.cell_size)

func _grid_to_pixels_float(pos: Vector2) -> Vector2:
	return pos * float(world.cell_size)

func _uses_player_sprite() -> bool:
	return world.player_text == "我"

func _update_player_visual_animation(delta: float) -> void:
	if player_sprite == null or player_walk_visual_timer <= 0.0:
		return
	player_walk_visual_timer = maxf(player_walk_visual_timer - delta, 0.0)
	player_walk_frame_timer += delta
	if player_walk_frame_timer >= PLAYER_WALK_FRAME_TIME:
		player_walk_frame_timer = 0.0
		player_sprite.frame = 1 - player_sprite.frame
	if player_walk_visual_timer <= 0.0:
		_set_player_idle_visual()

func _play_player_walk_visual() -> void:
	if player_sprite == null or not _uses_player_sprite():
		return
	player_sprite.texture = preload("res://assets/player/me_walk.png")
	player_sprite.hframes = 2
	player_sprite.vframes = 1
	player_sprite.frame = 0
	player_sprite.centered = true
	player_sprite.scale = Vector2.ONE
	player_sprite.modulate = Color.WHITE
	player_sprite.rotation = 0.0
	player_walk_visual_timer = PLAYER_WALK_VISUAL_TIME
	player_walk_frame_timer = 0.0

func _set_player_idle_visual() -> void:
	if player_sprite == null:
		return
	player_sprite.texture = preload("res://assets/player/me_default.png")
	player_sprite.hframes = 1
	player_sprite.vframes = 1
	player_sprite.frame = 0
	player_sprite.centered = true
	player_sprite.scale = Vector2.ONE
	player_sprite.modulate = Color.WHITE
	player_sprite.rotation = 0.0
	player_walk_visual_timer = 0.0
	player_walk_frame_timer = 0.0

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
	if keycode == SWORD_SCENE_SHORTCUT_KEY:
		return SWORD_FLOW_SCENE_PATH
	if keycode == GLOVE_SCENE_SHORTCUT_KEY:
		return GLOVE_PREVIEW_SCENE_PATH
	if keycode == HALL_SCENE_SHORTCUT_KEY:
		return HALL_PREVIEW_SCENE_PATH
	return ""

func _entry_scene_path_for_key(entry_key: String) -> String:
	match entry_key:
		"sword":
			return SWORD_FLOW_SCENE_PATH
		"glove":
			return GLOVE_PREVIEW_SCENE_PATH
		"hall":
			return HALL_PREVIEW_SCENE_PATH
		_:
			return ""

func _switch_to_scene(scene_path: String) -> void:
	if scene_path.is_empty() or get_tree() == null:
		return
	get_tree().change_scene_to_file(scene_path)

func _run_black_screen_transition(request: Dictionary) -> void:
	if get_tree() == null:
		return
	world.set_input_locked(true)
	world.set_event_locked(true)
	var cover := ColorRect.new()
	cover.name = "BlackScreenTransition"
	cover.position = Vector2.ZERO
	cover.size = get_viewport_rect().size
	cover.color = Color.BLACK
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.modulate.a = 0.0
	cover.z_index = 2000
	add_child(cover)
	var duration := maxf(float(request.get("duration", 1.0)), 0.01)
	var tween := create_tween()
	tween.tween_property(cover, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	var target_scene_path := str(request.get("target_scene_path", ""))
	if not target_scene_path.is_empty():
		_switch_to_scene(target_scene_path)
		return
	var target_level_index := int(request.get("target_level_index", -1))
	if target_level_index >= 0:
		_switch_to_level_index(target_level_index)
		cover.queue_free()
		return
	world.set_input_locked(false)
	world.set_event_locked(false)
	cover.queue_free()

func _switch_to_level_index(level_index: int) -> void:
	_load_level_index(level_index)
	_refresh_view()
