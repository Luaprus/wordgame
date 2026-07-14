extends Node2D

const GRID_COLUMNS := 32
const GRID_ROWS := 18
const CELL_SIZE := 60.0
const VIEWPORT_SIZE := Vector2(1920.0, 1080.0)
const PLAYFIELD_OFFSET_Y := 0.0
const TOP_BAR_COLOR := Color(0.14, 0.14, 0.14, 1.0)
const PLAYFIELD_COLOR := Color(0.03137255, 0.03137255, 0.03137255, 1.0)
const GRID_LINE_COLOR := Color(1.0, 1.0, 1.0, 0.08)
const DIALOGUE_FONT := preload("res://Fonts/Zpix.tres")
const WORD_SPRITE_SCENE := preload("res://Scenes/Events/WordSprite.tscn")
const RIVER_SCENE := preload("res://Scenes/Animations/Ch4RiverFlow/Ch4RiverFlow.tscn")
const RIVER_POSITION := Vector2(1020.0, 0.0)

const BRIDGE_GROUP_ORIGIN := Vector2(1140.0, 420.0)
const BRIDGE_LOOP_TIMES := [0.0, 0.5, 1.0, 1.5, 2.0]
const BRIDGE_BREAK_TIMES := [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]

const BRIDGE_TILES := [
	{"name": "Bridge01", "pos": Vector2(30.0, 30.0), "rot": -8.0, "jitter": 0.0, "start_y": 190.0, "break_mid_y": -1.0, "break_end_y": -1.0},
	{"name": "Bridge02", "pos": Vector2(90.0, 96.0), "rot": -14.0, "jitter": 2.0, "start_y": 190.0, "break_mid_y": -1.0, "break_end_y": -1.0},
	{"name": "Bridge03", "pos": Vector2(150.0, 210.0), "rot": -11.0, "jitter": 3.0, "start_y": 190.0, "break_mid_y": 268.0, "break_end_y": 328.0},
	{"name": "Bridge04", "pos": Vector2(210.0, 210.0), "rot": -7.0, "jitter": 4.0, "start_y": 190.0, "break_mid_y": 262.0, "break_end_y": 322.0},
	{"name": "Bridge05", "pos": Vector2(270.0, 210.0), "rot": -2.0, "jitter": 5.0, "start_y": 190.0, "break_mid_y": 258.0, "break_end_y": 318.0},
	{"name": "Bridge06", "pos": Vector2(330.0, 210.0), "rot": 4.0, "jitter": 4.0, "start_y": 190.0, "break_mid_y": 262.0, "break_end_y": 322.0},
	{"name": "Bridge07", "pos": Vector2(390.0, 210.0), "rot": 10.0, "jitter": 3.0, "start_y": 190.0, "break_mid_y": 268.0, "break_end_y": 328.0},
	{"name": "Bridge08", "pos": Vector2(450.0, 96.0), "rot": 14.0, "jitter": 2.0, "start_y": 190.0, "break_mid_y": -1.0, "break_end_y": -1.0},
	{"name": "Bridge09", "pos": Vector2(510.0, 30.0), "rot": 8.0, "jitter": 0.0, "start_y": 190.0, "break_mid_y": -1.0, "break_end_y": -1.0},
	{"name": "Bridge10", "pos": Vector2(30.0, 270.0), "rot": -8.0, "jitter": 0.0, "start_y": 276.0, "break_mid_y": -1.0, "break_end_y": -1.0},
	{"name": "Bridge11", "pos": Vector2(90.0, 216.0), "rot": -14.0, "jitter": 2.0, "start_y": 276.0, "break_mid_y": -1.0, "break_end_y": -1.0},
	{"name": "Bridge12", "pos": Vector2(150.0, 330.0), "rot": -11.0, "jitter": 3.0, "start_y": 276.0, "break_mid_y": 336.0, "break_end_y": 396.0},
	{"name": "Bridge13", "pos": Vector2(210.0, 330.0), "rot": -7.0, "jitter": 4.0, "start_y": 276.0, "break_mid_y": 330.0, "break_end_y": 390.0},
	{"name": "Bridge14", "pos": Vector2(270.0, 330.0), "rot": -2.0, "jitter": 5.0, "start_y": 276.0, "break_mid_y": 326.0, "break_end_y": 386.0},
	{"name": "Bridge15", "pos": Vector2(330.0, 330.0), "rot": 4.0, "jitter": 4.0, "start_y": 276.0, "break_mid_y": 330.0, "break_end_y": 390.0},
	{"name": "Bridge16", "pos": Vector2(390.0, 330.0), "rot": 10.0, "jitter": 3.0, "start_y": 276.0, "break_mid_y": 336.0, "break_end_y": 396.0},
	{"name": "Bridge17", "pos": Vector2(450.0, 216.0), "rot": 14.0, "jitter": 2.0, "start_y": 276.0, "break_mid_y": -1.0, "break_end_y": -1.0},
	{"name": "Bridge18", "pos": Vector2(510.0, 270.0), "rot": 8.0, "jitter": 0.0, "start_y": 276.0, "break_mid_y": -1.0, "break_end_y": -1.0}
]

const BRIDGE_BREAK_ROTATIONS := [
	[10.0],
	[12.0],
	[-8.0, -10.0, 1.0, -10.0, 6.0, -12.0, 6.0, -8.0],
	[16.0, 18.0, -2.0, 20.0, -10.0, 20.0, -10.0, 16.0],
	[-6.0, -8.0, 1.0, -10.0, 6.0, -12.0, 6.0, -6.0],
	[-12.0, -14.0, 2.0, -16.0, 8.0, -16.0, 8.0, -12.0],
	[10.0, 13.0, 0.0, 15.0, -10.0, 20.0, -10.0, 10.0],
	[-12.0],
	[-8.0],
	[16.0],
	[8.0],
	[-10.0, -12.0, 1.0, -13.0, 7.0, -15.0, 7.0, -15.0],
	[-6.0, -8.0, 2.0, -10.0, 5.0, -12.0, 6.0, -12.0],
	[4.0, 6.0, -2.0, 8.0, -4.0, 9.0, -4.0, 8.0],
	[-12.0, -14.0, 1.0, -16.0, 8.0, -16.0, 8.0, -16.0],
	[-8.0, -10.0, 3.0, -12.0, 6.0, -13.0, 6.0, 12.0],
	[14.0],
	[14.0]
]

var _animation_player: AnimationPlayer
var _bridge_tiles: Array[Node2D] = []
var _falling_player: Node2D
@export var play_original_bridge_sequence := false
@export var play_idle_bridge_shake := true
@export var show_test_grid := false


func _ready() -> void:
	_build_scene()
	_build_animations()
	if play_original_bridge_sequence:
		play_bridge_sequence()
	elif play_idle_bridge_shake:
		play_idle_shake()


func _build_scene() -> void:
	_add_frame_bars()
	_add_playfield()
	_add_dialogue()
	_add_water()
	_add_player_hint()
	_add_bridge_masks()
	_add_bridge_tiles()
	_add_falling_player()

	_animation_player = AnimationPlayer.new()
	_animation_player.name = "AnimationPlayer"
	add_child(_animation_player)


func _add_frame_bars() -> void:
	var top_bar := ColorRect.new()
	top_bar.name = "TopBar"
	top_bar.size = Vector2(VIEWPORT_SIZE.x, PLAYFIELD_OFFSET_Y)
	top_bar.color = TOP_BAR_COLOR
	add_child(top_bar)

	var bottom_bar := ColorRect.new()
	bottom_bar.name = "BottomBar"
	bottom_bar.position = Vector2(0.0, VIEWPORT_SIZE.y - PLAYFIELD_OFFSET_Y)
	bottom_bar.size = Vector2(VIEWPORT_SIZE.x, PLAYFIELD_OFFSET_Y)
	bottom_bar.color = TOP_BAR_COLOR
	add_child(bottom_bar)


func _add_playfield() -> void:
	var playfield := ColorRect.new()
	playfield.name = "Playfield"
	playfield.position = Vector2(0.0, PLAYFIELD_OFFSET_Y)
	playfield.size = Vector2(VIEWPORT_SIZE.x, GRID_ROWS * CELL_SIZE)
	playfield.color = PLAYFIELD_COLOR
	add_child(playfield)
	if show_test_grid:
		_add_test_grid()


func _add_test_grid() -> void:
	var grid_size := Vector2(GRID_COLUMNS * CELL_SIZE, GRID_ROWS * CELL_SIZE)
	for x in range(GRID_COLUMNS + 1):
		var line := Line2D.new()
		line.name = "GridV%d" % x
		var px := float(x) * CELL_SIZE
		line.points = PackedVector2Array([
			Vector2(px, PLAYFIELD_OFFSET_Y),
			Vector2(px, PLAYFIELD_OFFSET_Y + grid_size.y)
		])
		line.width = 1.0
		line.default_color = GRID_LINE_COLOR
		add_child(line)

	for y in range(GRID_ROWS + 1):
		var line := Line2D.new()
		line.name = "GridH%d" % y
		var py := PLAYFIELD_OFFSET_Y + float(y) * CELL_SIZE
		line.points = PackedVector2Array([
			Vector2(0.0, py),
			Vector2(grid_size.x, py)
		])
		line.width = 1.0
		line.default_color = GRID_LINE_COLOR
		add_child(line)


func _add_dialogue() -> void:
	var label := Label.new()
	label.name = "Dialogue"
	label.position = Vector2(80.0, 126.0)
	label.size = Vector2(860.0, 420.0)
	label.text = "一条溪水阻挡前路。旁边的桥\n很好用，  感觉应该帮得上忙。\n\n这桥  看起来很好用，\n小心点肯定帮得上忙。\n\n无法跨越的湍急野溪，我\n而桥下的坚石河水难\n撑得起沉甸甸的重量。"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	if DIALOGUE_FONT != null:
		label.add_theme_font_override("font", DIALOGUE_FONT)
	label.add_theme_font_size_override("font_size", 54)
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)


func _add_water() -> void:
	var river := RIVER_SCENE.instantiate()
	river.name = "River"
	river.position = RIVER_POSITION
	add_child(river)


func _add_player_hint() -> void:
	_create_word_sprite("PlayerHint", "我", _cell_center(Vector2i(16, 2)))


func _add_bridge_masks() -> void:
	for mask in [
		{"pos": Vector2(90.0, 150.0), "offset": Vector2(-30.0, -90.0), "size": Vector2(60.0, 180.0)},
		{"pos": Vector2(150.0, 270.0), "offset": Vector2(-30.0, -90.0), "size": Vector2(300.0, 180.0)},
		{"pos": Vector2(450.0, 150.0), "offset": Vector2(-30.0, -90.0), "size": Vector2(60.0, 180.0)}
	]:
		var mask_pos: Vector2 = mask["pos"]
		var mask_offset: Vector2 = mask["offset"]
		var mask_size: Vector2 = mask["size"]
		var mask_rect := ColorRect.new()
		mask_rect.name = "BridgeMask"
		mask_rect.position = _bridge_scene_position(mask_pos) + mask_offset
		mask_rect.size = mask_size
		mask_rect.color = Color.BLACK
		add_child(mask_rect)


func _add_bridge_tiles() -> void:
	for tile in BRIDGE_TILES:
		_bridge_tiles.append(_create_bridge_tile(tile))


func _add_falling_player() -> void:
	_falling_player = Node2D.new()
	_falling_player.name = "FallingPlayer"
	_falling_player.position = _cell_center(Vector2i(24, 9))
	_falling_player.modulate = Color(1, 1, 1, 0)
	add_child(_falling_player)

	var sprite := WORD_SPRITE_SCENE.instantiate()
	sprite.name = "PlayerGlyph"
	sprite.text = "我"
	sprite.position = Vector2.ZERO
	_falling_player.add_child(sprite)


func _create_word_sprite(name: String, text: String, pos: Vector2) -> Node2D:
	var holder := Node2D.new()
	holder.name = name
	holder.position = pos

	var sprite := WORD_SPRITE_SCENE.instantiate()
	sprite.name = "WordSprite"
	sprite.text = text
	sprite.position = Vector2.ZERO
	holder.add_child(sprite)
	add_child(holder)
	return holder


func _create_bridge_tile(tile: Dictionary) -> Node2D:
	var holder := Node2D.new()
	holder.name = tile["name"]
	holder.position = _bridge_scene_position(tile["pos"])
	holder.rotation_degrees = tile["rot"]

	var sprite := WORD_SPRITE_SCENE.instantiate()
	sprite.name = "WordSprite"
	sprite.text = "桥"
	sprite.position = Vector2.ZERO
	holder.add_child(sprite)

	add_child(holder)
	return holder


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * CELL_SIZE, PLAYFIELD_OFFSET_Y + (cell.y + 0.5) * CELL_SIZE)


func _bridge_scene_position(local_pos: Vector2) -> Vector2:
	return BRIDGE_GROUP_ORIGIN + local_pos


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
	for index in range(_bridge_tiles.size()):
		var tile := _bridge_tiles[index]
		var data: Dictionary = BRIDGE_TILES[index]
		var start_y := float(data["start_y"])
		var local_pos: Vector2 = data["pos"]
		_add_value_track(animation, tile, "rotation_degrees", [
			{"time": 0.0, "value": 0.0},
			{"time": 0.5, "value": float(data["rot"])}
		])
		if start_y >= 0.0:
			_add_value_track(animation, tile, "position", [
				{"time": 0.0, "value": _bridge_scene_position(Vector2(local_pos.x, start_y))},
				{"time": 0.5, "value": _bridge_scene_position(local_pos)}
			])
	return animation


func _make_loose_loop() -> Animation:
	var animation := Animation.new()
	animation.length = 2.0
	animation.loop_mode = Animation.LOOP_LINEAR
	for index in range(_bridge_tiles.size()):
		var tile := _bridge_tiles[index]
		var data: Dictionary = BRIDGE_TILES[index]
		var local_pos: Vector2 = data["pos"]
		var jitter := float(data["jitter"])
		_add_value_track(animation, tile, "rotation_degrees", [
			{"time": 0.0, "value": float(data["rot"])},
			{"time": 1.0, "value": float(data["rot"])},
			{"time": 2.0, "value": float(data["rot"])}
		])
		if jitter > 0.0:
			_add_value_track(animation, tile, "position", [
				{"time": BRIDGE_LOOP_TIMES[0], "value": _bridge_scene_position(local_pos)},
				{"time": BRIDGE_LOOP_TIMES[1], "value": _bridge_scene_position(local_pos + Vector2(jitter, 0.0))},
				{"time": BRIDGE_LOOP_TIMES[2], "value": _bridge_scene_position(local_pos)},
				{"time": BRIDGE_LOOP_TIMES[3], "value": _bridge_scene_position(local_pos - Vector2(jitter, 0.0))},
				{"time": BRIDGE_LOOP_TIMES[4], "value": _bridge_scene_position(local_pos)}
			])
	return animation


func play_bridge_sequence() -> void:
	if _animation_player == null:
		return
	_animation_player.play("LooseBridge")


func play_idle_shake() -> void:
	if _animation_player == null:
		return
	_animation_player.play("LooseLoop")


func _make_loose_dismiss() -> Animation:
	var animation := Animation.new()
	animation.length = 0.5
	for index in range(_bridge_tiles.size()):
		var tile := _bridge_tiles[index]
		var data: Dictionary = BRIDGE_TILES[index]
		var start_y := float(data["start_y"])
		var local_pos: Vector2 = data["pos"]
		_add_value_track(animation, tile, "rotation_degrees", [
			{"time": 0.0, "value": float(data["rot"])},
			{"time": 0.5, "value": 0.0}
		])
		if start_y >= 0.0:
			_add_value_track(animation, tile, "position", [
				{"time": 0.0, "value": _bridge_scene_position(local_pos)},
				{"time": 0.5, "value": _bridge_scene_position(Vector2(local_pos.x, start_y))}
			])
	return animation


func _make_loose_break() -> Animation:
	var animation := Animation.new()
	animation.length = 3.0
	for index in range(_bridge_tiles.size()):
		var tile := _bridge_tiles[index]
		var data: Dictionary = BRIDGE_TILES[index]
		_add_value_track(animation, tile, "rotation_degrees", _rotation_keys(BRIDGE_BREAK_TIMES, BRIDGE_BREAK_ROTATIONS[index]))

		var break_mid_y := float(data["break_mid_y"])
		var break_end_y := float(data["break_end_y"])
		if break_mid_y >= 0.0 and break_end_y >= 0.0:
			var local_pos: Vector2 = data["pos"]
			_add_value_track(animation, tile, "position", [
				{"time": 0.0, "value": _bridge_scene_position(local_pos)},
				{"time": 0.55, "value": _bridge_scene_position(local_pos)},
				{"time": 1.0, "value": _bridge_scene_position(Vector2(local_pos.x, break_mid_y))},
				{"time": 3.0, "value": _bridge_scene_position(Vector2(local_pos.x, break_end_y))}
			])
	return animation


func _make_broken() -> Animation:
	var animation := Animation.new()
	animation.length = 5.0
	_add_value_track(animation, _falling_player, "modulate", [
		{"time": 0.0, "value": Color(1, 1, 1, 1.0)},
		{"time": 5.0, "value": Color(1, 1, 1, 0.0)}
	])
	_add_value_track(animation, _falling_player, "position", [
		{"time": 0.0, "value": _cell_center(Vector2i(24, 9))},
		{"time": 0.85, "value": _cell_center(Vector2i(24, 10))},
		{"time": 1.15, "value": _cell_center(Vector2i(24, 12))},
		{"time": 5.0, "value": _cell_center(Vector2i(24, 17)) + Vector2(0, 120)}
	])
	_add_value_track(animation, _falling_player, "rotation_degrees", [
		{"time": 0.2, "value": 0.0},
		{"time": 0.5, "value": -15.0},
		{"time": 0.75, "value": 15.0},
		{"time": 0.85, "value": -10.0},
		{"time": 5.0, "value": -20.0}
	])
	return animation


func _make_loose_bridge() -> Animation:
	var animation := Animation.new()
	animation.length = 10.5
	_add_bridge_sequence(animation, 0.0, _make_loose_start())
	_add_bridge_sequence(animation, 0.5, _make_loose_loop())
	_add_bridge_sequence(animation, 2.5, _make_loose_loop())
	_add_bridge_sequence(animation, 4.5, _make_loose_loop())
	_add_bridge_sequence(animation, 6.5, _make_loose_loop())
	_add_bridge_sequence(animation, 8.5, _make_loose_dismiss())
	return animation


func _add_value_track(animation: Animation, target: Node, property: String, keys: Array) -> void:
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath("%s:%s" % [get_path_to(target), property]))
	for key in keys:
		animation.track_insert_key(track, key["time"], key["value"])


func _add_bridge_sequence(animation: Animation, start_time: float, clip: Animation) -> void:
	for track_index in range(clip.get_track_count()):
		var new_track := animation.add_track(clip.track_get_type(track_index))
		animation.track_set_path(new_track, clip.track_get_path(track_index))
		for key_index in range(clip.track_get_key_count(track_index)):
			animation.track_insert_key(
				new_track,
				start_time + clip.track_get_key_time(track_index, key_index),
				clip.track_get_key_value(track_index, key_index)
			)


func _rotation_keys(times: Array, rotations: Array) -> Array:
	var keys := []
	for index in range(rotations.size()):
		var key_time := float(times[min(index, times.size() - 1)])
		keys.append({"time": key_time, "value": float(rotations[index])})
	return keys
