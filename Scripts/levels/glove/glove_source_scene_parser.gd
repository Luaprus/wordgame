extends RefCounted

const SOURCE_SCENE_PATH := "res://../参考资料/文字游戏源码/文字遊戲_pck/res/Scenes/Maps/第三章/15_添譜來堂_拳頭.tscn"
const PT_SOURCE_SCENE_PATH := "res://../参考资料/文字游戏源码/文字遊戲_pck/res/Scenes/Maps/第三章/50_添譜來堂_拳頭PT用.tscn"
const TYPEWRITER_INTRO_SCENE_PATH := "res://../参考资料/文字游戏源码/文字遊戲_pck/res/Scenes/Maps/測試用/map0001.tscn"
const TYPEWRITER_SAMPLE_SCENE_PATH := "res://../参考资料/文字游戏源码/文字遊戲_pck/res/Scenes/Maps/測試用/map0002.tscn"

const STATE_TO_NODE_NAME := {
	"zero": "零的手勢",
	"like": "好的手勢",
	"one": "一的手勢",
	"two": "二的手勢",
	"win": "贏的手勢",
	"love": "愛的手勢",
	"release": "放開手勢"
}

const TYPEWRITER_SCRIPT_PATH := "res://../鍙傝€冭祫鏂?鏂囧瓧娓告垙婧愮爜/鏂囧瓧閬婃埐_pck/res/Scripts/Typewriter.gdc"

func extract_gesture_shapes() -> Dictionary:
	var source_text := _read_source_scene_text()
	if source_text.is_empty():
		return {}

	var shapes := {}
	for state_name in STATE_TO_NODE_NAME.keys():
		var node_name := str(STATE_TO_NODE_NAME[state_name])
		var raw_big_text := _extract_node_big_text(source_text, node_name)
		if raw_big_text.is_empty():
			continue
		shapes[state_name] = _normalize_big_text(raw_big_text)
	return shapes

func extract_love_word_source_details() -> Dictionary:
	var source_text := _read_source_scene_text()
	if source_text.is_empty():
		return {}

	var node_name := str(STATE_TO_NODE_NAME.get("zero", ""))
	if node_name.is_empty():
		return {}
	var node_block := _extract_node_block(source_text, node_name)
	if node_block.is_empty():
		return {}
	var commands_text := _extract_quoted_property(node_block, "commands = \"")
	if commands_text.is_empty():
		return {}

	var typed_texts_raw := _extract_escaped_string_property(commands_text, "\\\"texts\\\": \\\"")
	var label_tag := _extract_tag_name(typed_texts_raw)
	var typed_text_pos := _extract_int_array(commands_text, "\\\"pos\\\": [", "]")
	var label_grid_candidate: Array[int] = []
	var opening_tag := "<%s>" % label_tag
	var tag_index := typed_texts_raw.find(opening_tag)
	if typed_text_pos.size() >= 2 and tag_index >= 0:
		var visible_prefix := typed_texts_raw.substr(0, tag_index).replace("||", "").replace("&", "")
		label_grid_candidate = [int(typed_text_pos[0]) + visible_prefix.length(), int(typed_text_pos[1])]
	return {
		"source_scene_node": node_name,
		"typed_texts_raw": typed_texts_raw,
		"typed_text_pos": typed_text_pos,
		"computed_label_grid_candidate": label_grid_candidate,
		"computed_label_grid_method": "type 起点 x + 标签前可见字符数；标签标记与停顿控制符不占格",
		"computed_label_grid_status": "source_inference",
		"pushable_label_tag": label_tag,
		"pushable_label_text": _extract_tagged_text(typed_texts_raw, label_tag),
		"label_can_push": _extract_label_can_push(commands_text, label_tag),
		"gating_condition": _extract_if_condition(commands_text),
		"commands_excerpt": _extract_type_block(commands_text).replace("\\\"", "\"")
	}

func extract_love_gesture_state_details() -> Dictionary:
	var source_text := _read_text_file(SOURCE_SCENE_PATH)
	var pt_scene_text := _read_text_file(PT_SOURCE_SCENE_PATH)
	if source_text.is_empty() or pt_scene_text.is_empty():
		return {}

	var love_gesture_block := _extract_node_block_by_snippet(source_text, "3-5")
	if love_gesture_block.is_empty():
		return {}

	var state_values := _extract_int_array(love_gesture_block, "\\\"arg_array\\\": [", "]")
	var love_state_value := state_values[0] if not state_values.is_empty() else -1
	var pt_love_test_node := "T_愛的手勢" if pt_scene_text.contains("T_愛的手勢") else ""
	return {
		"source_path": ProjectSettings.globalize_path(SOURCE_SCENE_PATH).replace("\\", "/"),
		"love_state_value": int(love_state_value),
		"love_activation_switch": "ch3_愛的手勢成立",
		"first_love_switch": "ch3_第一次愛的手勢",
		"achievement_id": _extract_set_achievement_id(love_gesture_block),
		"pt_source_path": ProjectSettings.globalize_path(PT_SOURCE_SCENE_PATH).replace("\\", "/"),
		"pt_love_test_node": pt_love_test_node
	}

func extract_typewriter_layer_reference_details() -> Dictionary:
	var intro_text := _read_text_file(TYPEWRITER_INTRO_SCENE_PATH)
	var sample_text := _read_text_file(TYPEWRITER_SAMPLE_SCENE_PATH)
	if intro_text.is_empty() or sample_text.is_empty():
		return {}

	var intro_block := _extract_node_block_by_snippet(intro_text, "@[clear_typed] \\\"typed\\\"")
	var sample_block := _extract_node_block_by_snippet(sample_text, "@[clear_typed] \\\"room\\\"")
	if intro_block.is_empty() or sample_block.is_empty():
		return {}

	return {
		"intro_source_path": ProjectSettings.globalize_path(TYPEWRITER_INTRO_SCENE_PATH).replace("\\", "/"),
		"intro_clear_tag": "typed",
		"intro_typed_pos": _extract_int_array(intro_block, "\\\"pos\\\":[", "]"),
		"sample_source_path": ProjectSettings.globalize_path(TYPEWRITER_SAMPLE_SCENE_PATH).replace("\\", "/"),
		"sample_clear_tag": "room",
		"sample_tag": _extract_first_array_string(sample_block, "\\\"tags\\\":[\\\"", "\\\""),
		"sample_event_now_pos": _extract_vector2_array(sample_block, "now_pos = Vector2( ", " )"),
		"sample_typed_pos": _extract_int_array(sample_block, "\\\"pos\\\":[", "]")
	}

func extract_typewriter_runtime_generation_details() -> Dictionary:
	var typewriter_script_path := _resolve_typewriter_script_path()
	if typewriter_script_path.is_empty():
		return {}
	var typewriter_bytes := _read_binary_file(typewriter_script_path)
	if typewriter_bytes.is_empty():
		return {}

	var has_generated_in_runtime := _binary_has_ascii_token(typewriter_bytes, "generated_in_runtime")
	var has_exist_event := _binary_has_ascii_token(typewriter_bytes, "exist_event")
	var has_both := _binary_has_ascii_token(typewriter_bytes, "both")
	var has_copy := _binary_has_ascii_token(typewriter_bytes, "copy")
	var has_label_settings := _binary_has_ascii_token(typewriter_bytes, "label_settings")
	var has_default_tag := _binary_has_ascii_token(typewriter_bytes, "has_defalut_tag")
	var supports_runtime_pushable_label_inference := (
		has_generated_in_runtime
		and has_exist_event
		and has_both
		and has_copy
		and has_label_settings
		and has_default_tag
	)

	return {
		"source_path": typewriter_script_path,
		"contains_generated_in_runtime": has_generated_in_runtime,
		"contains_exist_event": has_exist_event,
		"contains_both": has_both,
		"contains_copy": has_copy,
		"contains_label_settings": has_label_settings,
		"contains_has_default_tag": has_default_tag,
		"supports_runtime_pushable_label_inference": supports_runtime_pushable_label_inference
	}

func _read_source_scene_text() -> String:
	return _read_text_file(SOURCE_SCENE_PATH)

func _extract_node_big_text(source_text: String, node_name: String) -> String:
	var node_block := _extract_node_block(source_text, node_name)
	if node_block.is_empty():
		return ""
	return _extract_quoted_property(node_block, "big_text = \"")

func _normalize_big_text(raw_big_text: String) -> Array[String]:
	var lines: Array[String] = []
	for line_variant in raw_big_text.replace("\r", "").split("\n"):
		lines.append(String(line_variant).replace("＿", " ").replace("　", " "))

	while not lines.is_empty() and lines[0].strip_edges().is_empty():
		lines.remove_at(0)
	while not lines.is_empty() and lines[lines.size() - 1].strip_edges().is_empty():
		lines.remove_at(lines.size() - 1)
	return lines

func _extract_node_block(source_text: String, node_name: String) -> String:
	var node_marker := "[node name=\"%s\"" % node_name
	var node_start := source_text.find(node_marker)
	if node_start == -1:
		return ""

	var next_node_start := source_text.find("\n[node name=", node_start + node_marker.length())
	return source_text.substr(
		node_start,
		(next_node_start if next_node_start != -1 else source_text.length()) - node_start
	)

func _extract_node_block_by_snippet(source_text: String, snippet: String) -> String:
	var snippet_index := source_text.find(snippet)
	if snippet_index == -1:
		return ""
	var node_start := source_text.rfind("[node name=\"", snippet_index)
	if node_start == -1:
		return ""
	var next_node_start := source_text.find("\n[node name=", snippet_index)
	return source_text.substr(
		node_start,
		(next_node_start if next_node_start != -1 else source_text.length()) - node_start
	)

func _extract_quoted_property(block_text: String, property_marker: String) -> String:
	var value_start := block_text.find(property_marker)
	if value_start == -1:
		return ""
	value_start += property_marker.length()
	var value_end := _find_unescaped_quote(block_text, value_start)
	if value_end == -1:
		return ""
	return block_text.substr(value_start, value_end - value_start)

func _extract_escaped_string_property(text: String, property_marker: String) -> String:
	var value_start := text.find(property_marker)
	if value_start == -1:
		return ""
	value_start += property_marker.length()
	var value_end := text.find("\\\"", value_start)
	if value_end == -1:
		return ""
	return text.substr(value_start, value_end - value_start)

func _find_unescaped_quote(text: String, from_index: int) -> int:
	var escaped := false
	for index in range(from_index, text.length()):
		var char := text.unicode_at(index)
		if escaped:
			escaped = false
			continue
		if char == 92:
			escaped = true
			continue
		if char == 34:
			return index
	return -1

func _extract_int_array(text: String, prefix: String, suffix: String) -> Array[int]:
	var start := text.find(prefix)
	if start == -1:
		return []
	start += prefix.length()
	var finish := text.find(suffix, start)
	if finish == -1:
		return []
	var raw_items := text.substr(start, finish - start).split(",")
	var values: Array[int] = []
	for item in raw_items:
		var trimmed := String(item).strip_edges()
		if trimmed.is_empty():
			continue
		values.append(int(trimmed))
	return values

func _extract_vector2_array(text: String, prefix: String, suffix: String) -> Array[int]:
	var start := text.find(prefix)
	if start == -1:
		return []
	start += prefix.length()
	var finish := text.find(suffix, start)
	if finish == -1:
		return []
	var raw_items := text.substr(start, finish - start).split(",")
	var values: Array[int] = []
	for item in raw_items:
		var trimmed := String(item).strip_edges()
		if trimmed.is_empty():
			continue
		values.append(int(float(trimmed)))
	return values

func _extract_first_array_string(text: String, prefix: String, suffix: String) -> String:
	var start := text.find(prefix)
	if start == -1:
		return ""
	start += prefix.length()
	var finish := text.find(suffix, start)
	if finish == -1:
		return ""
	return text.substr(start, finish - start)

func _extract_set_achievement_id(text: String) -> String:
	var prefix := "@[set_achievement] \\\""
	var start := text.find(prefix)
	if start == -1:
		return ""
	start += prefix.length()
	var finish := text.find("\\\"", start)
	if finish == -1:
		return ""
	return text.substr(start, finish - start)

func _extract_first_node_name_with_token(source_text: String, token: String) -> String:
	var block := _extract_node_block_by_snippet(source_text, token)
	if block.is_empty():
		return ""
	var prefix := "[node name=\""
	var start := block.find(prefix)
	if start == -1:
		return ""
	start += prefix.length()
	var finish := block.find("\"", start)
	if finish == -1:
		return ""
	return block.substr(start, finish - start)

func _extract_tag_name(text: String) -> String:
	var tag_start := text.find("<")
	if tag_start == -1:
		return ""
	var tag_end := text.find(">", tag_start + 1)
	if tag_end == -1:
		return ""
	return text.substr(tag_start + 1, tag_end - tag_start - 1)

func _extract_tagged_text(text: String, tag_name: String) -> String:
	if tag_name.is_empty():
		return ""
	var start_token := "<%s>" % tag_name
	var end_token := "</%s>" % tag_name
	var start := text.find(start_token)
	if start == -1:
		return ""
	start += start_token.length()
	var finish := text.find(end_token, start)
	if finish == -1:
		return ""
	return text.substr(start, finish - start)

func _extract_label_can_push(commands_text: String, tag_name: String) -> bool:
	if tag_name.is_empty():
		return false
	var label_marker := "\\\"%s\\\": {" % tag_name
	var label_start := commands_text.find(label_marker)
	if label_start == -1:
		return false
	var label_block := commands_text.substr(label_start, mini(160, commands_text.length() - label_start))
	return label_block.contains("\\\"can_push\\\": true")

func _extract_if_condition(commands_text: String) -> String:
	var prefix := "@[if] \\\""
	var start := commands_text.find(prefix)
	if start == -1:
		return ""
	start += prefix.length()
	var finish := commands_text.find("\\\"", start)
	if finish == -1:
		return ""
	return commands_text.substr(start, finish - start)

func _extract_type_block(commands_text: String) -> String:
	var block_start := commands_text.find("@[type] {")
	if block_start == -1:
		return ""
	var block_end := commands_text.find("@[set_switch]", block_start)
	if block_end == -1:
		block_end = commands_text.find("@[end_if]", block_start)
	if block_end == -1:
		return commands_text.substr(block_start).strip_edges()
	return commands_text.substr(block_start, block_end - block_start).strip_edges()

func _read_text_file(path: String) -> String:
	var resolved_path := path
	if path.begins_with("res://") or path.begins_with("user://"):
		resolved_path = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(resolved_path):
		return ""
	var file := FileAccess.open(resolved_path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

func _read_binary_file(path: String) -> PackedByteArray:
	var resolved_path := path
	if path.begins_with("res://") or path.begins_with("user://"):
		resolved_path = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(resolved_path):
		return PackedByteArray()
	var file := FileAccess.open(resolved_path, FileAccess.READ)
	if file == null:
		return PackedByteArray()
	return file.get_buffer(file.get_length())

func _binary_has_ascii_token(bytes: PackedByteArray, token: String) -> bool:
	var token_bytes := token.to_ascii_buffer()
	if token_bytes.is_empty() or bytes.size() < token_bytes.size():
		return false
	for start in range(bytes.size() - token_bytes.size() + 1):
		var matched := true
		for offset in range(token_bytes.size()):
			if bytes[start + offset] != token_bytes[offset]:
				matched = false
				break
		if matched:
			return true
	return false

func _resolve_typewriter_script_path() -> String:
	var source_scene_path := ProjectSettings.globalize_path(SOURCE_SCENE_PATH).replace("\\", "/")
	var marker := "/Scenes/Maps/"
	var marker_index := source_scene_path.find(marker)
	if marker_index == -1:
		return ""
	return "%s/Scripts/Typewriter.gdc" % source_scene_path.substr(0, marker_index)
