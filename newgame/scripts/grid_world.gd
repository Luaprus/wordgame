extends RefCounted

const PrecisionMovement = preload("res://scripts/precision_movement.gd")
const RuleEngine = preload("res://scripts/rule_engine.gd")
const WordEntity = preload("res://scripts/word_entity.gd")

const ACTION_MOVE := "move"
const ACTION_INTERACT := "interact"
const ACTION_DELETE := "delete"
const ACTION_SPLIT := "split"
const ACTION_PULL := "pull"

var cell_size := 60
var screen_size := Vector2i(32, 18)
var player_pos := Vector2i.ZERO
var facing := Vector2i(1, 0)
var player_moving := false
var player_move_cooldown := 0
var player_input_locked := false
var player_event_locked := false
var player_visible := true
var player_text := "我"
var player_abilities: PackedStringArray = PackedStringArray()
var current_page_origin := Vector2i.ZERO
var bounded := false
var allow_edge_transition := true
var entities: Dictionary = {}
var highlighted_cells: Array[Vector2i] = []
var last_message := ""
var rows: Array = []
var split_rules: Dictionary = {}
var merge_rules: Dictionary = {}
var sentence_rules: Dictionary = {}
var ignored_row_texts := PackedStringArray(["我"])
var entity_configs: Dictionary = {}
var cell_entity_configs: Dictionary = {}
var merge_effects: Dictionary = {}
var split_effects: Dictionary = {}
var player_merge_rules: Dictionary = {}
var player_merge_effects: Dictionary = {}
var player_split_rules: Dictionary = {}
var player_split_effects: Dictionary = {}
var passable_text_by_player: Dictionary = {}
var step_effects: Array = []
var pending_timed_effect: Dictionary = {}
var pending_timed_delay := 0.0
var typewriter_queue: Array[Dictionary] = []
var typewriter_after_effect: Dictionary = {}
var typewriter_delay := 0.2
var pending_interact_effect: Dictionary = {}
var current_level: Dictionary = {}
var rule_engine := RuleEngine.new()
var highlight_animation_strengths: Dictionary = {}
var highlight_animation_duration := 0.8

var _next_id := 1
var _map_caption_ids: Dictionary = {}

func load_level(level: Dictionary) -> void:
	clear()
	current_level = level.duplicate(true)
	screen_size = level.get("screen_size", screen_size)
	bounded = bool(level.get("bounded", false))
	allow_edge_transition = bool(level.get("allow_edge_transition", true))
	rows = level.get("rows", [])
	player_pos = level.get("player_start", player_pos)
	facing = level.get("player_facing", Vector2i(1, 0))
	player_moving = false
	player_move_cooldown = maxi(int(level.get("player_move_cooldown", 0)), 0)
	player_input_locked = bool(level.get("player_input_locked", false))
	player_event_locked = bool(level.get("player_event_locked", false))
	player_visible = bool(level.get("player_visible", true))
	player_text = str(level.get("player_text", "我"))
	set_player_abilities(level.get("player_abilities", []))
	set_ignored_row_texts(level.get("ignored_row_texts", ["我"]))
	entity_configs = level.get("entities", {})
	cell_entity_configs = level.get("cell_entity_configs", {})
	split_rules = level.get("split_rules", {})
	merge_rules = level.get("merge_rules", {})
	sentence_rules = level.get("sentence_rules", {})
	merge_effects = level.get("merge_effects", {})
	split_effects = level.get("split_effects", {})
	player_merge_rules = level.get("player_merge_rules", {})
	player_merge_effects = level.get("player_merge_effects", {})
	player_split_rules = level.get("player_split_rules", {})
	player_split_effects = level.get("player_split_effects", {})
	passable_text_by_player = level.get("passable_text_by_player", {})
	step_effects = level.get("step_effects", [])
	pending_interact_effect = level.get("initial_interact_effect", {}).duplicate(true)
	_parse_rows(rows)
	for spawn_config in level.get("initial_spawn", []):
		var entry: Dictionary = spawn_config
		if entry.has("text") and entry.has("pos"):
			add_entity(str(entry.text), entry.pos, entry.get("config", {}))
	update_page()

func clear() -> void:
	entities.clear()
	highlighted_cells.clear()
	last_message = ""
	player_moving = false
	player_move_cooldown = 0
	player_input_locked = false
	player_event_locked = false
	player_visible = true
	player_text = "我"
	bounded = false
	allow_edge_transition = true
	player_abilities = PackedStringArray()
	ignored_row_texts = PackedStringArray(["我"])
	entity_configs.clear()
	cell_entity_configs.clear()
	merge_effects.clear()
	split_effects.clear()
	player_merge_rules.clear()
	player_merge_effects.clear()
	player_split_rules.clear()
	player_split_effects.clear()
	passable_text_by_player.clear()
	step_effects.clear()
	highlight_animation_strengths.clear()
	pending_timed_effect.clear()
	pending_timed_delay = 0.0
	typewriter_queue.clear()
	typewriter_after_effect.clear()
	typewriter_delay = 0.2
	pending_interact_effect.clear()
	current_page_origin = Vector2i.ZERO
	_next_id = 1
	_map_caption_ids.clear()
	rule_engine.reset()

func try_player_action(action: String, direction := Vector2i.ZERO) -> Dictionary:
	match action:
		ACTION_MOVE:
			return try_move_player(direction)
		ACTION_INTERACT:
			return interact_front()
		ACTION_DELETE:
			return delete_front()
		ACTION_SPLIT:
			return split_front()
		ACTION_PULL:
			return pull_front(direction)
		_:
			return {"success": false, "message": "unknown action"}

func get_player_state() -> Dictionary:
	return {
		"grid_pos": player_pos,
		"facing": facing,
		"moving": player_moving,
		"visible": player_visible,
		"text": player_text,
		"move_cooldown": player_move_cooldown,
		"input_locked": player_input_locked,
		"event_locked": player_event_locked,
		"abilities": player_abilities.duplicate()
	}

func set_input_locked(locked: bool) -> void:
	player_input_locked = locked

func trigger_step_effect_at(pos: Vector2i) -> Dictionary:
	return _trigger_step_effect_at(pos)

func apply_preview_effect(effect: Dictionary) -> void:
	_apply_map_effect(effect)

func set_event_locked(locked: bool) -> void:
	player_event_locked = locked

func set_player_move_cooldown(cooldown: int) -> void:
	player_move_cooldown = maxi(cooldown, 0)

func tick_player_state(steps := 1) -> Dictionary:
	player_move_cooldown = maxi(player_move_cooldown - maxi(steps, 0), 0)
	return get_player_state()

func set_player_abilities(abilities: Array) -> void:
	var normalized := PackedStringArray()
	for ability in abilities:
		var ability_name := str(ability)
		if not normalized.has(ability_name):
			normalized.append(ability_name)
	player_abilities = normalized

func set_ignored_row_texts(texts: Array) -> void:
	var normalized := PackedStringArray()
	for text in texts:
		var value := str(text)
		if not normalized.has(value):
			normalized.append(value)
	ignored_row_texts = normalized

func get_rule_state() -> Dictionary:
	return rule_engine.get_state()

func get_highlight_animation_strength(cell: Vector2i) -> float:
	return float(highlight_animation_strengths.get(_cell_key(cell), 0.0))

func advance_highlight_animation(delta: float) -> void:
	if highlight_animation_strengths.is_empty():
		return
	var next_strengths: Dictionary = {}
	for key in highlight_animation_strengths.keys():
		var next_value := maxf(float(highlight_animation_strengths[key]) - (delta / highlight_animation_duration), 0.0)
		if next_value > 0.0:
			next_strengths[key] = next_value
	highlight_animation_strengths = next_strengths

func player_has_ability(ability: String) -> bool:
	return player_abilities.has(ability)

func try_move_player(direction: Vector2i) -> Dictionary:
	if direction == Vector2i.ZERO:
		return {"success": false, "message": "zero direction"}
	if player_input_locked:
		return {"success": false, "message": "input locked"}
	if player_move_cooldown > 0:
		return {"success": false, "message": "cooldown"}
	var intent := PrecisionMovement.resolve_turn_or_move(facing, direction)
	facing = intent.facing
	if intent.should_turn:
		return {"success": true, "turned": true, "moved": false}
	player_moving = true
	var target := player_pos + direction
	var bounds_result := _check_move_bounds(target)
	if not bounds_result.success:
		player_moving = false
		return bounds_result
	if bounds_result.has("transition"):
		player_moving = false
		return bounds_result
	var entity := get_entity_at(target)
	if entity:
		var player_merged := _try_merge_player_with_entity(entity)
		if player_merged.success:
			return player_merged
		if _can_player_pass_entity(entity):
			player_pos = target
			update_page()
			var step_result := _trigger_step_effect_at(player_pos)
			player_moving = false
			if not step_result.is_empty():
				return step_result
			return {"success": true}
		if not entity.pushable:
			player_moving = false
			return {"success": false, "message": "blocked"}
		var pushed := move_entity_by(entity.id, direction)
		if not pushed.success:
			player_moving = false
			return pushed
	player_pos = target
	update_page()
	check_sentence_rules()
	var step_result := _trigger_step_effect_at(player_pos)
	player_moving = false
	if not step_result.is_empty():
		return step_result
	return {"success": true}

func _check_move_bounds(target: Vector2i) -> Dictionary:
	if not bounded:
		return {"success": true}
	if target.x < 0 or target.y < 0 or target.y >= screen_size.y:
		return {"success": false, "message": "boundary"}
	if target.x >= screen_size.x and allow_edge_transition:
		return {
			"success": true,
			"transition": "next_level",
			"exit_pos": player_pos,
			"exit_y": player_pos.y
		}
	if target.x >= screen_size.x:
		return {"success": false, "message": "boundary"}
	return {"success": true}

func _get_front_target() -> Dictionary:
	var entity := get_entity_at(player_pos + facing)
	if not entity:
		return {"success": false, "message": "target not in front"}
	return {"success": true, "entity": entity}

func interact_front() -> Dictionary:
	if not pending_interact_effect.is_empty():
		var only_without_front := bool(pending_interact_effect.get("only_without_front_target", false))
		var only_at_start := bool(pending_interact_effect.get("only_at_player_start", false))
		var at_start: bool = player_pos == current_level.get("player_start", player_pos)
		if (not only_without_front or not _get_front_target().success) and (not only_at_start or at_start):
			var effect := pending_interact_effect.duplicate(true)
			pending_interact_effect.clear()
			_apply_map_effect(effect)
			return {"success": true, "message": last_message}
	if player_input_locked:
		return {"success": false, "message": "input locked"}
	if player_event_locked:
		return {"success": false, "message": "event locked"}
	var front_target := _get_front_target()
	if not front_target.success:
		return front_target
	var entity: WordEntity = front_target.entity
	if entity.interact_text:
		last_message = entity.interact_text
		if entity.interact_effect.is_empty():
			_spawn_interaction_caption(entity)
		else:
			_apply_map_effect(entity.interact_effect)
		return {"success": true, "message": entity.interact_text}
	return {"success": false, "message": "not interactable"}

func delete_front() -> Dictionary:
	if player_input_locked:
		return {"success": false, "message": "input locked"}
	if player_event_locked:
		return {"success": false, "message": "event locked"}
	var front_target := _get_front_target()
	if not front_target.success:
		return front_target
	var entity: WordEntity = front_target.entity
	if not entity.deletable:
		return {"success": false, "message": "not deletable"}
	var deleted_text := entity.text
	var deleted_pos := entity.grid_pos
	entities.erase(entity.id)
	_apply_entity_delete_effects(deleted_text, deleted_pos)
	check_sentence_rules()
	return {"success": true}

func _apply_entity_delete_effects(deleted_text: String, deleted_pos: Vector2i) -> void:
	for raw_entry in current_level.get("entity_delete_effects", []):
		var entry: Dictionary = raw_entry
		if str(entry.get("text", "")) != deleted_text:
			continue
		if entry.has("pos") and entry.get("pos") != deleted_pos:
			continue
		_apply_map_effect(entry.get("effect", {}))

func split_front() -> Dictionary:
	if player_input_locked:
		return {"success": false, "message": "input locked"}
	if player_event_locked:
		return {"success": false, "message": "event locked"}
	var player_split := _try_split_player()
	if player_split.success:
		return player_split
	var front_target := _get_front_target()
	if not front_target.success:
		return front_target
	var entity: WordEntity = front_target.entity
	if not entity.splittable or not split_rules.has(entity.text):
		return {"success": false, "message": "not splittable"}
	var parts: Array = split_rules[entity.text]
	if parts.size() != 2:
		return {"success": false, "message": "split rule needs two parts"}
	var split_positions := _split_positions_for(entity)
	if split_positions.size() != 2:
		return {"success": false, "message": "split rule needs two positions"}
	var space_result := _make_room_for_split(entity, split_positions)
	if not space_result.success:
		return space_result
	entities.erase(entity.id)
	_apply_map_effect(_effect_for_target(split_effects.get(entity.text, {}), entity.grid_pos))
	add_entity(str(parts[0]), split_positions[0], _config_for_text_at(str(parts[0]), split_positions[0], {
		"solid": true,
		"pushable": true,
		"splittable": true
	}))
	add_entity(str(parts[1]), split_positions[1], _config_for_text_at(str(parts[1]), split_positions[1], {
		"solid": true,
		"pushable": true,
		"splittable": true
	}))
	check_sentence_rules()
	return {"success": true}

func pull_front(move_direction: Vector2i) -> Dictionary:
	if move_direction == Vector2i.ZERO:
		return {"success": false, "message": "zero direction"}
	if player_input_locked:
		return {"success": false, "message": "input locked"}
	if player_event_locked:
		return {"success": false, "message": "event locked"}
	if player_move_cooldown > 0:
		return {"success": false, "message": "cooldown"}
	var front_target := _get_front_target()
	if not front_target.success:
		return front_target
	var entity: WordEntity = front_target.entity
	if not entity.pushable:
		return {"success": false, "message": "nothing pullable"}
	if move_direction != -facing:
		return {"success": false, "message": "pull direction locked"}
	var old_player_pos := player_pos
	var new_player_pos := player_pos + move_direction
	var bounds_result := _check_move_bounds(new_player_pos)
	if not bounds_result.success or bounds_result.has("transition"):
		return {"success": false, "message": "boundary"}
	if get_entity_at(new_player_pos):
		return {"success": false, "message": "player target blocked"}
	player_moving = true
	player_pos = new_player_pos
	move_entity_to(entity.id, old_player_pos)
	facing = -move_direction
	update_page()
	check_sentence_rules()
	player_moving = false
	return {"success": true}

func move_entity_by(entity_id: String, direction: Vector2i) -> Dictionary:
	var entity: WordEntity = entities.get(entity_id)
	if not entity:
		return {"success": false, "message": "missing entity"}
	var own_cells := {}
	for cell in entity.cells:
		own_cells[cell] = true
	for cell in entity.cells:
		var target := cell + direction
		if bounded and (target.x < 0 or target.x >= screen_size.x or target.y < 0 or target.y >= screen_size.y):
			return {"success": false, "message": "boundary"}
		var blocker := get_entity_at(target)
		if blocker and blocker.id != entity.id:
			var merged := try_merge_entities(entity.grid_pos, blocker.grid_pos)
			if merged.success:
				return merged
			return {"success": false, "message": "blocked by word"}
		if target == player_pos and not own_cells.has(target):
			return {"success": false, "message": "blocked by player"}
	_move_entity_and_apply_effects(entity, direction)
	return {"success": true}

func move_entity_to(entity_id: String, pos: Vector2i) -> Dictionary:
	var entity: WordEntity = entities.get(entity_id)
	if not entity:
		return {"success": false, "message": "missing entity"}
	var delta := pos - entity.grid_pos
	_move_entity_and_apply_effects(entity, delta)
	return {"success": true}

func _move_entity_and_apply_effects(entity: WordEntity, delta: Vector2i) -> void:
	var from_pos := entity.grid_pos
	entity.move_by(delta)
	var to_pos := entity.grid_pos
	for raw_entry in current_level.get("entity_move_effects", []):
		var entry: Dictionary = raw_entry
		if str(entry.get("text", "")) != entity.text:
			continue
		if entry.has("from") and entry.get("from") != from_pos:
			continue
		if entry.has("to") and entry.get("to") != to_pos:
			continue
		if bool(entry.get("leaves_from", false)) and to_pos == from_pos:
			continue
		_apply_map_effect(entry.get("effect", {}))

func _try_merge_player_with_entity(entity: WordEntity) -> Dictionary:
	var keys := ["%s+%s" % [player_text, entity.text], "%s+%s" % [entity.text, player_text]]
	for key in keys:
		if not player_merge_rules.has(key):
			continue
		entities.erase(entity.id)
		player_text = str(player_merge_rules[key])
		player_pos = entity.grid_pos
		_apply_map_effect(player_merge_effects.get(key, {}))
		update_page()
		check_sentence_rules()
		player_moving = false
		return {"success": true, "merged": true}
	return {"success": false, "message": "no player merge rule"}

func _can_player_pass_entity(entity: WordEntity) -> bool:
	var passable_texts: Array = passable_text_by_player.get(player_text, [])
	return passable_texts.has(entity.text)

func _try_split_player() -> Dictionary:
	if not player_split_rules.has(player_text):
		return {"success": false, "message": "no player split rule"}
	var old_text := player_text
	player_text = str(player_split_rules[old_text])
	_apply_map_effect(player_split_effects.get(old_text, {}))
	update_page()
	check_sentence_rules()
	return {"success": true, "player_split": true}

func try_merge_entities(from_pos: Vector2i, to_pos: Vector2i) -> Dictionary:
	var first := get_entity_at(from_pos)
	var second := get_entity_at(to_pos)
	if not first or not second or first.id == second.id:
		return {"success": false, "message": "need two words"}
	var key := "%s+%s" % [first.text, second.text]
	if not merge_rules.has(key):
		return {"success": false, "message": "no merge rule"}
	var merged_text := str(merge_rules[key])
	var split_positions := _merge_split_positions(merged_text, first, second)
	entities.erase(first.id)
	entities.erase(second.id)
	var merged := add_entity(merged_text, to_pos, _config_for_text_at(merged_text, to_pos, {
		"solid": true,
		"pushable": true,
		"splittable": split_rules.has(merged_text)
	}))
	merged.split_positions = split_positions
	_apply_map_effect(_effect_for_target(merge_effects.get(key, {}), to_pos))
	check_sentence_rules()
	return {"success": true}

func check_sentence_rules() -> Dictionary:
	highlighted_cells.clear()
	for entity in entities.values():
		entity.highlighted = false
	var result := {}
	var evaluation: Dictionary = rule_engine.evaluate(entities, sentence_rules, Callable(self, "get_entity_at"))
	for cell in evaluation.get("highlighted_cells", []):
		highlighted_cells.append(cell)
		highlight_animation_strengths[_cell_key(cell)] = 1.0
		var entity := get_entity_at(cell)
		if entity:
			entity.highlighted = true
	var matches: Dictionary = evaluation.get("matches", {})
	for sentence in matches.keys():
		var match: Dictionary = matches[sentence]
		var config: Dictionary = match.get("config", {})
		var found_cells: Array[Vector2i] = match.get("cells", [])
		last_message = str(match.get("message", ""))
		_spawn_sentence_caption(str(sentence), config, found_cells)
		result[sentence] = {"message": last_message, "cells": found_cells}
	return result

func update_page() -> void:
	current_page_origin = Vector2i(
		floori(float(player_pos.x) / float(screen_size.x)) * screen_size.x,
		floori(float(player_pos.y) / float(screen_size.y)) * screen_size.y
	)

func get_entity_at(pos: Vector2i) -> WordEntity:
	for entity in entities.values():
		if entity.solid and entity.cells.has(pos):
			return entity
	return null

func get_any_entity_at(pos: Vector2i) -> WordEntity:
	for entity in entities.values():
		if entity.cells.has(pos):
			return entity
	return null

func find_first_entity_by_text(text: String) -> WordEntity:
	for entity in entities.values():
		if entity.text == text:
			return entity
	return null

func add_entity(text: String, pos: Vector2i, config := {}) -> WordEntity:
	var occupied_cells: Array[Vector2i] = []
	for i in range(text.length()):
		occupied_cells.append(pos + Vector2i(i, 0))
	var entity := WordEntity.new("word_%03d" % _next_id, text, pos, occupied_cells)
	_next_id += 1
	entity.set_from_config(config)
	entities[entity.id] = entity
	return entity

func spawn_map_caption(text: String, near_pos: Vector2i, config := {}) -> WordEntity:
	if text.is_empty():
		return null
	if _map_caption_ids.has(text) and entities.has(_map_caption_ids[text]):
		return entities[_map_caption_ids[text]]
	var pos := near_pos
	if config.has("caption_pos"):
		pos = config.caption_pos
	else:
		pos = _find_free_caption_pos(near_pos, text.length())
	var caption := add_entity(text, pos, {
		"solid": config.get("caption_solid", true),
		"pushable": config.get("caption_pushable", false),
		"deletable": config.get("caption_deletable", false),
		"splittable": config.get("caption_splittable", false),
		"interact_text": config.get("caption_interact_text", "")
	})
	_map_caption_ids[text] = caption.id
	return caption

func _spawn_sentence_caption(sentence: String, config: Dictionary, cells: Array[Vector2i]) -> void:
	var caption_text := str(config.get("message", ""))
	if caption_text.is_empty():
		return
	spawn_map_caption(caption_text, cells[0] + Vector2i(0, 1), config)

func _spawn_interaction_caption(entity: WordEntity) -> void:
	if entity.interact_caption_lines.is_empty():
		spawn_map_caption(entity.interact_text, entity.grid_pos + Vector2i(0, 1))
		return
	var pos := entity.grid_pos + Vector2i(0, 1)
	if entity.has_interact_caption_pos:
		pos = entity.interact_caption_pos
	for i in range(entity.interact_caption_lines.size()):
		spawn_map_caption(str(entity.interact_caption_lines[i]), pos + Vector2i(0, i), {
			"caption_solid": entity.interact_caption_solid
		})

func _split_positions_for(entity: WordEntity) -> Array[Vector2i]:
	if not entity.split_positions.is_empty():
		return entity.split_positions.duplicate()
	return [entity.grid_pos, entity.grid_pos + facing]

func _make_room_for_split(entity: WordEntity, split_positions: Array[Vector2i]) -> Dictionary:
	var split_direction := Vector2i.RIGHT
	if split_positions.size() >= 2 and split_positions[0] != split_positions[1]:
		split_direction = split_positions[1] - split_positions[0]
	for i in range(split_positions.size()):
		var pos: Vector2i = split_positions[i]
		if player_pos == pos:
			var push_direction := split_direction
			if i == 0:
				push_direction = -split_direction
			var pushed_pos := player_pos + push_direction
			if get_entity_at(pushed_pos):
				return {"success": false, "message": "player split target blocked"}
			player_pos = pushed_pos
		var blocker := get_entity_at(pos)
		if blocker and blocker.id != entity.id:
			return {"success": false, "message": "split target blocked"}
	return {"success": true}

func _merge_split_positions(merged_text: String, first: WordEntity, second: WordEntity) -> Array[Vector2i]:
	var parts: Array = split_rules.get(merged_text, [])
	if parts.size() != 2:
		return [first.grid_pos, second.grid_pos]
	var sources := [first, second]
	var used := {}
	var result: Array[Vector2i] = []
	for part in parts:
		var matched: WordEntity = null
		for i in range(sources.size()):
			if used.has(i):
				continue
			if sources[i].text == str(part):
				matched = sources[i]
				used[i] = true
				break
		if matched:
			result.append(matched.grid_pos)
	if result.size() == 2:
		return result
	return [first.grid_pos, second.grid_pos]

func _apply_map_effect(config: Dictionary) -> void:
	var preserved_entities: Array[Dictionary] = []
	for text in config.get("preserve_texts", []):
		preserved_entities.append_array(_snapshot_entities_by_text(str(text)))
	if bool(config.get("reset_level", false)):
		var reset_player_pos = config.get("reset_player_pos", current_level.get("player_start", player_pos))
		load_level(current_level.duplicate(true))
		player_pos = reset_player_pos
		update_page()
		return
	if config.has("condition"):
		var condition: Dictionary = config.condition
		var pos: Vector2i = condition.get("pos", Vector2i.ZERO)
		var expected_text := str(condition.get("text", ""))
		var entity := get_any_entity_at(pos)
		if entity and entity.text == expected_text:
			_apply_map_effect(condition.get("then", {}))
		else:
			_apply_map_effect(condition.get("else", {}))
		return
	if bool(config.get("clear_entities", false)):
		entities.clear()
		_map_caption_ids.clear()
	if config.has("set_player_pos"):
		player_pos = config.set_player_pos
		update_page()
	if config.has("set_player_visible"):
		player_visible = bool(config.set_player_visible)
	if config.has("set_player_text"):
		player_text = str(config.set_player_text)
	if config.has("set_input_locked"):
		player_input_locked = bool(config.set_input_locked)
	if config.has("set_event_locked"):
		player_event_locked = bool(config.set_event_locked)
	if config.has("set_pending_interact_effect"):
		pending_interact_effect = config.set_pending_interact_effect
	if config.has("set_pending_timed_effect"):
		pending_timed_effect = config.set_pending_timed_effect
		pending_timed_delay = float(config.get("pending_timed_delay", pending_timed_delay))
	if config.has("last_message"):
		last_message = str(config.last_message)
	for text in config.get("remove_texts", []):
		_erase_entities_by_text(str(text))
	for pos in config.get("remove_at", []):
		_erase_entities_at(pos)
	for replace_config in config.get("replace_text", []):
		if _replace_text_if_present(replace_config):
			for pos in replace_config.get("remove_on_replace", []):
				_erase_entities_at(pos)
			for spawn_config in replace_config.get("spawn_on_replace", []):
				var entry: Dictionary = spawn_config
				var text := str(entry.get("text", ""))
				if text.is_empty() or not entry.has("pos"):
					continue
				var pos: Vector2i = entry.pos
				var overrides: Dictionary = entry.get("config", {})
				add_entity(text, pos, _config_for_text_at(text, pos, overrides))
	for spawn_config in config.get("spawn", []):
		var entry: Dictionary = spawn_config
		var text := str(entry.get("text", ""))
		if text.is_empty() or not entry.has("pos"):
			continue
		var pos: Vector2i = entry.pos
		var overrides: Dictionary = entry.get("config", {})
		add_entity(text, pos, _config_for_text_at(text, pos, overrides))
	for behind_config in config.get("spawn_behind_player", []):
		_spawn_behind_player(behind_config)
	for move_config in config.get("move_entities", []):
		var entry: Dictionary = move_config
		if not entry.has("to"):
			continue
		var entity: WordEntity = null
		if entry.has("id"):
			entity = entities.get(str(entry.get("id")))
		elif entry.has("from"):
			entity = get_any_entity_at(entry.get("from"))
		if entity:
			move_entity_to(entity.id, entry.get("to"))
	if config.has("fly_entity_left"):
		_fly_entity_left(config.fly_entity_left)
	for text_config in config.get("spawn_text", []):
		_spawn_effect_text(text_config)
	if config.has("start_typewriter"):
		_start_typewriter(config.start_typewriter)
	for preserved in preserved_entities:
		var preserved_id := str(preserved.get("id", ""))
		if entities.has(preserved_id):
			continue
		var preserved_text := str(preserved.get("text", ""))
		var preserved_pos: Vector2i = preserved.get("pos", Vector2i.ZERO)
		var preserved_config: Dictionary = preserved.get("config", {})
		var restored := add_entity(preserved_text, preserved_pos, preserved_config)
		var temp_id := restored.id
		restored.id = preserved_id
		entities.erase(temp_id)
		entities[preserved_id] = restored

func _fly_entity_left(fly_config: Dictionary) -> void:
	var entity: WordEntity = null
	if fly_config.has("id"):
		entity = entities.get(str(fly_config.get("id")))
	elif fly_config.has("from"):
		entity = get_any_entity_at(fly_config.get("from"))
	if not entity:
		return
	entity.move_by(Vector2i.LEFT)
	var until_x := int(fly_config.get("until_x", -3))
	if entity.grid_pos.x > until_x:
		pending_timed_effect = {
			"fly_entity_left": {
				"id": entity.id,
				"until_x": until_x,
				"step_delay": fly_config.get("step_delay", 0.12)
			}
		}
		pending_timed_delay = float(fly_config.get("step_delay", 0.12))

func _spawn_behind_player(spawn_config: Dictionary) -> void:
	var text := str(spawn_config.get("text", ""))
	if text.is_empty():
		return
	var pos := player_pos - facing
	if spawn_config.has("offset"):
		pos = player_pos + spawn_config.get("offset")
	var overrides: Dictionary = spawn_config.get("config", {})
	var spawned := add_entity(text, pos, _config_for_text_at(text, pos, overrides))
	if spawn_config.has("timed_move_left"):
		var move_config: Dictionary = spawn_config.get("timed_move_left")
		var delay := float(move_config.get("delay", 1.0))
		var to_x := int(move_config.get("to_x", -3))
		var step_delay := float(move_config.get("step_delay", 0.12))
		pending_timed_effect = {
			"fly_entity_left": {
				"id": spawned.id,
				"until_x": to_x,
				"step_delay": step_delay
			}
		}
		pending_timed_delay = delay

func _effect_for_target(effect_config, target_pos: Vector2i) -> Dictionary:
	if not effect_config is Dictionary:
		return {}
	var config: Dictionary = effect_config
	if not config.has("by_target"):
		return config
	for entry_config in config.get("by_target", []):
		var entry: Dictionary = entry_config
		if entry.get("pos", Vector2i.ZERO) == target_pos:
			return entry.get("effect", {})
	return config.get("default", {})

func has_pending_timed_effect() -> bool:
	return not pending_timed_effect.is_empty()

func resolve_pending_timed_effect() -> Dictionary:
	if pending_timed_effect.is_empty():
		return {"success": false, "message": "no pending effect"}
	var effect := pending_timed_effect
	pending_timed_effect = {}
	pending_timed_delay = 0.0
	if bool(effect.get("typewriter_step", false)):
		_advance_typewriter()
		return {"success": true, "message": last_message}
	_apply_map_effect(effect)
	return {"success": true, "message": last_message}

func _start_typewriter(definition: Dictionary) -> void:
	typewriter_queue.clear()
	var lines: Array = definition.get("lines", [])
	var origin: Vector2i = definition.get("pos", Vector2i.ZERO)
	var config: Dictionary = definition.get("config", {})
	for line_index in range(lines.size()):
		var line := str(lines[line_index])
		for char_index in range(line.length()):
			typewriter_queue.append({
				"text": line.substr(char_index, 1),
				"pos": origin + Vector2i(char_index, line_index),
				"config": config
			})
	typewriter_after_effect = definition.get("after_effect", {}).duplicate(true)
	typewriter_delay = float(definition.get("char_delay", 0.2))
	_advance_typewriter()

func _advance_typewriter() -> void:
	if typewriter_queue.is_empty():
		if not typewriter_after_effect.is_empty():
			var after_effect: Dictionary = typewriter_after_effect.duplicate(true)
			typewriter_after_effect.clear()
			_apply_map_effect(after_effect)
		return
	var entry: Dictionary = typewriter_queue.pop_front()
	add_entity(str(entry.text), entry.pos, _config_for_text_at(str(entry.text), entry.pos, entry.get("config", {})))
	if typewriter_queue.is_empty():
		if not typewriter_after_effect.is_empty():
			var after_effect: Dictionary = typewriter_after_effect.duplicate(true)
			typewriter_after_effect.clear()
			_apply_map_effect(after_effect)
		return
	pending_timed_effect = {"typewriter_step": true}
	pending_timed_delay = typewriter_delay

func _trigger_step_effect_at(pos: Vector2i) -> Dictionary:
	for step_config in step_effects:
		var entry: Dictionary = step_config
		if entry.get("pos", Vector2i.ZERO) != pos:
			continue
		if not _step_condition_matches(entry.get("condition", {})):
			continue
		var effect: Dictionary = entry.get("effect", {})
		var delay := float(entry.get("delay_seconds", 0.0))
		if delay > 0.0:
			pending_timed_effect = effect
			pending_timed_delay = delay
			player_input_locked = bool(entry.get("lock_input", true))
			return {"success": true, "pending_delay": delay}
		_apply_map_effect(effect)
		return {"success": true}
	return {}

func _step_condition_matches(condition_config) -> bool:
	var condition: Dictionary = condition_config
	if condition.is_empty():
		return true
	if condition.has("absent_text_at"):
		var absent: Dictionary = condition.absent_text_at
		var entity := get_any_entity_at(absent.get("pos", Vector2i.ZERO))
		if entity and entity.text == str(absent.get("text", "")):
			return false
	if condition.has("present_text_at"):
		var present: Dictionary = condition.present_text_at
		var entity := get_any_entity_at(present.get("pos", Vector2i.ZERO))
		if not entity or entity.text != str(present.get("text", "")):
			return false
	return true

func _erase_entities_at(pos: Vector2i) -> void:
	var erased_ids: Array[String] = []
	for entity in entities.values():
		if entity.cells.has(pos) and not erased_ids.has(entity.id):
			erased_ids.append(entity.id)
	for id in erased_ids:
		var entity: WordEntity = entities.get(id)
		if entity and _map_caption_ids.get(entity.text, "") == id:
			_map_caption_ids.erase(entity.text)
		entities.erase(id)

func _erase_entities_by_text(text: String) -> void:
	var erased_ids: Array[String] = []
	for entity in entities.values():
		if entity.text == text and not erased_ids.has(entity.id):
			erased_ids.append(entity.id)
	for id in erased_ids:
		var entity: WordEntity = entities.get(id)
		if entity and _map_caption_ids.get(entity.text, "") == id:
			_map_caption_ids.erase(entity.text)
		entities.erase(id)

func _snapshot_entities_by_text(text: String) -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	for entity in entities.values():
		if entity.text != text:
			continue
		snapshots.append({
			"id": entity.id,
			"text": entity.text,
			"pos": entity.grid_pos,
			"config": {
				"solid": entity.solid,
				"pushable": entity.pushable,
				"deletable": entity.deletable,
				"splittable": entity.splittable,
				"interact_text": entity.interact_text,
				"interact_effect": entity.interact_effect.duplicate(true),
				"interact_caption_lines": entity.interact_caption_lines.duplicate(),
				"interact_caption_solid": entity.interact_caption_solid,
				"interact_caption_pos": entity.interact_caption_pos,
				"has_interact_caption_pos": entity.has_interact_caption_pos,
				"split_positions": entity.split_positions.duplicate()
			}
		})
	return snapshots

func _replace_text_if_present(replace_config: Dictionary) -> bool:
	var from_text := str(replace_config.get("from", ""))
	var to_text := str(replace_config.get("to", ""))
	if from_text.is_empty() or to_text.is_empty():
		return false
	var pos: Vector2i = replace_config.get("pos", Vector2i.ZERO)
	var target: WordEntity = null
	for entity in entities.values():
		if entity.text == from_text and entity.grid_pos == pos:
			target = entity
			break
	if not target:
		return false
	entities.erase(target.id)
	if _map_caption_ids.get(from_text, "") == target.id:
		_map_caption_ids.erase(from_text)
	var replacement := add_entity(to_text, pos, _config_for_text_at(to_text, pos, replace_config.get("config", {})))
	_map_caption_ids[to_text] = replacement.id
	return true

func _spawn_effect_text(text_config: Dictionary) -> void:
	var text := str(text_config.get("text", ""))
	if text.is_empty() or not text_config.has("pos"):
		return
	var pos: Vector2i = text_config.pos
	var config: Dictionary = text_config.get("config", {})
	var cell_configs: Dictionary = text_config.get("cell_configs", {})
	if not bool(text_config.get("as_chars", false)):
		add_entity(text, pos, _config_for_text_at(text, pos, config))
		return
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		if ch == " ":
			continue
		var cell := pos + Vector2i(i, 0)
		var overrides := config.duplicate()
		var char_config: Dictionary = cell_configs.get(i, {})
		for key in char_config.keys():
			overrides[key] = char_config[key]
		add_entity(ch, cell, _config_for_text_at(ch, cell, overrides))

func _find_free_caption_pos(start: Vector2i, text_length: int) -> Vector2i:
	for distance in range(0, 8):
		for offset in [Vector2i(0, distance), Vector2i(0, -distance), Vector2i(distance, 0), Vector2i(-distance, 0)]:
			var candidate: Vector2i = start + offset
			if _can_place_text(candidate, text_length):
				return candidate
	return start

func _can_place_text(pos: Vector2i, text_length: int) -> bool:
	for i in range(text_length):
		var cell := pos + Vector2i(i, 0)
		if cell == player_pos or get_entity_at(cell):
			return false
	return true

func _parse_rows(level_rows: Array) -> void:
	var multi_texts := _get_multi_texts(entity_configs)
	var covered := {}
	for y in range(level_rows.size()):
		var line := str(level_rows[y])
		var x := 0
		while x < line.length():
			var pos := Vector2i(x, y)
			if covered.has(pos):
				x += 1
				continue
			var matched := _match_multi_text(line, x, multi_texts)
			if matched:
				add_entity(matched, pos, _config_for_text_at(matched, pos))
				for offset in range(matched.length()):
					covered[pos + Vector2i(offset, 0)] = true
				x += matched.length()
				continue
			var ch := line.substr(x, 1)
			if ch != " " and not ignored_row_texts.has(ch):
				add_entity(ch, pos, _config_for_text_at(ch, pos))
			x += 1

func _config_for_text_at(text: String, pos: Vector2i, overrides := {}) -> Dictionary:
	var config := {"solid": true}
	var text_config: Dictionary = entity_configs.get(text, {})
	for key in text_config.keys():
		config[key] = text_config[key]
	var cell_config: Dictionary = cell_entity_configs.get(pos, {})
	for key in cell_config.keys():
		config[key] = cell_config[key]
	for key in overrides.keys():
		config[key] = overrides[key]
	return config

func _cell_key(cell: Vector2i) -> String:
	return "%s,%s" % [cell.x, cell.y]

func _get_multi_texts(entity_configs: Dictionary) -> Array[String]:
	var texts: Array[String] = []
	for text in entity_configs.keys():
		var s := str(text)
		if s.length() > 1:
			texts.append(s)
	texts.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	return texts

func _match_multi_text(line: String, start: int, multi_texts: Array[String]) -> String:
	for text in multi_texts:
		if start + text.length() <= line.length() and line.substr(start, text.length()) == text:
			return text
	return ""
