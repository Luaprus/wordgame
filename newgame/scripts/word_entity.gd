extends RefCounted

var id: String
var text: String
var grid_pos := Vector2i.ZERO
var cells: Array[Vector2i] = []
var solid := true
var pushable := false
var deletable := false
var splittable := false
var interact_text := ""
var interact_caption_lines: Array = []
var interact_caption_pos := Vector2i.ZERO
var has_interact_caption_pos := false
var interact_caption_solid := false
var interact_effect: Dictionary = {}
var split_positions: Array[Vector2i] = []
var highlighted := false
var visual_rotation_degrees := 0.0

func _init(entity_id := "", entity_text := "", pos := Vector2i.ZERO, occupied_cells: Array[Vector2i] = []) -> void:
	id = entity_id
	text = entity_text
	grid_pos = pos
	if occupied_cells.is_empty():
		cells = [pos]
	else:
		cells = occupied_cells.duplicate()

func set_from_config(config: Dictionary) -> void:
	solid = config.get("solid", solid)
	pushable = config.get("pushable", pushable)
	deletable = config.get("deletable", deletable)
	splittable = config.get("splittable", splittable)
	interact_text = config.get("interact_text", interact_text)
	interact_caption_lines = config.get("interact_caption_lines", interact_caption_lines)
	if config.has("interact_caption_pos"):
		interact_caption_pos = config.interact_caption_pos
		has_interact_caption_pos = true
	interact_caption_solid = config.get("interact_caption_solid", interact_caption_solid)
	interact_effect = config.get("interact_effect", interact_effect)
	if config.has("split_positions"):
		split_positions.clear()
		for pos in config.split_positions:
			split_positions.append(pos)
	visual_rotation_degrees = float(config.get("visual_rotation_degrees", visual_rotation_degrees))

func move_by(delta: Vector2i) -> void:
	grid_pos += delta
	for i in range(cells.size()):
		cells[i] += delta

func move_to(pos: Vector2i) -> void:
	var delta := pos - grid_pos
	move_by(delta)
