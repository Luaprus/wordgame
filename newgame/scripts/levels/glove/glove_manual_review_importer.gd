extends RefCounted

const DEFAULT_OUTPUT_PATH := "res://../harness/demo_routes/glove/manual_review_overrides.json"

func import_review_result(input_path: String, output_path: String = DEFAULT_OUTPUT_PATH) -> Dictionary:
	var input_doc := _load_json_dictionary(input_path)
	if input_doc.is_empty():
		return {
			"success": false,
			"message": "input review json missing or unreadable"
		}
	var normalized := _normalize_review_document(input_doc)
	if normalized.is_empty():
		return {
			"success": false,
			"message": "input review json could not be normalized"
		}
	_write_json_file(ProjectSettings.globalize_path(output_path), normalized)
	return {
		"success": true,
		"output_path": ProjectSettings.globalize_path(output_path).replace("\\", "/"),
		"checkpoint_review_count": int(normalized.get("checkpoint_reviews", []).size()),
		"route_step_review_count": int(normalized.get("route_step_reviews", []).size()),
		"focus_review_count": int(normalized.get("focus_reviews", []).size())
	}

func _normalize_review_document(input_doc: Dictionary) -> Dictionary:
	var checkpoint_reviews: Array[Dictionary] = []
	var seen_checkpoint_keys: Dictionary = {}
	for review_variant in input_doc.get("checkpoint_reviews", []):
		if not (review_variant is Dictionary):
			continue
		var review := _normalize_checkpoint_review(review_variant as Dictionary)
		if review.is_empty():
			continue
		var dedupe_key := _checkpoint_key(review)
		seen_checkpoint_keys[dedupe_key] = review
	for dedupe_key in seen_checkpoint_keys.keys():
		checkpoint_reviews.append((seen_checkpoint_keys[dedupe_key] as Dictionary).duplicate(true))

	var route_step_reviews: Array[Dictionary] = []
	var seen_route_step_keys: Dictionary = {}
	for review_variant in input_doc.get("route_step_reviews", []):
		if not (review_variant is Dictionary):
			continue
		var review := _normalize_route_step_review(review_variant as Dictionary)
		if review.is_empty():
			continue
		seen_route_step_keys[_route_step_key(review)] = review
	for route_step_key in seen_route_step_keys.keys():
		route_step_reviews.append((seen_route_step_keys[route_step_key] as Dictionary).duplicate(true))

	var focus_reviews: Array[Dictionary] = []
	var seen_focus_keys: Dictionary = {}
	for focus_variant in input_doc.get("focus_reviews", []):
		if not (focus_variant is Dictionary):
			continue
		var review := _normalize_focus_review(focus_variant as Dictionary)
		if review.is_empty():
			continue
		seen_focus_keys[str(review.get("focus", ""))] = review
	for focus_key in seen_focus_keys.keys():
		focus_reviews.append((seen_focus_keys[focus_key] as Dictionary).duplicate(true))

	return {
		"level_id": "glove",
		"updated_at": Time.get_datetime_string_from_system(false, true),
		"checkpoint_reviews": checkpoint_reviews,
		"route_step_reviews": route_step_reviews,
		"focus_reviews": focus_reviews
	}

func _normalize_checkpoint_review(review: Dictionary) -> Dictionary:
	var checkpoint_id := _first_non_empty_string(review, ["id", "checkpoint_id"])
	var ref := _first_non_empty_string(review, ["ref", "screenshot_ref"])
	var source_grid_id := _first_non_empty_string(review, ["source_grid_id", "grid_ref"])
	var route_id := _first_non_empty_string(review, ["route_id"])
	var status := _normalize_review_status(_first_non_empty_string(review, ["review_status", "status"]))
	if checkpoint_id.is_empty() or ref.is_empty() or source_grid_id.is_empty():
		return {}
	return {
		"id": checkpoint_id,
		"ref": ref,
		"source_grid_id": source_grid_id,
		"route_id": route_id,
		"review_status": status,
		"reviewer": _first_non_empty_string(review, ["reviewer", "actor"]),
		"reviewed_at": _first_non_empty_string(review, ["reviewed_at", "time"]),
		"resolution_note": _first_non_empty_string(review, ["resolution_note", "note", "comment"])
	}

func _normalize_focus_review(review: Dictionary) -> Dictionary:
	var focus := _first_non_empty_string(review, ["focus", "manual_review_focus"])
	if focus.is_empty():
		return {}
	return {
		"focus": focus,
		"review_status": _normalize_focus_status(_first_non_empty_string(review, ["review_status", "status"])),
		"reviewer": _first_non_empty_string(review, ["reviewer", "actor"]),
		"reviewed_at": _first_non_empty_string(review, ["reviewed_at", "time"]),
		"resolution_note": _first_non_empty_string(review, ["resolution_note", "note", "comment"])
	}

func _normalize_route_step_review(review: Dictionary) -> Dictionary:
	var route_id := _first_non_empty_string(review, ["route_id"])
	var step_index_raw := _first_non_empty_string(review, ["step_index"])
	var step_index := int(step_index_raw) if not step_index_raw.is_empty() else -1
	if route_id.is_empty() or step_index < 0:
		return {}
	return {
		"route_id": route_id,
		"step_index": step_index,
		"caption": _first_non_empty_string(review, ["caption"]),
		"review_status": _normalize_review_status(_first_non_empty_string(review, ["review_status", "status"])),
		"reviewer": _first_non_empty_string(review, ["reviewer", "actor"]),
		"reviewed_at": _first_non_empty_string(review, ["reviewed_at", "time"]),
		"resolution_note": _first_non_empty_string(review, ["resolution_note", "note", "comment"])
	}

func _first_non_empty_string(review: Dictionary, keys: Array[String]) -> String:
	for key in keys:
		var value := str(review.get(key, "")).strip_edges()
		if not value.is_empty():
			return value
	return ""

func _normalize_review_status(raw_status: String) -> String:
	match raw_status:
		"confirmed", "人工确认", "通过", "pass":
			return "confirmed"
		"rejected", "人工驳回", "不一致", "fail":
			return "rejected"
		_:
			return "pending"

func _normalize_focus_status(raw_status: String) -> String:
	match raw_status:
		"resolved", "已解决", "confirmed", "人工确认":
			return "resolved"
		"rejected", "人工驳回":
			return "rejected"
		_:
			return "pending"

func _checkpoint_key(review: Dictionary) -> String:
	return "%s|%s|%s" % [
		str(review.get("id", "")),
		str(review.get("ref", "")),
		str(review.get("source_grid_id", ""))
	]

func _route_step_key(review: Dictionary) -> String:
	return "%s|%s" % [
		str(review.get("route_id", "")),
		str(review.get("step_index", -1))
	]

func _load_json_dictionary(path: String) -> Dictionary:
	var actual_path := path
	if path.begins_with("res://") or path.begins_with("user://"):
		actual_path = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(actual_path):
		return {}
	var file := FileAccess.open(actual_path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return (parsed as Dictionary).duplicate(true)
	return {}

func _write_json_file(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload, "\t"))
