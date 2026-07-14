extends Node2D

const GridWorld = preload("res://scripts/grid_world.gd")
const WordEntity = preload("res://scripts/word_entity.gd")
const LevelLoader = preload("res://scripts/level_loader.gd")
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
const TreeSpriteScene = preload("res://scenes/animations/TreeSprite.tscn")
const OriginalFont = preload("res://Fonts/Zpix-v3.1.6.ttf")

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
const RIVER_DEPTH_STEP := 10
const RIVER_PLAYER_DEPTH_OFFSET := 5
const HIGHLIGHT_VISUAL_CONFIG_PATH := "res://assets/animations/highlight/highlight_visual_config.json"
const GLOVE_PREVIEW_SCENE_PATH := "res://levels/glove/glove_preview.tscn"
const STARTUP_ENTRY_ARG_PREFIX := "--entry="
const GLOVE_SCENE_SHORTCUT_KEY := KEY_F9
const LEVEL_SEQUENCE := [
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

var world := GridWorld.new()
var page_camera := PageCamera.new()
var demo := DemoRunner.new()
var player_mover := SmoothGridMover.new()
var current_level_index := 0
var entity_movers: Dictionary = {}
var entity_labels: Dictionary = {}
var player_label: Label
var player_sprite: Sprite2D
var map_layer: Node2D
var bridge_tree_effect_layer: Node2D
var demo_timer: Timer
var world_event_timer: Timer
var direction_marker: Node2D
var direction_marker_fill: Polygon2D
var direction_marker_outline: Line2D
var direction_marker_timer: Timer
var fullscreen_video_player: VideoStreamPlayer
var gem_burst_effect
var light_glow_effect
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
var highlight_visual_config: Dictionary = {}
var gem_labels: Array = []
var intro_phase := "lights"
var intro_reveal_elapsed := 0.0
var intro_reveal_max_distance := 0.0
var creek_wave_elapsed := 0.0

func _ready() -> void:
	var startup_scene_path := resolve_startup_scene_path(OS.get_cmdline_user_args())
	if not startup_scene_path.is_empty():
		call_deferred("_switch_to_scene", startup_scene_path)
		return
	highlight_visual_config = load_highlight_visual_config()
	_load_level_index(startup_level_index, _startup_level_overrides())
	page_camera.sync_to_world(world)
	_build_scene()
	_refresh_view()

func _process(delta: float) -> void:
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
	_apply_visual_positions()
	_update_intro_sequence(delta)
	_update_gem_labels()

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
	if current_level_index != 0 or intro_phase != "prompt":
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
	if current_level_index != 0 or intro_phase != "lights":
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
			entity_labels[id].position = visual_position

func _is_creek_visual_entity(entity: WordEntity) -> bool:
	return current_level_index > 0 and entity != null and entity.text == "溪" and entity.grid_pos.x >= CREEK_MIN_X

func _entity_depth_for(entity: WordEntity) -> int:
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

func _sync_entity_label_group(group: Node2D, entity) -> void:
	if _is_tree_animated_entity(entity):
		_sync_tree_sprite_group(group)
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
	if current_level_index == 0 and intro_phase == "lights" and result.get("success", false) and not world.has_pending_timed_effect():
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
	for i in range(visual_requests.size()):
		var request: Dictionary = visual_requests[i]
		var effect_type := str(request.get("type", ""))
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
		if effect_type == "player_river_enter":
			_play_player_river_enter(request)
			continue
		if effect_type == "player_river_exit":
			_play_player_river_exit(request)
			continue
		if effect_type == "bridge_tree_transition":
			var context: Dictionary = visual_contexts[i] if i < visual_contexts.size() else {}
			call_deferred("_run_bridge_tree_transition", request.duplicate(true), context, _visual_effect_generation)

func _prepare_visual_effect_contexts(visual_requests: Array) -> Array:
	var contexts: Array = []
	for request in visual_requests:
		var request_dict: Dictionary = request
		var effect_type := str(request_dict.get("type", ""))
		if effect_type != "bridge_tree_transition":
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

func _run_bridge_tree_transition(request: Dictionary, context: Dictionary, generation: int) -> void:
	if generation != _visual_effect_generation or bridge_tree_effect_layer == null:
		return
	var mode := str(request.get("mode", ""))
	var tree_fade_duration := float(request.get("tree_fade_duration", 0.42))
	var tree_fade_in_duration := float(request.get("tree_fade_in_duration", 0.3))
	var bridge_step_delay := float(request.get("bridge_step_delay", 0.055))
	var bridge_fade_duration := float(request.get("bridge_fade_duration", 0.12))
	if mode == "merge":
		_run_bridge_tree_merge_transition(request, context, generation, tree_fade_duration, bridge_step_delay, bridge_fade_duration)
	elif mode == "split":
		_run_bridge_tree_split_transition(request, context, generation, tree_fade_in_duration, bridge_step_delay, bridge_fade_duration)

func _run_bridge_tree_merge_transition(request: Dictionary, context: Dictionary, generation: int, tree_fade_duration: float, bridge_step_delay: float, bridge_fade_duration: float) -> void:
	var overlays: Array = context.get("tree_overlays", [])
	for overlay: Node2D in overlays:
		if bridge_tree_effect_layer:
			bridge_tree_effect_layer.add_child(overlay)
	var tree_tween: Tween = null
	if not overlays.is_empty():
		tree_tween = create_tween()
		tree_tween.set_parallel(true)
		for overlay: Node2D in overlays:
			overlay.modulate.a = 1.0
			tree_tween.tween_property(overlay, "modulate:a", 0.0, tree_fade_duration)
	var bridge_groups: Array = _find_groups_for_cells(request.get("bridge_cells", []))
	_set_groups_alpha(bridge_groups, 0.0)
	var bridge_columns: Dictionary = _group_effect_targets_by_x(bridge_groups)
	for x in bridge_columns.keys():
		if generation != _visual_effect_generation:
			_clear_effect_overlays(overlays)
			return
		_tween_groups_alpha(bridge_columns[x], 1.0, bridge_fade_duration)
		await get_tree().create_timer(bridge_step_delay).timeout
	if tree_tween != null:
		await tree_tween.finished
	_clear_effect_overlays(overlays)

func _run_bridge_tree_split_transition(request: Dictionary, context: Dictionary, generation: int, tree_fade_in_duration: float, bridge_step_delay: float, bridge_fade_duration: float) -> void:
	var overlays: Array = _build_visual_overlays(context.get("bridge_visual_specs", []))
	for overlay: Node2D in overlays:
		if bridge_tree_effect_layer:
			bridge_tree_effect_layer.add_child(overlay)
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
	if current_level_index != 0 or gem_burst_effect == null:
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
	if current_level_index == 0:
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

func _startup_level_overrides() -> Dictionary:
	var overrides := {}
	if startup_player_pos.x >= 0 and startup_player_pos.y >= 0:
		overrides["player_pos"] = startup_player_pos
	if not startup_player_text.is_empty():
		overrides["player_text"] = startup_player_text
	if startup_player_facing != Vector2i.ZERO:
		overrides["player_facing"] = startup_player_facing
	return overrides

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
