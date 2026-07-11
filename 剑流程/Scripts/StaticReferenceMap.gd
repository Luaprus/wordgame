extends Control

const DATA_PATHS := [
	"res://Data/reference_maze_map.json",
	"res://Data/reference_treasure_room_empty_map.json",
]
const FONT := preload("res://Fonts/Zpix-v3.1.6.ttf")

const BACKGROUND_COLOR := Color.BLACK
const WALL_COLOR := Color(0.58, 0.58, 0.58, 1.0)
const DIALOGUE_COLOR := Color(0.82, 0.82, 0.82, 1.0)
const PLAYER_COLOR := Color(0.86, 0.86, 0.86, 1.0)

var _data: Dictionary
var _cell_size := 60
var _font_size := 56
var _map_index := 0
var _map_layer: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw_background()
	_setup_map_layer()
	_load_data(DATA_PATHS[_map_index])
	_draw_map()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_map_index = (_map_index + 1) % DATA_PATHS.size()
			_load_data(DATA_PATHS[_map_index])
			_draw_map()


func _load_data(data_path: String) -> void:
	var file := FileAccess.open(data_path, FileAccess.READ)
	if file == null:
		push_error("Cannot open map data: %s" % data_path)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Map data is not a JSON object: %s" % data_path)
		return

	_data = parsed
	var grid: Dictionary = _data["grid"]
	_cell_size = int(grid["cell_size"])
	_font_size = int(grid["wall_font_size"])


func _draw_background() -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND_COLOR
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)


func _setup_map_layer() -> void:
	_map_layer = Control.new()
	_map_layer.name = "MapLayer"
	_map_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_map_layer)


func _draw_map() -> void:
	if _data.is_empty():
		return
	for child in _map_layer.get_children():
		child.queue_free()

	var rows: Array = _data["rows"]
	for y in range(rows.size()):
		var row := String(rows[y])
		for x in range(row.length()):
			var text := row.substr(x, 1)
			if text == " ":
				continue
			_draw_cell_text(text, x, y)


func _draw_cell_text(text: String, grid_x: int, grid_y: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = Vector2(grid_x * _cell_size, grid_y * _cell_size)
	label.size = Vector2(_cell_size, _cell_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", _font_size)

	if text == "我":
		label.modulate = PLAYER_COLOR
	elif grid_y >= 14 and grid_y <= 15 and text != "岩" and text != "窟":
		label.modulate = DIALOGUE_COLOR
	else:
		label.modulate = WALL_COLOR

	_map_layer.add_child(label)
