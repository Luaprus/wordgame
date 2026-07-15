extends RefCounted

static func effect(source_text: String, part_texts: Array, extra: Dictionary = {}) -> Dictionary:
	var config := {
		"type": "word_split_transition",
		"source_text": source_text,
		"part_texts": part_texts.duplicate(),
		"jump_height": 30.0,
		"part_jump_heights": [30.0, 0.0],
		"move_duration": 0.5,
		"settle_duration": 0.18,
		"source_fade_duration": 0.08,
		"part_fade_in_duration": 0.06,
		"square_alpha": 0.42,
		"square_color": Color(0.96, 0.92, 0.62, 1.0),
		"particle_duration": 0.4,
		"particle_frame_count": 15
	}
	for key in extra.keys():
		config[key] = extra[key]
	return config
