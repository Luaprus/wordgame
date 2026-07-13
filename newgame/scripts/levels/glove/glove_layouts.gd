extends RefCounted

const WIDTH := 32
const HEIGHT := 18
const HAND_ORIGIN := Vector2i(7, 0)
const PLAYER_START := Vector2i(20, 15)
const LIFELINE_POS := Vector2i(21, 12)
const LIFELINE_HINT_POS := Vector2i(21, 13)
const GOOD_WORD_POS := Vector2i(14, 13)
const SWORD_SENTENCE_POS := Vector2i(4, 2)
const SWORD_LEFT_POS := Vector2i(16, 7)
const SWORD_RIGHT_POS := Vector2i(28, 6)
const GESTURE_SLOT_POS := Vector2i(26, 17)
const LIFELINE_WALL_CELLS: Array[Vector2i] = [
	Vector2i(21, 12), Vector2i(22, 12), Vector2i(23, 12),
	Vector2i(23, 13), Vector2i(23, 14), Vector2i(23, 15), Vector2i(23, 16)
]
const LIFELINE_INSPECT_CELLS: Array[Vector2i] = [
	Vector2i(21, 13), Vector2i(22, 13), Vector2i(22, 14), Vector2i(22, 15), Vector2i(22, 16)
]

const TOP_LINES := [
	{"pos": Vector2i(1, 2), "text": "＿得圣剑，拜见指内勇者。"},
	{"pos": Vector2i(1, 3), "text": "巨掌紧握，＿会轻易放开。"},
	{"pos": Vector2i(1, 5), "text": "＿勇者站在旁边大力＿扬。"}
]

const BOTTOM_LINE := {"pos": Vector2i(15, 17), "text": "俯瞰这＿个巨大手掌，是＿的手势"}

const PUSHABLE_WORDS := [
	{"pos": Vector2i(1, 2), "text": "赢"},
	{"pos": Vector2i(6, 3), "text": "不"},
	{"pos": Vector2i(1, 5), "text": "二"},
	{"pos": Vector2i(10, 5), "text": "赞"},
	{"pos": Vector2i(18, 17), "text": "一"},
	{"pos": Vector2i(26, 17), "text": "零"}
]

const HAND_LAYOUTS := {
	"zero": [
		"＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿",
		"＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿",
		"＿＿＿＿＿＿＿＿掌掌掌＿掌掌掌＿掌掌掌＿＿＿＿＿",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿＿",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌掌掌掌＿",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿掌掌掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿掌＿＿＿掌掌掌＿掌掌掌＿掌掌掌＿掌掌掌＿",
		"＿＿＿＿掌＿＿＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿掌＿＿＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌"
	],
	"like": [
		"＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿",
		"＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿",
		"＿＿＿＿＿＿＿＿掌掌掌＿掌掌掌＿掌掌掌＿＿＿＿＿",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿＿",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌掌掌掌＿",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿掌掌掌掌掌掌掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"掌＿＿＿＿＿＿＿掌掌掌＿掌掌掌＿掌掌掌＿掌掌掌＿",
		"掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌"
	],
	"one": [
		"＿＿＿＿＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌掌掌掌＿掌掌掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌掌掌掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿掌掌掌掌掌掌掌掌＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿掌＿＿＿＿＿＿＿＿掌掌＿掌掌掌＿掌掌掌＿",
		"＿＿＿＿掌＿＿＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿掌＿＿＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌"
	],
	"two": [
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌掌掌掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌掌掌掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿掌掌掌掌掌掌掌掌＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿掌＿＿＿＿＿＿＿＿掌＿＿掌掌掌＿掌掌掌＿",
		"＿＿＿＿掌＿＿＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿掌＿＿＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌"
	],
	"win": [
		"＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿掌＿＿＿掌＿＿掌＿＿＿掌",
		"＿＿＿＿掌＿＿＿掌＿＿掌＿＿＿掌掌掌掌",
		"＿＿＿＿＿掌＿＿＿掌＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿掌＿＿＿掌＿掌＿＿＿掌＿＿＿掌掌掌掌",
		"＿＿＿＿＿＿掌＿＿＿掌掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿掌＿＿＿掌掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿掌掌掌掌掌掌掌掌＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿掌＿＿＿＿＿＿＿＿掌＿＿掌掌掌＿掌掌掌＿",
		"＿＿＿＿掌＿＿＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿掌＿＿＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌"
	],
	"love": [
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿＿＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿＿＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌掌掌掌＿掌掌掌掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿掌掌掌掌掌掌掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"掌＿＿＿＿＿＿＿＿＿＿＿掌掌掌＿掌掌掌＿＿＿＿掌",
		"掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌"
	],
	"release": [
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿＿",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌掌掌掌＿",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿掌掌掌掌掌掌掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌",
		"＿＿＿＿＿＿＿掌＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿掌"
	]
}

static func build_rows() -> Array[String]:
	var rows: Array[String] = []
	for _i in range(HEIGHT):
		rows.append(" ".repeat(WIDTH))
	_overlay_block(rows, hand_lines("zero"), HAND_ORIGIN)
	for entry in TOP_LINES:
		rows[entry.pos.y] = _overlay(rows[entry.pos.y], _normalize(entry.text), entry.pos.x)
	rows[BOTTOM_LINE.pos.y] = _overlay(rows[BOTTOM_LINE.pos.y], _normalize(BOTTOM_LINE.text), BOTTOM_LINE.pos.x)
	rows[13] = _overlay(rows[13], "掌掌掌掌掌掌掌掌", 12)
	rows[12] = _overlay(rows[12], "掌掌掌", 21)
	for y in range(13, 17):
		rows[y] = _overlay(rows[y], "掌", 23)
	for entry in PUSHABLE_WORDS:
		rows[entry.pos.y] = _overlay(rows[entry.pos.y], entry.text, entry.pos.x)
	rows[SWORD_LEFT_POS.y] = _overlay(rows[SWORD_LEFT_POS.y], "剑", SWORD_LEFT_POS.x)
	for brave_pos in [Vector2i(24, 4), Vector2i(1, 16)]:
		rows[brave_pos.y] = _overlay(rows[brave_pos.y], "勇", brave_pos.x)
	rows[PLAYER_START.y] = _overlay(rows[PLAYER_START.y], " ", PLAYER_START.x)
	return rows

static func pushable_cell_configs() -> Dictionary:
	return {
		Vector2i(1, 2): {"pushable": true},
		Vector2i(6, 3): {"pushable": true, "deletable": true},
		Vector2i(1, 5): {"pushable": true},
		Vector2i(10, 5): {"pushable": true},
		Vector2i(18, 17): {"pushable": true},
		Vector2i(26, 17): {"pushable": true}
	}

static func hand_lines(state_name: String) -> Array[String]:
	var normalized: Array[String] = []
	for raw_line in HAND_LAYOUTS.get(state_name, HAND_LAYOUTS.zero):
		normalized.append(_normalize(String(raw_line)))
	return normalized

static func hand_spawn_text(state_name: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var lines := hand_lines(state_name)
	for y in range(lines.size()):
		var line := String(lines[y])
		if line.strip_edges().is_empty():
			continue
		entries.append({
			"text": line,
			"pos": HAND_ORIGIN + Vector2i(0, y),
			"as_chars": true,
			"config": {"solid": true}
		})
	return entries

static func hand_cells(state_name: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var lines := hand_lines(state_name)
	for y in range(lines.size()):
		var line := String(lines[y])
		for x in range(line.length()):
			if line.substr(x, 1) == " ":
				continue
			var cell := HAND_ORIGIN + Vector2i(x, y)
			if cell.x < 0 or cell.x >= WIDTH or cell.y < 0 or cell.y >= HEIGHT:
				continue
			if not cells.has(cell):
				cells.append(cell)
	return cells

static func all_hand_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for state_name in HAND_LAYOUTS.keys():
		for cell in hand_cells(String(state_name)):
			if not cells.has(cell):
				cells.append(cell)
	return cells

static func gesture_state_for_text(text: String) -> String:
	match text:
		"赞", "好":
			return "like"
		"一":
			return "one"
		"二":
			return "two"
		"赢":
			return "win"
		"爱":
			return "love"
		_:
			return "zero"

static func _overlay_block(rows: Array[String], lines: Array[String], origin: Vector2i) -> void:
	for y in range(lines.size()):
		var target_y := origin.y + y
		if target_y < 0 or target_y >= rows.size():
			continue
		rows[target_y] = _overlay(rows[target_y], lines[y], origin.x)

static func _normalize(text: String) -> String:
	return text.replace("＿", " ")

static func _overlay(base: String, text: String, start_x: int) -> String:
	var result := base
	for i in range(text.length()):
		var x := start_x + i
		if x < 0 or x >= WIDTH:
			continue
		if text.substr(i, 1) == " ":
			continue
		result = result.substr(0, x) + text.substr(i, 1) + result.substr(x + 1)
	return result


