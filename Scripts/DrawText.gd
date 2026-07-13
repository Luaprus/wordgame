@tool
extends Sprite2D

const CELL_SIZE := float(GameConfigRules.CELL_SIZE.x)
const FONT_SIZE := 54
const FONT_SCALE := 1.12

var font := preload("res://Fonts/Zpix.tres")
const TextureTextResourse := preload("res://Scenes/Events/TextureText.tscn")

@export_multiline var text := "":
	set(value):
		text = value
		update_draw()

@export var text_color: Color = Color.WHITE:
	set(value):
		text_color = value
		update_draw()

@export var has_background := true:
	set(value):
		has_background = value
		update_draw()

@export var render_type := "canvas_draw":
	set(value):
		render_type = value
		update_draw()

@export var is_tofu := false:
	set(value):
		is_tofu = value
		update_draw()

var text_wh := Vector2.ZERO
var tag := "default"
var is_dissolving := false
var is_crashing := false

signal text_drawn
signal dissolve_tween_completed
signal crash_tween_completed
signal draw_text_to_sprite_complete

var vport: SubViewport


func _ready() -> void:
	if not Engine.is_editor_hint() and texture == null and ResourceLoader.exists("res://Sprites/base_transparent.png"):
		texture = load("res://Sprites/base_transparent.png")
	queue_redraw()


func _on_WordSprite_tree_entered() -> void:
	update_draw()


func update_draw() -> void:
	queue_redraw()


func _draw() -> void:
	draw_text()


func draw_text() -> void:
	var glyph_size := FONT_SIZE * FONT_SCALE
	var lines := text.replace("\r\n", "\n").split("\n")
	text_wh = Vector2.ZERO
	text_wh.y = lines.size()

	for y in lines.size():
		var line := String(lines[y])
		text_wh.x = max(text_wh.x, line.length())
		for x in line.length():
			var character := line[x]
			var glyph_origin := Vector2(CELL_SIZE * x, CELL_SIZE * y)
			if has_background:
				draw_rect(
					Rect2(
						glyph_origin - Vector2(glyph_size, glyph_size) / 2.0,
						Vector2(glyph_size, glyph_size)
					),
					Color.BLACK
				)

			if _is_blank_placeholder(character):
				continue

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

	text_drawn.emit()


func draw_text_to_sprite() -> void:
	if not get_parent():
		return

	var lines := text.replace("\r\n", "\n").split("\n")
	text_wh = Vector2.ZERO
	text_wh.y = lines.size()
	for line in lines:
		text_wh.x = max(text_wh.x, String(line).length())

	centered = false
	offset = Vector2(-30, -30)

	vport = TextureTextResourse.instantiate()
	var cvitem := vport.get_child(0)
	vport.size = Vector2(max(text_wh.x, 1.0) * CELL_SIZE, max(text_wh.y, 1.0) * CELL_SIZE)
	cvitem.has_background = has_background
	cvitem.text_color = text_color
	cvitem.text = text

	add_child(vport)
	await RenderingServer.frame_post_draw

	if "has_sprite_animation" in get_parent() and get_parent().has_sprite_animation:
		return

	hframes = 1
	vframes = 1
	frame = 0

	await RenderingServer.frame_post_draw

	texture = ImageTexture.create_from_image(vport.get_texture().get_image())
	centered = true
	position = position - Vector2(30, 30) + Vector2(text_wh.x * 30, text_wh.y * 30)
	offset = Vector2.ZERO

	if is_ancestor_of(vport):
		remove_child(vport)
		vport.queue_free()
	elif has_node("SubViewport"):
		get_node("SubViewport").queue_free()

	render_type = "sprite"
	queue_redraw()

	draw_text_to_sprite_complete.emit()


func _is_blank_placeholder(character: String) -> bool:
	return character in ["", "\uFF3F", "_", "\u3000", " "]


func dissolve(_time := 1.0) -> void:
	is_dissolving = false
	dissolve_tween_completed.emit()


func crash(_time := 1.0) -> void:
	is_crashing = false
	crash_tween_completed.emit()


func is_in_tofu_white_list(_text: String) -> bool:
	return true
