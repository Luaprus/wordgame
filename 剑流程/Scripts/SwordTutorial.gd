extends Control

const CELL := 60
const GRID_W := 32
const GRID_H := 18
const VIEWPORT_SIZE := Vector2(1920, 1080)
const FONT := preload("res://Fonts/Zpix-v3.1.6.ttf")
const WALL_FONT_SIZE := 56
const DIALOGUE_FONT_SIZE := 42

const BGM_SWORD := "res://Assets/audio/bgm/ch2/BGM_2_20_cave_sword_AB.ogg"
const SE_DRAW := "res://Assets/audio/se/sword_draw_out_1.wav"
const SE_SWING := "res://Assets/audio/se/第二章 音效/SE_2_23_sword_big_swing_B.wav"
const SE_RETURN := "res://Assets/audio/se/第二章 音效/SE_2_25_sword_return.wav"
const SE_WIND := "res://Assets/audio/se/第二章 音效/SE_2_26_wind_fill_C.wav"
const SE_ROCK := "res://Assets/audio/se/第二章 音效/SE_2_27_rock_break.wav"
const SE_FIRE := "res://Assets/audio/se/第三章 音效/SE_3_36_fire_lit_C.wav"
const SE_MELODY := "res://Assets/audio/se/MEL/MEL_2_24_sword.wav"
const SWORD_VIDEO := "res://Assets/video/u_sword.ogv"

enum Phase {
	INTRO,
	WALK_TO_TREASURE,
	TREASURE_SEQUENCE,
	OPPORTUNITY_SEQUENCE,
	FIND_SWORD,
	SWORD_FOUND,
	SWORD_CUTSCENE,
	EXPLAIN,
	LAMP_WAIT,
	AIR_WAIT,
	FALL_WAIT,
	FALLING,
	COMPLETE
}

var phase := Phase.INTRO
var rng := RandomNumberGenerator.new()
var player_cell := Vector2i(3, 12)
var wall_cells := {}
var treasure_cells := {}
var input_locked := false
var treasure_labels: Array[Label] = []
var opportunity_labels: Array[Label] = []

var map_layer: Control
var word_layer: Control
var actor_layer: Control
var fx_layer: Control
var sentence_layer: Control
var ui_layer: CanvasLayer
var dialogue_box: ColorRect
var dialogue_text: RichTextLabel
var hint_label: Label
var toast_label: Label
var save_label: Label
var dark_overlay: ColorRect
var blur_overlay: ColorRect
var cutscene_layer: Control
var video_player: VideoStreamPlayer
var cutscene_title: Label
var player_label: Label
var poet_label: Label
var sword_label: Label
var selection_marker: Label
var bgm_player: AudioStreamPlayer
var se_players: Array[AudioStreamPlayer] = []
var se_index := 0

var dialogue_lines: Array[String] = []
var dialogue_index := 0
var dialogue_callback: Callable
var dialogue_active := false

var sword_spawn_points: Array[Vector2i] = [
	Vector2i(8, 5), Vector2i(12, 6), Vector2i(16, 4),
	Vector2i(20, 6), Vector2i(14, 9), Vector2i(22, 10),
	Vector2i(10, 11), Vector2i(17, 12), Vector2i(24, 12)
]
var sword_active := false
var sword_cell := Vector2i.ZERO
var sword_life := 0.0
var sword_spawn_delay := 0.0
var sword_pulse := 0.0
var treasure_inspect_count := 0

var active_sentence_chars: Array[String] = []
var active_sentence_labels: Array[Label] = []
var sentence_target_index := -1
var sentence_selected_index := 0
var sentence_callback: Callable
var sentence_locked := false


func _ready() -> void:
	rng.randomize()
	size = VIEWPORT_SIZE
	_setup_layers()
	_setup_audio()
	_build_map()
	_place_actors()
	_start_intro()


func _process(delta: float) -> void:
	if phase == Phase.FIND_SWORD:
		_update_sword(delta)
	if sword_active:
		sword_pulse += delta * 6.0
		var alpha := 0.72 + sin(sword_pulse) * 0.28
		sword_label.modulate = Color(1.0, 1.0, 1.0, alpha)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if dialogue_active:
		if _is_accept_key(key_event):
			_next_dialogue()
		return

	if sentence_layer.visible:
		if key_event.keycode == KEY_LEFT or key_event.keycode == KEY_A:
			_move_sentence_selection(-1)
		elif key_event.keycode == KEY_RIGHT or key_event.keycode == KEY_D:
			_move_sentence_selection(1)
		elif key_event.keycode == KEY_BACKSPACE or key_event.keycode == KEY_DELETE:
			_try_delete_selected_char()
		return

	if input_locked:
		return

	if _is_accept_key(key_event):
		_try_interact()
		return

	var direction := Vector2i.ZERO
	match key_event.keycode:
		KEY_LEFT, KEY_A:
			direction = Vector2i.LEFT
		KEY_RIGHT, KEY_D:
			direction = Vector2i.RIGHT
		KEY_UP, KEY_W:
			direction = Vector2i.UP
		KEY_DOWN, KEY_S:
			direction = Vector2i.DOWN
	if direction != Vector2i.ZERO:
		_move_player(direction)


func _setup_layers() -> void:
	map_layer = Control.new()
	map_layer.name = "MainMap"
	map_layer.size = VIEWPORT_SIZE
	add_child(map_layer)

	word_layer = Control.new()
	word_layer.name = "WordLayer"
	word_layer.size = VIEWPORT_SIZE
	map_layer.add_child(word_layer)

	actor_layer = Control.new()
	actor_layer.name = "ActorLayer"
	actor_layer.size = VIEWPORT_SIZE
	map_layer.add_child(actor_layer)

	fx_layer = Control.new()
	fx_layer.name = "FxLayer"
	fx_layer.size = VIEWPORT_SIZE
	add_child(fx_layer)

	dark_overlay = ColorRect.new()
	dark_overlay.name = "DarkOverlay"
	dark_overlay.size = VIEWPORT_SIZE
	dark_overlay.color = Color(0, 0, 0, 0)
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(dark_overlay)

	blur_overlay = ColorRect.new()
	blur_overlay.name = "BreathBlurOverlay"
	blur_overlay.size = VIEWPORT_SIZE
	blur_overlay.color = Color(0.78, 0.86, 0.92, 0)
	blur_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(blur_overlay)

	sentence_layer = Control.new()
	sentence_layer.name = "SentenceLayer"
	sentence_layer.size = VIEWPORT_SIZE
	sentence_layer.visible = false
	fx_layer.add_child(sentence_layer)

	selection_marker = _make_label("▲", 34, Color(1.0, 0.95, 0.62))
	selection_marker.visible = false
	selection_marker.size = Vector2(CELL, CELL)
	sentence_layer.add_child(selection_marker)

	cutscene_layer = Control.new()
	cutscene_layer.name = "CutsceneLayer"
	cutscene_layer.size = VIEWPORT_SIZE
	cutscene_layer.visible = false
	fx_layer.add_child(cutscene_layer)

	var cutscene_back := ColorRect.new()
	cutscene_back.name = "CutsceneBack"
	cutscene_back.size = VIEWPORT_SIZE
	cutscene_back.color = Color.BLACK
	cutscene_layer.add_child(cutscene_back)

	video_player = VideoStreamPlayer.new()
	video_player.name = "SwordVideo"
	video_player.position = Vector2.ZERO
	video_player.size = VIEWPORT_SIZE
	video_player.stream = load(SWORD_VIDEO)
	cutscene_layer.add_child(video_player)

	cutscene_title = _make_label("贝克思贝斯之剑", 68, Color(1, 1, 1, 0))
	cutscene_title.position = Vector2(0, 780)
	cutscene_title.size = Vector2(VIEWPORT_SIZE.x, 120)
	cutscene_layer.add_child(cutscene_title)

	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	add_child(ui_layer)

	dialogue_box = ColorRect.new()
	dialogue_box.name = "DialogueBox"
	dialogue_box.position = Vector2(520, 760)
	dialogue_box.size = Vector2(980, 170)
	dialogue_box.color = Color(0, 0, 0, 0)
	dialogue_box.visible = false
	ui_layer.add_child(dialogue_box)

	dialogue_text = RichTextLabel.new()
	dialogue_text.name = "DialogueText"
	dialogue_text.position = Vector2.ZERO
	dialogue_text.size = Vector2(980, 170)
	dialogue_text.bbcode_enabled = false
	dialogue_text.scroll_active = false
	dialogue_text.fit_content = false
	dialogue_text.add_theme_font_override("normal_font", FONT)
	dialogue_text.add_theme_font_size_override("normal_font_size", DIALOGUE_FONT_SIZE)
	dialogue_box.add_child(dialogue_text)

	hint_label = _make_label("", 24, Color(0.76, 0.80, 0.82))
	hint_label.name = "Hint"
	hint_label.position = Vector2(36, 28)
	hint_label.size = Vector2(1200, 46)
	hint_label.visible = false
	ui_layer.add_child(hint_label)

	toast_label = _make_label("", 28, Color(0.9, 0.9, 0.9))
	toast_label.name = "Toast"
	toast_label.position = Vector2(360, 720)
	toast_label.size = Vector2(1200, 54)
	toast_label.modulate.a = 0
	ui_layer.add_child(toast_label)

	save_label = _make_label("已存档", 28, Color(0.84, 0.84, 0.84, 0))
	save_label.name = "SaveHint"
	save_label.position = Vector2(1685, 28)
	save_label.size = Vector2(190, 52)
	ui_layer.add_child(save_label)


func _setup_audio() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGM"
	add_child(bgm_player)

	for i in range(8):
		var player := AudioStreamPlayer.new()
		player.name = "SE_%02d" % i
		add_child(player)
		se_players.append(player)


func _build_map() -> void:
	_build_maze_view()


func _clear_word_layer() -> void:
	for child in word_layer.get_children():
		word_layer.remove_child(child)
		child.queue_free()
	wall_cells.clear()
	treasure_cells.clear()
	treasure_labels.clear()
	opportunity_labels.clear()


func _build_maze_view() -> void:
	_clear_word_layer()
	for x in range(GRID_W):
		_add_wall(Vector2i(x, 0))
		_add_wall(Vector2i(x, GRID_H - 1))
	for y in range(GRID_H):
		_add_wall(Vector2i(0, y))
		_add_wall(Vector2i(GRID_W - 1, y))

	for y in range(1, 15):
		if y != 12:
			_add_wall(Vector2i(8, y))
	for y in range(3, GRID_H - 1):
		if y != 6 and y != 12:
			_add_wall(Vector2i(16, y))
	for y in range(1, 15):
		if y < 10 or y > 13:
			_add_wall(Vector2i(23, y))

	for x in range(24, 31):
		_add_wall(Vector2i(x, 7))
	for x in range(24, 31):
		if x != 26:
			_add_wall(Vector2i(x, 15))

	_add_wall(Vector2i(3, 3))
	_add_wall(Vector2i(4, 3))
	_add_wall(Vector2i(11, 5))
	_add_wall(Vector2i(12, 5))
	_add_wall(Vector2i(19, 5))
	_add_wall(Vector2i(20, 5))


func _build_treasure_room(show_treasure: bool, show_opportunity: bool) -> void:
	_clear_word_layer()
	for x in range(0, 25):
		_add_wall(Vector2i(x, 0))
	for x in range(0, 29):
		_add_wall(Vector2i(x, GRID_H - 1))
	for y in range(1, GRID_H - 1):
		if y <= 4 or y >= 7:
			_add_wall(Vector2i(0, y))
		if y >= 6:
			_add_wall(Vector2i(1, y))
		if y >= 14:
			_add_wall(Vector2i(2, y))
	for y in range(1, GRID_H - 1):
		if y <= 5 or y >= 9:
			_add_wall(Vector2i(30, y))
		if y <= 4 or y >= 13:
			_add_wall(Vector2i(29, y))
		if y <= 3:
			_add_wall(Vector2i(28, y))
	for x in range(2, 28):
		_add_wall(Vector2i(x, 17))
	for x in range(24, 31):
		_add_wall(Vector2i(x, 1))

	for cell in [Vector2i(4, 2), Vector2i(5, 2), Vector2i(3, 3), Vector2i(27, 15), Vector2i(28, 15)]:
		_add_wall(cell)

	if show_treasure:
		_add_treasure_text("锂钠\n钾钪铯钫", Vector2(1025, 185))
		_add_treasure_text("镍镁\n钙锶钡镭", Vector2(660, 285))
		_add_treasure_text("锇铼钱\n铱铂金汞钫", Vector2(930, 430))
		_add_treasure_text("锰钼\n银镉铪铅", Vector2(1310, 290))
		_add_treasure_text("钛钒\n钒铬锰铁钴镍\n铜锌钇锆铌钼钌", Vector2(420, 520))
		_add_treasure_text("铀钍铝\n锆镓铟铊镝铋", Vector2(1390, 540))
	if show_opportunity:
		_add_opportunity_text(Vector2(350, 390))
		_add_opportunity_text(Vector2(610, 205))
		_add_opportunity_text(Vector2(900, 345))
		_add_opportunity_text(Vector2(1215, 205))
		_add_opportunity_text(Vector2(1040, 640))


func _add_wall(cell: Vector2i) -> void:
	if wall_cells.has(cell):
		return
	wall_cells[cell] = true
	var text := "岩" if (cell.x + cell.y) % 2 == 0 else "窟"
	var label := _make_grid_word(text, cell, Color(0.52, 0.52, 0.52), WALL_FONT_SIZE)
	word_layer.add_child(label)


func _add_treasure(cell: Vector2i, text: String, color := Color(0.72, 0.72, 0.72)) -> void:
	treasure_cells[cell] = true
	var label := _make_grid_word(text, cell, color, 48)
	label.name = "Treasure_%s_%s" % [cell.x, cell.y]
	word_layer.add_child(label)


func _add_treasure_text(text: String, pos: Vector2) -> void:
	var label := _make_label(text, 44, Color(0.78, 0.78, 0.78))
	label.position = pos
	label.size = Vector2(360, 160)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.name = "TreasureText"
	word_layer.add_child(label)
	treasure_labels.append(label)


func _add_opportunity_text(pos: Vector2) -> void:
	var label := _make_label("机会稍纵即逝", 42, Color(0.75, 0.75, 0.75))
	label.position = pos
	label.size = Vector2(360, 70)
	label.name = "OpportunityText"
	word_layer.add_child(label)
	opportunity_labels.append(label)


func _place_actors() -> void:
	player_label = _make_grid_word("我", player_cell, Color(0.94, 0.94, 0.94))
	player_label.name = "Player"
	player_label.z_index = 10
	actor_layer.add_child(player_label)

	poet_label = _make_grid_word("诗", Vector2i(2, 12), Color(0.7, 0.72, 0.78))
	poet_label.name = "Poet"
	poet_label.z_index = 9
	actor_layer.add_child(poet_label)

	sword_label = _make_grid_word("剑", Vector2i.ZERO, Color.WHITE)
	sword_label.name = "Sword"
	sword_label.visible = false
	sword_label.z_index = 15
	actor_layer.add_child(sword_label)


func _start_intro() -> void:
	phase = Phase.INTRO
	input_locked = true
	_set_hint("Enter/Space/E 推进字幕；方向键或 WASD 移动；Backspace 删除可疑文字。")
	_start_dialogue([
		"踏进一座曲折的迷宫，名符其实地十分曲折。\n就算是岩壁最薄的地方，也不可能让人穿越。"
	], Callable(self, "_after_intro"))


func _after_intro() -> void:
	_start_treasure_sequence()


func _move_player(direction: Vector2i) -> void:
	var next := player_cell + direction
	if not _is_walkable(next):
		_show_toast("岩壁挡住了去路。")
		return
	player_cell = next
	player_label.position = _cell_to_pos(player_cell)
	if poet_label.visible:
		poet_label.position = _cell_to_pos(player_cell - Vector2i(1, 0))
	_check_position_triggers()
	if sword_active and player_cell == sword_cell:
		_grab_sword()


func _is_walkable(cell: Vector2i) -> bool:
	if cell.x < 1 or cell.x >= GRID_W - 1 or cell.y < 1 or cell.y >= GRID_H - 1:
		return false
	return not wall_cells.has(cell)


func _check_position_triggers() -> void:
	if phase == Phase.WALK_TO_TREASURE and player_cell.x >= 24 and player_cell.y >= 9:
		_start_treasure_sequence()


func _start_treasure_sequence() -> void:
	phase = Phase.TREASURE_SEQUENCE
	input_locked = true
	_set_hint("")
	_build_treasure_room(false, false)
	_set_player_cell(Vector2i(4, 5))
	poet_label.visible = false
	_show_save_hint()
	_play_bgm(BGM_SWORD)
	_start_dialogue([
		"走着走着，来到一处较为宽敞的地方。\n天顶有一个小窗，洒下深蓝色的光芒。"
	], Callable(self, "_after_treasure_first_line"))


func _after_treasure_first_line() -> void:
	_build_treasure_room(true, false)
	_start_dialogue([
		"光线照亮之处，堆满了形形色色的武器与珍宝，\n想必都是蛇妖和喽啰四处搜刮来的战利品吧。",
		"诗人说的贝克思贝斯之剑肯定也在里面！"
	], Callable(self, "_start_opportunity_sequence"))


func _flash_treasure() -> void:
	for child in word_layer.get_children():
		if child.name.begins_with("Treasure_"):
			var tween := create_tween()
			tween.tween_property(child, "modulate", Color(1.0, 0.95, 0.62, 1), 0.25)
			tween.tween_property(child, "modulate", child.modulate, 0.5)


func _start_opportunity_sequence() -> void:
	phase = Phase.OPPORTUNITY_SEQUENCE
	_build_treasure_room(true, true)
	_start_dialogue([
		"定睛一看，四周的墙面闪灭着好几行字，\n全部都是相同内容：「机会稍纵即逝。」",
		"似乎隐约暗示着，想找到贝克思贝斯之剑，\n必须把握短暂的机会，心无旁骛地仔细观察。"
	], Callable(self, "_begin_find_sword"))


func _show_opportunity_words() -> void:
	var positions := [
		Vector2(210, 180), Vector2(1170, 150), Vector2(720, 300),
		Vector2(330, 610), Vector2(1050, 620)
	]
	for i in range(positions.size()):
		var label := _make_label("机会稍纵即逝", 34, Color(0.8, 0.8, 0.8, 0))
		label.position = positions[i]
		label.size = Vector2(420, 70)
		fx_layer.add_child(label)
		var tween := create_tween()
		tween.tween_property(label, "modulate:a", 1.0, 0.18).set_delay(i * 0.12)
		tween.tween_property(label, "modulate:a", 0.0, 0.45)
		tween.tween_callback(Callable(label, "queue_free"))


func _begin_find_sword() -> void:
	phase = Phase.FIND_SWORD
	input_locked = false
	sword_spawn_delay = 0.2
	_set_hint("观察宝物堆。圣剑会短暂出现：走到“剑”上，或贴近后按 E/Enter/Space。")


func _update_sword(delta: float) -> void:
	if sword_active:
		sword_life -= delta
		if sword_life <= 0.0:
			_vanish_sword()
	else:
		sword_spawn_delay -= delta
		if sword_spawn_delay <= 0.0:
			_spawn_sword()


func _spawn_sword() -> void:
	sword_cell = sword_spawn_points[rng.randi_range(0, sword_spawn_points.size() - 1)]
	if sword_cell == player_cell:
		sword_cell = sword_spawn_points[(sword_spawn_points.find(sword_cell) + 1) % sword_spawn_points.size()]
	sword_label.position = _cell_to_pos(sword_cell)
	sword_label.visible = true
	sword_label.modulate = Color.WHITE
	sword_active = true
	sword_life = 5.0
	_play_random_se([
		"res://Assets/audio/se/第二章 音效/SE_2_21_sword_crash_A.wav",
		"res://Assets/audio/se/第二章 音效/SE_2_21_sword_crash_B.wav",
		"res://Assets/audio/se/第二章 音效/SE_2_21_sword_crash_C.wav"
	])


func _vanish_sword() -> void:
	sword_active = false
	sword_label.visible = false
	sword_spawn_delay = 3.0
	_play_random_se([
		"res://Assets/audio/se/第二章 音效/SE_2_22_sword_vanish_A.wav",
		"res://Assets/audio/se/第二章 音效/SE_2_22_sword_vanish_B.wav"
	])


func _try_interact() -> void:
	if phase == Phase.FIND_SWORD:
		if sword_active and _cell_distance(player_cell, sword_cell) <= 1.1:
			_grab_sword()
			return
		if _is_near_treasure():
			_inspect_treasure()
			return
		_show_toast("这里没有可以调查的东西。")


func _is_near_treasure() -> bool:
	for cell in treasure_cells.keys():
		if _cell_distance(player_cell, cell) <= 1.4:
			return true
	return false


func _inspect_treasure() -> void:
	var lines := [
		"只是个金光闪闪的乡里手艺品。",
		"只是个金光闪闪的室内用挂饰。",
		"只是个金光闪闪的多层次铠甲。",
		"只是个金光闪闪的高级调色盘。",
		"只是个金光闪闪的精装小法典。"
	]
	_show_toast(lines[treasure_inspect_count % lines.size()])
	treasure_inspect_count += 1


func _grab_sword() -> void:
	if phase != Phase.FIND_SWORD:
		return
	phase = Phase.SWORD_FOUND
	input_locked = true
	sword_active = false
	_build_treasure_room(false, false)
	_set_player_cell(Vector2i(8, 5))
	sword_label.position = _cell_to_pos(player_cell + Vector2i(0, 1))
	sword_label.visible = true
	sword_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_set_hint("")
	_play_se(SE_DRAW)
	_start_dialogue([
		"宝物堆中，一支剑柄闪耀着与众不同的光泽，\n我连忙伸手将它抽了出来，转头看向诗人。",
		"诗人露出一个欣慰的微笑。",
		"我感受到前所未有的能量在掌心流转，\n地面及岩壁震动，耳边传来一串谜样的响声……"
	], Callable(self, "_play_sword_cutscene"))


func _play_sword_cutscene() -> void:
	phase = Phase.SWORD_CUTSCENE
	dialogue_box.visible = false
	input_locked = true
	_play_se(SE_SWING)
	_play_se(SE_MELODY)
	cutscene_layer.visible = true
	cutscene_title.modulate.a = 0.0
	var title_tween := create_tween()
	title_tween.tween_property(cutscene_title, "modulate:a", 1.0, 0.45)
	title_tween.tween_property(cutscene_title, "modulate:a", 0.15, 0.45)
	title_tween.set_loops()
	if video_player.stream != null:
		video_player.play()
		await video_player.finished
	else:
		await get_tree().create_timer(8.0).timeout
	title_tween.kill()
	if video_player.is_playing():
		video_player.stop()
	cutscene_layer.visible = false
	sword_label.visible = false
	_play_se(SE_RETURN)
	await _shake_screen(0.45, 24.0)
	_start_explanation_sequence()


func _start_explanation_sequence() -> void:
	phase = Phase.EXPLAIN
	_show_save_hint()
	_start_dialogue([
		"「清除文字之中恶的成分，\n就是勇者的责任。」",
		"「只要心念上的一个微小改变，」诗人说：\n「就能让世界截然不同。」",
		"「找出不该存在的字，举起圣剑，然后对它按下\n『删除键』便是。」",
		"诗人对我说完，耸了耸肩。\n我似懂非懂地点头，思索着「删除剑」又是什么剑。\n此时，四周似乎渐渐地暗了下来……"
	], Callable(self, "_start_lamp_problem"))


func _start_lamp_problem() -> void:
	phase = Phase.LAMP_WAIT
	input_locked = true
	var tween := create_tween()
	tween.tween_property(dark_overlay, "color:a", 0.78, 0.8)
	await tween.finished
	_start_dialogue([
		"「勇者，」诗人扬起法杖，说：\n「灯[不]亮了。」"
	], Callable(self, "_show_lamp_sentence"))


func _show_lamp_sentence() -> void:
	_set_hint("←/→ 选择字，Backspace 删除。目标：让句子成立为“灯亮了”。")
	_start_delete_sentence(["灯", "不", "亮", "了", "。"], 1, Callable(self, "_lamp_deleted"))


func _lamp_deleted() -> void:
	await _flash_sentence_success()
	_clear_sentence()
	_start_dialogue([
		"「谢啦，勇者。」法杖前端重新亮起了火光。"
	], Callable(self, "_after_lamp_thanks"))


func _after_lamp_thanks() -> void:
	_play_se(SE_FIRE)
	var tween := create_tween()
	tween.tween_property(dark_overlay, "color:a", 0.0, 0.7)
	await tween.finished
	_start_air_problem()


func _start_air_problem() -> void:
	phase = Phase.AIR_WAIT
	_start_dialogue([
		"正想说句不客气，\n却感到一阵呼吸困难，\n这密闭的洞窟，眼看就快要[没][有][空][气]……"
	], Callable(self, "_show_air_sentence"))


func _show_air_sentence() -> void:
	var tween := create_tween()
	tween.tween_property(blur_overlay, "color:a", 0.36, 0.45)
	_set_hint("删除多余的一个字，让洞窟恢复“有空气”。")
	_start_delete_sentence(["没", "有", "空", "气"], 0, Callable(self, "_air_deleted"))


func _air_deleted() -> void:
	_play_se(SE_WIND)
	await _flash_sentence_success()
	_clear_sentence()
	var tween := create_tween()
	tween.tween_property(blur_overlay, "color:a", 0.0, 0.85)
	await tween.finished
	_start_dialogue([
		"一阵凉风拂过脸庞，\n伴随着清新的滋味。\n啊，能够大口深呼吸的感觉真好。",
		"这把贝克思贝斯之剑的威力果然不同凡响。\n有了圣剑，应该就不用再害怕蛇妖了吧？",
		"「勇者，」诗人举起法杖，照亮刚才走来的路。\n「先别管蛇妖，咱们好像出不去了……」",
		"刚才拔剑时引发的震动，\n落下碎石封住了入口。"
	], Callable(self, "_show_blocked_route"))


func _show_blocked_route() -> void:
	await _pan_to_blocked_rocks()
	phase = Phase.FALL_WAIT
	_start_dialogue([
		"前、后、左、右都被堵死，上方是坚硬石壁，\n看样子，只有[忘]掉下去这一条路了……"
	], Callable(self, "_show_fall_sentence"))


func _show_fall_sentence() -> void:
	_set_hint("删除“不该存在的字”，把“忘掉下去”改成“掉下去”。")
	_start_delete_sentence(["只", "有", "忘", "掉", "下", "去", "这", "一", "条", "路", "了", "…", "…"], 2, Callable(self, "_fall_deleted"))


func _fall_deleted() -> void:
	_play_se(SE_ROCK)
	await _flash_sentence_success()
	_clear_sentence()
	phase = Phase.FALLING
	_start_dialogue([
		"低头一看，等待在脚底下的，\n是岩窟的无底深渊，",
		"以及迎面而来的未来剧本。"
	], Callable(self, "_start_falling_transition"))


func _start_falling_transition() -> void:
	input_locked = true
	_set_hint("")
	_spawn_bottom_crash()
	await get_tree().create_timer(0.65).timeout
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(map_layer, "position:y", map_layer.position.y + 2200.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(dark_overlay, "color:a", 1.0, 2.5)
	await tween.finished
	_show_falling_words()
	await get_tree().create_timer(3.4).timeout
	phase = Phase.COMPLETE
	_start_dialogue([
		"复刻段落结束。\n下一段会衔接到「06_坠落」与史莱姆洞窟。"
	], Callable(self, "_complete_demo"))


func _complete_demo() -> void:
	input_locked = false
	_set_hint("流程已结束。可重新运行工程再次体验。")


func _start_delete_sentence(chars: Array[String], target_index: int, callback: Callable) -> void:
	sentence_layer.visible = true
	sentence_locked = false
	active_sentence_chars = chars.duplicate()
	sentence_target_index = target_index
	sentence_selected_index = target_index
	sentence_callback = callback
	for label in active_sentence_labels:
		label.queue_free()
	active_sentence_labels.clear()

	var total_width := chars.size() * CELL
	var start_x := (VIEWPORT_SIZE.x - total_width) * 0.5
	var y := 390.0
	for i in range(chars.size()):
		var label := _make_label(chars[i], 44, Color(0.82, 0.82, 0.82))
		label.position = Vector2(start_x + i * CELL, y)
		label.size = Vector2(CELL, CELL)
		sentence_layer.add_child(label)
		active_sentence_labels.append(label)
	_update_sentence_selection()


func _move_sentence_selection(step: int) -> void:
	if sentence_locked or active_sentence_labels.is_empty():
		return
	sentence_selected_index = clampi(sentence_selected_index + step, 0, active_sentence_labels.size() - 1)
	_update_sentence_selection()


func _update_sentence_selection() -> void:
	for i in range(active_sentence_labels.size()):
		var label := active_sentence_labels[i]
		if i == sentence_selected_index:
			label.modulate = Color(1.0, 0.95, 0.62)
		elif i == sentence_target_index:
			label.modulate = Color(0.92, 0.92, 0.92)
		else:
			label.modulate = Color(0.55, 0.55, 0.55)
	if sentence_selected_index >= 0 and sentence_selected_index < active_sentence_labels.size():
		var selected_label := active_sentence_labels[sentence_selected_index]
		selection_marker.visible = true
		selection_marker.position = selected_label.position + Vector2(0, 54)


func _try_delete_selected_char() -> void:
	if sentence_locked:
		return
	if sentence_selected_index != sentence_target_index:
		_show_toast("圣剑没有回应：这个字还不是恶的成分。")
		_shake_sentence()
		return
	sentence_locked = true
	var label := active_sentence_labels[sentence_target_index]
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 0.0, 0.22)
	tween.tween_property(label, "scale", Vector2(1.8, 1.8), 0.22)
	await tween.finished
	label.visible = false
	if sentence_callback.is_valid():
		sentence_callback.call()


func _clear_sentence() -> void:
	for label in active_sentence_labels:
		label.queue_free()
	active_sentence_labels.clear()
	selection_marker.visible = false
	sentence_layer.visible = false
	sentence_locked = false
	sentence_target_index = -1


func _flash_sentence_success() -> void:
	var flash := ColorRect.new()
	flash.size = VIEWPORT_SIZE
	flash.color = Color(1, 1, 1, 0.0)
	fx_layer.add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.72, 0.08)
	tween.tween_property(flash, "color:a", 0.0, 0.28)
	await tween.finished
	flash.queue_free()


func _shake_sentence() -> void:
	var original := sentence_layer.position
	var tween := create_tween()
	tween.tween_property(sentence_layer, "position:x", original.x - 16, 0.05)
	tween.tween_property(sentence_layer, "position:x", original.x + 16, 0.05)
	tween.tween_property(sentence_layer, "position", original, 0.06)


func _pan_to_blocked_rocks() -> void:
	var original := map_layer.position
	var tween := create_tween()
	tween.tween_property(map_layer, "position:x", original.x - 180.0, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.45)
	tween.tween_property(map_layer, "position:x", original.x, 0.8).set_trans(Tween.TRANS_SINE)
	await tween.finished


func _spawn_bottom_crash() -> void:
	var bottom := _make_label("底", 66, Color(0.85, 0.85, 0.85))
	bottom.position = _cell_to_pos(player_cell + Vector2i(0, 1))
	bottom.size = Vector2(CELL, CELL)
	fx_layer.add_child(bottom)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(bottom, "rotation", 0.6, 0.4)
	tween.tween_property(bottom, "scale", Vector2(2.2, 0.35), 0.4)
	tween.tween_property(bottom, "modulate:a", 0.0, 0.55)
	tween.tween_callback(Callable(bottom, "queue_free")).set_delay(0.6)


func _show_falling_words() -> void:
	dark_overlay.color.a = 1.0
	var lines := [
		"＿不断往下掉",
		"不知道＿还会坠落多久",
		"＿这是要死了吗？"
	]
	for i in range(lines.size()):
		var label := _make_label(lines[i], 38, Color(0.86, 0.86, 0.86, 0))
		label.position = Vector2(600 + i * 160, 1080 + i * 110)
		label.size = Vector2(720, 80)
		fx_layer.add_child(label)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(label, "position:y", -90.0, 3.2 + i * 0.35)
		tween.tween_property(label, "modulate:a", 1.0, 0.4)
		tween.tween_property(label, "rotation", -0.08 + i * 0.08, 1.0)
		tween.tween_callback(Callable(label, "queue_free")).set_delay(3.5 + i * 0.35)


func _start_dialogue(lines: Array[String], callback: Callable = Callable()) -> void:
	dialogue_lines = lines
	dialogue_index = 0
	dialogue_callback = callback
	dialogue_active = true
	dialogue_box.visible = true
	_show_current_dialogue()


func _show_current_dialogue() -> void:
	dialogue_text.clear()
	dialogue_text.text = dialogue_lines[dialogue_index] + "  ▽"


func _next_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		_show_current_dialogue()
		return
	dialogue_active = false
	dialogue_box.visible = false
	if dialogue_callback.is_valid():
		dialogue_callback.call()


func _is_accept_key(event: InputEventKey) -> bool:
	return event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_E


func _make_grid_word(text: String, cell: Vector2i, color: Color, font_size := 48) -> Label:
	var label := _make_label(text, font_size, color)
	label.position = _cell_to_pos(cell)
	label.size = Vector2(CELL, CELL)
	return label


func _set_player_cell(cell: Vector2i) -> void:
	player_cell = cell
	player_label.position = _cell_to_pos(player_cell)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = color
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _cell_to_pos(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL, cell.y * CELL)


func _cell_distance(a: Vector2i, b: Vector2i) -> float:
	return Vector2(a.x, a.y).distance_to(Vector2(b.x, b.y))


func _set_hint(text: String) -> void:
	hint_label.text = text


func _show_toast(text: String) -> void:
	toast_label.text = text
	var tween := create_tween()
	tween.tween_property(toast_label, "modulate:a", 1.0, 0.12)
	tween.tween_interval(1.25)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.35)


func _show_save_hint() -> void:
	var tween := create_tween()
	tween.tween_property(save_label, "modulate:a", 1.0, 0.15)
	tween.tween_interval(0.8)
	tween.tween_property(save_label, "modulate:a", 0.0, 0.35)


func _play_bgm(path: String) -> void:
	var stream := load(path)
	if stream == null:
		return
	bgm_player.stream = stream
	bgm_player.volume_db = -7.0
	bgm_player.play()


func _play_se(path: String) -> void:
	var stream := load(path)
	if stream == null:
		return
	var player := se_players[se_index]
	se_index = (se_index + 1) % se_players.size()
	player.stream = stream
	player.volume_db = -2.0
	player.play()


func _play_random_se(paths: Array[String]) -> void:
	_play_se(paths[rng.randi_range(0, paths.size() - 1)])


func _shake_screen(duration: float, strength: float) -> void:
	var original := map_layer.position
	var elapsed := 0.0
	while elapsed < duration:
		var offset := Vector2(rng.randf_range(-strength, strength), rng.randf_range(-strength, strength))
		map_layer.position = original + offset
		await get_tree().create_timer(0.035).timeout
		elapsed += 0.035
	map_layer.position = original
