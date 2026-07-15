extends RefCounted

const GloveEffects = preload("res://scripts/levels/glove/glove_effects.gd")

var step_results: Array[Dictionary] = []

func load_route_file(route_path: String) -> Dictionary:
	if not FileAccess.file_exists(route_path):
		return {}
	var route_file := FileAccess.open(route_path, FileAccess.READ)
	if route_file == null:
		return {}
	var parsed = JSON.parse_string(route_file.get_as_text())
	if parsed is Dictionary:
		return (parsed as Dictionary).duplicate(true)
	return {}

func run_route(world: RefCounted, route: Dictionary) -> Dictionary:
	step_results.clear()
	var steps: Array = route.get("steps", [])
	for step_index in range(steps.size()):
		var step: Dictionary = steps[step_index]
		var result := _run_step(world, step)
		result = _apply_step_expectations(world, step, result)
		_record_step_result(world, step_index, step, result)
		if not bool(result.get("success", false)):
			return {
				"success": false,
				"failed_step": step_index,
				"report": build_report(world, route)
			}
	return {
		"success": true,
		"failed_step": -1,
		"report": build_report(world, route)
	}

func build_report(world: RefCounted, route: Dictionary) -> Dictionary:
	var state: Dictionary = {}
	if world.has_method("get_player_state"):
		state = world.get_player_state()
	return {
		"route_id": str(route.get("route_id", "")),
		"feature_id": str(route.get("feature_id", "")),
		"target_feature_id": str(route.get("target_feature_id", "")),
		"baseline_id": str(route.get("baseline_id", "")),
		"behavior_id": str(route.get("behavior_id", "")),
		"level_id": str(route.get("level_id", "")),
		"steps": step_results.duplicate(true),
		"checkpoints": _extract_checkpoints(),
		"runtime_trace": _runtime_trace_state(world),
		"final_state": {
			"player_pos": _vec2i_to_array(state.get("grid_pos", Vector2i.ZERO)),
			"facing": _vec2i_to_array(state.get("facing", Vector2i.ZERO)),
			"visible": bool(state.get("visible", true)),
			"input_locked": bool(state.get("input_locked", false)),
			"last_message": str(world.last_message)
		}
	}

func _run_step(world: RefCounted, step: Dictionary) -> Dictionary:
	match str(step.get("type", "")):
		"checkpoint":
			if world.has_method("update_page"):
				world.update_page()
			return {"success": true, "message": str(step.get("caption", ""))}
		"set_player":
			world.player_pos = _to_vec2i(step.get("pos", world.player_pos))
			world.facing = _to_vec2i(step.get("facing", world.facing))
			world.update_page()
			return {"success": true, "message": str(step.get("caption", ""))}
		"move_path":
			return _move_path(world, step)
		"action_sequence":
			return _run_action_sequence(world, step)
		"route_segment":
			return _run_route_segment(world, step)
		"source_event":
			if not world.has_method("trigger_step_effect_at"):
				return {"success": false, "message": "source event API missing"}
			var event_result: Dictionary = world.trigger_step_effect_at(_to_vec2i(step.get("pos", Vector2i.ZERO)))
			if event_result.is_empty():
				return {"success": false, "message": "source event did not trigger"}
			return event_result
		"set_gesture_slot":
			return _set_gesture_slot(world, str(step.get("text", "")))
		"place_at_palm":
			return _place_at_first_palm(world)
		"action":
			return world.try_player_action(str(step.get("action", "")), _to_vec2i(step.get("direction", Vector2i.ZERO)))
		_:
			return {"success": false, "message": "unsupported glove route step"}

func _move_path(world: RefCounted, step: Dictionary) -> Dictionary:
	var current_result: Dictionary = {"success": true, "message": str(step.get("caption", ""))}
	for raw_direction in step.get("path", []):
		var direction := _to_vec2i(raw_direction)
		current_result = world.try_player_action("move", direction)
		if not bool(current_result.get("success", false)):
			return current_result
		if bool(current_result.get("turned", false)) and not bool(current_result.get("moved", false)):
			current_result = world.try_player_action("move", direction)
			if not bool(current_result.get("success", false)):
				return current_result
	return current_result

func _run_action_sequence(world: RefCounted, step: Dictionary) -> Dictionary:
	var current_result: Dictionary = {"success": true, "message": str(step.get("caption", ""))}
	for raw_action in step.get("actions", []):
		if not raw_action is Dictionary:
			return {"success": false, "message": "invalid action sequence entry"}
		var action: Dictionary = raw_action
		current_result = world.try_player_action(
			str(action.get("action", "")),
			_to_vec2i(action.get("direction", Vector2i.ZERO))
		)
		if not bool(current_result.get("success", false)):
			return current_result
	return current_result

func _run_route_segment(world: RefCounted, step: Dictionary) -> Dictionary:
	var route_path := str(step.get("route_path", ""))
	var through_caption := str(step.get("through_caption", ""))
	if route_path.is_empty() or through_caption.is_empty():
		return {"success": false, "message": "route segment config missing"}
	var nested_runner = get_script().new()
	var source_route: Dictionary = nested_runner.load_route_file(route_path)
	if source_route.is_empty():
		return {"success": false, "message": "route segment source missing"}
	var segment_steps: Array = []
	var found_end := false
	for step_variant in source_route.get("steps", []):
		var source_step: Dictionary = step_variant
		segment_steps.append(source_step.duplicate(true))
		if str(source_step.get("caption", "")) == through_caption:
			found_end = true
			break
	if not found_end:
		return {"success": false, "message": "route segment end missing"}
	var segment_route := source_route.duplicate(true)
	segment_route["steps"] = segment_steps
	var nested_result: Dictionary = nested_runner.run_route(world, segment_route)
	if not bool(nested_result.get("success", false)):
		return {"success": false, "message": "verified route segment failed"}
	return {
		"success": true,
		"message": str(step.get("caption", "verified route segment completed")),
		"nested_route_id": str(source_route.get("route_id", "")),
		"nested_step_count": segment_steps.size()
	}

func _set_gesture_slot(world: RefCounted, text: String) -> Dictionary:
	if text.is_empty():
		return {"success": false, "message": "gesture text missing"}
	var target_pos := Vector2i(26, 17)
	var parked_pos := Vector2i(31, 17)
	var occupying = world.get_any_entity_at(target_pos)
	if occupying != null and occupying.text != text:
		world.move_entity_to(occupying.id, parked_pos)
	var gesture_word = world.find_first_entity_by_text(text)
	if gesture_word == null:
		return {"success": false, "message": "gesture word missing"}
	world.move_entity_to(gesture_word.id, target_pos)
	return {"success": true, "message": "gesture slot prepared"}

func _place_at_first_palm(world: RefCounted) -> Dictionary:
	var palm = world.find_first_entity_by_text("掌")
	if palm == null:
		return {"success": false, "message": "palm wall missing"}
	world.player_pos = palm.grid_pos + Vector2i.LEFT
	world.facing = Vector2i.RIGHT
	world.update_page()
	return {"success": true, "message": "player placed at palm"}

func _apply_step_expectations(world: RefCounted, step: Dictionary, result: Dictionary) -> Dictionary:
	var expectation: Dictionary = step.get("expect", {})
	if expectation.is_empty():
		return result
	var evaluation := _evaluate_expectations(world, expectation, result)
	var checked := int(evaluation.get("checked", 0))
	var failures: Array[String] = evaluation.get("failures", [])
	var expected_result_checked := bool(evaluation.get("expected_result_checked", false))
	var next_result := result.duplicate(true)
	next_result["expectations_checked"] = checked
	next_result["expectation_failures"] = failures.duplicate()
	if failures.is_empty():
		next_result["success"] = bool(result.get("success", false)) or expected_result_checked
		return next_result
	next_result["success"] = false
	next_result["message"] = "; ".join(failures)
	return next_result

func _evaluate_expectations(world: RefCounted, expectation: Dictionary, result: Dictionary) -> Dictionary:
	var checked := 0
	var failures: Array[String] = []
	var expected_result_checked := false
	var player_state: Dictionary = world.get_player_state() if world.has_method("get_player_state") else {}
	if expectation.has("result_success"):
		checked += 1
		expected_result_checked = true
		var expected_step_success := bool(expectation.get("result_success", true))
		var actual_step_success := bool(result.get("success", false))
		if actual_step_success != expected_step_success:
			failures.append("result_success expected %s got %s" % [expected_step_success, actual_step_success])
	if expectation.has("result_message"):
		checked += 1
		var expected_result_message := str(expectation.get("result_message", ""))
		var actual_result_message := str(result.get("message", ""))
		if actual_result_message != expected_result_message:
			failures.append("result_message expected %s got %s" % [expected_result_message, actual_result_message])
	if expectation.has("player_pos"):
		checked += 1
		var expected_player_pos := _to_vec2i(expectation.get("player_pos", Vector2i.ZERO))
		var actual_player_pos: Vector2i = player_state.get("grid_pos", Vector2i.ZERO)
		if actual_player_pos != expected_player_pos:
			failures.append("player_pos expected %s got %s" % [expected_player_pos, actual_player_pos])
	if expectation.has("facing"):
		checked += 1
		var expected_facing := _to_vec2i(expectation.get("facing", Vector2i.ZERO))
		var actual_facing: Vector2i = player_state.get("facing", Vector2i.ZERO)
		if actual_facing != expected_facing:
			failures.append("facing expected %s got %s" % [expected_facing, actual_facing])
	if expectation.has("visible"):
		checked += 1
		var expected_visible := bool(expectation.get("visible", true))
		var actual_visible := bool(player_state.get("visible", true))
		if actual_visible != expected_visible:
			failures.append("visible expected %s got %s" % [expected_visible, actual_visible])
	if expectation.has("input_locked"):
		checked += 1
		var expected_input_locked := bool(expectation.get("input_locked", false))
		var actual_input_locked := bool(player_state.get("input_locked", false))
		if actual_input_locked != expected_input_locked:
			failures.append("input_locked expected %s got %s" % [expected_input_locked, actual_input_locked])
	if expectation.has("last_message"):
		checked += 1
		var expected_message := str(expectation.get("last_message", ""))
		var actual_message := str(world.last_message)
		if actual_message != expected_message:
			failures.append("last_message expected %s got %s" % [expected_message, actual_message])
	for entry in _normalize_expectation_entries(expectation.get("text_at", null)):
		checked += 1
		var pos := _to_vec2i(entry.get("pos", Vector2i.ZERO))
		var expected_text := str(entry.get("text", ""))
		var entity = world.get_any_entity_at(pos)
		var actual_text := ""
		if entity != null:
			actual_text = str(entity.text)
		if actual_text != expected_text:
			failures.append("text_at %s expected %s got %s" % [pos, expected_text, actual_text])
	for entry in _normalize_expectation_entries(expectation.get("absent_text_at", null)):
		checked += 1
		var pos := _to_vec2i(entry.get("pos", Vector2i.ZERO))
		var forbidden_text := str(entry.get("text", ""))
		var entity = world.get_any_entity_at(pos)
		if entity != null and str(entity.text) == forbidden_text:
			failures.append("absent_text_at %s still has %s" % [pos, forbidden_text])
	return {
		"checked": checked,
		"failures": failures,
		"expected_result_checked": expected_result_checked
	}

func _normalize_expectation_entries(value: Variant) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if value is Dictionary:
		entries.append((value as Dictionary).duplicate(true))
	elif value is Array:
		for item in value:
			if item is Dictionary:
				entries.append((item as Dictionary).duplicate(true))
	return entries

func _record_step_result(world: RefCounted, step_index: int, step: Dictionary, result: Dictionary) -> void:
	var state: Dictionary = {}
	if world.has_method("get_player_state"):
		state = world.get_player_state()
	var step_entry := {
		"index": step_index,
		"type": str(step.get("type", "")),
		"caption": str(step.get("caption", "")),
		"input_data": _build_step_input_data(step),
		"success": bool(result.get("success", false)),
		"message": str(result.get("message", "")),
		"last_message": str(world.last_message),
		"player_pos": _vec2i_to_array(state.get("grid_pos", Vector2i.ZERO)),
		"facing": _vec2i_to_array(state.get("facing", Vector2i.ZERO)),
		"runtime_trace": _runtime_trace_state(world),
		"expectations_checked": int(result.get("expectations_checked", 0)),
		"expectation_failures": result.get("expectation_failures", [])
	}
	var checkpoint: Dictionary = step.get("checkpoint", {})
	if not checkpoint.is_empty():
		step_entry["checkpoint"] = _build_checkpoint_entry(step_index, step, checkpoint, state, world)
	step_results.append(step_entry)

func _extract_checkpoints() -> Array[Dictionary]:
	var checkpoints: Array[Dictionary] = []
	for step_entry_variant in step_results:
		var step_entry: Dictionary = step_entry_variant
		var checkpoint: Dictionary = step_entry.get("checkpoint", {})
		if checkpoint.is_empty():
			continue
		checkpoints.append(checkpoint.duplicate(true))
	return checkpoints

func _build_checkpoint_entry(step_index: int, step: Dictionary, checkpoint: Dictionary, state: Dictionary, world: RefCounted) -> Dictionary:
	var entry := {
		"id": str(checkpoint.get("id", "")),
		"state_id": str(checkpoint.get("state_id", checkpoint.get("id", ""))),
		"ref": str(checkpoint.get("ref", "")),
		"label": str(checkpoint.get("label", "")),
		"step_index": step_index,
		"caption": str(step.get("caption", "")),
		"player_pos": _vec2i_to_array(state.get("grid_pos", Vector2i.ZERO)),
		"facing": _vec2i_to_array(state.get("facing", Vector2i.ZERO)),
		"visible": bool(state.get("visible", true)),
		"input_locked": bool(state.get("input_locked", false)),
		"last_message": str(world.last_message),
		"runtime_trace": _runtime_trace_state(world)
	}
	if checkpoint.has("verification_status"):
		entry["verification_status"] = str(checkpoint.get("verification_status", ""))
	if checkpoint.has("source_grid_id"):
		entry["source_grid_id"] = str(checkpoint.get("source_grid_id", ""))
	if checkpoint.has("review_note"):
		entry["review_note"] = str(checkpoint.get("review_note", ""))
	return entry

func _build_step_input_data(step: Dictionary) -> Dictionary:
	match str(step.get("type", "")):
		"checkpoint":
			return {}
		"set_player":
			return {
				"pos": step.get("pos", []),
				"facing": step.get("facing", [])
			}
		"move_path":
			return {
				"path": step.get("path", []).duplicate(true)
			}
		"action_sequence":
			return {
				"actions": step.get("actions", []).duplicate(true)
			}
		"route_segment":
			return {
				"route_path": str(step.get("route_path", "")),
				"through_caption": str(step.get("through_caption", ""))
			}
		"set_gesture_slot":
			return {
				"text": str(step.get("text", ""))
			}
		"place_at_palm":
			return {}
		"action":
			return {
				"action": str(step.get("action", "")),
				"direction": step.get("direction", [])
			}
		_:
			return {}

func _vec2i_to_array(value: Variant) -> Array[int]:
	var pos: Vector2i = value
	return [pos.x, pos.y]

func _to_vec2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	if value is Dictionary and value.has("x") and value.has("y"):
		return Vector2i(int(value.get("x", 0)), int(value.get("y", 0)))
	return Vector2i.ZERO

func _runtime_trace_state(world: RefCounted) -> Dictionary:
	var animation_seen := {}
	var audio_seen := {}
	for entity in world.entities.values():
		var text := str(entity.text)
		if text.begins_with(GloveEffects.TRACE_ANIMATION_PREFIX):
			animation_seen[text.trim_prefix(GloveEffects.TRACE_ANIMATION_PREFIX)] = true
		elif text.begins_with(GloveEffects.TRACE_AUDIO_PREFIX):
			audio_seen[text.trim_prefix(GloveEffects.TRACE_AUDIO_PREFIX)] = true
	var animation_ids: Array[String] = []
	for animation_id in animation_seen.keys():
		animation_ids.append(str(animation_id))
	animation_ids.sort()
	var audio_ids: Array[String] = []
	for audio_id in audio_seen.keys():
		audio_ids.append(str(audio_id))
	audio_ids.sort()
	return {
		"animation_ids": animation_ids,
		"audio_ids": audio_ids
	}
