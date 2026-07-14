extends RefCounted

var steps: Array[Dictionary] = []
var index := 0
var running := false
var route_id := "default-demo"
var feature_id := ""
var target_feature_id := ""
var baseline_id := ""
var behavior_id := ""
var level_id := ""
var current_route: Dictionary = {}
var step_results: Array[Dictionary] = []
var snapshot_paths: Array[String] = []

func start() -> void:
	start_route({
		"route_id": "default-demo",
		"feature_id": "",
		"baseline_id": "",
		"steps": _default_steps()
	})

func start_route(route: Dictionary) -> void:
	index = 0
	running = true
	current_route = route.duplicate(true)
	route_id = str(route.get("route_id", "unnamed-route"))
	feature_id = str(route.get("feature_id", ""))
	target_feature_id = str(route.get("target_feature_id", ""))
	baseline_id = str(route.get("baseline_id", ""))
	behavior_id = str(route.get("behavior_id", ""))
	level_id = str(route.get("level_id", ""))
	step_results.clear()
	snapshot_paths.clear()
	steps.clear()
	var route_steps = route.get("steps", _default_steps())
	for raw_step in route_steps:
		if raw_step is Dictionary:
			steps.append((raw_step as Dictionary).duplicate(true))

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

func run_route_to_completion(world: RefCounted, route: Dictionary) -> Dictionary:
	start_route(route)
	while running:
		var result: Dictionary = step(world)
		if world.has_method("has_pending_timed_effect") and world.has_pending_timed_effect():
			var timed_result: Dictionary = world.resolve_pending_timed_effect()
			if not bool(timed_result.get("success", false)):
				_record_step_result(world, step_results.size(), {"type": "timed_effect"}, timed_result)
				running = false
				break
		if not bool(result.get("success", false)):
			running = false
			break
	var failed_steps := _count_failed_steps()
	return {
		"exit_code": 0 if failed_steps == 0 else 1,
		"failed_steps": failed_steps,
		"report": build_report(world)
	}

func step(world: RefCounted) -> Dictionary:
	if not running or index >= steps.size():
		running = false
		return {"success": false, "message": "demo finished"}
	var item: Dictionary = steps[index]
	var step_index := index
	index += 1
	var result := {"success": false, "message": "unknown demo step"}
	match str(item.get("type", "")):
		"set_player":
			world.player_pos = _to_vec2i(item.get("pos", world.player_pos))
			world.facing = _to_vec2i(item.get("facing", world.facing))
			world.update_page()
			result = {"success": true, "message": str(item.get("caption", ""))}
		"action":
			result = world.try_player_action(str(item.get("action", "")), _to_vec2i(item.get("direction", Vector2i.ZERO)))
			if not result.get("message", ""):
				result.message = str(item.get("caption", ""))
		"merge":
			result = world.try_merge_entities(_to_vec2i(item.get("from", Vector2i.ZERO)), _to_vec2i(item.get("to", Vector2i.ZERO)))
			result.message = str(item.get("caption", ""))
		"sentence":
			var first_text := str(item.get("first_text", ""))
			var second_text := str(item.get("second_text", ""))
			var target_sentence := str(item.get("target_sentence", ""))
			var first = world.find_first_entity_by_text(first_text)
			var second = world.find_first_entity_by_text(second_text)
			if first and second:
				world.move_entity_to(first.id, second.grid_pos - Vector2i(1, 0))
			var sentence_result: Dictionary = world.check_sentence_rules()
			result = {"success": sentence_result.has(target_sentence), "message": str(item.get("caption", ""))}
	_record_step_result(world, step_index, item, result)
	if index >= steps.size():
		running = false
	return result

func build_report(world: RefCounted) -> Dictionary:
	var player_state: Dictionary = world.get_player_state() if world.has_method("get_player_state") else {}
	return {
		"route_id": route_id,
		"feature_id": feature_id,
		"target_feature_id": target_feature_id,
		"baseline_id": baseline_id,
		"behavior_id": behavior_id,
		"level_id": level_id,
		"steps": step_results.duplicate(true),
		"snapshots": snapshot_paths.duplicate(),
		"failed_steps": _count_failed_steps(),
		"final_state": {
			"player_pos": _vec2i_to_array(player_state.get("grid_pos", Vector2i.ZERO)),
			"facing": _vec2i_to_array(player_state.get("facing", Vector2i.ZERO)),
			"current_page_origin": _vec2i_to_array(world.current_page_origin),
			"rule_state": world.get_rule_state() if world.has_method("get_rule_state") else {}
		}
	}

func write_report(report_path: String, world: RefCounted) -> void:
	var report_file := FileAccess.open(report_path, FileAccess.WRITE)
	if report_file == null:
		return
	report_file.store_string(JSON.stringify(build_report(world), "\t"))

func write_snapshot_png(snapshot_path: String, world: RefCounted) -> void:
	var image := Image.create(world.screen_size.x * 8, world.screen_size.y * 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.04, 0.04, 0.04, 1.0))
	var cell_size := 8
	for entity in world.entities.values():
		var color := Color(0.96, 0.96, 0.96, 1.0)
		if entity.highlighted:
			color = Color(1.0, 0.92, 0.24, 1.0)
		for cell in entity.cells:
			var local_cell: Vector2i = cell - world.current_page_origin
			if local_cell.x < 0 or local_cell.y < 0 or local_cell.x >= world.screen_size.x or local_cell.y >= world.screen_size.y:
				continue
			image.fill_rect(Rect2i(local_cell.x * cell_size, local_cell.y * cell_size, cell_size, cell_size), color)
	if world.player_visible:
		var player_local: Vector2i = world.player_pos - world.current_page_origin
		if player_local.x >= 0 and player_local.y >= 0 and player_local.x < world.screen_size.x and player_local.y < world.screen_size.y:
			image.fill_rect(Rect2i(player_local.x * cell_size, player_local.y * cell_size, cell_size, cell_size), Color(0.92, 0.28, 0.28, 1.0))
	image.save_png(snapshot_path)
	snapshot_paths.append(snapshot_path.replace("\\", "/"))

func _record_step_result(world: RefCounted, step_index: int, item: Dictionary, result: Dictionary) -> void:
	var player_state: Dictionary = world.get_player_state() if world.has_method("get_player_state") else {}
	step_results.append({
		"index": step_index,
		"type": str(item.get("type", "")),
		"success": bool(result.get("success", false)),
		"message": str(result.get("message", "")),
		"player_pos": _vec2i_to_array(player_state.get("grid_pos", Vector2i.ZERO)),
		"facing": _vec2i_to_array(player_state.get("facing", Vector2i.ZERO))
	})

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

func _default_steps() -> Array[Dictionary]:
	return [
		{"type": "set_player", "pos": Vector2i(3, 1), "facing": Vector2i.RIGHT, "caption": "move to watch"},
		{"type": "action", "action": "interact", "direction": Vector2i.ZERO},
		{"type": "set_player", "pos": Vector2i(4, 2), "facing": Vector2i.RIGHT, "caption": "face deletable word"},
		{"type": "action", "action": "delete", "direction": Vector2i.ZERO},
		{"type": "set_player", "pos": Vector2i(6, 1), "facing": Vector2i.RIGHT, "caption": "push stone"},
		{"type": "action", "action": "move", "direction": Vector2i.RIGHT},
		{"type": "set_player", "pos": Vector2i(9, 1), "facing": Vector2i.LEFT, "caption": "prepare pull"},
		{"type": "action", "action": "pull", "direction": Vector2i.RIGHT},
		{"type": "set_player", "pos": Vector2i(7, 2), "facing": Vector2i.RIGHT, "caption": "prepare split"},
		{"type": "action", "action": "split", "direction": Vector2i.ZERO},
		{"type": "merge", "from": Vector2i(8, 2), "to": Vector2i(9, 2), "caption": "merge split parts"},
		{
			"type": "sentence",
			"first_text": "天",
			"second_text": "气",
			"target_sentence": "天气",
			"caption": "trigger sentence rule"
		},
		{"type": "set_player", "pos": Vector2i(31, 1), "facing": Vector2i.RIGHT, "caption": "move to page edge"},
		{"type": "action", "action": "move", "direction": Vector2i.RIGHT}
	]

func _count_failed_steps() -> int:
	var count := 0
	for step_result in step_results:
		if not bool(step_result.get("success", false)):
			count += 1
	return count
