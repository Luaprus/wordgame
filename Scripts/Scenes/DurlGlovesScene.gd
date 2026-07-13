extends Control

const CELL_SIZE := 60.0
const GRID_SIZE := Vector2i(32, 18)
const GRID_COLOR := Color(1, 1, 1, 0.035)
const BACKGROUND_COLOR := Color("#080808")
const FONT_SIZE := 54
const FONT_SCALE := 1.12
const HERO_TEXT := "勇"
const HERO_COLUMNS_PER_SIDE := 5
const HERO_ROWS := 9
const LEFT_START_COL := 0
const RIGHT_START_COL := GRID_SIZE.x - HERO_COLUMNS_PER_SIDE
const TOP_START_ROW := 0

const HERO_COLOR_GRID := [
	[
		Color8(92, 90, 14),
		Color8(78, 77, 19),
		Color8(123, 120, 88),
		Color8(118, 117, 92),
		Color8(108, 107, 83),
	],
	[
		Color8(203, 206, 85),
		Color8(203, 205, 145),
		Color8(208, 205, 162),
		Color8(204, 202, 142),
		Color8(203, 203, 95),
	],
	[
		Color8(72, 72, 58),
		Color8(58, 59, 50),
		Color8(98, 97, 84),
		Color8(103, 102, 59),
		Color8(92, 87, 40),
	],
	[
		Color8(205, 205, 158),
		Color8(208, 206, 149),
		Color8(204, 205, 95),
		Color8(202, 204, 41),
		Color8(201, 206, 26),
	],
	[
		Color8(169, 167, 116),
		Color8(181, 181, 87),
		Color8(112, 110, 0),
		Color8(127, 126, 2),
		Color8(148, 149, 21),
	],
	[
		Color8(203, 203, 99),
		Color8(204, 203, 44),
		Color8(200, 203, 26),
		Color8(202, 205, 36),
		Color8(207, 207, 82),
	],
	[
		Color8(93, 93, 30),
		Color8(95, 95, 22),
		Color8(91, 93, 19),
		Color8(89, 92, 39),
		Color8(94, 94, 62),
	],
	[
		Color8(73, 76, 1),
		Color8(80, 83, 21),
		Color8(87, 91, 19),
		Color8(61, 63, 21),
		Color8(67, 66, 37),
	],
	[
		Color8(203, 204, 44),
		Color8(201, 204, 52),
		Color8(207, 208, 92),
		Color8(203, 207, 143),
		Color8(203, 203, 158),
	],
]

var font := preload("res://Fonts/Zpix.tres")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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

	_draw_hero_bank(LEFT_START_COL, false)
	_draw_hero_bank(RIGHT_START_COL, true)


func _draw_hero_bank(start_col: int, mirror_colors: bool) -> void:
	for row in range(HERO_ROWS):
		for col in range(HERO_COLUMNS_PER_SIDE):
			var color_index := HERO_COLUMNS_PER_SIDE - 1 - col if mirror_colors else col
			_draw_hero(Vector2i(start_col + col, TOP_START_ROW + row), HERO_COLOR_GRID[row][color_index])


func _draw_hero(grid_pos: Vector2i, color: Color) -> void:
	var glyph_origin := Vector2(
		grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
		grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0
	)
	draw_string(
		font,
		glyph_origin + Vector2(
			FONT_SIZE * (FONT_SCALE - 1.1) / 2.0 - FONT_SIZE * FONT_SCALE / 2.0,
			FONT_SIZE * (FONT_SCALE / 2.0 + 0.26) - FONT_SIZE * FONT_SCALE / 2.0
		),
		HERO_TEXT,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		FONT_SIZE,
		color
	)
