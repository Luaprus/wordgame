extends Node2D

const CELL_SIZE := 60.0
const GRID_SIZE := Vector2i(32, 18)
const GRID_COLOR := Color(1, 1, 1, 0.035)
const FONT_SIZE := 54
const FONT_SCALE := 1.12

const INTRO_TEXT := "一条溪水阻挡前路。旁边的乔木\n很熟悉，我感觉应该帮得上忙。"
const TREE_TEXT := "＿樹\n樹樹樹\n＿木"
const DIALOG_POS := Vector2(2, 3) * CELL_SIZE
const TREE_POS := Vector2(14, 8) * CELL_SIZE

var font := preload("res://Fonts/Zpix.tres")

func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var width := GRID_SIZE.x * CELL_SIZE
	var height := GRID_SIZE.y * CELL_SIZE
	draw_rect(Rect2(Vector2.ZERO, Vector2(width, height)), Color("#080808"))

	for x in range(GRID_SIZE.x + 1):
		var px := x * CELL_SIZE
		draw_line(Vector2(px, 0), Vector2(px, height), GRID_COLOR, 1.0)

	for y in range(GRID_SIZE.y + 1):
		var py := y * CELL_SIZE
		draw_line(Vector2(0, py), Vector2(width, py), GRID_COLOR, 1.0)

	_draw_word_block(INTRO_TEXT, DIALOG_POS, Color.WHITE, false)
	_draw_word_block(TREE_TEXT, TREE_POS, Color.WHITE, true)


func _draw_word_block(text: String, top_left: Vector2, color: Color, draw_background: bool) -> void:
	var glyph_size := FONT_SIZE * FONT_SCALE
	var lines := text.replace("\r\n", "\n").split("\n")

	for y in lines.size():
		var line := String(lines[y])
		for x in line.length():
			var character := line[x]
			if _is_blank_placeholder(character):
				continue

			var glyph_origin := top_left + Vector2(CELL_SIZE * x + CELL_SIZE / 2.0, CELL_SIZE * y + CELL_SIZE / 2.0)
			if draw_background:
				draw_rect(
					Rect2(
						glyph_origin - Vector2(glyph_size, glyph_size) / 2.0,
						Vector2(glyph_size, glyph_size)
					),
					Color.BLACK
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
				color
			)


func _is_blank_placeholder(character: String) -> bool:
	return character in ["", "\uFF3F", "_", "\u3000", " "]
