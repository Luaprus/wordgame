extends Control

const CELL := 60
const GRID_W := 32
const GRID_H := 18
const VIEWPORT_SIZE := Vector2(1920, 1080)
const FONT := preload("res://Fonts/Zpix-v3.1.6.ttf")
const ME_DEFAULT_TEXTURE := preload("res://Assets/sprites/me/me_default.png")
const ME_WALK_TEXTURE := preload("res://Assets/sprites/me/me_walk.png")
const START_AT_SNAKE_FOR_TEST := false

const MAP_MAZE := 0
const MAP_TREASURE := 1
const MAP_SLIME_LEFT := 2
const MAP_SLIME_RIGHT := 3
const MAP_SNAKE := 4

const MAP_PATHS := [
	"res://Data/reference_maze_map.json",
	"res://Data/reference_treasure_room_empty_map.json",
	"res://Data/reference_slime_cave_left_map.json",
	"res://Data/reference_slime_cave_right_map.json",
	"res://Data/reference_snake_boss_map.json",
]

const BGM_SWORD := "res://Assets/audio/bgm/ch2/BGM_2_20_cave_sword_AB.ogg"
const SE_DRAW := "res://Assets/audio/se/sword_draw_out_1.wav"
const SE_SWING := "res://Assets/audio/se/第二章 音效/SE_2_23_sword_big_swing_B.wav"
const SE_RETURN := "res://Assets/audio/se/第二章 音效/SE_2_25_sword_return.wav"
const SE_WIND := "res://Assets/audio/se/第二章 音效/SE_2_26_wind_fill_C.wav"
const SE_ROCK := "res://Assets/audio/se/第二章 音效/SE_2_27_rock_break.wav"
const SE_FIRE := "res://Assets/audio/se/第三章 音效/SE_3_36_fire_lit_C.wav"
const SE_MELODY := "res://Assets/audio/se/MEL/MEL_2_24_sword.wav"
const BGM_SNAKE_FIGHT := "res://Assets/audio/bgm/ch2/BGM_2_16_snake_fight_AB.ogg"
const BGM_SNAKE_SECOND := "res://Assets/audio/bgm/ch2/BGM_2_40.1_snake_fight_second_A.ogg"
const BGM_SNAKE_END := "res://Assets/audio/bgm/ch2/BGM_2_50_qwerty_happy.ogg"
const SE_SNAKE_HISS := "res://Assets/audio/se/第二章 音效/SE_2_26_wind_fill_C.wav"
const SE_SNAKE_BIG_HISS := "res://Assets/audio/se/第二章 音效/SE_2_23_sword_big_swing_B.wav"
const SE_SNAKE_WINK := "res://Assets/audio/se/MEL/MEL_2_24_sword.wav"
const SE_SNAKE_STONE := "res://Assets/audio/se/第二章 音效/SE_2_27_rock_break.wav"
const SE_SNAKE_HIT := "res://Assets/audio/se/第二章 音效/SE_2_21_sword_crash_A.wav"
const SE_SNAKE_HURT := "res://Assets/audio/se/第二章 音效/SE_2_21_sword_crash_B.wav"
const SE_SNAKE_EVOLVE := "res://Assets/audio/se/第二章 音效/SE_2_23_sword_big_swing_B.wav"
const SE_SNAKE_WEAKEN := "res://Assets/audio/se/第二章 音效/SE_2_22_sword_vanish_A.wav"
const SE_SNAKE_WEAKEN_FINAL := "res://Assets/audio/se/第二章 音效/SE_2_22_sword_vanish_B.wav"
const SE_SNAKE_VANISH := "res://Assets/audio/se/第二章 音效/SE_2_22_sword_vanish_A.wav"
const SE_STONE_OFF := "res://Assets/audio/se/第二章 音效/SE_2_26_wind_fill_C.wav"
const SE_SNAKE_GRAB := "res://Assets/audio/se/sword_draw_out_1.wav"
const SE_SNAKE_BITE := "res://Assets/audio/se/第二章 音效/SE_2_21_sword_crash_C.wav"
const SE_SNAKE_HOLY := "res://Assets/audio/se/MEL/MEL_2_24_sword.wav"
const SWORD_VIDEO := "res://Assets/video/u_sword.ogv"
const BACKSPACE_SPLASH_TEXTURE := preload("res://Assets/sprites/backspace_splash/splash.png")
const BACKSPACE_CUT_SHADER := preload("res://Assets/shaders/cut2.gdshader")
const BACKSPACE_CUT_ANIMATION_CHARS := ["忘"]
const BACKSPACE_CUT_MASK_EXTRA_X := 14.0

const WALL_COLOR := Color(0.58, 0.58, 0.58, 1.0)
const DIALOGUE_COLOR := Color(0.86, 0.86, 0.86, 1.0)
const PLAYER_COLOR := Color(0.88, 0.88, 0.88, 1.0)
const DIM_COLOR := Color(0.38, 0.38, 0.38, 1.0)

const MAZE_EXIT_CELL := Vector2i(31, 5)
const TREASURE_ROOM_SPAWN := Vector2i(3, 5)
const TREASURE_ORIGIN := Vector2i(3, 3)
const SWORD_SPAWN_WAIT := 3.0
const SWORD_VISIBLE_TIME := 5.0
const PLAYER_WALK_VISUAL_TIME := 0.12
const PLAYER_WALK_FRAME_TIME := 0.055
const PLAYER_MOVE_REPEAT_TIME := 0.12
const PLAYER_BLOCKED_RETRY_TIME := 0.12
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
const SLIME_RIGHT_EXIT_Y := [8]
const SNAKE_SPAWN := Vector2i(16, 2)
const SNAKE_PLAYER_SPAWN := Vector2i(16, 6)
const SNAKE_SENTENCE_START := Vector2i(11, 5)
const SNAKE_REVERSE_SENTENCE_START := Vector2i(10, 3)
const SNAKE_BODY_TOP_Y := 10
const SNAKE_BODY_BIG_TOP_Y := 10
const SNAKE_SCROLL_SPEED := 60.0
const SNAKE_SCROLL_INITIAL_ROWS := 18
const SNAKE_SCROLL_LOOP_ROWS := 32
const SNAKE_LOOP_COPIES := 4
const SNAKE_TWIST_SPEED := 2.0
const SNAKE_TWIST_INTERVAL := 0.3
const SNAKE_TWIST_DISTANCE := 7.0
const SNAKE_FOLLOW_DURATION := 0.8
const SNAKE_SECOND_TALK_DELAY := 4.0
const SNAKE_SECOND_TALK_INTERVAL := 12.0
const SNAKE_RAY_INTERVAL := 5.0
const SNAKE_RAY_WARNING_TIME := 0.45
const SNAKE_RAY_HOLD_TIME := 0.55
const SNAKE_RAY_MOVE_TIME := 1.5
const SNAKE_RAY_DISTANCE := 780.0
const SNAKE_SECOND_REACTION_DELAY := 0.35
const SNAKE_SECOND_REACTION_HOLD_TIME := 1.0
const SNAKE_SECOND_REACTION_FADE_TIME := 1.0
const SNAKE_SECOND_REACTION_RESUME_DELAY := 0.8
const SNAKE_SECOND_POST_REVERSE_DELAY := 4.0
const SNAKE_OBJECT_RESULT_HOLD_TIME := 0.9
const SNAKE_LOOP_SOURCE_ROWS := [
	"＿＿＿＿＿壁＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿箱＿＿＿＿＿",
	"＿＿箱＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿",
	"＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿货货＿",
	"＿树＿＿＿＿坊＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿货货＿＿",
	"树树树＿坊坊坊＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿",
	"＿木＿坊坊坊坊坊＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿壁壁＿＿＿＿",
	"＿＿＿＿货货坊坊坊＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿树＿＿＿＿＿＿",
	"货货＿＿货货＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿树树树＿＿＿＿",
	"货货＿＿＿＿＿箱＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿木＿＿＿＿＿",
	"＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿",
	"＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿树＿＿",
	"＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿树树树＿＿",
	"＿＿＿＿＿栈＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿树＿＿＿木＿＿＿＿",
	"＿＿＿栈栈栈＿仓＿＿＿＿＿＿＿＿＿＿＿＿＿＿树树树＿＿＿＿＿＿＿",
	"＿树＿栈栈栈栈栈＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿木＿＿＿货货＿＿＿",
	"树树树＿栈栈栈＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿货货＿＿＿",
	"＿木＿＿栈栈栈＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿",
	"＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿箱＿",
	"＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿壁＿＿",
	"＿＿＿＿＿＿＿货货＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿壁＿＿",
	"＿＿＿货货＿＿货货＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿店＿＿＿＿壁＿＿",
	"＿＿＿货货＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿店店店＿箱＿＿＿＿",
	"＿货货＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿店店店店店＿＿＿＿＿",
	"＿货货＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿店店店＿＿＿＿＿＿",
	"＿＿＿货货＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿店店店＿＿＿＿＿＿",
	"＿＿＿货货＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿",
	"＿树＿＿＿＿箱＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿树＿",
	"树树树＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿树树树",
	"＿木＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿木＿",
	"＿箱＿树＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿",
	"＿＿树树树＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿",
	"＿＿＿木＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿",
]

const SNAKE_BODY_CELLS := [
	Vector2i(16, 10),
	Vector2i(15, 11), Vector2i(16, 11), Vector2i(17, 11),
	Vector2i(15, 12), Vector2i(16, 12), Vector2i(17, 12),
	Vector2i(14, 13), Vector2i(15, 13), Vector2i(16, 13), Vector2i(17, 13),
	Vector2i(14, 14), Vector2i(15, 14), Vector2i(16, 14), Vector2i(17, 14),
	Vector2i(15, 15), Vector2i(16, 15), Vector2i(17, 15),
	Vector2i(15, 16), Vector2i(16, 16), Vector2i(17, 16),
	Vector2i(16, 17),
]
const SNAKE_BODY_BIG_CELLS := [
	Vector2i(16, 9),
	Vector2i(15, 10), Vector2i(16, 10), Vector2i(17, 10),
	Vector2i(14, 11), Vector2i(15, 11), Vector2i(16, 11), Vector2i(17, 11), Vector2i(18, 11),
	Vector2i(14, 12), Vector2i(15, 12), Vector2i(16, 12), Vector2i(17, 12), Vector2i(18, 12),
	Vector2i(14, 13), Vector2i(15, 13), Vector2i(16, 13), Vector2i(17, 13), Vector2i(18, 13),
	Vector2i(14, 14), Vector2i(15, 14), Vector2i(16, 14), Vector2i(17, 14), Vector2i(18, 14),
	Vector2i(15, 15), Vector2i(16, 15), Vector2i(17, 15),
	Vector2i(15, 16), Vector2i(16, 16), Vector2i(17, 16),
	Vector2i(16, 17),
]
const SNAKE_BODY_SMALL_CELLS := [
	Vector2i(16, 10),
	Vector2i(15, 11),
	Vector2i(15, 12),
	Vector2i(16, 13),
	Vector2i(17, 14),
	Vector2i(16, 15),
]
const SNAKE_SEGMENT_WIDTHS := [2, 4, 4, 4, 4, 3, 3, 3]
const SNAKE_SEGMENT_BIG_WIDTHS := [3, 3, 5, 5, 5, 5, 5, 4]
const SNAKE_OBJECT_KEYWORDS := ["箱", "树", "铺", "壁", "坊", "栈", "货", "仓", "店"]

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
	SNAKE_INTRO,
	SNAKE_FREE,
	SNAKE_OBJECT_SENTENCE,
	SNAKE_SECOND_INTRO,
	SNAKE_SECOND,
	SNAKE_DEFEATED,
	CHAPTER_END,
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
var player_sprite: Sprite2D
var player_walk_visual_timer := 0.0
var player_walk_frame_timer := 0.0
var player_move_repeat_timer := 0.0
var player_blocked_retry_timer := 0.0
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
var sentence_source_lines: Array = []
var sentence_source_starts: Array[Vector2i] = []
var sentence_source_success_cells: Array[Vector2i] = []
var sentence_source_fail_cells: Array[Vector2i] = []

var fissure_labels: Array[Label] = []
var fissure_open := false
var slime_labels: Array[Label] = []
var slime_visible: Array[bool] = []
var slime_reinforcement_timer := 0.0
var slime_reinforcement_cursor := 0
var pending_death_sentence := ""
var death_checkpoint: Dictionary = {}
var death_checkpoint_valid := false
var snake_labels: Array[Label] = []
var snake_used_keywords: Dictionary = {}
var snake_success_count := 0
var snake_reverse_count := 0
var snake_current_keyword := ""
var snake_stone_mode := false
var snake_body_base_cells: Array[Vector2i] = []
var snake_body_current_cells: Dictionary = {}
var snake_body_label_segments: Array[int] = []
var snake_body_label_offsets: Array[float] = []
var snake_segment_x: Array[float] = []
var snake_dynamic_map_labels: Array[Label] = []
var snake_scroll_active := false
var snake_scroll_offset := 0.0
var snake_player_scroll_remainder := 0.0
var snake_twist_time := 0.0
var snake_follow_x := 16.0
var snake_current_object_cell := Vector2i.ZERO
var snake_second_talk_timer := 0.0
var snake_ray_timer := 0.0
var snake_ray_disabled := false
var snake_big_attack_disabled := false
var snake_ray_active := false
var snake_reverse_after_text: String = ""
var snake_reverse_after_final := false
var snake_ray_labels: Array[Label] = []

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
	if START_AT_SNAKE_FOR_TEST:
		call_deferred("_enter_snake_boss_direct")


func _process(delta: float) -> void:
	_update_player_visual_animation(delta)
	_update_continuous_player_movement(delta)
	if phase == Phase.FIND_SWORD:
		_update_sword(delta)
	if opportunity_active:
		_update_opportunity_text(delta)
	if sword_active:
		sword_pulse += delta * 6.0
		sword_label.modulate = Color(1.0, 1.0, 1.0, 0.72 + sin(sword_pulse) * 0.28)
	if phase == Phase.SLIME_STAGE1:
		_update_slime_reinforcements(delta)
	if current_map == MAP_SNAKE:
		_update_snake_battle_motion(delta)


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
		_move_player_from_input(direction)


func _update_continuous_player_movement(delta: float) -> void:
	if player_move_repeat_timer > 0.0:
		player_move_repeat_timer = maxf(player_move_repeat_timer - delta, 0.0)
	if player_blocked_retry_timer > 0.0:
		player_blocked_retry_timer = maxf(player_blocked_retry_timer - delta, 0.0)

	if dialogue_active or input_locked:
		return

	var held_direction := _get_held_direction()
	if held_direction == Vector2i.ZERO:
		return
	if player_move_repeat_timer > 0.0 or player_blocked_retry_timer > 0.0:
		return

	_move_player_from_input(held_direction)


func _get_held_direction() -> Vector2i:
	if _is_direction_held(last_direction):
		return last_direction

	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		return Vector2i.LEFT
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		return Vector2i.RIGHT
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		return Vector2i.UP
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		return Vector2i.DOWN

	return Vector2i.ZERO


func _is_direction_held(direction: Vector2i) -> bool:
	match direction:
		Vector2i.LEFT:
			return Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
		Vector2i.RIGHT:
			return Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
		Vector2i.UP:
			return Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)
		Vector2i.DOWN:
			return Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)
		_:
			return false


func _move_player_from_input(direction: Vector2i) -> void:
	last_direction = direction
	var previous_cell := player_cell
	_try_move_player(direction)
	player_move_repeat_timer = PLAYER_MOVE_REPEAT_TIME
	if player_cell == previous_cell:
		player_blocked_retry_timer = PLAYER_BLOCKED_RETRY_TIME


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
	player_label = _make_cell_label("", player_cell.x, player_cell.y, PLAYER_COLOR)
	player_label.name = "Player"
	player_label.z_index = 20
	actor_layer.add_child(player_label)
	_setup_player_sprite()

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

	if current_map == MAP_SLIME_RIGHT and next.x >= GRID_W and SLIME_RIGHT_EXIT_Y.has(next.y):
		if phase == Phase.SLIME_DONE:
			_finish_slime_trial()
		else:
			_show_toast("挡路的史莱姆还没有离开。")
		return

	if current_map == MAP_SNAKE:
		if _is_snake_body_cell(next):
			_snake_failure("", "我被蛇妖打倒了。")
			return
		if phase == Phase.SNAKE_FREE and _is_snake_object_cell(next):
			_open_snake_object(next)
			return

	if current_map == MAP_SLIME_LEFT and not fissure_open and _is_fissure_block_cell(next):
		_show_toast("岩壁间的缝隙还打不开。")
		return

	if current_map == MAP_SLIME_RIGHT and _is_visible_slime_cell(next):
		_slime_failure("", "我被史莱姆杀死了。")
		return

	if sentence_active and _is_sentence_cell(next):
		
		return

	if not _is_walkable(current_map, next):
		_show_toast("岩壁挡住了去路。")
		return

	player_cell = next
	_play_player_walk_visual()
	_update_player_position()


func _is_walkable(map_index: int, cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= GRID_W or cell.y < 0 or cell.y >= GRID_H:
		return false
	if map_index == MAP_SNAKE:
		var snake_text := _snake_visible_cell_text(cell)
		return snake_text == " " or snake_text == "＿"
	var text := _map_cell_text(map_index, cell)
	return text != "岩" and text != "窟"


func _map_cell_text(map_index: int, cell: Vector2i) -> String:
	if map_index < 0 or map_index >= map_data.size():
		return ""
	if cell.x < 0 or cell.x >= GRID_W or cell.y < 0 or cell.y >= GRID_H:
		return ""
	var rows: Array = map_data[map_index]["rows"]
	return String(rows[cell.y]).substr(cell.x, 1)


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
	if current_map == MAP_SNAKE and phase == Phase.SNAKE_FREE:
		var front := player_cell + last_direction
		if _is_snake_object_cell(front):
			_open_snake_object(front)
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
		"...不断往下掉",
		"不知道还会坠落多久...",
		"这是要死了吗？",
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
	_slime_failure("", "我摔死了。")


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
	_slime_failure("空气越来越稀薄，||视线越来越模糊……", "我死了。")


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
	_slime_failure("看着看着，||害我好想安稳地睡上一觉……", "我睡死了。")


func _unlock_slime_exit() -> void:
	phase = Phase.SLIME_DONE
	input_locked = false
	_set_hint("")


func _finish_slime_trial() -> void:
	if phase != Phase.SLIME_DONE:
		return
	phase = Phase.SNAKE_INTRO
	input_locked = true
	_start_dialogue(MAP_SLIME_RIGHT, [
		["穿过洞窟，外头传来蛇妖的嘶鸣。", "现在该把圣剑带回战场了。"]
	], Callable(self, "_enter_snake_boss"))


func _enter_snake_boss() -> void:
	_prepare_snake_boss_state()

	var tween := create_tween()
	tween.tween_property(world_layer, "position:x", -MAP_SNAKE * VIEWPORT_SIZE.x, 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	_begin_snake_boss_scene()


func _enter_snake_boss_direct() -> void:
	_prepare_snake_boss_state()
	world_layer.position.x = -MAP_SNAKE * VIEWPORT_SIZE.x
	_begin_snake_boss_scene()


func _prepare_snake_boss_state() -> void:
	input_locked = true
	_clear_dialogue()
	_clear_sentence()
	_clear_slimes()
	_clear_fissure_overlay()
	snake_success_count = 0
	snake_reverse_count = 0
	snake_current_keyword = ""
	snake_stone_mode = false
	snake_scroll_active = false
	snake_scroll_offset = 0.0
	snake_player_scroll_remainder = 0.0
	snake_twist_time = 0.0
	snake_follow_x = float(SNAKE_SPAWN.x)
	snake_segment_x.clear()
	snake_current_object_cell = Vector2i.ZERO
	snake_second_talk_timer = 0.0
	snake_ray_timer = 0.0
	snake_ray_disabled = false
	snake_big_attack_disabled = false
	snake_used_keywords.clear()
	_clear_snake_body()
	_clear_snake_rays()
	_build_snake_dynamic_map()
	_set_snake_map_root_offset()
	_set_snake_map_dimmed(false)
	_play_bgm(BGM_SNAKE_FIGHT)


func _begin_snake_boss_scene() -> void:
	current_map = MAP_SNAKE
	player_cell = SNAKE_PLAYER_SPAWN
	last_direction = Vector2i.UP
	player_label.visible = true
	_update_player_position()
	_show_snake_body(false)
	_start_snake_intro()


func _start_snake_intro() -> void:
	phase = Phase.SNAKE_INTRO
	_play_se(SE_SNAKE_HISS)
	_start_dialogue(MAP_SNAKE, [
		["我一边喘着气，一边看着", "眼前这条笔直的道路。"],
		["蛇妖说：「哼，干嘛那么", "认真？你厌烦我了吗？」"],
		["手握贝克思贝斯之剑，", "我明白此处不能退缩。"],
		["「你这样很没有礼貌。」", "蛇妖故作生气地嘶鸣。"],
		["蛇妖又说：「这是我的", "世界，你是我的世界……」"],
		["一边沿着街道躲避攻击，", "一边思考诗人说的话。"],
		["「只要一个微小改变，", "就能让世界截然不同。」"]
	], Callable(self, "_unlock_snake_boss"))


func _unlock_snake_boss() -> void:
	phase = Phase.SNAKE_FREE
	input_locked = false
	snake_current_keyword = ""
	snake_scroll_active = current_map == MAP_SNAKE and not snake_stone_mode
	_set_hint("")


func _is_snake_body_cell(cell: Vector2i) -> bool:
	if current_map != MAP_SNAKE:
		return false
	if snake_body_current_cells.has(_cell_key(cell)):
		return true
	if not snake_body_current_cells.is_empty():
		return false
	if snake_stone_mode:
		return SNAKE_BODY_BIG_CELLS.has(cell)
	return SNAKE_BODY_CELLS.has(cell)


func _show_snake_body(big: bool) -> void:
	_clear_snake_body()
	var widths: Array[int] = _snake_segment_widths(big)
	var top_y: int = SNAKE_BODY_BIG_TOP_Y if big else SNAKE_BODY_TOP_Y
	snake_segment_x.clear()
	for segment_index in range(widths.size()):
		var width: int = widths[segment_index]
		snake_segment_x.append(float(SNAKE_SPAWN.x))
		var left_x: int = SNAKE_SPAWN.x - int(ceil(float(width) / 2.0)) + 1
		for col_index in range(width):
			var cell: Vector2i = Vector2i(left_x + col_index, top_y + segment_index)
			snake_body_base_cells.append(cell)
			snake_body_label_segments.append(segment_index)
			snake_body_label_offsets.append(float(cell.x - SNAKE_SPAWN.x))
			var label: Label = _make_world_cell_label("蛇", MAP_SNAKE, cell.x, cell.y, DIALOGUE_COLOR)
			label.z_index = 18
			actor_layer.add_child(label)
			snake_labels.append(label)
	_update_snake_body_motion(0.0)
	var cells: Array = []
	for cell in cells:
		snake_body_base_cells.append(cell)
		var label := _make_world_cell_label("蛇", MAP_SNAKE, cell.x, cell.y, DIALOGUE_COLOR)
		label.z_index = 18
		actor_layer.add_child(label)
		snake_labels.append(label)
	_update_snake_body_motion(0.0)


func _clear_snake_body() -> void:
	for label in snake_labels:
		label.queue_free()
	snake_labels.clear()
	snake_body_base_cells.clear()
	snake_body_current_cells.clear()
	snake_body_label_segments.clear()
	snake_body_label_offsets.clear()


func _snake_segment_widths(big: bool) -> Array[int]:
	var source: Array = SNAKE_SEGMENT_WIDTHS
	if big:
		source = SNAKE_SEGMENT_BIG_WIDTHS
	var widths: Array[int] = []
	for width in source:
		widths.append(int(width))
	return widths


func _ensure_snake_segment_state(segment_count: int) -> void:
	while snake_segment_x.size() < segment_count:
		snake_segment_x.append(snake_follow_x)
	if snake_segment_x.size() > segment_count:
		snake_segment_x.resize(segment_count)


func _snake_max_segment_width(widths: Array[int]) -> int:
	var max_width: int = 1
	for width in widths:
		max_width = maxi(max_width, int(width))
	return max_width


func _clear_snake_dynamic_map() -> void:
	for label in snake_dynamic_map_labels:
		label.queue_free()
	snake_dynamic_map_labels.clear()


func _build_snake_dynamic_map() -> void:
	_clear_snake_dynamic_map()
	if MAP_SNAKE < 0 or MAP_SNAKE >= map_roots.size():
		return
	var rows: Array = map_data[MAP_SNAKE]["rows"]
	var root: Control = map_roots[MAP_SNAKE]

	for y in range(rows.size()):
		var row: String = String(rows[y])
		if y < 14 or y > 15:
			continue
		for x in range(row.length()):
			var text: String = row.substr(x, 1)
			if text == " " or text == "＿" or text == "我":
				continue
			var label: Label = _make_cell_label(text, x, y, WALL_COLOR)
			root.add_child(label)
			snake_dynamic_map_labels.append(label)

	for copy_index in range(SNAKE_LOOP_COPIES):
		for y in range(SNAKE_LOOP_SOURCE_ROWS.size()):
			var row: String = String(SNAKE_LOOP_SOURCE_ROWS[y])
			for x in range(row.length()):
				var text: String = row.substr(x, 1)
				if text == " " or text == "＿" or text == "我":
					continue
				var absolute_y: int = y - SNAKE_SCROLL_LOOP_ROWS * (copy_index + 1)
				var label: Label = _make_cell_label(text, x, absolute_y, WALL_COLOR)
				root.add_child(label)
				snake_dynamic_map_labels.append(label)


func _set_snake_map_root_offset() -> void:
	if MAP_SNAKE < 0 or MAP_SNAKE >= map_roots.size():
		return
	var root: Control = map_roots[MAP_SNAKE]
	root.position.y = snake_scroll_offset


func _snake_scroll_wrap_threshold() -> float:
	return float(CELL * (SNAKE_SCROLL_INITIAL_ROWS + SNAKE_SCROLL_LOOP_ROWS * (SNAKE_LOOP_COPIES - 2)))


func _snake_scroll_pixel_offset() -> float:
	return fposmod(snake_scroll_offset, float(CELL))


func _snake_visual_y(grid_y: int) -> float:
	if current_map == MAP_SNAKE:
		return float(grid_y * CELL) - _snake_scroll_pixel_offset()
	return float(grid_y * CELL)


func _snake_player_visual_y(grid_y: int) -> float:
	if current_map == MAP_SNAKE:
		return float(grid_y * CELL) + _snake_scroll_pixel_offset()
	return float(grid_y * CELL)


func _snake_scroll_row_offset() -> int:
	return int(floor(snake_scroll_offset / CELL))


func _snake_map_cell_text_at_absolute(x: int, y: int) -> String:
	if x < 0 or x >= GRID_W:
		return ""
	if y >= 0 and y < GRID_H:
		return _map_cell_text(MAP_SNAKE, Vector2i(x, y))
	var loop_y: int = posmod(y, SNAKE_SCROLL_LOOP_ROWS)
	if loop_y < 0 or loop_y >= SNAKE_LOOP_SOURCE_ROWS.size():
		return ""
	var row: String = String(SNAKE_LOOP_SOURCE_ROWS[loop_y])
	if x >= row.length():
		return ""
	return row.substr(x, 1)


func _snake_visible_cell_text(cell: Vector2i) -> String:
	if cell.x < 0 or cell.x >= GRID_W or cell.y < 0 or cell.y >= GRID_H:
		return ""
	var source_y: int = cell.y - _snake_scroll_row_offset()
	return _snake_map_cell_text_at_absolute(cell.x, source_y)


func _update_snake_battle_motion(delta: float) -> void:
	var can_scroll: bool = _can_scroll_snake_battle()
	if can_scroll:
		var scroll_delta: float = SNAKE_SCROLL_SPEED * delta
		snake_scroll_offset += SNAKE_SCROLL_SPEED * delta
		_advance_snake_player_with_camera(scroll_delta)
		if phase == Phase.COMPLETE:
			return
		if snake_scroll_offset >= _snake_scroll_wrap_threshold():
			snake_scroll_offset -= float(CELL * SNAKE_SCROLL_LOOP_ROWS)
		if phase == Phase.SNAKE_SECOND:
			if not sentence_active:
				snake_second_talk_timer -= delta
				if snake_second_talk_timer <= 0.0:
					_show_snake_reverse_sentence()
			if not snake_ray_disabled and not sentence_locked:
				snake_ray_timer -= delta
				if snake_ray_timer <= 0.0:
					snake_ray_timer = SNAKE_RAY_INTERVAL
					_fire_snake_ray()
	_set_snake_map_root_offset()
	_update_player_position()
	_sync_snake_sentence_positions()
	_update_snake_body_motion(delta)
	if _snake_body_overlaps_sentence():
		_shatter_snake_sentence()
	if can_scroll and snake_body_current_cells.has(_cell_key(player_cell)):
		_snake_failure("", "我被蛇妖追上了。")


func _can_scroll_snake_battle() -> bool:
	if not snake_scroll_active or dialogue_active:
		return false
	if sentence_active and sentence_locked:
		return false
	if phase == Phase.SNAKE_FREE or phase == Phase.SNAKE_SECOND:
		return true
	if phase == Phase.SNAKE_OBJECT_SENTENCE:
		return sentence_active
	return false


func _advance_snake_player_with_camera(scroll_delta: float) -> void:
	snake_player_scroll_remainder += scroll_delta
	while snake_player_scroll_remainder >= float(CELL):
		snake_player_scroll_remainder -= float(CELL)
		player_cell.y += 1
		_shift_snake_sentence_cells(1)
		if _snake_sentence_scrolled_out():
			_clear_sentence()
			if phase == Phase.SNAKE_OBJECT_SENTENCE:
				_unlock_snake_boss()
			elif phase == Phase.SNAKE_SECOND:
				_unlock_snake_second_phase()
			return
		if player_cell.y >= GRID_H:
			player_cell.y = GRID_H - 1
			_snake_failure("", "我被蛇妖追上了。")
			return


func _shift_snake_sentence_cells(delta_y: int) -> void:
	if delta_y == 0 or not sentence_active or sentence_map_index != MAP_SNAKE:
		return
	for i in range(sentence_cells.size()):
		var sentence_cell: Vector2i = sentence_cells[i]
		sentence_cell.y += delta_y
		sentence_cells[i] = sentence_cell
	for i in range(sentence_highlight_cells.size()):
		var highlight_cell: Vector2i = sentence_highlight_cells[i]
		highlight_cell.y += delta_y
		sentence_highlight_cells[i] = highlight_cell
	for i in range(sentence_source_starts.size()):
		var start_cell: Vector2i = sentence_source_starts[i]
		start_cell.y += delta_y
		sentence_source_starts[i] = start_cell
	for i in range(sentence_source_success_cells.size()):
		var success_cell: Vector2i = sentence_source_success_cells[i]
		success_cell.y += delta_y
		sentence_source_success_cells[i] = success_cell
	for i in range(sentence_source_fail_cells.size()):
		var fail_cell: Vector2i = sentence_source_fail_cells[i]
		fail_cell.y += delta_y
		sentence_source_fail_cells[i] = fail_cell
	if sentence_target_index >= 0 and sentence_target_index < sentence_cells.size():
		sentence_target_cell = sentence_cells[sentence_target_index]


func _snake_sentence_scrolled_out() -> bool:
	if not sentence_active or sentence_map_index != MAP_SNAKE or sentence_cells.is_empty():
		return false
	for cell in sentence_cells:
		if cell.y < GRID_H:
			return false
	return true


func _sync_snake_sentence_positions() -> void:
	if sentence_map_index != MAP_SNAKE:
		return
	for i in range(mini(active_sentence_labels.size(), sentence_cells.size())):
		var label: Label = active_sentence_labels[i]
		var cell: Vector2i = sentence_cells[i]
		label.position.x = MAP_SNAKE * VIEWPORT_SIZE.x + cell.x * CELL
		label.position.y = roundf(_snake_player_visual_y(cell.y))


func _snake_body_overlaps_sentence() -> bool:
	if not sentence_active or sentence_locked or sentence_map_index != MAP_SNAKE:
		return false
	if snake_body_current_cells.is_empty():
		return false
	for cell in sentence_cells:
		if snake_body_current_cells.has(_cell_key(cell)):
			return true
	return false


func _shatter_snake_sentence() -> void:
	if not sentence_active:
		return
	var labels: Array[Label] = []
	for active_label in active_sentence_labels:
		var typed_label: Label = active_label as Label
		if typed_label != null:
			labels.append(typed_label)
	active_sentence_labels.clear()
	sentence_cells.clear()
	sentence_highlight_cells.clear()
	sentence_success_indices.clear()
	sentence_fail_indices.clear()
	sentence_source_lines.clear()
	sentence_source_starts.clear()
	sentence_source_success_cells.clear()
	sentence_source_fail_cells.clear()
	sentence_target_index = -1
	sentence_target_cell = Vector2i.ZERO
	sentence_active = false
	sentence_locked = false
	sentence_callback = Callable()
	sentence_fail_callback = Callable()
	_play_se(SE_SNAKE_HIT)
	if phase == Phase.SNAKE_OBJECT_SENTENCE:
		_unlock_snake_boss()
	elif phase == Phase.SNAKE_SECOND:
		snake_second_talk_timer = maxf(snake_second_talk_timer, 3.0)
		_unlock_snake_second_phase()
	var tween := create_tween()
	tween.set_parallel(true)
	for i in range(labels.size()):
		var label: Label = labels[i]
		if not is_instance_valid(label):
			continue
		var direction: Vector2 = Vector2(float((i % 3) - 1) * 18.0, -22.0 - float(i % 2) * 12.0)
		label.z_index = 38
		tween.tween_property(label, "position", label.position + direction, 0.24)
		tween.tween_property(label, "modulate:a", 0.0, 0.24)
	tween.finished.connect(func() -> void:
		for label in labels:
			if is_instance_valid(label):
				label.queue_free()
	)


func _clear_snake_rays() -> void:
	snake_ray_active = false
	for label in snake_ray_labels:
		label.queue_free()
	snake_ray_labels.clear()


func _fire_snake_ray() -> void:
	if phase != Phase.SNAKE_SECOND or dialogue_active or snake_ray_active:
		return
	_clear_snake_rays()
	snake_ray_active = true
	var ray_x: int = clampi(int(round(snake_follow_x)), 2, GRID_W - 3)
	var start_y: int = SNAKE_BODY_BIG_TOP_Y
	var trail_count := 2
	_play_se(SE_SNAKE_WINK)
	for i in range(trail_count):
		var cell := Vector2i(ray_x, start_y + i)
		var label := _make_snake_visible_cell_label("眼", cell, Color(1.0, 1.0, 1.0, 0.0))
		label.z_index = 34
		actor_layer.add_child(label)
		snake_ray_labels.append(label)
	var tween := create_tween()
	tween.set_parallel(true)
	for label in snake_ray_labels:
		tween.tween_property(label, "modulate:a", 1.0, SNAKE_RAY_WARNING_TIME)
		tween.tween_property(label, "position:y", label.position.y - SNAKE_RAY_DISTANCE, SNAKE_RAY_MOVE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	if not snake_ray_active:
		return
	if player_cell.x == ray_x and player_cell.y <= start_y + trail_count:
		_snake_failure("蛇妖的媚眼射出白光。", "我被蛇妖石化了。")
		return
	var fade := create_tween()
	fade.set_parallel(true)
	for label in snake_ray_labels:
		fade.tween_property(label, "modulate:a", 0.0, SNAKE_RAY_HOLD_TIME)
	await fade.finished
	_clear_snake_rays()


func _update_snake_body_motion(delta: float) -> void:
	if snake_labels.is_empty():
		snake_body_current_cells.clear()
		return
	snake_twist_time += delta
	var widths: Array[int] = _snake_segment_widths(snake_stone_mode)
	_ensure_snake_segment_state(widths.size())
	var max_width: int = _snake_max_segment_width(widths)
	var min_center_x: float = float(max_width - 1) * 0.5
	var max_center_x: float = float(GRID_W - 1) - min_center_x
	var body_top_y: int = SNAKE_BODY_BIG_TOP_Y if snake_stone_mode else SNAKE_BODY_TOP_Y
	var follow_duration: float = SNAKE_FOLLOW_DURATION
	if _snake_player_visual_y(player_cell.y) > float(body_top_y * CELL):
		follow_duration = 0.4
	var follow_t: float = 1.0
	if follow_duration > 0.0:
		follow_t = minf(1.0, delta / follow_duration)
	var target_x: float = clampf(float(player_cell.x), min_center_x, max_center_x)
	snake_follow_x = clampf(lerpf(snake_follow_x, target_x, follow_t), min_center_x, max_center_x)
	for segment in range(snake_segment_x.size()):
		var segment_t: float = follow_t * ((101.0 - float(segment + 1)) / 100.0)
		snake_segment_x[segment] = clampf(lerpf(snake_segment_x[segment], target_x, segment_t), min_center_x, max_center_x)
	if not snake_segment_x.is_empty():
		snake_segment_x[0] = snake_follow_x
	snake_body_current_cells.clear()

	for i in range(snake_labels.size()):
		if i >= snake_body_base_cells.size():
			continue
		var label: Label = snake_labels[i] as Label
		var base_cell: Vector2i = snake_body_base_cells[i]
		var segment_index: int = clampi(base_cell.y - body_top_y + 1, 1, 8)
		var segment_array_index: int = segment_index - 1
		var segment_center_x: float = snake_follow_x
		var segment_offset_x: float = float(base_cell.x - SNAKE_SPAWN.x)
		if i < snake_body_label_segments.size():
			segment_array_index = clampi(snake_body_label_segments[i], 0, maxi(0, snake_segment_x.size() - 1))
			segment_index = segment_array_index + 1
		if segment_array_index >= 0 and segment_array_index < snake_segment_x.size():
			segment_center_x = snake_segment_x[segment_array_index]
		if i < snake_body_label_offsets.size():
			segment_offset_x = snake_body_label_offsets[i]
		var twist_multiplier: float = 0.0
		if segment_index >= 5:
			twist_multiplier = float(segment_index - 4) * 2.0
		var twist_scale: float = 1.35 if snake_stone_mode else 1.0
		var twist: float = cos(snake_twist_time * SNAKE_TWIST_SPEED + SNAKE_TWIST_INTERVAL * float(segment_index)) * SNAKE_TWIST_DISTANCE * twist_multiplier * twist_scale
		var local_x: float = (segment_center_x + segment_offset_x) * CELL + twist
		local_x = clampf(local_x, 0.0, float(GRID_W - 1) * CELL)
		var local_y: float = _snake_visual_y(base_cell.y)
		if current_map == MAP_SNAKE:
			local_y = float(base_cell.y * CELL)
		label.position.x = MAP_SNAKE * VIEWPORT_SIZE.x + local_x
		label.position.y = local_y
		var hit_y: int = int(round(local_y / CELL))
		if hit_y >= 0 and hit_y < GRID_H:
			var hit_cell: Vector2i = Vector2i(int(round(local_x / CELL)), hit_y)
			snake_body_current_cells[_cell_key(hit_cell)] = true


func _restore_snake_boss_visuals() -> void:
	if current_map != MAP_SNAKE:
		_clear_snake_body()
		_clear_snake_dynamic_map()
		_clear_snake_rays()
		return
	_clear_snake_rays()
	_build_snake_dynamic_map()
	_set_snake_map_root_offset()
	_update_player_position()
	_set_snake_map_dimmed(snake_stone_mode)
	for keyword in snake_used_keywords.keys():
		_set_snake_keyword_color(String(keyword), DIM_COLOR)
	_show_snake_body(snake_stone_mode)


func _snake_keyword_at_cell(cell: Vector2i) -> String:
	var text := _snake_visible_cell_text(cell)
	if text == "木":
		return "树"
	return text


func _is_snake_object_cell(cell: Vector2i) -> bool:
	return SNAKE_OBJECT_KEYWORDS.has(_snake_keyword_at_cell(cell))


func _open_snake_object(cell: Vector2i) -> void:
	var keyword := _snake_keyword_at_cell(cell)
	if not SNAKE_OBJECT_KEYWORDS.has(keyword):
		return
	phase = Phase.SNAKE_OBJECT_SENTENCE
	snake_current_keyword = keyword
	snake_current_object_cell = cell
	snake_scroll_active = not snake_stone_mode

	if snake_used_keywords.has(keyword):
		snake_scroll_active = false
		_start_dialogue(MAP_SNAKE, [[_snake_used_text(keyword)]], Callable(self, "_unlock_snake_boss"))
		return

	var data := _get_snake_object_data(keyword)
	if data.is_empty():
		_unlock_snake_boss()
		return

	var line := String(data["line"])
	var chars := _chars(line)
	var success_index := int(data["success"])
	var start := _snake_sentence_start_for_cell(cell, chars.size())
	var success_cell := start + Vector2i(success_index, 0)
	var fail_cells: Array[Vector2i] = []
	for fail_index in data["fail_indices"]:
		fail_cells.append(start + Vector2i(int(fail_index), 0))

	_start_delete_sentence_lines(
		[chars],
		[start],
		[success_cell],
		fail_cells,
		Callable(self, "_snake_object_deleted"),
		Callable(self, "_snake_object_failed"),
		MAP_SNAKE
	)


func _snake_sentence_start_for_cell(trigger_cell: Vector2i, line_length: int) -> Vector2i:
	var _unused_trigger_cell := trigger_cell
	var x := 11
	var row_offset := _snake_scroll_row_offset()
	if row_offset >= 10:
		var wave_index := int(row_offset / 4) % 8
		var wave_offsets: Array[int] = [1, 2, 1, 0, -1, -2, -1, 0]
		x += wave_offsets[wave_index]
	var max_x: int = maxi(1, GRID_W - line_length - 1)
	x = maxi(1, mini(max_x, x))
	var y := 4
	return Vector2i(x, y)


func _stand_near_sentence_cell(cell: Vector2i) -> void:
	var candidates: Array[Vector2i] = [
		cell + Vector2i(0, 1),
		cell + Vector2i(-1, 0),
		cell + Vector2i(1, 0),
		cell + Vector2i(0, -1),
	]
	var directions: Array[Vector2i] = [
		Vector2i.UP,
		Vector2i.RIGHT,
		Vector2i.LEFT,
		Vector2i.DOWN,
	]
	var stand: Vector2i = candidates[0]
	var direction: Vector2i = directions[0]
	for i in range(candidates.size()):
		var candidate: Vector2i = candidates[i]
		if candidate.x < 0 or candidate.x >= GRID_W or candidate.y < 0 or candidate.y >= GRID_H:
			continue
		if sentence_cells.has(candidate):
			continue
		if _is_snake_body_cell(candidate):
			continue
		stand = candidate
		direction = directions[i]
		break
	last_direction = direction
	stand.x = maxi(0, mini(GRID_W - 1, stand.x))
	stand.y = maxi(0, mini(GRID_H - 1, stand.y))
	player_cell = stand
	_update_player_position()


func _get_snake_object_data(keyword: String) -> Dictionary:
	match keyword:
		"箱":
			return {"line": "箱子没有份量。", "success": 2, "fail_indices": [3], "right": "勇者有胆量。", "wrong": "勇者没胜算。"}
		"货":
			return {"line": "就快要过期了。", "success": 4, "fail_indices": [], "right": "绝对不放弃。", "wrong": "蛇妖抓住破绽反击。"}
		"仓":
			return {"line": "仓库是别人的朋友。", "success": 3, "fail_indices": [4], "right": "不给魔物好脸色。", "wrong": "跟勇者没有关系。"}
		"栈":
			return {"line": "小栈里住着好伤心的人。", "success": 6, "fail_indices": [5], "right": "用爱化解一切的纷争。", "wrong": "专心打牌没有要帮忙。"}
		"店":
			return {"line": "老板决定要打烊了。", "success": 6, "fail_indices": [], "right": "帮勇者一点小忙。", "wrong": "蛇妖趁机逼近。"}
		"铺":
			return {"line": "今天没有开门。", "success": 2, "fail_indices": [3], "right": "传来加油声。", "wrong": "再敲也没用。"}
		"树":
			return {"line": "树木看起来没生气了。", "success": 5, "fail_indices": [], "right": "愤怒地冲了出来！", "wrong": "树木没有反应。"}
		"壁":
			return {"line": "墙壁不会坚持到底。", "success": 2, "fail_indices": [3], "right": "和勇者一样坚定。", "wrong": "勇者也不太坚定。"}
		"坊":
			return {"line": "作坊的工具好难用。", "success": 6, "fail_indices": [5], "right": "可以拖延些时间。", "wrong": "什么忙也帮不上。"}
	return {}


func _snake_used_text(keyword: String) -> String:
	match keyword:
		"箱":
			return "箱子＿有份量。已经用过了。"
		"货":
			return "就快要过＿了。去别处试一试吧。"
		"仓":
			return "仓库是＿人的朋友，但是别一直麻烦他。"
		"栈":
			return "小栈里住着好＿心的人，不要滥用他的同情心。"
		"店":
			return "老板决定要打＿了，刚才已经帮了大忙。"
		"铺":
			return "今天＿有开门，店铺主人已出门。"
		"树":
			return "树木看起来＿生气了，但撞过一轮也累坏了。"
		"壁":
			return "墙壁＿会坚持到底，已经坚定到极限了。"
		"坊":
			return "作坊的工具好＿用，用太频繁也会坏掉。"
	return "这里已经帮不上更多忙了。"


func _snake_attack_char(keyword: String) -> String:
	match keyword:
		"箱":
			return "胆"
		"货":
			return "弃"
		"仓":
			return "脸"
		"栈":
			return "爱"
		"店":
			return "忙"
		"铺":
			return "声"
		"树":
			return "树"
		"壁":
			return "壁"
		"坊":
			return "具"
	return keyword


func _snake_attack_sound(keyword: String) -> String:
	match keyword:
		"箱", "仓", "店":
			return SE_SNAKE_HIT
		"树", "壁":
			return SE_ROCK
		"铺", "栈":
			return SE_MELODY
		"坊", "货":
			return SE_SWING
	return SE_SNAKE_HIT


func _make_snake_visible_cell_label(text: String, cell: Vector2i, color: Color) -> Label:
	var label := _make_world_cell_label(text, MAP_SNAKE, cell.x, cell.y, color)
	label.position.y = roundf(_snake_player_visual_y(cell.y))
	return label


func _snake_head_world_position() -> Vector2:
	var body_top_y: int = SNAKE_BODY_BIG_TOP_Y if snake_stone_mode else SNAKE_BODY_TOP_Y
	return Vector2(MAP_SNAKE * VIEWPORT_SIZE.x + snake_follow_x * CELL, float(body_top_y * CELL))


func _show_snake_result_phrase(result: String) -> Array[Label]:
	var labels: Array[Label] = []
	var chars := _chars(result)
	var start := _snake_sentence_start_for_cell(snake_current_object_cell, chars.size())
	for i in range(chars.size()):
		var cell := start + Vector2i(i, 0)
		var label := _make_snake_visible_cell_label(String(chars[i]), cell, DIALOGUE_COLOR)
		label.z_index = 32
		actor_layer.add_child(label)
		labels.append(label)
	return labels


func _snake_play_object_assist(keyword: String, result: String) -> void:
	var result_labels: Array[Label] = _show_snake_result_phrase(result)
	if result_labels.is_empty():
		return
	_play_se(_snake_attack_sound(keyword))
	var phrase_center: Vector2 = Vector2.ZERO
	for label in result_labels:
		phrase_center += label.position
		label.z_index = 36
	var strike_delta: Vector2 = _snake_head_world_position() - (phrase_center / float(result_labels.size()))
	var tween := create_tween()
	tween.set_parallel(true)
	for label in result_labels:
		var target_position: Vector2 = label.position + strike_delta
		tween.tween_property(label, "position", target_position, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(label, "scale", Vector2(1.18, 1.18), 0.38)
	await tween.finished
	_play_se(SE_SNAKE_HURT)
	await _flash_snake_hurt()
	await get_tree().create_timer(SNAKE_OBJECT_RESULT_HOLD_TIME).timeout
	var fade := create_tween()
	fade.set_parallel(true)
	for label in result_labels:
		fade.tween_property(label, "modulate:a", 0.0, 0.2)
	await fade.finished
	for label in result_labels:
		label.queue_free()


func _snake_object_deleted() -> void:
	var keyword := snake_current_keyword
	var data := _get_snake_object_data(keyword)
	var result := "局势稍微向勇者倾斜。"
	if data.has("right"):
		result = String(data["right"])
	snake_used_keywords[keyword] = true
	snake_success_count += 1
	_clear_sentence()
	_set_snake_keyword_color(keyword, DIM_COLOR)
	await _snake_play_object_assist(keyword, result)
	if snake_success_count >= 3:
		_start_dialogue(MAP_SNAKE, [
			["蛇妖怒吼起来。"],
			["「你真以为，凭那几招", "三脚猫功夫就能赢本蛇？」"]
		], Callable(self, "_start_snake_second_phase"))
	else:
		_start_dialogue(MAP_SNAKE, [[result]], Callable(self, "_unlock_snake_boss"))


func _snake_object_failed() -> void:
	var data := _get_snake_object_data(snake_current_keyword)
	var line := "蛇妖抓住破绽反击。"
	if data.has("wrong"):
		line = String(data["wrong"])
	_snake_failure(line, "我被蛇妖打倒了。")


func _set_snake_keyword_color(keyword: String, color: Color) -> void:
	if MAP_SNAKE < 0 or MAP_SNAKE >= map_roots.size():
		return
	for child in map_roots[MAP_SNAKE].get_children():
		if child is Label:
			var label := child as Label
			if label.text == keyword or (keyword == "树" and label.text == "木"):
				label.modulate = color


func _set_snake_map_dimmed(dimmed: bool) -> void:
	if MAP_SNAKE < 0 or MAP_SNAKE >= map_roots.size():
		return
	for child in map_roots[MAP_SNAKE].get_children():
		if child is Label:
			var label := child as Label
			label.modulate = DIM_COLOR if dimmed else WALL_COLOR


func _flash_snake_hurt() -> void:
	await _shake_world(0.32, 18.0)
	if snake_labels.is_empty():
		return
	var tween := create_tween()
	tween.set_parallel(true)
	for label in snake_labels:
		tween.tween_property(label, "modulate:a", 0.35, 0.12)
	await tween.finished
	var back := create_tween()
	back.set_parallel(true)
	for label in snake_labels:
		back.tween_property(label, "modulate:a", 1.0, 0.18)
	await back.finished


func _start_snake_second_phase() -> void:
	phase = Phase.SNAKE_SECOND_INTRO
	input_locked = true
	_clear_sentence()
	_clear_snake_rays()
	snake_current_keyword = ""
	snake_scroll_active = false
	snake_stone_mode = true
	snake_second_talk_timer = SNAKE_SECOND_TALK_DELAY
	snake_ray_timer = SNAKE_RAY_INTERVAL
	snake_ray_disabled = false
	snake_big_attack_disabled = false
	_set_snake_map_dimmed(true)
	_play_bgm(BGM_SNAKE_SECOND)
	_play_se(SE_SNAKE_EVOLVE)
	_show_snake_body(true)
	await _shake_world(0.5, 22.0)
	_start_dialogue(MAP_SNAKE, [
		["「只要石化所有东西的话，", "你就没办法制造变化了！」"],
		["「哈，好傻好天真的勇者，", "乖乖让本蛇收拾你吧！」"]
	], Callable(self, "_unlock_snake_second_phase"))


func _unlock_snake_second_phase(delay: float = SNAKE_SECOND_TALK_DELAY) -> void:
	phase = Phase.SNAKE_SECOND
	input_locked = false
	snake_current_keyword = ""
	snake_second_talk_timer = maxf(snake_second_talk_timer, delay)
	snake_ray_timer = maxf(snake_ray_timer, SNAKE_RAY_INTERVAL)
	snake_scroll_active = current_map == MAP_SNAKE and snake_stone_mode
	_set_hint("")


func _show_snake_reverse_sentence() -> void:
	if snake_reverse_count >= 3:
		_start_snake_defeat_sequence()
		return
	phase = Phase.SNAKE_SECOND
	snake_scroll_active = current_map == MAP_SNAKE and snake_stone_mode
	_clear_dialogue()
	_clear_snake_rays()
	var data: Dictionary = _get_snake_reverse_data(snake_reverse_count)
	var line: String = String(data["line"])
	var text_lines: Array = [line]
	if data.has("lines"):
		text_lines = data["lines"]
	elif data.has("say"):
		text_lines = _snake_dialogue_page(String(data["say"]))
	var lines: Array = []
	var starts: Array[Vector2i] = []
	var target_line_index: int = int(data.get("success_line", 0))
	var target_offset: int = int(data.get("target_offset", 0))
	for line_index in range(text_lines.size()):
		var text_line: String = String(text_lines[line_index])
		var found: int = text_line.find(line)
		if not data.has("success_line") and found != -1:
			target_line_index = line_index
			target_offset = found
		lines.append(_chars(text_line))
		var start_x: int = maxi(1, int((GRID_W - text_line.length()) / 2.0))
		starts.append(Vector2i(start_x, SNAKE_REVERSE_SENTENCE_START.y + line_index))
	target_line_index = clampi(target_line_index, 0, maxi(0, starts.size() - 1))
	var target_start: Vector2i = starts[target_line_index] + Vector2i(target_offset, 0)
	var success_cell: Vector2i = target_start + Vector2i(int(data["success"]), 0)
	var fail_cells: Array[Vector2i] = _line_cells_except(target_start, line.length(), success_cell)
	_stand_near_sentence_cell(success_cell)
	_start_delete_sentence_lines(
		lines,
		starts,
		[success_cell],
		fail_cells,
		Callable(self, "_snake_reverse_deleted"),
		Callable(self, "_snake_reverse_failed"),
		MAP_SNAKE
	)


func _get_snake_reverse_data_fixed(index: int) -> Dictionary:
	match index:
		0:
			return {
				"line": "你却自己摔得鼻青脸肿。",
				"success": 0,
				"success_line": 1,
				"target_offset": 0,
				"lines": ["本蛇只是甩一甩尾巴，", "你却自己摔得鼻青脸肿。"],
				"right": "蛇妖却自己摔得鼻青脸肿。",
				"after": "竟然能扭转攻击！可恶，这下必杀技不能用了……"
			}
		1:
			return {
				"line": "是走向勇者投降的结局。",
				"success": 1,
				"success_line": 1,
				"target_offset": 2,
				"lines": ["任何抵抗都是徒劳，", "注定是走向勇者投降的结局。"],
				"right": "是向勇者投降的结局。",
				"after": "竟然能操弄情节！可恶，真不想要变回原状呢……"
			}
		2:
			return {
				"line": "眼中不过是虚有其表。",
				"success": 3,
				"success_line": 1,
				"target_offset": 0,
				"lines": ["名为勇者的家伙，在本蛇", "眼中不过是虚有其表。"],
				"right": "眼中不是虚有其表。",
				"after": "竟然有这等能耐！可恶，身体渐渐不听使唤了……"
			}
	return {}


func _get_snake_reverse_data(index: int) -> Dictionary:
	match index:
		0:
			return {
				"line": "你却自己摔得鼻青脸肿。",
				"success": 0,
				"say": "本蛇只是甩一甩尾巴，你却自己摔得鼻青脸肿。",
				"right": "蛇妖却自己摔得鼻青脸肿。",
				"after": "竟然能扭转攻击！可恶，这下必杀技不能用了……"
			}
		1:
			return {
				"line": "是走向勇者投降的结局。",
				"success": 1,
				"say": "任何抵抗都是徒劳，注定是走向勇者投降的结局。",
				"right": "是向勇者投降的结局。",
				"after": "竟然能操弄情节！可恶，真不想要变回原状呀……"
			}
		2:
			return {
				"line": "眼中不过是虚有其表。",
				"success": 3,
				"say": "名为勇者的家伙，在本蛇眼中不过是虚有其表。",
				"right": "眼中不是虚有其表。",
				"after": "竟然有这等能耐！可恶，身体渐渐不听使唤了……"
			}
	return {}


func _line_cells_except(start: Vector2i, length: int, success_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i in range(length):
		var cell := start + Vector2i(i, 0)
		if cell != success_cell:
			cells.append(cell)
	return cells


func _snake_dialogue_page(text: String) -> Array:
	if text.length() <= 16:
		return [text]
	var split_at := text.find("，")
	if split_at == -1 or split_at > 18:
		split_at = mini(16, text.length())
	else:
		split_at += 1
	return [text.substr(0, split_at), text.substr(split_at)]


func _show_snake_speech_text(text: String) -> void:
	var lines: Array = _snake_dialogue_page(text)
	var labels: Array[Label] = []
	for line_index in range(lines.size()):
		var line := String(lines[line_index])
		var start_x: int = maxi(1, int((GRID_W - line.length()) / 2.0))
		var y: int = 2 + line_index
		for i in range(line.length()):
			var char := line.substr(i, 1)
			if char == " ":
				continue
			var label := _make_world_cell_label(char, MAP_SNAKE, start_x + i, y, DIALOGUE_COLOR)
			label.z_index = 33
			label.modulate.a = 0.0
			actor_layer.add_child(label)
			labels.append(label)
	var tween := create_tween()
	tween.set_parallel(true)
	for label in labels:
		tween.tween_property(label, "modulate:a", 1.0, 0.16)
	await tween.finished
	await get_tree().create_timer(SNAKE_SECOND_REACTION_HOLD_TIME).timeout
	var out := create_tween()
	out.set_parallel(true)
	for label in labels:
		out.tween_property(label, "modulate:a", 0.0, SNAKE_SECOND_REACTION_FADE_TIME)
	await out.finished
	for label in labels:
		label.queue_free()


func _snake_reverse_deleted() -> void:
	var data: Dictionary = _get_snake_reverse_data(snake_reverse_count)
	var result: String = String(data["right"])
	var after_text := ""
	if data.has("after"):
		after_text = String(data["after"])
	snake_reverse_count += 1
	_clear_sentence()
	_apply_snake_reverse_effect(snake_reverse_count)
	await _trim_snake_body_after_reverse()
	snake_reverse_after_text = after_text
	snake_reverse_after_final = snake_reverse_count >= 3
	_start_dialogue(MAP_SNAKE, [_snake_dialogue_page(result)], Callable(self, "_continue_snake_reverse_reaction"))


func _continue_snake_reverse_reaction() -> void:
	input_locked = true
	snake_scroll_active = false
	_clear_dialogue()
	_clear_snake_rays()
	await get_tree().create_timer(SNAKE_SECOND_REACTION_DELAY).timeout
	if not snake_reverse_after_text.is_empty():
		_start_dialogue(MAP_SNAKE, [_snake_dialogue_page(snake_reverse_after_text)], Callable(self, "_finish_snake_reverse_reaction"))
		return
	_finish_snake_reverse_reaction()


func _finish_snake_reverse_reaction() -> void:
	input_locked = true
	snake_scroll_active = false
	_clear_dialogue()
	await get_tree().create_timer(SNAKE_SECOND_REACTION_RESUME_DELAY).timeout
	if snake_reverse_after_final:
		snake_reverse_after_text = ""
		snake_reverse_after_final = false
		_start_snake_defeat_sequence()
		return
	snake_reverse_after_text = ""
	snake_reverse_after_final = false
	snake_second_talk_timer = maxf(snake_second_talk_timer, SNAKE_SECOND_POST_REVERSE_DELAY)
	snake_ray_timer = maxf(snake_ray_timer, SNAKE_RAY_INTERVAL)
	_unlock_snake_second_phase(SNAKE_SECOND_POST_REVERSE_DELAY)


func _snake_reverse_failed() -> void:
	_snake_failure("蛇妖趁着破绽反击。", "我被蛇妖吞没了。")


func _apply_snake_reverse_effect(count: int) -> void:
	match count:
		1:
			snake_ray_disabled = true
			snake_big_attack_disabled = true
			_clear_snake_rays()
		2:
			snake_second_talk_timer = SNAKE_SECOND_TALK_INTERVAL + 3.0
			snake_ray_timer = SNAKE_RAY_INTERVAL + 2.0
		3:
			snake_scroll_active = false


func _trim_snake_body_after_reverse() -> void:
	_play_se(SE_SNAKE_WEAKEN_FINAL if snake_reverse_count >= 3 else SE_SNAKE_WEAKEN)
	await _flash_snake_hurt()
	if snake_labels.is_empty():
		return
	var remove_count: int = mini(5 if snake_reverse_count >= 3 else 4, snake_labels.size())
	var tween := create_tween()
	tween.set_parallel(true)
	for i in range(remove_count):
		var label: Label = snake_labels[snake_labels.size() - 1 - i] as Label
		tween.tween_property(label, "modulate:a", 0.0, 0.24)
	await tween.finished
	for i in range(remove_count):
		var label: Label = snake_labels.pop_back() as Label
		label.queue_free()
		if not snake_body_base_cells.is_empty():
			snake_body_base_cells.pop_back()
		if not snake_body_label_segments.is_empty():
			snake_body_label_segments.pop_back()
		if not snake_body_label_offsets.is_empty():
			snake_body_label_offsets.pop_back()


func _start_snake_defeat_sequence() -> void:
	phase = Phase.SNAKE_DEFEATED
	input_locked = true
	_clear_sentence()
	_clear_snake_rays()
	snake_scroll_active = false
	snake_ray_disabled = true
	snake_big_attack_disabled = true
	player_cell = Vector2i(SNAKE_SPAWN.x, 7)
	last_direction = Vector2i.UP
	_update_player_position()
	await _collapse_snake_body()
	_start_dialogue(MAP_SNAKE, [
		["蛇妖被圣剑删改了命运，", "缩成一团，在角落挣扎。"],
		["「你……」蛇妖抬起头，", "有气无力地说了几句话。"],
		["「其实你和我都一样。」", "「总以为自己很伟大……」"],
		["「但我们并没有像自己", "所以为的那么重要。」"],
		["「只不过，大家现在", "更需要你罢了。如此而已。」"],
		["「呵，算了，", "当我没说吧。」"],
		["「你可以假装看不到我，", "却不可能轻易甩开我。」"],
		["「我们还会再相见的……", "勇者，我不会忘记你。」"],
		["蛇妖说完，化为一团黑气，", "消失得无影无踪。"]
	], Callable(self, "_snake_vanish_and_start_chapter_end"))


func _collapse_snake_body() -> void:
	_play_se(SE_SNAKE_WEAKEN_FINAL)
	if not snake_labels.is_empty():
		var tween := create_tween()
		tween.set_parallel(true)
		for label in snake_labels:
			tween.tween_property(label, "modulate:a", 0.0, 0.55)
			tween.tween_property(label, "scale", Vector2(0.25, 0.25), 0.55)
		await tween.finished
	_clear_snake_body()
	for cell in SNAKE_BODY_SMALL_CELLS:
		snake_body_base_cells.append(cell)
		var label := _make_world_cell_label("蛇", MAP_SNAKE, cell.x, cell.y, DIALOGUE_COLOR)
		label.z_index = 18
		label.modulate.a = 0.0
		actor_layer.add_child(label)
		snake_labels.append(label)
	var in_tween := create_tween()
	in_tween.set_parallel(true)
	for label in snake_labels:
		in_tween.tween_property(label, "modulate:a", 0.75, 0.4)
	await in_tween.finished


func _snake_vanish_and_start_chapter_end() -> void:
	input_locked = true
	_play_se(SE_SNAKE_VANISH)
	if not snake_labels.is_empty():
		var tween := create_tween()
		tween.set_parallel(true)
		for label in snake_labels:
			tween.tween_property(label, "modulate:a", 0.0, 0.8)
			tween.tween_property(label, "scale", Vector2(0.1, 0.1), 0.8)
		await tween.finished
	_clear_snake_body()
	await _fade_overlay(dark_overlay, 0.0, 0.5)
	_start_chapter_end_sequence()


func _start_chapter_end_sequence() -> void:
	phase = Phase.CHAPTER_END
	snake_scroll_active = false
	snake_stone_mode = false
	_clear_snake_rays()
	_set_snake_map_dimmed(false)
	_play_bgm(BGM_SNAKE_END)
	_play_se(SE_STONE_OFF)
	_start_dialogue(MAP_SNAKE, [
		["蛇妖消失后，黑气逐渐散去。", "村庄重新亮了起来。"],
		["天亮了。石化解除，", "库尔提村恢复了声音。"],
		["诗人把「黎明来临前", "总是特别黑暗」说完，"],
		["却发现黎明已经来了。"],
		["村民送来一篮", "史莱姆造型葡萄干面包。"],
		["我刚想吃，诗人提醒我：", "勇者只能做正确的事。"],
		["即使必须承受痛苦，", "也不能忘记自己是勇者。"],
		["于是我继续上路。"],
		["第二章结束。获得成就：2-5。"]
	], Callable(self, "_complete_flow"))


func _snake_failure(line: String, death_sentence: String) -> void:
	_capture_death_checkpoint()
	_clear_sentence()
	_clear_snake_rays()
	_play_se(SE_SNAKE_BITE)
	snake_scroll_active = false
	phase = Phase.COMPLETE
	input_locked = true
	pending_death_sentence = death_sentence
	if line.is_empty():
		_show_pending_death()
		return
	_start_dialogue(current_map, [
		Array(line.split("||"))
	], Callable(self, "_show_pending_death"))



func _complete_flow() -> void:
	input_locked = true
	_set_hint("")


func _slime_failure(line: String, death_sentence: String) -> void:
	_capture_death_checkpoint()
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


func _capture_death_checkpoint() -> void:
	var slime_state: Array[bool] = []
	for visible in slime_visible:
		slime_state.append(bool(visible))
	death_checkpoint = {
		"phase": phase,
		"current_map": current_map,
		"player_cell": _pack_vector2i(player_cell),
		"last_direction": _pack_vector2i(last_direction),
		"world_position": [world_layer.position.x, world_layer.position.y],
		"player_visible": player_label.visible,
		"dark_alpha": dark_overlay.color.a,
		"blur_alpha": blur_overlay.color.a,
		"fissure_open": fissure_open,
		"slime_visible": slime_state,
		"slime_reinforcement_timer": slime_reinforcement_timer,
		"slime_reinforcement_cursor": slime_reinforcement_cursor,
		"sentence_active": sentence_active,
		"sentence_lines": _duplicate_sentence_lines(sentence_source_lines),
		"sentence_starts": _pack_vector2i_array(sentence_source_starts),
		"sentence_success_cells": _pack_vector2i_array(sentence_source_success_cells),
		"sentence_fail_cells": _pack_vector2i_array(sentence_source_fail_cells),
		"sentence_callback": sentence_callback,
		"sentence_fail_callback": sentence_fail_callback,
		"sentence_map_index": sentence_map_index,
		"snake_success_count": snake_success_count,
		"snake_reverse_count": snake_reverse_count,
		"snake_current_keyword": snake_current_keyword,
		"snake_stone_mode": snake_stone_mode,
		"snake_used_keywords": snake_used_keywords.duplicate(),
		"snake_scroll_active": snake_scroll_active,
		"snake_scroll_offset": snake_scroll_offset,
		"snake_player_scroll_remainder": snake_player_scroll_remainder,
		"snake_twist_time": snake_twist_time,
		"snake_follow_x": snake_follow_x,
		"snake_current_object_cell": _pack_vector2i(snake_current_object_cell),
		"snake_second_talk_timer": snake_second_talk_timer,
		"snake_ray_timer": snake_ray_timer,
		"snake_ray_disabled": snake_ray_disabled,
		"snake_big_attack_disabled": snake_big_attack_disabled,
	}
	death_checkpoint_valid = true


func _restore_death_checkpoint() -> void:
	_clear_dialogue()
	_clear_sentence()
	_clear_falling_interlude()
	for child in death_layer.get_children():
		child.queue_free()
	death_layer.visible = false
	pending_death_sentence = ""
	dialogue_active = false
	_set_hint("")
	if not death_checkpoint_valid:
		input_locked = false
		return

	current_map = int(death_checkpoint["current_map"])
	phase = int(death_checkpoint["phase"])
	var packed_player_cell: Array = death_checkpoint["player_cell"]
	var packed_last_direction: Array = death_checkpoint["last_direction"]
	player_cell = _unpack_vector2i(packed_player_cell)
	last_direction = _unpack_vector2i(packed_last_direction)
	var restored_world_position: Array = death_checkpoint["world_position"]
	world_layer.position = Vector2(float(restored_world_position[0]), float(restored_world_position[1]))
	player_label.visible = bool(death_checkpoint["player_visible"])
	_update_player_position()
	dark_overlay.color.a = float(death_checkpoint["dark_alpha"])
	blur_overlay.color.a = float(death_checkpoint["blur_alpha"])

	fissure_open = bool(death_checkpoint["fissure_open"])
	if current_map == MAP_SLIME_LEFT:
		if fissure_open:
			_clear_fissure_overlay()
		else:
			_show_fissure_overlay()
	else:
		_clear_fissure_overlay()

	if current_map == MAP_SLIME_RIGHT:
		var restored_slime_visible: Array = death_checkpoint["slime_visible"]
		_restore_slimes(restored_slime_visible)
		slime_reinforcement_timer = float(death_checkpoint["slime_reinforcement_timer"])
		slime_reinforcement_cursor = int(death_checkpoint["slime_reinforcement_cursor"])
	else:
		_clear_slimes()

	snake_success_count = int(death_checkpoint.get("snake_success_count", 0))
	snake_reverse_count = int(death_checkpoint.get("snake_reverse_count", 0))
	snake_current_keyword = String(death_checkpoint.get("snake_current_keyword", ""))
	snake_stone_mode = bool(death_checkpoint.get("snake_stone_mode", false))
	snake_scroll_active = bool(death_checkpoint.get("snake_scroll_active", false))
	snake_scroll_offset = float(death_checkpoint.get("snake_scroll_offset", 0.0))
	snake_player_scroll_remainder = float(death_checkpoint.get("snake_player_scroll_remainder", fposmod(snake_scroll_offset, float(CELL))))
	snake_twist_time = float(death_checkpoint.get("snake_twist_time", 0.0))
	snake_follow_x = float(death_checkpoint.get("snake_follow_x", float(SNAKE_SPAWN.x)))
	snake_second_talk_timer = float(death_checkpoint.get("snake_second_talk_timer", 0.0))
	snake_ray_timer = float(death_checkpoint.get("snake_ray_timer", 0.0))
	snake_ray_disabled = bool(death_checkpoint.get("snake_ray_disabled", false))
	snake_big_attack_disabled = bool(death_checkpoint.get("snake_big_attack_disabled", false))
	if death_checkpoint.has("snake_current_object_cell"):
		var packed_snake_object_cell: Array = death_checkpoint["snake_current_object_cell"]
		snake_current_object_cell = _unpack_vector2i(packed_snake_object_cell)
	else:
		snake_current_object_cell = Vector2i.ZERO
	snake_used_keywords.clear()
	if death_checkpoint.has("snake_used_keywords"):
		var restored_snake_keywords: Dictionary = death_checkpoint["snake_used_keywords"]
		snake_used_keywords = restored_snake_keywords.duplicate()
	if current_map == MAP_SNAKE:
		_apply_snake_respawn_gap()
		_restore_snake_boss_visuals()
	else:
		_clear_snake_body()

	if bool(death_checkpoint["sentence_active"]):
		var restored_phase := phase
		var restored_lines: Array = death_checkpoint["sentence_lines"]
		var packed_starts: Array = death_checkpoint["sentence_starts"]
		var packed_success_cells: Array = death_checkpoint["sentence_success_cells"]
		var packed_fail_cells: Array = death_checkpoint["sentence_fail_cells"]
		var restored_starts := _unpack_vector2i_array(packed_starts)
		var restored_success_cells := _unpack_vector2i_array(packed_success_cells)
		var restored_fail_cells := _unpack_vector2i_array(packed_fail_cells)
		var restored_callback: Callable = death_checkpoint["sentence_callback"]
		var restored_fail_callback: Callable = death_checkpoint["sentence_fail_callback"]
		_start_delete_sentence_lines(
			restored_lines,
			restored_starts,
			restored_success_cells,
			restored_fail_cells,
			restored_callback,
			restored_fail_callback,
			int(death_checkpoint["sentence_map_index"])
		)
		phase = restored_phase
	else:
		input_locked = false

	death_checkpoint.clear()
	death_checkpoint_valid = false


func _apply_snake_respawn_gap() -> void:
	var body_top_y: int = SNAKE_BODY_BIG_TOP_Y if snake_stone_mode else SNAKE_BODY_TOP_Y
	var safe_y: int = maxi(1, body_top_y - 5)
	if player_cell.y > safe_y:
		player_cell.y = safe_y
	player_cell.x = clampi(player_cell.x, 2, GRID_W - 3)
	last_direction = Vector2i.UP
	snake_player_scroll_remainder = 0.0
	snake_body_current_cells.clear()


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
	var labels: Array[Label] = []
	for i in range(death_sentence.length()):
		var label := _make_label(death_sentence.substr(i, 1), 56, DIALOGUE_COLOR)
		label.position = Vector2((start_x + i) * CELL, y * CELL)
		label.size = Vector2(CELL, CELL)
		label.modulate.a = 0.0
		death_layer.add_child(label)
		labels.append(label)

	var text_in := create_tween()
	text_in.set_parallel(true)
	for label in labels:
		text_in.tween_property(label, "modulate:a", 1.0, 0.35)
	await text_in.finished

	await get_tree().create_timer(2.0).timeout

	var out := create_tween()
	out.set_parallel(true)
	for label in labels:
		out.tween_property(label, "modulate:a", 0.0, 0.35)
	out.tween_property(back, "color:a", 0.0, 0.35)
	await out.finished
	_restore_death_checkpoint()


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


func _restore_slimes(visible_state: Array) -> void:
	_clear_slimes()
	for i in range(SLIME_CELLS.size()):
		var cell: Vector2i = SLIME_CELLS[i]
		var label := _make_world_cell_label("史", MAP_SLIME_RIGHT, cell.x, cell.y, DIALOGUE_COLOR)
		label.z_index = 18
		label.visible = i < visible_state.size() and bool(visible_state[i])
		actor_layer.add_child(label)
		slime_labels.append(label)
		slime_visible.append(label.visible)


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
		var start_x: int = 6
		var y: int = 14 + line_index
		if map_index == MAP_SNAKE:
			start_x = maxi(1, int((GRID_W - line.length()) / 2.0))
			y = 2 + line_index
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


func _duplicate_sentence_lines(lines: Array) -> Array:
	var copy := []
	for line in lines:
		if line is Array:
			copy.append(line.duplicate())
		else:
			copy.append(line)
	return copy


func _pack_vector2i(value: Vector2i) -> Array:
	return [value.x, value.y]


func _unpack_vector2i(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))


func _pack_vector2i_array(values: Array) -> Array:
	var packed := []
	for value in values:
		packed.append(_pack_vector2i(value))
	return packed


func _unpack_vector2i_array(values: Array) -> Array[Vector2i]:
	var unpacked: Array[Vector2i] = []
	for value in values:
		unpacked.append(_unpack_vector2i(value))
	return unpacked


func _start_delete_sentence_lines(lines: Array, starts: Array[Vector2i], success_cells: Array[Vector2i], fail_cells: Array[Vector2i], callback: Callable, fail_callback: Callable, map_index: int) -> void:
	sentence_layer.visible = false
	sentence_locked = false
	sentence_active = true
	sentence_callback = callback
	sentence_fail_callback = fail_callback
	sentence_map_index = map_index
	sentence_source_lines = _duplicate_sentence_lines(lines)
	sentence_source_starts = starts.duplicate()
	sentence_source_success_cells = success_cells.duplicate()
	sentence_source_fail_cells = fail_cells.duplicate()
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
			if map_index == MAP_SNAKE:
				label.position.y = roundf(_snake_player_visual_y(cell.y))
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
		await _play_sentence_legal_animation()
		if sentence_fail_callback.is_valid():
			sentence_fail_callback.call()
		return

	return


func _delete_sentence_index(index: int) -> void:
	sentence_locked = true
	var label := active_sentence_labels[index]
	if _uses_backspace_cut_animation(label):
		await _play_backspace_cut_animation(label)
	else:
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(label, "modulate:a", 0.0, 0.22)
		tween.tween_property(label, "scale", Vector2(1.7, 1.7), 0.22)
		await tween.finished
	label.visible = false


func _uses_backspace_cut_animation(label: Label) -> bool:
	return BACKSPACE_CUT_ANIMATION_CHARS.has(label.text)


func _play_backspace_cut_animation(label: Label) -> void:
	_play_se(SE_SWING)
	var original_z_index := label.z_index
	var original_material := label.material
	var original_modulate := label.modulate

	var mask := ColorRect.new()
	mask.name = "BackspaceForgetMask"
	mask.position = label.position - Vector2(BACKSPACE_CUT_MASK_EXTRA_X, 0)
	mask.size = label.size + Vector2(BACKSPACE_CUT_MASK_EXTRA_X * 2.0, 0)
	mask.color = Color.BLACK
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask.z_index = 70
	actor_layer.add_child(mask)

	label.z_index = 72
	label.modulate = DIALOGUE_COLOR

	var material := ShaderMaterial.new()
	material.shader = BACKSPACE_CUT_SHADER
	material.set_shader_parameter("degree", 45.0)
	material.set_shader_parameter("time", 0.0)
	label.material = material

	var slash := Sprite2D.new()
	slash.texture = BACKSPACE_SPLASH_TEXTURE
	slash.hframes = 10
	slash.vframes = 2
	slash.frame = 0
	slash.z_index = 74
	slash.centered = true
	slash.position = label.position + label.size * 0.5
	slash.rotation_degrees = 45.0
	actor_layer.add_child(slash)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(material, "shader_parameter/time", 1.0, 1.15).from(0.0)
	tween.tween_property(slash, "frame", 17, 0.5).from(0)
	tween.tween_property(label, "modulate:a", 0.18, 0.72).set_delay(0.28)
	await tween.finished

	label.modulate.a = 0.0
	await get_tree().create_timer(0.08).timeout
	label.visible = true
	label.material = null
	label.modulate.a = 0.26
	await get_tree().create_timer(0.08).timeout
	label.modulate.a = 0.48
	await get_tree().create_timer(0.06).timeout
	label.modulate.a = 0.16
	await get_tree().create_timer(0.08).timeout
	label.modulate.a = 0.0
	label.z_index = original_z_index
	label.material = original_material
	label.modulate = original_modulate
	slash.queue_free()
	mask.queue_free()


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
	var frame_y := float(min_y * CELL)
	if sentence_map_index == MAP_SNAKE:
		frame_y = roundf(_snake_player_visual_y(min_y))
	frame.position = Vector2(sentence_map_index * VIEWPORT_SIZE.x + min_x * CELL, frame_y)
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
	var y: float = float(player_cell.y * CELL)
	if current_map == MAP_SNAKE:
		y = _snake_player_visual_y(player_cell.y)
	player_label.position = Vector2(current_map * VIEWPORT_SIZE.x + player_cell.x * CELL, y)


func _setup_player_sprite() -> void:
	player_sprite = Sprite2D.new()
	player_sprite.name = "PlayerVisual"
	player_sprite.position = Vector2(CELL, CELL) / 2.0
	player_sprite.z_index = 1
	player_label.add_child(player_sprite)
	_set_player_idle_visual()


func _update_player_visual_animation(delta: float) -> void:
	if player_sprite == null or player_walk_visual_timer <= 0.0:
		return

	player_walk_visual_timer = maxf(player_walk_visual_timer - delta, 0.0)
	player_walk_frame_timer += delta
	if player_walk_frame_timer >= PLAYER_WALK_FRAME_TIME:
		player_walk_frame_timer = 0.0
		player_sprite.frame = 1 - player_sprite.frame

	if player_walk_visual_timer <= 0.0:
		_set_player_idle_visual()


func _play_player_walk_visual() -> void:
	if player_sprite == null:
		return

	player_sprite.texture = ME_WALK_TEXTURE
	player_sprite.hframes = 2
	player_sprite.vframes = 1
	player_sprite.frame = 0
	player_sprite.centered = true
	player_sprite.scale = Vector2.ONE
	player_sprite.modulate = Color.WHITE
	player_sprite.rotation = 0.0
	player_walk_visual_timer = PLAYER_WALK_VISUAL_TIME
	player_walk_frame_timer = 0.0


func _set_player_idle_visual() -> void:
	if player_sprite == null:
		return

	player_sprite.texture = ME_DEFAULT_TEXTURE
	player_sprite.hframes = 1
	player_sprite.vframes = 1
	player_sprite.frame = 0
	player_sprite.centered = true
	player_sprite.scale = Vector2.ONE
	player_sprite.modulate = Color.WHITE
	player_sprite.rotation = 0.0
	player_walk_visual_timer = 0.0
	player_walk_frame_timer = 0.0


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


func _fade_overlay(rect: ColorRect, alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(rect, "color:a", alpha, duration)
	await tween.finished


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
