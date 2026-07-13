extends RefCounted

static func build_test_level() -> Dictionary:
	return {
		"rows": [
			"墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙",
			"墙我 手表  石 墙          天 气很好        墙",
			"墙    删  戏  又 戈                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙"
		],
		"player_start": Vector2i(1, 1),
		"screen_size": Vector2i(32, 18),
		"entities": {
			"手表": {"interact_text": "手表可以查看人类世界的时间", "solid": true},
			"石": {"pushable": true, "solid": true},
			"删": {"deletable": true, "solid": true},
			"戏": {"splittable": true, "pushable": true, "solid": true},
			"又": {"pushable": true, "solid": true},
			"戈": {"pushable": true, "solid": true},
			"天": {"pushable": true, "solid": true},
			"气": {"solid": true},
			"很": {"solid": true},
			"好": {"solid": true}
		},
		"split_rules": {"戏": ["又", "戈"]},
		"merge_rules": {"又+戈": "戏", "戈+又": "戏"},
		"sentence_rules": {"天气": {"message": "已识别"}}
	}
