@tool
extends Node2D

const CELL_SIZE := 60.0
const FRAME_COLUMNS := 30
const FRAME_ROWS := 5
const DEFAULT_RIVER_SHAPE := "＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿溪溪溪溪溪"

@export_multiline var river_shape := DEFAULT_RIVER_SHAPE:
	set(value):
		river_shape = value
		queue_redraw()

@export var text_color := Color(1, 1, 1, 1):
	set(value):
		text_color = value
		queue_redraw()

@export var background_color := Color(0.0, 0.0, 0.0, 1.0):
	set(value):
		background_color = value
		queue_redraw()

@export var animation_fps := 30.0
@export var show_background := true:
	set(value):
		show_background = value
		queue_redraw()

var stream_texture := preload("res://Sprites/ch4_streams/streams.png")
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var lines := river_shape.replace("\r\n", "\n").split("\n")
	var frame_width := float(stream_texture.get_width()) / FRAME_COLUMNS
	var frame_height := float(stream_texture.get_height()) / FRAME_ROWS
	var base_frame := int(floor(_time * animation_fps)) % FRAME_COLUMNS
	var cells := _get_occupied_cells(lines)
	if cells.is_empty():
		return
	var min_x := cells[0].x
	var min_y := cells[0].y
	for cell in cells:
		min_x = min(min_x, cell.x)
		min_y = min(min_y, cell.y)

	for cell in cells:
		var local_x := int(cell.x - min_x)
		var local_y := int(cell.y - min_y)
		var draw_pos := Vector2(CELL_SIZE * local_x, CELL_SIZE * local_y)
		if show_background:
			draw_rect(Rect2(draw_pos, Vector2(CELL_SIZE, CELL_SIZE)), background_color)

		var frame := posmod(base_frame - local_x, FRAME_COLUMNS)
		var variant_row := local_y % FRAME_ROWS
		var region := Rect2(
			Vector2(frame * frame_width, variant_row * frame_height),
			Vector2(frame_width, frame_height)
		)
		draw_texture_rect_region(
			stream_texture,
			Rect2(draw_pos, Vector2(CELL_SIZE, CELL_SIZE)),
			region,
			text_color
		)


func _get_occupied_cells(lines: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in lines.size():
		var line := String(lines[y])
		for x in line.length():
			var character := line.substr(x, 1)
			if _is_blank_placeholder(character):
				continue
			cells.append(Vector2i(x, y))
	return cells


func _is_blank_placeholder(character: String) -> bool:
	return character in ["", "\uFF3F", "_", "\u3000", " "]
