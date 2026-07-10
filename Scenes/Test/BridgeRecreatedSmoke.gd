extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	var bridge_scene := load("res://Scenes/Animations/BridgeRecreated.tscn")
	assert_true(bridge_scene is PackedScene, "BridgeRecreated scene loads as PackedScene")
	if bridge_scene is PackedScene:
		var bridge_instance: Node = (bridge_scene as PackedScene).instantiate()
		assert_true(bridge_instance is Node2D, "BridgeRecreated scene instantiates as Node2D")
		bridge_instance.free()

	if failures.is_empty():
		print("bridge recreated smoke passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)


func assert_true(actual: bool, label: String) -> void:
	if not actual:
		failures.append("%s expected true but got false" % label)
