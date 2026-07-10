extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	assert_true(FileAccess.file_exists("res://Fonts/Zpix.ttf"), "original Zpix font is present")
	assert_true(ResourceLoader.exists("res://Fonts/Zpix.tres"), "Zpix Godot font resource is present")
	assert_true(ResourceLoader.exists("res://scenes/animations/BridgeRecreated.tscn"), "BridgeRecreated scene is present")
	var bridge_scene := load("res://scenes/animations/BridgeRecreated.tscn")
	assert_true(bridge_scene is PackedScene, "BridgeRecreated scene loads as PackedScene")
	if bridge_scene is PackedScene:
		var bridge_instance: Node = (bridge_scene as PackedScene).instantiate()
		assert_true(bridge_instance is Node2D, "BridgeRecreated scene instantiates as Node2D")
		bridge_instance.free()

	if failures.is_empty():
		print("visual_resources tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func assert_true(actual: bool, label: String) -> void:
	if not actual:
		failures.append("%s expected true but got false" % label)
