extends Node2D

const TILE_TEXT := "桥"
const TILE_SIZE := Vector2(60.0, 60.0)
const SCENE_SIZE := Vector2(600.0, 420.0)
const FONT_PATH := "res://Fonts/Zpix-v3.1.6.ttf"

const TOP_TILES := [
	{"name": "Top0", "pos": Vector2(30, 30), "rot": 10.0},
	{"name": "Top1", "pos": Vector2(90, 96), "rot": 12.0},
	{"name": "Top2", "pos": Vector2(150, 90), "rot": -8.0},
	{"name": "Top3", "pos": Vector2(210, 90), "rot": 16.0},
	{"name": "Top4", "pos": Vector2(270, 90), "rot": -6.0},
	{"name": "Top5", "pos": Vector2(330, 90), "rot": -12.0},
	{"name": "Top6", "pos": Vector2(390, 90), "rot": 10.0},
	{"name": "Top7", "pos": Vector2(450, 96), "rot": -12.0},
	{"name": "Top8", "pos": Vector2(510, 30), "rot": -8.0}
]

const BOTTOM_TILES := [
	{"name": "Bottom0", "pos": Vector2(30, 270), "rot": 16.0},
	{"name": "Bottom1", "pos": Vector2(90, 216), "rot": 8.0},
	{"name": "Bottom2", "pos": Vector2(150, 210), "rot": -10.0},
	{"name": "Bottom3", "pos": Vector2(210, 210), "rot": -6.0},
	{"name": "Bottom4", "pos": Vector2(270, 210), "rot": 4.0},
	{"name": "Bottom5", "pos": Vector2(330, 210), "rot": -12.0},
	{"name": "Bottom6", "pos": Vector2(390, 210), "rot": -8.0},
	{"name": "Bottom7", "pos": Vector2(450, 216), "rot": 14.0},
	{"name": "Bottom8", "pos": Vector2(510, 270), "rot": 14.0}
]

var _font: FontFile
var _bridge_visual: Node2D
var _water_layer: Node2D
var _falling_player: Node2D
var _animation_player: AnimationPlayer
var _tile_nodes: Array[Node2D] = []
var _mid_blocks: Array[ColorRect] = []


func _ready() -> void:
	_font = load(FONT_PATH) as FontFile
	_build_scene()
	_build_animations()


func _build_scene() -> void:
	_add_background()

	_bridge_visual = Node2D.new()
	_bridge_visual.name = "BridgeVisual"
	add_child(_bridge_visual)

	_water_layer = Node2D.new()
	_water_layer.name = "WaterLayer"
	_bridge_visual.add_child(_water_layer)
	_add_water_strip(Vector2(60, 60), Vector2(420, 60), Color(0.10, 0.53, 0.66, 0.82))
	_add_water_strip(Vector2(60, 180), Vector2(420, 60), Color(0.12, 0.47, 0.71, 0.82))
	_add_water_glow(Vector2(60, 84), Vector2(420, 8), Color(0.70, 0.94, 0.97, 0.40))
	_add_water_glow(Vector2(60, 204), Vector2(420, 8), Color(0.70, 0.94, 0.97, 0.40))

	var mid_block_holder := Node2D.new()
	mid_block_holder.name = "MidBlocks"
	_bridge_visual.add_child(mid_block_holder)
	for index in range(7):
		var block := ColorRect.new()
		block.name = "Block%d" % index
		block.position = Vector2(90 + index * 60, 120)
		block.size = TILE_SIZE
		block.color = Color(0.05, 0.05, 0.08, 1.0)
		mid_block_holder.add_child(block)
		_mid_blocks.append(block)

	var top_holder := Node2D.new()
	top_holder.name = "TopTiles"
	_bridge_visual.add_child(top_holder)
	for tile in TOP_TILES:
		var tile_node := _create_tile(tile)
		top_holder.add_child(tile_node)
		_tile_nodes.append(tile_node)

	var bottom_holder := Node2D.new()
	bottom_holder.name = "BottomTiles"
	_bridge_visual.add_child(bottom_holder)
	for tile in BOTTOM_TILES:
		var tile_node := _create_tile(tile)
		bottom_holder.add_child(tile_node)
		_tile_nodes.append(tile_node)

	_falling_player = Node2D.new()
	_falling_player.name = "FallingPlayer"
	_falling_player.position = Vector2(270, 150)
	_falling_player.modulate = Color(1, 1, 1, 1)
	add_child(_falling_player)

	var player_label := Label.new()
	player_label.name = "PlayerLabel"
	player_label.position = Vector2(-30, 90)
	player_label.size = TILE_SIZE
	player_label.text = "我"
	player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _font != null:
		player_label.add_theme_font_override("font", _font)
	player_label.add_theme_font_size_override("font_size", 56)
	player_label.modulate = Color(0.98, 0.98, 0.98, 1.0)
	_falling_player.add_child(player_label)

	_animation_player = AnimationPlayer.new()
	_animation_player.name = "AnimationPlayer"
	add_child(_animation_player)


func _add_background() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.position = Vector2.ZERO
	background.size = SCENE_SIZE
	background.color = Color(0.06, 0.08, 0.12, 1.0)
	add_child(background)


func _add_water_strip(pos: Vector2, size: Vector2, color: Color) -> void:
	var strip := ColorRect.new()
	strip.position = pos
	strip.size = size
	strip.color = color
	_water_layer.add_child(strip)


func _add_water_glow(pos: Vector2, size: Vector2, color: Color) -> void:
	var glow := ColorRect.new()
	glow.position = pos
	glow.size = size
	glow.color = color
	_water_layer.add_child(glow)


func _create_tile(tile: Dictionary) -> Node2D:
	var holder := Node2D.new()
	holder.name = tile["name"]
	holder.position = tile["pos"]
	holder.rotation_degrees = tile["rot"]

	var glyph := Label.new()
	glyph.name = "Glyph"
	glyph.position = -TILE_SIZE / 2.0
	glyph.size = TILE_SIZE
	glyph.text = TILE_TEXT
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _font != null:
		glyph.add_theme_font_override("font", _font)
	glyph.add_theme_font_size_override("font_size", 56)
	glyph.modulate = Color(0.97, 0.97, 0.97, 1.0)
	holder.add_child(glyph)
	return holder


func _build_animations() -> void:
	var library := AnimationLibrary.new()
	library.add_animation("LooseStart", _make_loose_start())
	library.add_animation("LooseLoop", _make_loose_loop())
	library.add_animation("LooseDismiss", _make_loose_dismiss())
	library.add_animation("LooseBreak", _make_loose_break())
	library.add_animation("Broken", _make_broken())
	library.add_animation("LooseBridge", _make_loose_bridge())
	_animation_player.add_animation_library("", library)


func _make_loose_start() -> Animation:
	var animation := Animation.new()
	animation.length = 0.5
	for index in range(_tile_nodes.size()):
		var tile := _tile_nodes[index]
		var base_rot := tile.rotation_degrees
		var delta := 3.5 if index % 2 == 0 else -3.5
		_add_value_track(animation, tile, "rotation_degrees", [
			{"time": 0.0, "value": base_rot},
			{"time": 0.5, "value": base_rot + delta}
		])
	_add_value_track(animation, _water_layer, "modulate", [
		{"time": 0.0, "value": Color(1, 1, 1, 0.82)},
		{"time": 0.5, "value": Color(1, 1, 1, 1.0)}
	])
	return animation


func _make_loose_loop() -> Animation:
	var animation := Animation.new()
	animation.length = 2.0
	for index in range(_tile_nodes.size()):
		var tile := _tile_nodes[index]
		var base_rot := tile.rotation_degrees
		var delta := 5.0 if index % 2 == 0 else -5.0
		_add_value_track(animation, tile, "rotation_degrees", [
			{"time": 0.0, "value": base_rot + delta * 0.4},
			{"time": 0.5, "value": base_rot + delta},
			{"time": 1.0, "value": base_rot + delta * 0.2},
			{"time": 1.5, "value": base_rot + delta},
			{"time": 2.0, "value": base_rot + delta * 0.4}
		])
	_add_value_track(animation, _water_layer, "position", [
		{"time": 0.0, "value": Vector2.ZERO},
		{"time": 0.5, "value": Vector2(0, -4)},
		{"time": 1.0, "value": Vector2.ZERO},
		{"time": 1.5, "value": Vector2(0, 4)},
		{"time": 2.0, "value": Vector2.ZERO}
	])
	return animation


func _make_loose_dismiss() -> Animation:
	var animation := Animation.new()
	animation.length = 0.5
	_add_value_track(animation, _bridge_visual, "modulate", [
		{"time": 0.0, "value": Color(1, 1, 1, 1.0)},
		{"time": 0.5, "value": Color(1, 1, 1, 0.0)}
	])
	_add_value_track(animation, _bridge_visual, "position", [
		{"time": 0.0, "value": Vector2.ZERO},
		{"time": 0.5, "value": Vector2(0, 18)}
	])
	return animation


func _make_loose_break() -> Animation:
	var animation := Animation.new()
	animation.length = 3.0
	for index in range(_tile_nodes.size()):
		var tile := _tile_nodes[index]
		var base_rot := tile.rotation_degrees
		var base_pos := tile.position
		var delta := 12.0 if index % 2 == 0 else -12.0
		_add_value_track(animation, tile, "rotation_degrees", [
			{"time": 0.0, "value": base_rot},
			{"time": 0.4, "value": base_rot + delta},
			{"time": 1.2, "value": base_rot - delta * 1.2},
			{"time": 2.2, "value": base_rot + delta * 0.3},
			{"time": 3.0, "value": base_rot + delta * 1.4}
		])
		_add_value_track(animation, tile, "position", [
			{"time": 0.0, "value": base_pos},
			{"time": 0.55, "value": base_pos},
			{"time": 1.0, "value": base_pos + Vector2(0, 36)},
			{"time": 3.0, "value": base_pos + Vector2(0, 120)}
		])
	_add_value_track(animation, _bridge_visual, "modulate", [
		{"time": 0.0, "value": Color(1, 1, 1, 1.0)},
		{"time": 2.5, "value": Color(1, 1, 1, 1.0)},
		{"time": 3.0, "value": Color(1, 1, 1, 0.0)}
	])
	return animation


func _make_broken() -> Animation:
	var animation := Animation.new()
	animation.length = 5.0
	_add_value_track(animation, _falling_player, "position", [
		{"time": 0.0, "value": Vector2(270, 150)},
		{"time": 0.85, "value": Vector2(270, 210)},
		{"time": 1.15, "value": Vector2(270, 300)},
		{"time": 5.0, "value": Vector2(270, 420)}
	])
	_add_value_track(animation, _falling_player, "rotation_degrees", [
		{"time": 0.2, "value": 0.0},
		{"time": 0.5, "value": -15.0},
		{"time": 0.75, "value": 15.0},
		{"time": 0.85, "value": -10.0},
		{"time": 5.0, "value": -20.0}
	])
	_add_value_track(animation, _falling_player, "modulate", [
		{"time": 0.0, "value": Color(1, 1, 1, 1.0)},
		{"time": 1.15, "value": Color(1, 1, 1, 1.0)},
		{"time": 5.0, "value": Color(1, 1, 1, 0.0)}
	])
	return animation


func _make_loose_bridge() -> Animation:
	var animation := Animation.new()
	animation.length = 10.5
	for index in range(_tile_nodes.size()):
		var tile := _tile_nodes[index]
		var base_rot := tile.rotation_degrees
		var base_pos := tile.position
		var delta := 6.0 if index % 2 == 0 else -6.0
		_add_value_track(animation, tile, "rotation_degrees", [
			{"time": 0.0, "value": base_rot},
			{"time": 0.5, "value": base_rot + delta * 0.6},
			{"time": 2.5, "value": base_rot + delta},
			{"time": 4.5, "value": base_rot + delta * 0.5},
			{"time": 6.5, "value": base_rot + delta},
			{"time": 8.5, "value": base_rot + delta * 1.1},
			{"time": 10.5, "value": base_rot + delta * 2.0}
		])
		_add_value_track(animation, tile, "position", [
			{"time": 0.0, "value": base_pos},
			{"time": 8.5, "value": base_pos},
			{"time": 9.2, "value": base_pos + Vector2(0, 30)},
			{"time": 10.5, "value": base_pos + Vector2(0, 120)}
		])
	_add_value_track(animation, _water_layer, "position", [
		{"time": 0.0, "value": Vector2.ZERO},
		{"time": 0.5, "value": Vector2(0, -3)},
		{"time": 2.5, "value": Vector2(0, 3)},
		{"time": 4.5, "value": Vector2.ZERO},
		{"time": 6.5, "value": Vector2(0, -3)},
		{"time": 8.5, "value": Vector2.ZERO},
		{"time": 10.5, "value": Vector2(0, 5)}
	])
	_add_value_track(animation, _bridge_visual, "modulate", [
		{"time": 0.0, "value": Color(1, 1, 1, 1.0)},
		{"time": 8.5, "value": Color(1, 1, 1, 1.0)},
		{"time": 10.5, "value": Color(1, 1, 1, 0.0)}
	])
	_add_value_track(animation, _falling_player, "position", [
		{"time": 0.0, "value": Vector2(270, 150)},
		{"time": 8.6, "value": Vector2(270, 150)},
		{"time": 9.05, "value": Vector2(270, 210)},
		{"time": 10.5, "value": Vector2(270, 380)}
	])
	_add_value_track(animation, _falling_player, "rotation_degrees", [
		{"time": 8.6, "value": 0.0},
		{"time": 9.2, "value": -15.0},
		{"time": 9.8, "value": 15.0},
		{"time": 10.5, "value": -20.0}
	])
	_add_value_track(animation, _falling_player, "modulate", [
		{"time": 0.0, "value": Color(1, 1, 1, 1.0)},
		{"time": 10.5, "value": Color(1, 1, 1, 0.0)}
	])
	return animation


func _add_value_track(animation: Animation, target: Node, property: String, keys: Array) -> void:
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath("%s:%s" % [get_path_to(target), property]))
	for key in keys:
		animation.track_insert_key(track, key["time"], key["value"])
