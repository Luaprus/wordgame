extends Node2D

const OriginalFont = preload("res://Fonts/Zpix.tres")
const GRID_SIZE := Vector2i(32, 18)
const CELL_SIZE := 60.0
const WORD_FONT_SIZE := 54
const FINAL_MESSAGE := "勇者们整齐地排成队，留出一条笔直的道路。"
const FINAL_MESSAGE_CELL := Vector2i(6, 4)
const TYPEWRITER_CHAR_DELAY := 0.1

var groups := {}
var heroes: Array[Label] = []

func _enter_tree() -> void:
	# The source project Global autoload probes these optional debug actions.
	for action_name in ["ui_debug", "ui_translate"]:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)

func _ready() -> void:
	_build_background()
	heros_enter()

func _build_background() -> void:
	var background := ColorRect.new()
	background.color = Color("080808")
	background.size = Vector2(GRID_SIZE) * CELL_SIZE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var grid := GridLines.new()
	grid.size = GRID_SIZE
	grid.cell_size = CELL_SIZE
	add_child(grid)

# Direct Godot 4 port of 16_添譜來堂_尾聲.tscn::heros_enter().
func heros_enter() -> void:
	var need_delete: Array[Label] = []

	for x in [2, 4, 6, 8, 10, 12, 19, 21, 23, 25, 27, 29]:
		start_move_route(create_hero(Vector2i(x, -1), ["up1"]), _route(Vector2i.DOWN, 2), randf() * 0.5)
	for y in [2, 4, 6, 10, 12, 14]:
		var hero := create_hero(Vector2i(-1, y), ["left1"])
		start_move_route(hero, _route(Vector2i.RIGHT, 2), randf() * 0.5)
		if y == 2:
			need_delete.append(hero)
	for y in [2, 4, 8, 10, 12, 14, 16]:
		var hero := create_hero(Vector2i(32, y), ["right1"])
		start_move_route(hero, _route(Vector2i.LEFT, 2), randf() * 0.5)
		if y == 2:
			need_delete.append(hero)
	create_hero(Vector2i(1, 8), ["left1"])
	create_hero(Vector2i(1, 16), ["left1"])
	create_hero(Vector2i(30, 6), ["right1"])

	await get_tree().create_timer(1.1).timeout
	for x in [0, 31]:
		start_move_route(create_hero(Vector2i(x, -1), ["up1"]), _route(Vector2i.DOWN, 2), randf() * 0.5)
	for x in [1, 3, 5, 7, 9, 11, 13, 18, 20, 22, 24, 26, 28, 30]:
		if x != 1 and x != 30:
			start_move_route(create_hero(Vector2i(x, -1), ["up2"]), _route(Vector2i.DOWN, 3), randf() * 0.5)
		start_move_route(create_hero(Vector2i(x, -3), ["up3"]), _route(Vector2i.DOWN, 3), randf() * 0.5)
	for y in [3, 5, 7, 9, 11, 13, 15, 17]:
		start_move_route(create_hero(Vector2i(-1, y), ["left2"]), _route(Vector2i.RIGHT, 3), randf() * 0.5)
		start_move_route(create_hero(Vector2i(32, y), ["right2"]), _route(Vector2i.LEFT, 3), randf() * 0.5)
		start_move_route(create_hero(Vector2i(-3, y), ["left3"]), _route(Vector2i.RIGHT, 3), randf() * 0.5)
		start_move_route(create_hero(Vector2i(34, y), ["right3"]), _route(Vector2i.LEFT, 3), randf() * 0.5)

	await get_tree().create_timer(1.5).timeout
	create_hero(Vector2i(1, 2), ["up2"])
	create_hero(Vector2i(30, 2), ["up2"])
	for hero in need_delete:
		hero.queue_free()
		heroes.erase(hero)
	for group_name in ["left1", "left2", "left3"]:
		_move_group(group_name, _route(Vector2i.RIGHT, 2))
	for group_name in ["right1", "right2", "right3"]:
		_move_group(group_name, _route(Vector2i.LEFT, 2))
	for y in [3, 5, 7, 9, 11, 13, 15, 17]:
		start_move_route(create_hero(Vector2i(-2, y), ["left5"]), _route(Vector2i.RIGHT, 2), randf() * 0.5)
		start_move_route(create_hero(Vector2i(33, y), ["right5"]), _route(Vector2i.LEFT, 2), randf() * 0.5)
		if y != 17:
			start_move_route(create_hero(Vector2i(-1, y + 1), ["left4"]), _route(Vector2i.RIGHT, 2), randf() * 0.5)
			start_move_route(create_hero(Vector2i(32, y + 1), ["right4"]), _route(Vector2i.LEFT, 2), randf() * 0.5)

	await get_tree().create_timer(1.1).timeout
	_move_group("up1", _route(Vector2i.DOWN, 1))
	_move_group("up3", _route(Vector2i.DOWN, 1))
	for group_name in ["left1", "left2", "left3", "left4", "left5"]:
		_move_group(group_name, _route(Vector2i.RIGHT, 2))
	for group_name in ["right1", "right2", "right3", "right4", "right5"]:
		_move_group(group_name, _route(Vector2i.LEFT, 2))
	for x in [0, 2, 4, 6, 8, 10, 12, 19, 21, 23, 25, 27, 29, 31]:
		start_move_route(create_hero(Vector2i(x, -1), ["up4"]), _route(Vector2i.DOWN, 2), randf() * 0.5)
	for x in range(32):
		if x in [14, 15, 16, 17]:
			continue
		start_move_route(create_hero(Vector2i(x, -2), ["up5"]), _route(Vector2i.DOWN, 2), randf() * 0.5 + 0.3)
	for y in [4, 6, 8, 10, 12, 14, 16]:
		start_move_route(create_hero(Vector2i(-1, y), ["left6"]), _route(Vector2i.RIGHT, 3), randf() * 0.5)
		start_move_route(create_hero(Vector2i(32, y), ["right6"]), _route(Vector2i.LEFT, 3), randf() * 0.5)
	for y in range(3, 18):
		start_move_route(create_hero(Vector2i(-2, y), ["left7"]), _route(Vector2i.RIGHT, 3), randf() * 0.2 + 0.3)
		start_move_route(create_hero(Vector2i(-3, y), ["left8"]), _route(Vector2i.RIGHT, 3), randf() * 0.2 + 0.3)
		start_move_route(create_hero(Vector2i(33, y), ["right7"]), _route(Vector2i.LEFT, 3), randf() * 0.2 + 0.5)
		start_move_route(create_hero(Vector2i(34, y), ["right8"]), _route(Vector2i.LEFT, 3), randf() * 0.2 + 0.5)
	await get_tree().create_timer(2.2).timeout
	await _shift_side_walls_outward()
	await _typewrite_final_message()

func _shift_side_walls_outward() -> void:
	_ensure_top_side_anchors()
	var inner_wall_words: Array[Label] = []
	for hero in heroes:
		if not is_instance_valid(hero):
			continue
		var cell := Vector2i(roundi(hero.position.x / CELL_SIZE), roundi(hero.position.y / CELL_SIZE))
		if cell.y >= 3 and ((cell.x >= 5 and cell.x <= 6) or (cell.x >= 25 and cell.x <= 26)):
			inner_wall_words.append(hero)
	for hero in inner_wall_words:
		var tween := create_tween()
		tween.tween_property(hero, "modulate:a", 0.0, 0.35)

	var occupied := {}
	for hero in heroes:
		if not is_instance_valid(hero) or inner_wall_words.has(hero):
			continue
		var cell := Vector2i(roundi(hero.position.x / CELL_SIZE), roundi(hero.position.y / CELL_SIZE))
		occupied[cell] = true
	for y in range(3, GRID_SIZE.y):
		for x in range(5):
			_fade_in_missing_hero(Vector2i(x, y), occupied)
		for x in range(27, 32):
			_fade_in_missing_hero(Vector2i(x, y), occupied)
	await get_tree().create_timer(0.35).timeout
	for hero in inner_wall_words:
		if is_instance_valid(hero):
			hero.queue_free()
		heroes.erase(hero)

func _ensure_top_side_anchors() -> void:
	var occupied := {}
	for hero in heroes:
		if is_instance_valid(hero):
			occupied[Vector2i(roundi(hero.position.x / CELL_SIZE), roundi(hero.position.y / CELL_SIZE))] = true
	for y in range(3):
		for x in range(14):
			var left_cell := Vector2i(x, y)
			if not occupied.has(left_cell):
				create_hero(left_cell, [])
		for x in range(18, 32):
			var right_cell := Vector2i(x, y)
			if not occupied.has(right_cell):
				create_hero(right_cell, [])

func _fade_in_missing_hero(cell: Vector2i, occupied: Dictionary) -> void:
	if occupied.has(cell):
		return
	var hero := create_hero(cell, [])
	hero.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(hero, "modulate:a", 1.0, 0.35)
	occupied[cell] = true

func _typewrite_final_message() -> void:
	var label := _make_message_label()
	label.position = Vector2(FINAL_MESSAGE_CELL) * CELL_SIZE
	add_child(label)
	for index in range(FINAL_MESSAGE.length()):
		label.text = FINAL_MESSAGE.left(index + 1)
		await get_tree().create_timer(TYPEWRITER_CHAR_DELAY).timeout
	var prompt := _make_message_label()
	prompt.text = "▽"
	prompt.position = label.position + Vector2(FINAL_MESSAGE.length() * CELL_SIZE, 0.0)
	prompt.size = Vector2.ONE * CELL_SIZE
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(prompt)

func _make_message_label() -> Label:
	var label := Label.new()
	label.size = Vector2(1440.0, CELL_SIZE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", OriginalFont)
	label.add_theme_font_size_override("font_size", WORD_FONT_SIZE)
	label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	return label

func create_hero(cell: Vector2i, group_names: Array[String]) -> Label:
	var hero := Label.new()
	hero.text = "勇"
	hero.position = Vector2(cell) * CELL_SIZE
	hero.size = Vector2.ONE * CELL_SIZE
	hero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hero.add_theme_font_override("font", OriginalFont)
	hero.add_theme_font_size_override("font_size", WORD_FONT_SIZE)
	hero.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	add_child(hero)
	heroes.append(hero)
	for group_name in group_names:
		if not groups.has(group_name):
			groups[group_name] = []
		groups[group_name].append(hero)
	return hero

func start_move_route(hero: Label, route: Array[Vector2i], delay := 0.0) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	for index in range(route.size()):
		if not is_instance_valid(hero):
			return
		await walk(hero, route[index])
		if index + 1 < route.size():
			await get_tree().create_timer(0.05).timeout

func walk(hero: Label, direction: Vector2i) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(hero, "position", hero.position + Vector2(direction) * CELL_SIZE, 0.3)
	await tween.finished

func _move_group(group_name: String, route: Array[Vector2i]) -> void:
	for hero in groups.get(group_name, []):
		if is_instance_valid(hero):
			start_move_route(hero, route, randf() * 0.5)

func _route(direction: Vector2i, count: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for _index in range(count):
		result.append(direction)
	return result

class GridLines extends Node2D:
	var size := Vector2i.ZERO
	var cell_size := 60.0

	func _draw() -> void:
		var color := Color(1.0, 1.0, 1.0, 0.12)
		for x in range(size.x + 1):
			var offset := x * cell_size
			draw_line(Vector2(offset, 0.0), Vector2(offset, size.y * cell_size), color)
		for y in range(size.y + 1):
			var offset := y * cell_size
			draw_line(Vector2(0.0, offset), Vector2(size.x * cell_size, offset), color)
