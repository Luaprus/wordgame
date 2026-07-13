extends Control

const CELL := 60
const GRID_W := 32
const GRID_H := 18
const VIEWPORT_SIZE := Vector2(1920, 1080)
const FONT := preload("res://Fonts/Zpix-v3.1.6.ttf")

const MAP_MAZE := 0
const MAP_TREASURE := 1
const MAP_SLIME_LEFT := 2
const MAP_SLIME_RIGHT := 3

const MAP_PATHS := [
	"res://Data/reference_maze_map.json",
	"res://Data/reference_treasure_room_empty_map.json",
	"res://Data/reference_slime_cave_left_map.json",
	"res://Data/reference_slime_cave_right_map.json",
]

const BGM_SWORD := "res://Assets/audio/bgm/ch2/BGM_2_20_cave_sword_AB.ogg"
const SE_DRAW := "res://Assets/audio/se/sword_draw_out_1.wav"
const SE_SWING := "res://Assets/audio/se/第二章 音效/SE_2_23_sword_big_swing_B.wav"
const SE_RETURN := "res://Assets/audio/se/第二章 音效/SE_2_25_sword_return.wav"
const SE_WIND := "res://Assets/audio/se/第二章 音效/SE_2_26_wind_fill_C.wav"
const SE_ROCK := "res://Assets/audio/se/第二章 音效/SE_2_27_rock_break.wav"
const SE_FIRE := "res://Assets/audio/se/第三章 音效/SE_3_36_fire_lit_C.wav"
const SE_MELODY := "res://Assets/audio/se/MEL/MEL_2_24_sword.wav"
const SWORD_VIDEO := "res://Assets/video/u_sword.ogv"

const WALL_COLOR := Color(0.58, 0.58, 0.58, 1.0)
const DIALOGUE_COLOR := Color(0.86, 0.86, 0.86, 1.0)
const PLAYER_COLOR := Color(0.88, 0.88, 0.88, 1.0)
const DIM_COLOR := Color(0.38, 0.38, 0.38, 1.0)

const MAZE_EXIT_CELL := Vector2i(31, 5)
const TREASURE_ROOM_SPAWN := Vector2i(3, 5)
const TREASURE_ORIGIN := Vector2i(3, 3)
const SWORD_SPAWN_WAIT := 3.0
const SWORD_VISIBLE_TIME := 5.0
const SLIME_REINFORCEMENT_INTERVAL := 4.0
const OPPORTUNITY_CELLS := [
	Vector2i(2, 7),
	Vector2i(7, 3),
	Vector2i(14, 6),
	Vector2i(17, 12),
	Vector2i(21, 3),
]
const OPPORTUNITY_START_OFFSETS := [0.0, 1.1, 2.0, 3.0, 4.0]
const OPPORTUNITY_LOOP_TIME := 8.0
const LEGAL_HIGHLIGHT_HOLD_TIME := 1.6
const SLIME_LEFT_SPAWN := Vector2i(14, 10)
const SLIME_RIGHT_SPAWN := Vector2i(4, 12)
const FISSURE_EXIT_Y := [10, 11]

const FISSURE_PATTERN := [
	"岩窟＿窟",
	"＿岩窟窟",
	"＿＿窟＿",
	"＿＿＿窟",
]
const FISSURE_ORIGIN := Vector2i(28, 10)

const SLIME_CELLS := [
	Vector2i(30, 8),
	Vector2i(26, 5),
	Vector2i(28, 9),
	Vector2i(27, 10),
	Vector2i(25, 13),
	Vector2i(24, 9),
	Vector2i(22, 12),
	Vector2i(20, 9),
	Vector2i(18, 11),
	Vector2i(19, 15),
]
const SLIME_INITIAL_INDICES := [0, 1, 4, 6, 9]
const SLIME_REINFORCEMENT_INDICES := [5, 3, 8, 2, 7]
const SLIME_PARTIAL_FADE_INDICES := [2, 3, 5, 7, 8]

const TREASURE_SOURCE_ROWS := [
	"＿＿＿＿＿＿＿＿＿＿＿＿＿＿锂钠＿＿＿＿＿＿＿＿＿＿",
	"＿＿＿＿＿＿＿＿＿＿＿＿＿钾铷铯钫＿＿＿＿＿＿＿＿＿",
	"＿＿＿＿＿＿铍镁＿＿＿＿＿＿＿＿＿＿＿＿铑钯＿＿＿＿",
	"＿＿＿＿＿钙锶钡镭＿＿＿＿＿＿＿＿＿＿银镉铪钽＿＿＿",
	"＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿",
	"＿＿＿＿＿＿＿＿＿＿＿＿钨铼锇＿＿＿＿＿＿＿＿＿＿＿",
	"＿＿＿＿钪钛＿＿＿＿＿铱铂金汞鑪＿＿＿＿＿＿＿＿＿＿",
	"＿钒铬锰铁钴镍＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿铀钸铝＿",
	"铜锌钇锆铌钼锝钌＿＿＿＿＿＿＿＿＿＿＿＿锗镓铊铟镝铋",
]

const SOURCE_SWORD_MASK := [
	"00000000000000110000000000",
	"00000000000001111000000000",
	"00000011000000000000110000",
	"00000111100000000001111000",
	"00000000000000000000000000",
	"00000000000011100000000000",
	"00001100000111110000000000",
	"01110010000000000000001110",
	"11111111000000000000111111",
]

enum Phase {
	MAZE,
	ROOM_TRANSITION,
	ROOM4_DIALOGUE,
	FIND_SWORD,
	SWORD_FOUND,
	SWORD_CUTSCENE,
	EXPLAIN,
	LAMP_WAIT,
	AIR_WAIT,
	FALL_WAIT,
	FALLING,
	SLIME_LEFT_INTRO,
	SLIME_LEFT_WAIT,
	SLIME_RIGHT_INTRO,
	SLIME_STAGE1,
	SLIME_STAGE2,
	SLIME_STAGE3,
	SLIME_STAGE4,
	SLIME_DONE,
	COMPLETE,
}

var phase := Phase.MAZE
var rng := RandomNumberGenerator.new()
var map_data: Array[Dictionary] = []
var map_roots: Array[Control] = []
var current_map := 0
var player_cell := Vector2i(22, 5)
var input_locked := false

var world_layer: Control
var actor_layer: Control
var dialogue_layer: Control
var treasure_layer: Control
var opportunity_layer: Control
var fx_layer: Control
var sentence_layer: Control
var cutscene_layer: Control
var falling_layer: Control
var death_layer: Control
var video_player: VideoStreamPlayer
var dark_overlay: ColorRect
var blur_overlay: ColorRect

var player_label: Label
var sword_label: Label
var toast_label: Label
var hint_label: Label

var dialogue_pages: Array = []
var dialogue_index := 0
var dialogue_callback: Callable
var dialogue_active := false
var active_dialogue_map := 0

var last_direction := Vector2i.RIGHT
var metal_slots: Array[Vector2i] = []
var metal_cells: Dictionary = {}
var metal_labels: Dictionary = {}
var metal_letters: Array[String] = []
var sword_active := false
var sword_cell := Vector2i.ZERO
var sword_life := 0.0
var sword_spawn_delay := 0.0
var sword_pulse := 0.0
var opportunity_labels: Array[Label] = []
var opportunity_offsets: Array[float] = []
var opportunity_active := false
var opportunity_time := 0.0

var active_sentence_labels: Array[Label] = []
var sentence_cells: Array[Vector2i] = []
var sentence_highlight_cells: Array[Vector2i] = []
var sentence_success_indices: Array[int] = []
var sentence_fail_indices: Array[int] = []
var sentence_target_cell := Vector2i.ZERO
var sentence_target_index := -1
var sentence_callback: Callable
var sentence_fail_callback: Callable
var sentence_locked := false
var sentence_active := false
var sentence_map_index := MAP_TREASURE

var fissure_labels: Array[Label] = []
var fissure_open := false
var slime_labels: Array[Label] = []
var slime_visible: Array[bool] = []
var slime_reinforcement_timer := 0.0
var slime_reinforcement_cursor := 0
var pending_death_sentence := ""

var bgm_player: AudioStreamPlayer
var se_players: Array[AudioStreamPlayer] = []
var se_index := 0


func _ready() -> void:
	rng.randomize()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_maps()
	_setup_layers()
	_setup_audio()
	_render_reference_maps()
	_create_actors()
	_set_hint("")


func _process(delta: float) -> void:
	if phase == Phase.FIND_SWORD:
		_update_sword(delta)
	if opportunity_active:
		_update_opportunity_text(delta)
	if sword_active:
		sword_pulse += delta * 6.0
		sword_label.modulate = Color(1.0, 1.0, 1.0, 0.72 + sin(sword_pulse) * 0.28)
	if phase == Phase.SLIME_STAGE1:
		_update_slime_reinforcements(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if dialogue_active:
		if _is_accept_key(key_event):
			_advance_dialogue()
		return

	if _is_delete_key(key_event) and sentence_active:
		_try_delete_front_char()
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
		last_direction = direction
		_try_move_player(direction)


func _load_maps() -> void:
	for path in MAP_PATHS:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("Cannot open map data: %s" % path)
			continue
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			map_data.append(parsed)
		else:
			push_error("Invalid map JSON: %s" % path)


func _setup_layers() -> void:
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	world_layer = Control.new()
	world_layer.name = "WorldLayer"
	world_layer.size = Vector2(VIEWPORT_SIZE.x * map_data.size(), VIEWPORT_SIZE.y)
	world_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(world_layer)

	treasure_layer = Control.new()
	treasure_layer.name = "TreasureLayer"
	treasure_layer.z_index = 5
	treasure_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_layer.add_child(treasure_layer)

	opportunity_layer = Control.new()
	opportunity_layer.name = "OpportunityLayer"
	opportunity_layer.z_index = 6
	opportunity_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_layer.add_child(opportunity_layer)

	dialogue_layer = Control.new()
	dialogue_layer.name = "DialogueLayer"
	dialogue_layer.z_index = 10
	dialogue_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_layer.add_child(dialogue_layer)

	actor_layer = Control.new()
	actor_layer.name = "ActorLayer"
	actor_layer.z_index = 20
	actor_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_layer.add_child(actor_layer)

	fx_layer = Control.new()
	fx_layer.name = "FxLayer"
	fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	blur_overlay.color = Color(0.72, 0.82, 0.92, 0)
	blur_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(blur_overlay)

	sentence_layer = Control.new()
	sentence_layer.name = "SentenceLayer"
	sentence_layer.size = VIEWPORT_SIZE
	sentence_layer.visible = false
	fx_layer.add_child(sentence_layer)

	cutscene_layer = Control.new()
	cutscene_layer.name = "CutsceneLayer"
	cutscene_layer.size = VIEWPORT_SIZE
	cutscene_layer.visible = false
	fx_layer.add_child(cutscene_layer)

	var cutscene_back := ColorRect.new()
	cutscene_back.size = VIEWPORT_SIZE
	cutscene_back.color = Color.BLACK
	cutscene_layer.add_child(cutscene_back)

	video_player = VideoStreamPlayer.new()
	video_player.name = "SwordVideo"
	video_player.position = Vector2.ZERO
	video_player.size = VIEWPORT_SIZE
	video_player.stream = load(SWORD_VIDEO)
	cutscene_layer.add_child(video_player)

	falling_layer = Control.new()
	falling_layer.name = "FallingLayer"
	falling_layer.size = VIEWPORT_SIZE
	falling_layer.visible = false
	falling_layer.z_index = 40
	fx_layer.add_child(falling_layer)

	death_layer = Control.new()
	death_layer.name = "DeathLayer"
	death_layer.size = VIEWPORT_SIZE
	death_layer.visible = false
	death_layer.z_index = 80
	fx_layer.add_child(death_layer)

	hint_label = _make_label("", 30, Color(0.72, 0.72, 0.72, 1.0))
	hint_label.name = "Hint"
	hint_label.position = Vector2(36, 24)
	hint_label.size = Vector2(1200, 60)
	hint_label.visible = false
	fx_layer.add_child(hint_label)

	toast_label = _make_label("", 38, DIALOGUE_COLOR)
	toast_label.name = "Toast"
	toast_label.position = Vector2(420, 690)
	toast_label.size = Vector2(1080, 80)
	toast_label.modulate.a = 0
	fx_layer.add_child(toast_label)


func _setup_audio() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGM"
	add_child(bgm_player)
	for i in range(8):
		var player := AudioStreamPlayer.new()
		player.name = "SE_%02d" % i
		add_child(player)
		se_players.append(player)


func _render_reference_maps() -> void:
	for map_index in range(map_data.size()):
		var root := Control.new()
		root.name = "ReferenceMap_%d" % map_index
		root.position = Vector2(map_index * VIEWPORT_SIZE.x, 0)
		root.size = VIEWPORT_SIZE
		root.z_index = 0
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world_layer.add_child(root)
		map_roots.append(root)
		_render_base_map(map_index, root)
	_render_dialogue(MAP_MAZE, ["踏进一座曲折的迷宫，名符其实地十分曲折。", "就算是岩壁最薄的地方，也不可能让人穿越。"], false)


func _render_base_map(map_index: int, root: Control) -> void:
	var rows: Array = map_data[map_index]["rows"]
	for y in range(rows.size()):
		var row := String(rows[y])
		for x in range(row.length()):
			var text := row.substr(x, 1)
			if text == " " or text == "＿" or text == "我":
				continue
			if y >= 14 and y <= 15 and text != "岩" and text != "窟":
				continue
			var label := _make_cell_label(text, x, y, WALL_COLOR)
			root.add_child(label)


func _create_actors() -> void:
	player_label = _make_cell_label("我", player_cell.x, player_cell.y, PLAYER_COLOR)
	player_label.name = "Player"
	player_label.z_index = 20
	actor_layer.add_child(player_label)

	sword_label = _make_cell_label("剑", 0, 0, Color.WHITE)
	sword_label.name = "Sword"
	sword_label.visible = false
	sword_label.z_index = 25
	actor_layer.add_child(sword_label)


func _try_move_player(direction: Vector2i) -> void:
	var next := player_cell + direction
	if phase == Phase.MAZE and next == MAZE_EXIT_CELL:
		player_cell = next
		_update_player_position()
		_start_room_transition()
		return

	if phase == Phase.FIND_SWORD:
		if sword_active and next == sword_cell:
			_grab_sword(player_cell, sword_cell)
			return
		if _is_metal_cell(next):
			_inspect_metal_cell(next)
			return

	if current_map == MAP_SLIME_LEFT and next.x >= GRID_W and FISSURE_EXIT_Y.has(next.y):
		if fissure_open:
			_enter_slime_right()
		else:
			_show_toast("岩壁之间还没有能穿过去的缝隙。")
		return

	if current_map == MAP_SLIME_RIGHT and next.x >= GRID_W and FISSURE_EXIT_Y.has(next.y):
		if phase == Phase.SLIME_DONE:
			_finish_slime_trial()
		else:
			_show_toast("挡路的史莱姆还没有离开。")
		return

	if current_map == MAP_SLIME_LEFT and not fissure_open and _is_fissure_block_cell(next):
		_show_toast("岩壁间的缝隙还打不开。")
		return

	if current_map == MAP_SLIME_RIGHT and _is_visible_slime_cell(next):
		_slime_failure("", "被弄死了。")
		return

	if sentence_active and _is_sentence_cell(next):
		_show_toast("举起圣剑，对准这个字按删除键。")
		return

	if not _is_walkable(current_map, next):
		_show_toast("岩壁挡住了去路。")
		return

	player_cell = next
	_update_player_position()


func _is_walkable(map_index: int, cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= GRID_W or cell.y < 0 or cell.y >= GRID_H:
		return false
	var rows: Array = map_data[map_index]["rows"]
	var text := String(rows[cell.y]).substr(cell.x, 1)
	return text != "岩" and text != "窟"


func _start_room_transition() -> void:
	phase = Phase.ROOM_TRANSITION
	input_locked = true
	_clear_dialogue()
	_set_hint("")
	var tween := create_tween()
	tween.tween_property(world_layer, "position:x", -MAP_TREASURE * VIEWPORT_SIZE.x, 1.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	current_map = MAP_TREASURE
	player_cell = TREASURE_ROOM_SPAWN
	_update_player_position()
	_play_bgm(BGM_SWORD)
	phase = Phase.ROOM4_DIALOGUE
	_start_dialogue(MAP_TREASURE, [
		["走着走着，来到一处较为宽敞的地方。", "天顶有一个小窗，洒下深蓝色的光芒。"]
	], Callable(self, "_after_room4_intro"))


func _after_room4_intro() -> void:
	_show_treasure_text()
	_start_dialogue(MAP_TREASURE, [
		["光线照亮之处，堆满了形形色色的武器与珍宝，", "想必都是蛇妖和喽啰四处搜刮来的战利品吧。"],
		["诗人说的贝克思贝斯之剑肯定也在里面！"]
	], Callable(self, "_start_opportunity_sequence"))


func _start_opportunity_sequence() -> void:
	_show_opportunity_text()
	_start_dialogue(MAP_TREASURE, [
		["定睛一看，四周的墙面闪灭着好几行字，", "全部都是相同内容：「机会稍纵即逝。」"],
		["似乎隐约暗示着，想找到贝克思贝斯之剑，", "必须把握短暂的机会，心无旁骛地仔细观察。"]
	], Callable(self, "_begin_find_sword"))


func _begin_find_sword() -> void:
	phase = Phase.FIND_SWORD
	input_locked = false
	sword_spawn_delay = SWORD_SPAWN_WAIT
	_set_hint("")


func _update_sword(delta: float) -> void:
	if sword_active:
		sword_life -= delta
		if sword_life <= 0:
			_vanish_sword()
		return
	sword_spawn_delay -= delta
	if sword_spawn_delay <= 0:
		_spawn_sword()


func _spawn_sword() -> void:
	_refresh_metal_letters()
	sword_cell = _pick_sword_cell()
	_set_metal_cell_visible(sword_cell, false)
	_set_sword_position(sword_cell)
	sword_label.visible = true
	sword_active = true
	sword_life = SWORD_VISIBLE_TIME
	_play_random_se([
		"res://Assets/audio/se/第二章 音效/SE_2_21_sword_crash_A.wav",
		"res://Assets/audio/se/第二章 音效/SE_2_21_sword_crash_B.wav",
		"res://Assets/audio/se/第二章 音效/SE_2_21_sword_crash_C.wav"
	])


func _vanish_sword() -> void:
	sword_active = false
	sword_label.visible = false
	_set_metal_cell_visible(sword_cell, true)
	sword_spawn_delay = SWORD_SPAWN_WAIT
	_play_random_se([
		"res://Assets/audio/se/第二章 音效/SE_2_22_sword_vanish_A.wav",
		"res://Assets/audio/se/第二章 音效/SE_2_22_sword_vanish_B.wav"
	])


func _try_interact() -> void:
	if phase == Phase.FIND_SWORD and sword_active and _cell_distance(player_cell, sword_cell) <= 1.15:
		_grab_sword(player_cell, sword_cell)
		return
	if phase == Phase.FIND_SWORD:
		var front := player_cell + last_direction
		if _is_metal_cell(front):
			_inspect_metal_cell(front)
			return


func _grab_sword(player_display_cell: Vector2i, sword_display_cell: Vector2i) -> void:
	if phase != Phase.FIND_SWORD:
		return
	phase = Phase.SWORD_FOUND
	input_locked = true
	sword_active = false
	_clear_treasure_text()
	_clear_opportunity_text()
	_set_hint("")
	player_cell = player_display_cell
	_update_player_position()
	sword_cell = sword_display_cell
	_set_sword_position(sword_display_cell)
	sword_label.visible = true
	sword_label.modulate = Color.WHITE
	_play_se(SE_DRAW)
	_start_dialogue(MAP_TREASURE, [
		["宝物堆中，一支剑柄闪耀着与众不同的光泽，", "我连忙伸手将它抽了出来，转头看向诗人。"],
		["诗人露出一个欣慰的微笑。"],
		["我感受到前所未有的能量在掌心流转，", "地面及岩壁震动，耳边传来一串谜样的响声……"]
	], Callable(self, "_play_sword_cutscene"))


func _play_sword_cutscene() -> void:
	phase = Phase.SWORD_CUTSCENE
	_clear_dialogue()
	_play_se(SE_SWING)
	_play_se(SE_MELODY)
	player_label.visible = false
	sword_label.visible = false
	cutscene_layer.visible = true
	if video_player.stream != null:
		video_player.play()
		await video_player.finished
	else:
		await get_tree().create_timer(7.0).timeout
	if video_player.is_playing():
		video_player.stop()
	cutscene_layer.visible = false
	_play_se(SE_RETURN)
	player_label.visible = true
	sword_label.visible = false
	await _shake_world(0.45, 22.0)
	_start_explanation_sequence()


func _start_explanation_sequence() -> void:
	phase = Phase.EXPLAIN
	_start_dialogue(MAP_TREASURE, [
		["「清除文字之中恶的成分，", "就是勇者的责任。」"],
		["「只要心念上的一个微小改变，」诗人说：", "「就能让世界截然不同。」"],
		["「找出不该存在的字，举起圣剑，然后对它按下", "『删除键』便是。」"]
	], Callable(self, "_start_lamp_problem"))


func _start_lamp_problem() -> void:
	phase = Phase.LAMP_WAIT
	var tween := create_tween()
	tween.tween_property(dark_overlay, "color:a", 0.78, 0.8)
	await tween.finished
	_start_dialogue(MAP_TREASURE, [
		["「勇者，」诗人扬起法杖，说：", "「灯不亮了。」"]
	], Callable(self, "_show_lamp_sentence"))


func _show_lamp_sentence() -> void:
	_set_hint("")
	_start_delete_sentence(["灯", "不", "亮", "了", "。"], 1, Callable(self, "_lamp_deleted"))


func _lamp_deleted() -> void:
	_clear_sentence()
	_play_se(SE_FIRE)
	var tween := create_tween()
	tween.tween_property(dark_overlay, "color:a", 0.0, 0.7)
	await tween.finished
	_start_air_problem()


func _start_air_problem() -> void:
	phase = Phase.AIR_WAIT
	var tween := create_tween()
	tween.tween_property(blur_overlay, "color:a", 0.36, 0.45)
	_start_dialogue(MAP_TREASURE, [
		["这密闭的洞窟，眼看就快要没有空气……"]
	], Callable(self, "_show_air_sentence"))


func _show_air_sentence() -> void:
	_set_hint("")
	_start_delete_sentence(["没", "有", "空", "气"], 0, Callable(self, "_air_deleted"))


func _air_deleted() -> void:
	_play_se(SE_WIND)
	_clear_sentence()
	var tween := create_tween()
	tween.tween_property(blur_overlay, "color:a", 0.0, 0.85)
	await tween.finished
	_start_dialogue(MAP_TREASURE, [
		["一阵凉风拂过脸庞，伴随着清新的滋味。"],
		["刚才拔剑时引发的震动，", "落下碎石封住了入口。"],
		["前、后、左、右都被堵死，上方是坚硬石壁，", "看样子，只有忘掉下去这一条路了……"]
	], Callable(self, "_show_fall_sentence"))


func _show_fall_sentence() -> void:
	phase = Phase.FALL_WAIT
	_set_hint("")
	_start_delete_sentence(["只", "有", "忘", "掉", "下", "去", "这", "一", "条", "路", "了", "…", "…"], 2, Callable(self, "_fall_deleted"))


func _fall_deleted() -> void:
	_play_se(SE_ROCK)
	_clear_sentence()
	phase = Phase.FALLING
	_start_dialogue(MAP_TREASURE, [
		["低头一看，", "等待在脚底下的，", "是岩窟的无底深渊，"],
		["以及迎面而来的未来剧本。"]
	], Callable(self, "_start_fall_sequence"))


func _start_fall_sequence() -> void:
	input_locked = true
	_clear_dialogue()
	_set_hint("")
	await _fade_bottom_row(MAP_TREASURE)
	await _shake_world(0.35, 16.0)
	var fall_tween := create_tween()
	fall_tween.set_parallel(true)
	fall_tween.tween_property(player_label, "position:y", VIEWPORT_SIZE.y + CELL, 1.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fall_tween.tween_property(dark_overlay, "color:a", 1.0, 1.35)
	await fall_tween.finished
	await _play_falling_interlude()

	current_map = MAP_SLIME_LEFT
	world_layer.position = Vector2(-MAP_SLIME_LEFT * VIEWPORT_SIZE.x, 0)
	player_cell = SLIME_LEFT_SPAWN
	last_direction = Vector2i.UP
	player_label.visible = true
	_update_player_position()
	_show_fissure_overlay()
	var wake_tween := create_tween()
	wake_tween.tween_property(dark_overlay, "color:a", 0.0, 0.9)
	await wake_tween.finished
	_start_slime_left_intro()


func _play_falling_interlude() -> void:
	_clear_falling_interlude()
	falling_layer.visible = true

	var back := ColorRect.new()
	back.size = VIEWPORT_SIZE
	back.color = Color.BLACK
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	falling_layer.add_child(back)

	var fake_player := _make_label("我", 56, PLAYER_COLOR)
	fake_player.position = Vector2(15 * CELL, 0)
	fake_player.size = Vector2(CELL, CELL)
	falling_layer.add_child(fake_player)

	var phrases := [
		"＿不断往下掉",
		"不知道＿还会坠落多久",
		"＿这是要死了吗？",
	]
	var phrase_labels: Array[Label] = []
	for i in range(phrases.size()):
		var phrase := String(phrases[i])
		var start_x := 12 + i % 2 * 3
		var start_y := VIEWPORT_SIZE.y + (i * 180)
		for char_index in range(phrase.length()):
			var label := _make_label(phrase.substr(char_index, 1), 56, DIALOGUE_COLOR)
			label.position = Vector2((start_x + char_index) * CELL, start_y)
			label.size = Vector2(CELL, CELL)
			falling_layer.add_child(label)
			phrase_labels.append(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fake_player, "position:y", VIEWPORT_SIZE.y + CELL * 2, 2.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	for label in phrase_labels:
		tween.tween_property(label, "position:y", label.position.y - VIEWPORT_SIZE.y - CELL * 6, 2.8).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	_clear_falling_interlude()
	falling_layer.visible = false
	dark_overlay.color.a = 1.0


func _clear_falling_interlude() -> void:
	for child in falling_layer.get_children():
		child.queue_free()


func _fade_bottom_row(map_index: int) -> void:
	var labels: Array[Label] = []
	if map_index < 0 or map_index >= map_roots.size():
		return
	for child in map_roots[map_index].get_children():
		if child is Label and int(round(child.position.y / CELL)) == GRID_H - 1:
			labels.append(child)
	if labels.is_empty():
		return
	var tween := create_tween()
	tween.set_parallel(true)
	for label in labels:
		tween.tween_property(label, "modulate:a", 0.0, 0.7)
	await tween.finished
	for label in labels:
		label.queue_free()


func _show_fissure_overlay() -> void:
	_clear_fissure_overlay()
	fissure_open = false
	for y in range(FISSURE_PATTERN.size()):
		var row := String(FISSURE_PATTERN[y])
		for x in range(row.length()):
			var text := row.substr(x, 1)
			if text == "＿":
				continue
			var cell := FISSURE_ORIGIN + Vector2i(x, y)
			var label := _make_world_cell_label(text, MAP_SLIME_LEFT, cell.x, cell.y, WALL_COLOR)
			label.z_index = 12
			actor_layer.add_child(label)
			fissure_labels.append(label)


func _clear_fissure_overlay() -> void:
	for label in fissure_labels:
		label.queue_free()
	fissure_labels.clear()


func _is_fissure_block_cell(cell: Vector2i) -> bool:
	var local := cell - FISSURE_ORIGIN
	if local.x < 0 or local.y < 0 or local.y >= FISSURE_PATTERN.size():
		return false
	var row := String(FISSURE_PATTERN[local.y])
	if local.x >= row.length():
		return false
	return row.substr(local.x, 1) != "＿"


func _open_fissure() -> void:
	fissure_open = true
	if fissure_labels.is_empty():
		return
	var tween := create_tween()
	tween.set_parallel(true)
	for label in fissure_labels:
		tween.tween_property(label, "modulate:a", 0.0, 1.4)
	await tween.finished
	_clear_fissure_overlay()


func _start_slime_left_intro() -> void:
	phase = Phase.SLIME_LEFT_INTRO
	_start_dialogue(MAP_SLIME_LEFT, [
		["睁开眼睛……", "坚硬的岩壁围绕着四周。"]
	], Callable(self, "_show_left_fissure_sentence"))


func _show_left_fissure_sentence() -> void:
	phase = Phase.SLIME_LEFT_WAIT
	_start_delete_sentence_lines(
		[_chars("惊讶地发现自己没摔死，"), _chars("而这里似乎没有一条缝隙。")],
		[Vector2i(10, 8), Vector2i(10, 9)],
		[Vector2i(15, 9)],
		[Vector2i(17, 8)],
		Callable(self, "_left_fissure_deleted"),
		Callable(self, "_left_fissure_failed"),
		MAP_SLIME_LEFT
	)


func _left_fissure_deleted() -> void:
	_clear_sentence()
	_play_se(SE_ROCK)
	await _open_fissure()
	_start_dialogue(MAP_SLIME_LEFT, [
		["岩壁之间发出碎裂声。", "一条细缝露了出来。"]
	], Callable(self, "_unlock_left_cave"))


func _unlock_left_cave() -> void:
	phase = Phase.SLIME_LEFT_WAIT
	input_locked = false
	_set_hint("")


func _left_fissure_failed() -> void:
	_slime_failure("", "摔死了。")


func _enter_slime_right() -> void:
	if phase == Phase.SLIME_RIGHT_INTRO or current_map == MAP_SLIME_RIGHT:
		return
	phase = Phase.SLIME_RIGHT_INTRO
	input_locked = true
	_clear_sentence()
	_clear_dialogue()
	var tween := create_tween()
	tween.tween_property(world_layer, "position:x", -MAP_SLIME_RIGHT * VIEWPORT_SIZE.x, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	current_map = MAP_SLIME_RIGHT
	player_cell = SLIME_RIGHT_SPAWN
	last_direction = Vector2i.RIGHT
	_update_player_position()
	_show_slimes()
	_start_dialogue(MAP_SLIME_RIGHT, [
		["穿过了岩缝，", "来到了另一个洞窟。"],
		["在洞穴的另一头，", "有几只史莱姆。"],
		["他们似乎察觉到我的存在。", "不妙了。"]
	], Callable(self, "_show_slime_stage1_sentence"))


func _show_slime_stage1_sentence() -> void:
	phase = Phase.SLIME_STAGE1
	slime_reinforcement_timer = SLIME_REINFORCEMENT_INTERVAL
	slime_reinforcement_cursor = 0
	_start_delete_sentence_lines(
		[_chars("史莱姆不断冒出，"), _chars("如漫天飞舞闪烁的火焰。")],
		[Vector2i(8, 7), Vector2i(8, 8)],
		[Vector2i(12, 7)],
		[],
		Callable(self, "_slime_stage1_deleted"),
		Callable(),
		MAP_SLIME_RIGHT
	)


func _slime_stage1_deleted() -> void:
	_clear_sentence()
	await get_tree().create_timer(0.45).timeout
	_show_slime_stage2_sentence()


func _show_slime_stage2_sentence() -> void:
	phase = Phase.SLIME_STAGE2
	_start_delete_sentence_lines(
		[_chars("史莱姆盘踞洞窟，"), _chars("没有要撤退的迹象。")],
		[Vector2i(8, 7), Vector2i(8, 8)],
		[Vector2i(8, 8)],
		[Vector2i(9, 8), Vector2i(10, 8)],
		Callable(self, "_slime_stage2_deleted"),
		Callable(self, "_slime_stage2_failed"),
		MAP_SLIME_RIGHT
	)


func _slime_stage2_deleted() -> void:
	_clear_sentence()
	await _fade_slime_indices(SLIME_PARTIAL_FADE_INDICES)
	_show_slime_stage3_sentence()


func _slime_stage2_failed() -> void:
	_slime_failure("空气越来越稀薄，||视线越来越模糊……", "死了。")


func _show_slime_stage3_sentence() -> void:
	phase = Phase.SLIME_STAGE3
	_start_delete_sentence_lines(
		[_chars("任凭剑气在洞里轰轰作响，"), _chars("对敌方一筹莫展。")],
		[Vector2i(8, 7), Vector2i(8, 8)],
		[Vector2i(8, 8), Vector2i(9, 8)],
		[],
		Callable(self, "_slime_stage3_deleted"),
		Callable(),
		MAP_SLIME_RIGHT
	)


func _slime_stage3_deleted() -> void:
	_clear_sentence()
	await get_tree().create_timer(0.65).timeout
	_show_slime_stage4_sentence()


func _show_slime_stage4_sentence() -> void:
	phase = Phase.SLIME_STAGE4
	_start_delete_sentence_lines(
		[_chars("史莱姆们扭动着黏糊糊的身体跑来了，"), _chars("眼前这个画面不是很舒服……")],
		[Vector2i(8, 7), Vector2i(8, 8)],
		[Vector2i(22, 7)],
		[Vector2i(14, 8)],
		Callable(self, "_slime_stage4_deleted"),
		Callable(self, "_slime_stage4_failed"),
		MAP_SLIME_RIGHT
	)


func _slime_stage4_deleted() -> void:
	_clear_sentence()
	await _run_slimes_away()
	phase = Phase.SLIME_DONE
	_start_dialogue(MAP_SLIME_RIGHT, [
		["挡路的史莱姆已经跑光。", "赶紧把握机会离开这里吧。"]
	], Callable(self, "_unlock_slime_exit"))


func _slime_stage4_failed() -> void:
	_slime_failure("看着看着，||害我好想安稳地睡上一觉……", "睡死了。")


func _unlock_slime_exit() -> void:
	phase = Phase.SLIME_DONE
	input_locked = false
	_set_hint("")


func _finish_slime_trial() -> void:
	if phase != Phase.SLIME_DONE:
		return
	phase = Phase.COMPLETE
	input_locked = true
	_start_dialogue(MAP_SLIME_RIGHT, [
		["完成剑试炼。", "接下来进入避难洞窟。"]
	], Callable(self, "_fade_to_complete_flow"))


func _fade_to_complete_flow() -> void:
	var tween := create_tween()
	tween.tween_property(dark_overlay, "color:a", 1.0, 0.7)
	await tween.finished
	_complete_flow()


func _complete_flow() -> void:
	input_locked = true
	_set_hint("")


func _slime_failure(line: String, death_sentence: String) -> void:
	_clear_sentence()
	_clear_slimes()
	phase = Phase.COMPLETE
	input_locked = true
	pending_death_sentence = death_sentence
	if line.is_empty():
		_show_pending_death()
		return
	_start_dialogue(current_map, [
		Array(line.split("||"))
	], Callable(self, "_show_pending_death"))


func _show_pending_death() -> void:
	_show_death_screen(pending_death_sentence)


func _show_death_screen(death_sentence: String) -> void:
	_clear_dialogue()
	_clear_sentence()
	_clear_falling_interlude()
	dialogue_active = false
	phase = Phase.COMPLETE
	input_locked = true
	_set_hint("")
	for child in death_layer.get_children():
		child.queue_free()
	death_layer.visible = true

	var back := ColorRect.new()
	back.size = VIEWPORT_SIZE
	back.color = Color(0, 0, 0, 0)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	death_layer.add_child(back)

	var tween := create_tween()
	tween.tween_property(back, "color:a", 1.0, 0.45)
	await tween.finished

	var start_x := int((GRID_W - death_sentence.length()) / 2.0)
	var y := 9
	for i in range(death_sentence.length()):
		var label := _make_label(death_sentence.substr(i, 1), 56, DIALOGUE_COLOR)
		label.position = Vector2((start_x + i) * CELL, y * CELL)
		label.size = Vector2(CELL, CELL)
		death_layer.add_child(label)

	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()


func _show_slimes() -> void:
	_clear_slimes()
	for i in range(SLIME_CELLS.size()):
		var cell: Vector2i = SLIME_CELLS[i]
		var label := _make_world_cell_label("史", MAP_SLIME_RIGHT, cell.x, cell.y, DIALOGUE_COLOR)
		label.z_index = 18
		label.visible = SLIME_INITIAL_INDICES.has(i)
		actor_layer.add_child(label)
		slime_labels.append(label)
		slime_visible.append(label.visible)


func _clear_slimes() -> void:
	for label in slime_labels:
		label.queue_free()
	slime_labels.clear()
	slime_visible.clear()
	slime_reinforcement_timer = 0.0
	slime_reinforcement_cursor = 0


func _update_slime_reinforcements(delta: float) -> void:
	if slime_reinforcement_cursor >= SLIME_REINFORCEMENT_INDICES.size():
		return
	slime_reinforcement_timer -= delta
	if slime_reinforcement_timer > 0.0:
		return
	var index: int = SLIME_REINFORCEMENT_INDICES[slime_reinforcement_cursor]
	slime_reinforcement_cursor += 1
	slime_reinforcement_timer = SLIME_REINFORCEMENT_INTERVAL
	_reveal_slime_index(index)


func _reveal_slime_index(index: int) -> void:
	if index < 0 or index >= slime_labels.size() or slime_visible[index]:
		return
	var label := slime_labels[index]
	label.visible = true
	label.modulate.a = 0.0
	slime_visible[index] = true
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.45)


func _fade_slime_indices(indices: Array) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	var has_target := false
	for index in indices:
		if index < 0 or index >= slime_labels.size():
			continue
		var label := slime_labels[index]
		if not label.visible:
			continue
		has_target = true
		tween.tween_property(label, "modulate:a", 0.0, 0.65)
	if has_target:
		await tween.finished
	for index in indices:
		if index >= 0 and index < slime_labels.size():
			slime_labels[index].visible = false
			slime_visible[index] = false


func _run_slimes_away() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	var has_target := false
	for i in range(slime_labels.size()):
		if not slime_visible[i]:
			continue
		has_target = true
		var label := slime_labels[i]
		tween.tween_property(label, "position:x", label.position.x + CELL * 7, 1.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_property(label, "modulate:a", 0.0, 1.1)
	if has_target:
		await tween.finished
	for i in range(slime_labels.size()):
		slime_labels[i].visible = false
		slime_visible[i] = false


func _is_visible_slime_cell(cell: Vector2i) -> bool:
	if current_map != MAP_SLIME_RIGHT:
		return false
	for i in range(SLIME_CELLS.size()):
		if slime_visible.size() > i and slime_visible[i] and SLIME_CELLS[i] == cell:
			return true
	return false


func _chars(text: String) -> Array[String]:
	var result: Array[String] = []
	for i in range(text.length()):
		result.append(text.substr(i, 1))
	return result


func _start_dialogue(map_index: int, pages: Array, callback: Callable = Callable()) -> void:
	dialogue_pages = pages
	dialogue_index = 0
	dialogue_callback = callback
	dialogue_active = true
	input_locked = true
	active_dialogue_map = map_index
	_render_dialogue(active_dialogue_map, dialogue_pages[dialogue_index], true)


func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index < dialogue_pages.size():
		_render_dialogue(active_dialogue_map, dialogue_pages[dialogue_index], true)
		return
	dialogue_active = false
	_clear_dialogue()
	if dialogue_callback.is_valid():
		dialogue_callback.call()


func _render_dialogue(map_index: int, lines: Array, with_continue: bool) -> void:
	_clear_dialogue()
	for line_index in range(lines.size()):
		var line := String(lines[line_index])
		if with_continue and line_index == lines.size() - 1:
			line += "▽"
		var start_x := 6
		var y := 14 + line_index
		for i in range(line.length()):
			var text := line.substr(i, 1)
			if text == " ":
				continue
			var label := _make_world_cell_label(text, map_index, start_x + i, y, DIALOGUE_COLOR)
			dialogue_layer.add_child(label)


func _clear_dialogue() -> void:
	for child in dialogue_layer.get_children():
		child.queue_free()


func _show_treasure_text() -> void:
	_clear_treasure_text()
	metal_slots.clear()
	metal_cells.clear()
	metal_labels.clear()
	metal_letters.clear()

	for y in range(TREASURE_SOURCE_ROWS.size()):
		var row := String(TREASURE_SOURCE_ROWS[y])
		for x in range(row.length()):
			var text := row.substr(x, 1)
			if text == "＿":
				continue
			var cell := TREASURE_ORIGIN + Vector2i(x, y)
			var key := _cell_key(cell)
			var label := _make_world_cell_label(text, MAP_TREASURE, cell.x, cell.y, DIALOGUE_COLOR)
			treasure_layer.add_child(label)
			metal_slots.append(cell)
			metal_cells[key] = text
			metal_labels[key] = label
			metal_letters.append(text)


func _refresh_metal_letters() -> void:
	if metal_slots.is_empty():
		return
	metal_letters.shuffle()
	for i in range(metal_slots.size()):
		var cell := metal_slots[i]
		var key := _cell_key(cell)
		var text := metal_letters[i]
		metal_cells[key] = text
		if metal_labels.has(key):
			var label := metal_labels[key] as Label
			label.text = text
			label.visible = true


func _pick_sword_cell() -> Vector2i:
	var candidates: Array[Vector2i] = []
	for y in range(SOURCE_SWORD_MASK.size()):
		var row := String(SOURCE_SWORD_MASK[y])
		for x in range(row.length()):
			if row.substr(x, 1) == "1":
				var cell := TREASURE_ORIGIN + Vector2i(x, y)
				if metal_cells.has(_cell_key(cell)):
					candidates.append(cell)
	if candidates.is_empty():
		return TREASURE_ORIGIN
	return candidates[rng.randi_range(0, candidates.size() - 1)]


func _is_metal_cell(cell: Vector2i) -> bool:
	return current_map == MAP_TREASURE and metal_cells.has(_cell_key(cell))


func _set_metal_cell_visible(cell: Vector2i, is_visible: bool) -> void:
	var key := _cell_key(cell)
	if metal_labels.has(key):
		var label := metal_labels[key] as Label
		label.visible = is_visible


func _inspect_metal_cell(cell: Vector2i) -> void:
	if not metal_cells.has(_cell_key(cell)):
		return
	var messages := [
		"只是个金光闪闪的乡里手艺品。",
		"这看起来不太像圣剑……",
		"机会出现的瞬间，就是带走武器的机会。",
		"机会消失的时候，或许还有更好的机会。"
	]
	_show_toast(messages[rng.randi_range(0, messages.size() - 1)])


func _show_opportunity_text() -> void:
	_clear_opportunity_text()
	for group_index in range(OPPORTUNITY_CELLS.size()):
		var pos: Vector2i = OPPORTUNITY_CELLS[group_index]
		var text := "机会稍纵即逝"
		for i in range(text.length()):
			var label := _make_world_cell_label(text.substr(i, 1), MAP_TREASURE, pos.x + i, pos.y, DIALOGUE_COLOR)
			label.modulate = Color(0, 0, 0, 1.0)
			opportunity_layer.add_child(label)
			opportunity_labels.append(label)
			opportunity_offsets.append(float(OPPORTUNITY_START_OFFSETS[group_index]))
	opportunity_time = 0.0
	opportunity_active = true
	_update_opportunity_text(0.0)


func _clear_treasure_text() -> void:
	for child in treasure_layer.get_children():
		child.queue_free()
	metal_slots.clear()
	metal_cells.clear()
	metal_labels.clear()
	metal_letters.clear()


func _clear_opportunity_text() -> void:
	for child in opportunity_layer.get_children():
		child.queue_free()
	opportunity_labels.clear()
	opportunity_offsets.clear()
	opportunity_active = false
	opportunity_time = 0.0


func _update_opportunity_text(delta: float) -> void:
	opportunity_time += delta
	for i in range(opportunity_labels.size()):
		var label := opportunity_labels[i]
		var elapsed := opportunity_time - opportunity_offsets[i]
		var brightness := _get_opportunity_brightness(elapsed)
		label.modulate = Color(
			DIALOGUE_COLOR.r * brightness,
			DIALOGUE_COLOR.g * brightness,
			DIALOGUE_COLOR.b * brightness,
			1.0
		)


func _get_opportunity_brightness(elapsed: float) -> float:
	if elapsed < 0.0:
		return 0.0
	if elapsed < 1.0:
		return 0.2 * elapsed
	var loop_elapsed := fmod(elapsed - 1.0, OPPORTUNITY_LOOP_TIME)
	if loop_elapsed < 1.0:
		return 0.2 + 0.8 * loop_elapsed
	if loop_elapsed < 5.0:
		return 1.0 - 0.8 * ((loop_elapsed - 1.0) / 4.0)
	return 0.2


func _start_delete_sentence(chars: Array[String], target_index: int, callback: Callable) -> void:
	var start_x := int((GRID_W - chars.size()) / 2.0)
	var y := 8
	_start_delete_sentence_lines(
		[chars],
		[Vector2i(start_x, y)],
		[Vector2i(start_x + target_index, y)],
		[],
		callback,
		Callable(),
		current_map
	)


func _start_delete_sentence_lines(lines: Array, starts: Array[Vector2i], success_cells: Array[Vector2i], fail_cells: Array[Vector2i], callback: Callable, fail_callback: Callable, map_index: int) -> void:
	sentence_layer.visible = false
	sentence_locked = false
	sentence_active = true
	sentence_callback = callback
	sentence_fail_callback = fail_callback
	sentence_map_index = map_index
	input_locked = false
	for label in active_sentence_labels:
		label.queue_free()
	active_sentence_labels.clear()
	sentence_cells.clear()
	sentence_highlight_cells.clear()
	sentence_success_indices.clear()
	sentence_fail_indices.clear()
	sentence_target_index = -1
	sentence_target_cell = Vector2i.ZERO

	for line_index in range(lines.size()):
		var line_chars: Array = lines[line_index]
		var start := starts[line_index]
		for i in range(line_chars.size()):
			var cell := Vector2i(start.x + i, start.y)
			var label := _make_world_cell_label(String(line_chars[i]), map_index, cell.x, cell.y, DIALOGUE_COLOR)
			actor_layer.add_child(label)
			active_sentence_labels.append(label)
			sentence_cells.append(cell)
			sentence_highlight_cells.append(cell)

	for success_cell in success_cells:
		var index := sentence_cells.find(success_cell)
		if index != -1:
			sentence_success_indices.append(index)
			if sentence_target_index == -1:
				sentence_target_index = index
				sentence_target_cell = success_cell

	for fail_cell in fail_cells:
		var index := sentence_cells.find(fail_cell)
		if index != -1:
			sentence_fail_indices.append(index)


func _try_delete_front_char() -> void:
	if sentence_locked:
		return
	var front := player_cell + last_direction
	var front_index := sentence_cells.find(front)
	if front_index == -1:
		if sentence_target_index != -1 and _cell_distance(player_cell, sentence_target_cell) <= 1.15:
			_show_toast("需要面对这个字。")
		else:
			_show_toast("圣剑没有砍中该字。")
		return

	if sentence_success_indices.has(front_index):
		await _delete_sentence_index(front_index)
		await _play_sentence_legal_animation()
		if sentence_callback.is_valid():
			sentence_callback.call()
		return

	if sentence_fail_indices.has(front_index):
		await _delete_sentence_index(front_index)
		if sentence_fail_callback.is_valid():
			sentence_fail_callback.call()
		return

	return


func _delete_sentence_index(index: int) -> void:
	sentence_locked = true
	var label := active_sentence_labels[index]
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 0.0, 0.22)
	tween.tween_property(label, "scale", Vector2(1.7, 1.7), 0.22)
	await tween.finished
	label.visible = false


func _play_sentence_legal_animation() -> void:
	var cells := sentence_highlight_cells
	if cells.is_empty():
		cells = sentence_cells
	if cells.is_empty():
		return
	var min_x := cells[0].x
	var max_x := cells[0].x
	var min_y := cells[0].y
	var max_y := cells[0].y
	for cell in cells:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_y = maxi(max_y, cell.y)
	var frame := Control.new()
	frame.position = Vector2(sentence_map_index * VIEWPORT_SIZE.x + min_x * CELL, min_y * CELL)
	frame.size = Vector2((max_x - min_x + 1) * CELL, (max_y - min_y + 1) * CELL)
	frame.z_index = -2
	frame.modulate = Color(1, 1, 1, 0)
	actor_layer.add_child(frame)

	var fill := ColorRect.new()
	fill.size = frame.size
	fill.color = Color(1, 1, 1, 0.24)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(fill)

	var line_color := Color(1, 1, 1, 0.86)
	var top := _make_legal_line(Vector2.ZERO, Vector2(frame.size.x, 4), line_color)
	var bottom := _make_legal_line(Vector2(0, frame.size.y - 4), Vector2(frame.size.x, 4), line_color)
	var left := _make_legal_line(Vector2.ZERO, Vector2(4, frame.size.y), line_color)
	var right := _make_legal_line(Vector2(frame.size.x - 4, 0), Vector2(4, frame.size.y), line_color)
	frame.add_child(top)
	frame.add_child(bottom)
	frame.add_child(left)
	frame.add_child(right)

	var screen_flash := ColorRect.new()
	screen_flash.size = VIEWPORT_SIZE
	screen_flash.color = Color(1, 1, 1, 0)
	screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(screen_flash)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(frame, "modulate:a", 1.0, 0.16)
	tween.tween_property(screen_flash, "color:a", 0.72, 0.12)
	await tween.finished

	var flash_out_tween := create_tween()
	flash_out_tween.tween_property(screen_flash, "color:a", 0.0, 0.22)
	await flash_out_tween.finished

	await get_tree().create_timer(LEGAL_HIGHLIGHT_HOLD_TIME).timeout

	var out_tween := create_tween()
	out_tween.tween_property(frame, "modulate:a", 0.0, 0.28)
	await out_tween.finished
	frame.queue_free()
	screen_flash.queue_free()


func _make_legal_line(pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var line := ColorRect.new()
	line.position = pos
	line.size = size
	line.color = color
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


func _clear_sentence() -> void:
	for label in active_sentence_labels:
		label.queue_free()
	active_sentence_labels.clear()
	sentence_cells.clear()
	sentence_highlight_cells.clear()
	sentence_success_indices.clear()
	sentence_fail_indices.clear()
	sentence_layer.visible = false
	sentence_locked = false
	sentence_active = false
	sentence_target_index = -1
	sentence_fail_callback = Callable()


func _is_sentence_cell(cell: Vector2i) -> bool:
	return sentence_active and sentence_cells.has(cell)


func _update_player_position() -> void:
	player_label.position = Vector2(current_map * VIEWPORT_SIZE.x + player_cell.x * CELL, player_cell.y * CELL)


func _set_sword_position(cell: Vector2i) -> void:
	sword_label.position = Vector2(current_map * VIEWPORT_SIZE.x + cell.x * CELL, cell.y * CELL)


func _make_world_cell_label(text: String, map_index: int, grid_x: int, grid_y: int, color: Color) -> Label:
	var label := _make_cell_label(text, grid_x, grid_y, color)
	label.position.x += map_index * VIEWPORT_SIZE.x
	return label


func _make_cell_label(text: String, grid_x: int, grid_y: int, color: Color) -> Label:
	var label := _make_label(text, 56, color)
	label.position = Vector2(grid_x * CELL, grid_y * CELL)
	label.size = Vector2(CELL, CELL)
	return label


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


func _cell_distance(a: Vector2i, b: Vector2i) -> float:
	return Vector2(a.x, a.y).distance_to(Vector2(b.x, b.y))


func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


func _is_accept_key(event: InputEventKey) -> bool:
	return event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_E


func _is_delete_key(event: InputEventKey) -> bool:
	return event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE


func _set_hint(text: String) -> void:
	hint_label.text = text


func _show_toast(text: String) -> void:
	toast_label.text = text
	var tween := create_tween()
	tween.tween_property(toast_label, "modulate:a", 1.0, 0.12)
	tween.tween_interval(1.1)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.3)


func _flash_success() -> void:
	var flash := ColorRect.new()
	flash.size = VIEWPORT_SIZE
	flash.color = Color(1, 1, 1, 0)
	fx_layer.add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.72, 0.08)
	tween.tween_property(flash, "color:a", 0.0, 0.28)
	await tween.finished
	flash.queue_free()


func _shake_world(duration: float, strength: float) -> void:
	var original := world_layer.position
	var elapsed := 0.0
	while elapsed < duration:
		world_layer.position = original + Vector2(rng.randf_range(-strength, strength), rng.randf_range(-strength, strength))
		await get_tree().create_timer(0.035).timeout
		elapsed += 0.035
	world_layer.position = original


func _play_bgm(path: String) -> void:
	var stream := load(path)
	if stream == null:
		return
	bgm_player.stream = stream
	bgm_player.volume_db = -7.0
	bgm_player.play()


func _play_se(path: String) -> void:
	var stream := load(path)
	if stream == null or se_players.is_empty():
		return
	var player := se_players[se_index]
	se_index = (se_index + 1) % se_players.size()
	player.stream = stream
	player.volume_db = -2.0
	player.play()


func _play_random_se(paths: Array[String]) -> void:
	_play_se(paths[rng.randi_range(0, paths.size() - 1)])
