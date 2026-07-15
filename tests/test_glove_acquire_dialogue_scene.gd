extends SceneTree

const GlovePreviewScene = preload("res://levels/glove/glove_preview.tscn")
const EXPECTED_DIALOGUE := "不知道该如何使用这力量，又该承担怎样的责任。\n我犹豫地向前踏出了一步。勇者的觉悟不言自明。"
const EXPECTED_TUTORIAL := "「找出该被搬移的文字，用『方向键』推动看看文\n字吧。展现出勇者该有的觉悟，只在一步之遥。」"
const EXPECTED_HERO_QUOTE := "勇者说：「你已经学会了使用这股力量，\n现在你把剑给我，继续向前完成勇者试炼吧」"

func _init() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var preview = GlovePreviewScene.instantiate()
	root.add_child(preview)
	var dialogue = preview.get_node_or_null("GloveAcquisitionLayer/AcquireDialogueLabel")
	var tutorial = preview.get_node_or_null("GloveAcquisitionLayer/AcquireTutorialLabel")
	var indicator = preview.get_node_or_null("GloveAcquisitionLayer/AcquireDialogueContinue")
	var hero_quote = preview.get_node_or_null("GloveAcquisitionLayer/HeroQuoteLabel")
	var hero_player = preview.get_node_or_null("GloveAcquisitionLayer/HeroQuotePlayer")
	var hero_characters = preview.get_node_or_null("GloveAcquisitionLayer/HeroQuoteCharacters")
	if dialogue == null or tutorial == null or indicator == null or hero_quote == null or hero_player == null or hero_characters == null:
		printerr("the glove acquisition scene provides both dialogue layers, a grid-based hero quote, and its movable player word")
		preview.queue_free()
		quit(1)
		return
	if dialogue.position != Vector2(272, 572) or tutorial.position != Vector2(290, 314) or indicator.position != Vector2(1510, 315):
		printerr("the glove acquisition reflection and tutorial use their separately reviewed screen positions")
		preview.queue_free()
		quit(1)
		return
	preview._start_hero_quote()
	preview._advance_hero_quote(0.5)
	var hero_characters_before_skip_attempt: int = int(preview.hero_quote_index)
	var skip_attempt := InputEventKey.new()
	skip_attempt.pressed = true
	skip_attempt.keycode = KEY_SPACE
	preview._handle_hero_quote_input(skip_attempt)
	if preview.hero_quote_index != hero_characters_before_skip_attempt or hero_player.visible:
		printerr("hero quote input does not skip or spawn the player while the typewriter is still running")
		preview.queue_free()
		quit(1)
		return
	preview._advance_hero_quote(10.0)
	if hero_quote.text != EXPECTED_HERO_QUOTE.replace("我", "　") or not hero_player.visible or hero_player.text != "我":
		printerr("the completed hero quote turns its 我 character into the movable player word")
		preview.queue_free()
		quit(1)
		return
	if hero_characters.get_child_count() == 0 or fposmod(hero_player.position.x, 60.0) != 0.0 or fposmod(hero_player.position.y, 60.0) != 0.0:
		printerr("the hero quote player word starts on the same 60-pixel grid as the typed sentence")
		preview.queue_free()
		quit(1)
		return
	for character in hero_characters.get_children():
		if fposmod(character.position.x, 60.0) != 0.0 or fposmod(character.position.y, 60.0) != 0.0:
			printerr("every hero quote character occupies a 60-pixel grid cell")
			preview.queue_free()
		quit(1)
		return
	if not preview.hero_quote_world_active or preview.hero_quote_world.get_entity_at(preview._hero_quote_grid_cell_for_index(0)) == null or not preview.hero_exit_arrow.visible:
		printerr("the completed hero quote turns every visible word into a solid entity and shows the right-exit arrow")
		preview.queue_free()
		quit(1)
		return
	var player_before_move: Vector2 = hero_player.position
	var move_down := InputEventKey.new()
	move_down.pressed = true
	move_down.keycode = KEY_DOWN
	preview._handle_hero_quote_input(move_down)
	if hero_player.position != player_before_move:
		printerr("the hero quote player word turns before moving through the shared movement controller")
		preview.queue_free()
		quit(1)
		return
	preview._handle_hero_quote_input(move_down)
	if hero_player.position != player_before_move:
		printerr("the hero quote player word begins its smooth grid move instead of jumping immediately")
		preview.queue_free()
		quit(1)
		return
	preview._process(preview.move_visual_duration + 0.08)
	if hero_player.position != player_before_move + Vector2(0, 60):
		printerr("the hero quote player word reaches the next grid through the shared smooth grid mover: visual=%s expected=%s world=%s facing=%s" % [hero_player.position, player_before_move + Vector2(0, 60), preview.hero_quote_world.player_pos, preview.hero_quote_world.facing])
		preview.queue_free()
		quit(1)
		return
	preview.glove_acquisition_active = true
	preview._finish_glove_acquisition()
	preview._advance_acquisition_dialogue(10.0)
	if dialogue.text != EXPECTED_DIALOGUE:
		printerr("the glove acquisition dialogue shows both source lines before the continue indicator")
		preview.queue_free()
		quit(1)
		return
	preview._advance_acquisition_dialogue(10.0)
	if tutorial.text != EXPECTED_TUTORIAL or not preview.intro_active or indicator.visible:
		printerr("the completed glove tutorial becomes the playable push lesson without a continue prompt")
		preview.queue_free()
		quit(1)
		return
	var intro_no = preview.intro_world.get_entity_at(preview.INTRO_NO_START)
	if intro_no == null or intro_no.text != "不" or not intro_no.pushable or preview.intro_world.player_pos != preview.INTRO_PLAYER_START:
		printerr("the lower-line 我 is the player and the upper-line 不 is the pushable tutorial word")
		preview.queue_free()
		quit(1)
		return
	var reflection_word = preview.intro_world.get_entity_at(preview.INTRO_PLAYER_START + Vector2i.RIGHT)
	if reflection_word == null or reflection_word.text != preview.INTRO_BOTTOM_REMAINDER or reflection_word.pushable:
		printerr("every visible reflection word is a solid, non-pushable tutorial entity")
		preview.queue_free()
		quit(1)
		return
	var tutorial_word = preview.intro_world.get_entity_at(Vector2i(4, 4))
	if tutorial_word == null or not tutorial_word.text.begins_with("「"):
		printerr("the upper glove tutorial words are solid world entities")
		preview.queue_free()
		quit(1)
		return
	preview.intro_world.player_pos = Vector2i(4, 5)
	preview.intro_world.facing = Vector2i.UP
	preview._apply_intro_direction_step(Vector2i.UP)
	if preview.intro_world.player_pos != Vector2i(4, 5):
		printerr("the upper glove tutorial words prevent the player from overlapping them")
		preview.queue_free()
		quit(1)
		return
	preview.intro_world.player_pos = Vector2i(4, 7)
	preview.intro_world.facing = Vector2i.DOWN
	var intro_player_before_push: Vector2 = preview.intro_player.position
	preview._apply_intro_direction_step(Vector2i.DOWN)
	var pushed_no = preview.intro_world.get_entity_at(preview.INTRO_NO_TARGET)
	if pushed_no == null or pushed_no.text != "不" or not preview.intro_quote_started or tutorial.visible:
		printerr("pushing 不 into the reviewed target cell replaces the top tutorial with the brave quote typewriter")
		preview.queue_free()
		quit(1)
		return
	if preview.intro_player.position != intro_player_before_push:
		printerr("the push tutorial player uses the shared smooth movement instead of jumping")
		preview.queue_free()
		quit(1)
		return
	preview._process(preview.move_visual_duration)
	if preview.intro_player.position != preview._intro_grid_to_pixels(Vector2i(4, 8)):
		printerr("the push tutorial player reaches its new grid cell through the shared movement controller")
		preview.queue_free()
		quit(1)
		return
	preview._advance_intro_typewriter(10.0)
	var final_quote_character = preview.intro_world.get_entity_at(Vector2i(4, 5))
	if final_quote_character == null or final_quote_character.text != "知":
		printerr("the complete brave quote is emitted one character at a time on the reviewed top rows")
		preview.queue_free()
		quit(1)
		return
	preview.intro_world.player_pos = Vector2i(4, 5)
	preview.intro_world.facing = Vector2i.UP
	preview._apply_intro_direction_step(Vector2i.UP)
	if preview.intro_world.player_pos != Vector2i(4, 5):
		printerr("the typewritten brave quote characters are solid and prevent the player from overlapping them")
		preview.queue_free()
		quit(1)
		return
	var continue_intro := InputEventKey.new()
	continue_intro.pressed = true
	continue_intro.keycode = KEY_SPACE
	preview._handle_intro_input(continue_intro)
	var preserved_no = preview.intro_world.get_entity_at(preview.INTRO_NO_TARGET)
	var first_rewrite_character = preview.intro_world.get_entity_at(preview.INTRO_NO_TARGET + Vector2i.RIGHT)
	if preserved_no == null or preserved_no.text != "不" or not preserved_no.pushable or preview.intro_bottom_remainder.visible or first_rewrite_character == null or first_rewrite_character.text != "相":
		printerr("space after the completed brave quote preserves 不 and begins the replacement lower sentence with a typewriter")
		preview.queue_free()
		quit(1)
		return
	preview._advance_intro_typewriter(10.0)
	var second_rewrite_line = preview.intro_world.get_entity_at(Vector2i(4, 10))
	if second_rewrite_line == null or second_rewrite_line.text != "留":
		printerr("the replacement lower sentence completes its second typewriter line below the preserved 不")
		preview.queue_free()
		quit(1)
		return
	if not preview.intro_top_rewrite_started:
		printerr("completing the replacement lower sentence automatically starts the replacement top typewriter")
		preview.queue_free()
		quit(1)
		return
	preview._advance_intro_typewriter(10.0)
	var top_rewrite_character = preview.intro_world.get_entity_at(Vector2i(5, 4))
	if top_rewrite_character == null or top_rewrite_character.text != "当":
		printerr("the replacement top typewriter replaces the brave quote with the ALT pull instruction")
		preview.queue_free()
		quit(1)
		return
	var movable_no = preview.intro_world.get_entity_at(preview.INTRO_NO_TARGET)
	preview.intro_world.move_entity_to(movable_no.id, preview.INTRO_NO_FINAL_TARGET)
	preview._check_intro_completion()
	if not preview.intro_completion_pending or not preview.intro_active or preview.hero_quote_active:
		printerr("placing the always-pushable 不 before 留 holds the completed lesson before its transition")
		preview.queue_free()
		quit(1)
		return
	preview._advance_intro_completion_transition(0.29)
	if preview.hero_quote_active or preview.intro_layer.position != Vector2.ZERO:
		printerr("the completed lesson remains still for the required 0.3-second pause")
		preview.queue_free()
		quit(1)
		return
	preview._advance_intro_completion_transition(0.31)
	if preview.hero_quote_active or preview.intro_layer.position == Vector2.ZERO:
		printerr("the completed lesson shakes during the required 0.5-second transition")
		preview.queue_free()
		quit(1)
		return
	preview._advance_intro_completion_transition(0.5)
	if not preview.intro_completed or preview.intro_active or preview.intro_layer.visible or not preview.hero_quote_active:
		printerr("the completed lesson clears only after its pause and shake before starting the hero quote")
		preview.queue_free()
		quit(1)
		return
	preview._advance_hero_quote(0.1)
	if preview.hero_quote_characters.get_child_count() == 0:
		printerr("the cleared lesson begins the hero quote with its typewriter effect")
		preview.queue_free()
		quit(1)
		return
	preview.queue_free()
	print("glove acquisition dialogue scene tests passed")
	quit(0)
