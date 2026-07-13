extends Node2D

const GridWorld = preload("res://scripts/grid_world.gd")
const HelmetTutorial = preload("res://levels/helmet/helmet_tutorial.gd")
const GemBurstEffect = preload("res://scripts/gem_burst_effect.gd")
const OriginalFont = preload("res://Fonts/Zpix.tres")

const CELL_SIZE := 60
const GEM_ORIGIN_GRID := Vector2(15.5, 15.5)

var world := GridWorld.new()
var map_layer: Node2D
var gem_burst_effect
var gem_labels: Array = []

func _ready() -> void:
	world.load_level(HelmetTutorial.build_level())
	_build_scene()
	_refresh_scene()
	await get_tree().create_timer(0.45).timeout
	_play_gem_burst()

func _process(_delta: float) -> void:
	if gem_burst_effect == null:
		return
	for entry in gem_labels:
		var label: Label = entry.label
		var position: Vector2 = entry.position
		var base_color: Color = entry.base_color
		label.add_theme_color_override("font_color", gem_burst_effect.color_for_position(position, base_color))

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_R:
		_play_gem_burst()
	elif key_event.keycode == KEY_ESCAPE:
		get_tree().quit()

func _build_scene() -> void:
	map_layer = Node2D.new()
	map_layer.name = "GemLevel"
	add_child(map_layer)

	for entity in world.entities.values():
		var group := Node2D.new()
		group.position = _grid_to_pixels(entity.grid_pos)
		group.rotation_degrees = entity.visual_rotation_degrees
		for i in range(entity.text.length()):
			var character: String = str(entity.text).substr(i, 1)
			var label := _make_word_label(character, entity.visual_color)
			label.position = Vector2(i * CELL_SIZE, -2)
			group.add_child(label)
			if character == "宝" or character == "石":
				var cell_center := _grid_to_pixels(entity.grid_pos + Vector2i(i, 0)) + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
				gem_labels.append({"label": label, "position": cell_center, "base_color": entity.visual_color})
		map_layer.add_child(group)

	var player_label := _make_word_label(world.player_text, Color(0.92, 0.92, 0.92))
	player_label.position = _grid_to_pixels(world.player_pos)
	map_layer.add_child(player_label)

	gem_burst_effect = GemBurstEffect.new()
	gem_burst_effect.name = "GemBurstEffect"
	map_layer.add_child(gem_burst_effect)

	var canvas := CanvasLayer.new()
	canvas.name = "TestOverlay"
	add_child(canvas)
	var hint := _make_word_label("宝石闪光特效测试    Space / R 重播    Esc 退出", Color(0.66, 0.66, 0.66))
	hint.position = Vector2(24, 18)
	hint.scale = Vector2(0.55, 0.55)
	canvas.add_child(hint)

func _refresh_scene() -> void:
	map_layer.position = Vector2.ZERO

func _play_gem_burst() -> void:
	if gem_burst_effect == null:
		return
	var origin := _grid_to_pixels_float(GEM_ORIGIN_GRID)
	gem_burst_effect.play_at(origin, CELL_SIZE, 0.78, 1947)

func _grid_to_pixels(pos: Vector2i) -> Vector2:
	return Vector2(pos.x * CELL_SIZE, pos.y * CELL_SIZE)

func _grid_to_pixels_float(pos: Vector2) -> Vector2:
	return pos * float(CELL_SIZE)

func _make_word_label(text: String, font_color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.size = Vector2(CELL_SIZE, CELL_SIZE + 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_contents = false
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_font_override("font", OriginalFont)
	label.add_theme_color_override("font_color", font_color)
	return label
