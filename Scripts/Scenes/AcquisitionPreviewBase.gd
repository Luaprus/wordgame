extends Control

const CELL_SIZE := 60.0
const GRID_SIZE := Vector2i(32, 18)
const GRID_COLOR := Color(1, 1, 1, 0.12)
const BACKGROUND_COLOR := Color("#080808")
const TITLE_COLOR := Color(0.92, 0.92, 0.92, 1.0)
const META_COLOR := Color(0.62, 0.62, 0.62, 1.0)

var preview_font := preload("res://Fonts/Zpix.tres")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_label_style($TitleLabel, 32, TITLE_COLOR)
	_apply_label_style($KeywordLabel, 20, META_COLOR)
	_apply_label_style($HintLabel, 18, META_COLOR)
	queue_redraw()


func _draw() -> void:
	var width := GRID_SIZE.x * CELL_SIZE
	var height := GRID_SIZE.y * CELL_SIZE
	draw_rect(Rect2(Vector2.ZERO, Vector2(width, height)), BACKGROUND_COLOR)

	for x in range(GRID_SIZE.x + 1):
		var px := x * CELL_SIZE
		draw_line(Vector2(px, 0), Vector2(px, height), GRID_COLOR, 1.0)

	for y in range(GRID_SIZE.y + 1):
		var py := y * CELL_SIZE
		draw_line(Vector2(0, py), Vector2(width, py), GRID_COLOR, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()


func setup_preview(title: String, keywords: PackedStringArray, source_map: String) -> void:
	var keyword_list: Array[String] = []
	for keyword in keywords:
		keyword_list.append(keyword)

	$TitleLabel.text = title
	$KeywordLabel.text = "关键词: " + ", ".join(keyword_list)
	$HintLabel.text = "源地图: %s    Enter/Space 重播" % source_map


func root_relative_path(node: Node) -> String:
	return str(get_tree().get_root().get_path_to(node))


func _apply_label_style(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_override("font", preview_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
