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
var temporary_description := false
var persistent := false
var visual_rotation_degrees := 0.0
var visual_color := Color.WHITE
var visual_horizontal_shake_amplitude := 0.0
var visual_horizontal_shake_speed := 0.0
var visual_horizontal_shake_phase := 0.0
var visual_style := ""

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
	temporary_description = config.get("temporary_description", temporary_description)
	persistent = config.get("persistent", persistent)
	visual_rotation_degrees = float(config.get("visual_rotation_degrees", visual_rotation_degrees))
	visual_color = config.get("visual_color", visual_color)
	visual_horizontal_shake_amplitude = float(config.get("visual_horizontal_shake_amplitude", visual_horizontal_shake_amplitude))
	visual_horizontal_shake_speed = float(config.get("visual_horizontal_shake_speed", visual_horizontal_shake_speed))
	visual_horizontal_shake_phase = float(config.get("visual_horizontal_shake_phase", visual_horizontal_shake_phase))
	visual_style = str(config.get("visual_style", visual_style))

func move_by(delta: Vector2i) -> void:
	grid_pos += delta
	for i in range(cells.size()):
		cells[i] += delta

func move_to(pos: Vector2i) -> void:
	var delta := pos - grid_pos
	move_by(delta)
