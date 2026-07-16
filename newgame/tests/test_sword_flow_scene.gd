extends SceneTree

const SWORD_SCENE := "res://scenes/Maps/第二章/05_聖劍寶庫_復刻.tscn"
const REQUIRED_FILES := [
	"res://scripts/ReferenceSwordFlow.gd",
	"res://Data/reference_maze_map.json",
	"res://Data/reference_treasure_room_empty_map.json",
	"res://Data/reference_slime_cave_left_map.json",
	"res://Data/reference_slime_cave_right_map.json",
	"res://Data/reference_snake_boss_map.json",
	"res://assets/sprites/backspace_splash/splash.png",
	"res://assets/shaders/cut2.gdshader",
	"res://assets/sprites/me/me_default.png",
	"res://assets/sprites/me/me_walk.png",
	"res://assets/video/u_sword.ogv",
	"res://scenes/animations/TreeSprite.tscn",
	"res://Fonts/Zpix-v3.1.6.ttf"
]

var failures: Array[String] = []

func _init() -> void:
	for path in REQUIRED_FILES:
		assert_true(FileAccess.file_exists(path), "%s exists" % path)

	assert_true(ResourceLoader.exists(SWORD_SCENE), "sword flow scene is registered")
	var scene := load(SWORD_SCENE)
	assert_true(scene is PackedScene, "sword flow scene loads as PackedScene")
	if scene is PackedScene:
		var instance: Node = (scene as PackedScene).instantiate()
		assert_true(instance is Control, "sword flow scene instantiates as Control")
		assert_true(bool(instance.get("start_at_snake_second_phase")), "hall sword scene enters snake second phase directly")
		for cut_char in ["断", "没", "不", "对", "难", "你", "走", "过"]:
			var label := Label.new()
			label.text = cut_char
			assert_true(instance.call("_uses_backspace_cut_animation", label), "%s uses backspace cut animation" % cut_char)
			label.free()
		instance.free()
	var tree_scene := load("res://scenes/animations/TreeSprite.tscn")
	assert_true(tree_scene is PackedScene, "TreeSprite scene loads as PackedScene")
	if tree_scene is PackedScene:
		var tree_instance: Node = (tree_scene as PackedScene).instantiate()
		assert_true(tree_instance is Sprite2D, "TreeSprite scene instantiates as Sprite2D")
		tree_instance.free()

	if failures.is_empty():
		print("sword_flow_scene tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func assert_true(actual: bool, label: String) -> void:
	if not actual:
		failures.append("%s expected true but got false" % label)
