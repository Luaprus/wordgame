extends SceneTree

const BASELINE_PATH := "res://../harness/baselines/levels/glove/source_matrices.json"
const GloveLevel = preload("res://levels/glove/glove_level.gd")
const GridWorld = preload("res://core/grid_world.gd")

func _init() -> void:
	var baseline := _read_json(BASELINE_PATH)
	var expected_rows: Array = baseline.get("states", {}).get("figure-1", {}).get("rows", [])
	var world := GridWorld.new()
	world.load_level(GloveLevel.build_level())
	var differences: Array[String] = []
	for y in range(18):
		for x in range(32):
			var pos := Vector2i(x, y)
			var expected := String(expected_rows[y]).substr(x, 1)
			var actual := _character_at(world, pos)
			if actual != expected:
				differences.append("[%s,%s] expected=%s actual=%s" % [x, y, _shown(expected), _shown(actual)])
	if differences.is_empty():
		print("glove source matrix tests passed")
		quit(0)
	else:
		for difference in differences:
			printerr(difference)
		printerr("figure-1 matrix mismatch count: %s" % differences.size())
		quit(1)

func _character_at(world: RefCounted, pos: Vector2i) -> String:
	if world.player_visible and world.player_pos == pos:
		return world.player_text
	var entity = world.get_any_entity_at(pos)
	if entity == null:
		return " "
	var index: int = entity.cells.find(pos)
	if index < 0 or index >= entity.text.length():
		return " "
	return entity.text.substr(index, 1)

func _shown(value: String) -> String:
	return "<space>" if value == " " else value

func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
