@tool
extends Node2D

const CELL_SIZE := 60.0
const FONT_SIZE := 54
const FONT_SCALE := 1.12
const DEFAULT_RIVER_SHAPE := "＿＿＿＿溪溪溪溪溪\n＿＿＿＿溪溪溪溪溪\n＿＿＿＿溪溪溪溪溪\n＿＿＿＿溪溪溪溪溪\n＿＿＿＿溪溪溪溪溪\n＿＿＿＿溪溪溪溪溪\n＿＿＿＿溪溪溪溪溪\n＿＿＿＿溪溪溪溪溪\n＿＿＿＿溪溪溪溪溪\n＿＿＿＿溪溪溪溪溪\n＿＿＿＿溪溪溪溪溪\n＿＿＿＿溪溪溪溪溪\n＿＿＿＿溪溪溪溪溪\n＿＿＿＿溪溪溪溪溪\n＿溪溪溪溪溪溪溪溪\n溪溪溪溪溪溪溪溪溪\n溪溪溪溪溪溪溪溪溪\n溪溪溪溪溪溪溪溪溪\n溪溪溪溪溪\n溪溪溪溪溪"

@export_multiline var river_shape := DEFAULT_RIVER_SHAPE:
	set(value):
		river_shape = value
		queue_redraw()

@export var text_color := Color(0.86, 0.95, 1.0, 0.95):
	set(value):
		text_color = value
		queue_redraw()

@export var background_color := Color(0.0, 0.0, 0.0, 0.82):
	set(value):
		background_color = value
		queue_redraw()

@export var float_amplitude := 4.0
@export var float_speed := 1.65
@export var point_flow_amplitude := 6.0
@export var point_flow_speed := 2.2
@export var show_upper_flow_point := true:
	set(value):
		show_upper_flow_point = value
		queue_redraw()

var font := preload("res://Fonts/Zpix.tres")
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var glyph_size := FONT_SIZE * FONT_SCALE
	var lines := river_shape.replace("\r\n", "\n").split("\n")

	for y in lines.size():
		var line := String(lines[y])
		for x in line.length():
			var character := line[x]
			if _is_blank_placeholder(character):
				continue

			var phase := _time * float_speed + float(x) * 0.37 + float(y) * 0.61
			var bob := sin(phase) * float_amplitude
			var glyph_origin := Vector2(CELL_SIZE * x + CELL_SIZE / 2.0, CELL_SIZE * y + CELL_SIZE / 2.0 + bob)

			draw_rect(
				Rect2(
					glyph_origin - Vector2(glyph_size, glyph_size) / 2.0,
					Vector2(glyph_size, glyph_size)
				),
				background_color
			)

			draw_string(
				font,
				glyph_origin + Vector2(
					FONT_SIZE * (FONT_SCALE - 1.1) / 2.0 - FONT_SIZE * FONT_SCALE / 2.0,
					FONT_SIZE * (FONT_SCALE / 2.0 + 0.26) - FONT_SIZE * FONT_SCALE / 2.0
				),
				character,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				FONT_SIZE,
				text_color
			)

			if show_upper_flow_point:
				_draw_upper_flow_point(x, y, glyph_origin)


func _draw_upper_flow_point(x: int, y: int, glyph_origin: Vector2) -> void:
	var flow_phase := _time * point_flow_speed + float(x) * 0.71 + float(y) * 0.43
	var point_offset := Vector2(
		sin(flow_phase) * point_flow_amplitude,
		cos(flow_phase * 0.8) * float_amplitude
	)
	var point_pos := glyph_origin + Vector2(10.0, -21.0) + point_offset
	var point_color := Color(text_color.r, text_color.g, text_color.b, 0.68)
	draw_circle(point_pos, 3.2, point_color)
	draw_circle(point_pos + Vector2(5.0, -1.0), 1.7, Color(point_color.r, point_color.g, point_color.b, 0.36))


func _is_blank_placeholder(character: String) -> bool:
	return character in ["", "\uFF3F", "_", "\u3000", " "]
