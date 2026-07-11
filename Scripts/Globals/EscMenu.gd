extends CanvasLayer

@onready var items = [
	$container/option_hint, 
	$container/option_setting, 
	$container/option_back, 
	$container/option_leave
]

var is_open = false
var is_in_setting_menu = false
var is_in_leave_menu = false

func _ready():
	$background/ColorRect.material = $background/ColorRect.material.duplicate()
	$background/ColorRect.material.set_shader_parameter("time", 0)
	$container.modulate.a = 0
	
	$container/SettingMenu.connect("closed", Callable(self, "close_setting_menu"))
	$container/LeaveMenu.connect("closed", Callable(self, "close_leave_menu"))
	$container/LeaveMenu.connect("close_game", Callable(self, "close_menu_quick"))
	
	load_murmur()
	print_murmur()


var murmur_data
var murmur_text = "這是自己的房間。應該總會有方法出去的吧？"
var hint_texts = ["認真找一找，||總會有出口的吧。", "趕快開門出去，||趕快開門出去⋯⋯||門呢？", "這一個房間裡，||真的沒有門嗎？"]
var now_hint_index = 0

func refresh():
	now_hint_index = 0
	clear_hint()
	$container/option_hint/WordSprite.text = ["想沉思一下", "想沉思二下", "想沉思三下"][now_hint_index]

func load_murmur():
	var data_file = FileAccess.open("res://Datas/murmur_data.json", FileAccess.READ)
	if not data_file:
		return
	var data_text = data_file.get_as_text()
	data_file.close()
	var test_json_conv = JSON.new()
	if test_json_conv.parse(data_text) != OK:
		return
	murmur_data = test_json_conv.get_data()

func print_murmur():
	clear_murmur()
	
	if murmur_data.get(Global.now_game_section, null):
		murmur_text = murmur_data[Global.now_game_section].murmur
	else:
		murmur_text = "murmur " + str(Global.now_game_section)
	
	$container/hint/hint_title.text = murmur_text
	
func clear_murmur():
	$container/hint/hint_title.text = ""

func print_title():
	var title_text
	if murmur_data.get(Global.now_game_section, null):
		title_text = murmur_data[Global.now_game_section].get("title", "陷入沉思")
	else:
		title_text = "陷入沉思"
	
	$container/title/WordSprite.text = title_text

var is_typing = false
var has_released_accept = false
var is_waiting_accept = false
func print_hint():
	is_typing = true
	has_released_accept = false
	clear_hint()
	
	var is_skiping = false
	
	hint_texts = []
	if murmur_data.get(Global.now_game_section, null):
		var h1 = getFullSentence(murmur_data[Global.now_game_section].hint_1)
		var h2 = getFullSentence(murmur_data[Global.now_game_section].hint_2)
		var h3 = getFullSentence(murmur_data[Global.now_game_section].hint_3)
		if h1.length() > 0:
			hint_texts.append(h1)
		if h2.length() > 0:
			hint_texts.append(h2)
		if h3.length() > 0:
			hint_texts.append(h3)
	else:
		hint_texts = ["hint_1", "hint_2", "hint_3"]
	
	if GA.section_data.has("hint_count"):
		GA.section_data.hint_count += 1
	
	var hint_text = hint_texts[now_hint_index]
	for i in range(hint_text.length()):
		if not has_released_accept and not Input.is_action_pressed("ui_accept"):
			has_released_accept = true
		elif has_released_accept and Input.is_action_pressed("ui_accept"):
			is_skiping = true
			
		if hint_text[i] == "|":
			if not is_skiping:
				await get_tree().create_timer(0.07).timeout
		else:
			$container/hint/hint_content.text += hint_text[i]
			
			if not is_skiping:
				play_typing_se()
				await get_tree().create_timer(0.07).timeout
	
	$container/hint/hint_content.text += "▼"
	await get_tree().process_frame
	
	while not Input.is_action_just_pressed("ui_accept"):
		await get_tree().process_frame
	
	play_click_se()
	$container/hint/hint_content.text = $container/hint/hint_content.text.split("▼")[0]
	
	now_hint_index += 1
	now_hint_index = now_hint_index % hint_texts.size()
	
	$container/option_hint/WordSprite.text = ["想沉思一下", "想沉思二下", "想沉思三下"][now_hint_index]

	is_typing = false
	
func clear_hint():
	$container/hint/hint_content.text = ""


func getFullSentence(s):
	var full = ""
	for i in range(s.length()):
		var word = s[i]
		full += word
		if word in ["，", "。", "、", "！", "？", "⋯", "：", "」", "；"]:
			if i + 1 >= s.length():
				continue;
			var next_word = s[i + 1]
			if not (next_word in ["⋯", "」"]):
				full += "||"
	return full





var now_select_index = 0

func _input(event):
	if not is_open: return
	if is_typing: return
	if is_in_setting_menu or is_in_leave_menu: return
	
	if (Input.is_action_just_pressed("ui_down")):
		move_cursor(2)
	if (Input.is_action_just_pressed("ui_left")):
		move_cursor(4)
	if (Input.is_action_just_pressed("ui_right")):
		move_cursor(6)
	if (Input.is_action_just_pressed("ui_up")):
		move_cursor(8)
	if (Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_joy_cancel") or Input.is_action_just_pressed("ui_joy_menu")):
		play_cancel_se()
		close_menu()
	if (Input.is_action_just_pressed("ui_accept")):
		match now_select_index:
			0:
				play_click_se()
				print_hint()
			1:
				play_click_se()
				open_setting_menu()
			2:
				play_cancel_se()
				close_menu()
			3:
				play_click_se()
				open_leave_menu()


var select_index_before_bottom
func move_cursor(d):
	match d:
		2:
			if now_select_index in [0, 1]:
				now_select_index += 2
		4:
			if now_select_index in [1, 3]:
				now_select_index -= 1
		6:
			if now_select_index in [0, 2]:
				now_select_index += 1
		8:
			if now_select_index in [2, 3]:
				now_select_index -= 2
	
	update_cursor_pos()
	play_walking_se()

func update_cursor_pos():
	var pos = items[now_select_index].position - Vector2(60, 0)
	$container/cursor.position = pos


var walking_foot_cycle = false
func play_walking_se():
	var r = randi() % 6 + 2
	var db = - 10
	var pan
	if walking_foot_cycle:
		pan = - 0.3
	else:
		pan = 0.3
	walking_foot_cycle = not walking_foot_cycle
	
	Sound.play_se("res://Sounds/se/footstep_" + str(r) + ".wav", db, pan)

func play_typing_se():
	Sound.play_typing_se()

func play_click_se():
	Sound.play_se("res://Sounds/se/typerwriter_feedpaper_2.wav")

func play_adjust_se():
	Sound.play_se("res://Sounds/se/typerwriter_feedpaper_1.wav")

func play_cancel_se():
	Sound.play_se("res://Sounds/se/system/SE_S_25_cancel.wav")

func open_setting_menu():
	$container/SettingMenu.open()
	is_in_setting_menu = true

func close_setting_menu():
	await get_tree().process_frame
	is_in_setting_menu = false

func open_leave_menu():
	$container/LeaveMenu.open()
	is_in_leave_menu = true

func close_leave_menu():
	await get_tree().process_frame
	is_in_leave_menu = false

func open_menu():
	Sound.play_se("res://Sounds/se/system/SE_S_29_thought_A.wav")
	Global.game_pause()
	$AnimationPlayer.play("FadeIn")
	UI.hide_esc_hint()
	Global.game_map.player.clear_idle_count()
	UI.show_esc_menu_hint()
	Sound.fade_bgm_esc_menu(true)
	print_title()
	print_murmur()
	now_select_index = 0
	update_cursor_pos()
	
	await $AnimationPlayer.animation_finished
	is_open = true
	$container/option_hint/WordSprite.text = ["想沉思一下", "想沉思二下", "想沉思三下"][now_hint_index]
	
func close_menu():
	$AnimationPlayer.play("FadeOut")
	UI.hide_esc_menu_hint()
	Sound.fade_bgm_esc_menu(false)
	is_open = false
	
	await get_tree().process_frame
	Global.game_resume()
	
func close_menu_quick():
	$AnimationPlayer.play("FadeOut", - 1, 10)
	UI.hide_esc_menu_hint()
	is_open = false
	
	await get_tree().process_frame
	Global.game_resume()
	
func is_menu_animating():
	return $AnimationPlayer.is_playing()
