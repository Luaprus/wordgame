extends Node

var game_map

var is_in_debug_mode = false



var is_steam_lang_zh = true

var steam_id = 0
var is_dev = false
var steam_api = null

var black_bar = preload("res://Sprites/black_bar.png")

signal on_translate

func _ready():
	get_tree().set_auto_accept_quit(false)
	

	RenderingServer.set_default_clear_color(Color(0, 0, 0, 1.0))
	
	_initialize_Steam()
	
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	await Sound.is_ready
	ensure_user_save_dir()
	migrate_legacy_user_save_files()
	load_game_progress()
	load_settings()
	
	read_ts_dictionary()
	
	Input.set_custom_mouse_cursor(load("res://Sprites/tranparent_1x1.png"))
	


func _process(_delta: float) -> void :
	if steam_api:
		steam_api.run_callbacks()

func _initialize_Steam() -> void :
	if Engine.has_singleton("Steam"):
		steam_api = Engine.get_singleton("Steam")
	else:
		print("GodotSteam singleton not found; Steam features disabled.")
		return

	var INIT: Dictionary = steam_api.steamInit()
	print("Did Steam initialize?: " + str(INIT))
	
	if INIT["status"] != 1:
		print("Failed to initialize Steam. " + str(INIT["verbal"]) + " Shutting down...")
		if OS.has_feature("standalone"):
			get_tree().quit()
	
	if steam_api.getAppID() != 1109570:
		print("App ID Error.")
		if OS.has_feature("standalone"):
			get_tree().quit()
	
	print("IS_ONLINE:", steam_api.loggedOn())
	print("Steam ID:", steam_api.getSteamID())
	print("User Name:", steam_api.getPersonaName())
	
	print("App ID:", steam_api.getAppID())
	print("Language:", steam_api.getCurrentGameLanguage())

	is_steam_lang_zh = steam_api.getCurrentGameLanguage() == "tchinese"
	steam_id = steam_api.getSteamID()
	
	var dev_id_list = [
		76561198382689488, 
		76561198138500021, 
		76561198189580757, 
		76561198285083779, 
		76561198314128709, 
		76561198294832480
	]
	is_dev = steam_id in dev_id_list
	if is_dev: print("dev!")



var game_switches = {}

func set_game_switch(key, value):

	if get_game_switch(key) == value: return
	
	game_switches[key] = value
	refresh_map()
	
func get_game_switch(key):
	return game_switches.get(key, false)


var game_self_switches = {}
func set_game_self_switch(event_name, index, value):
	if get_game_self_switch(event_name, index) == value: return
	
	if not game_self_switches.has(now_map_name):
		game_self_switches[now_map_name] = {}
	if not game_self_switches[now_map_name].has(event_name):
		game_self_switches[now_map_name][event_name] = {}
	game_self_switches[now_map_name][event_name][index] = value
	refresh_map()
	
func get_game_self_switch(event_name, index):
	if not game_self_switches.has(now_map_name):
		return false
	if not game_self_switches[now_map_name].has(event_name):
		return false
	return game_self_switches[now_map_name][event_name].get(index, false)

func clear_game_self_condition():
	game_self_switches = {}


var game_variables = {}

func set_game_variable(key, value):
	if typeof(get_game_variable(key)) == typeof(value) and get_game_variable(key) == value: return
	
	game_variables[key] = value
	refresh_map()

func add_game_variable(key, value):
	var v = get_game_variable(key)
	set_game_variable(key, v + value)
	
func get_game_variable(key):
	return game_variables.get(key, 0)



var player_status_for_map_change = {
	"direction": 2, 
	"spawn_pos": null, 
	"opacity": null
}

var player_status = {
	"has_backspace_power": false, 
	"has_push_power": false, 
	"has_split_power": false, 
	"has_ctrl_z_power": false, 
	"opacity": 1
}

var now_map_name
func map_transport(map_name, pos = null, need_to_save_map_status = true, transition_type = "fade", opacity = null):
	if need_to_save_map_status:
		save_map_status()
	player_status_for_map_change["spawn_pos"] = pos
	player_status_for_map_change["opacity"] = opacity
	var scene_path = "res://Scenes/Maps/" + map_name + ".tscn"
	
	match transition_type:
		"fade":
			UI.fade_transition_scene(scene_path)
		"fade_white":
			UI.fade_white_transition_scene(scene_path)
		"fade_fast":
			UI.fade_fast_transition_scene(scene_path)
		"whirl":
			UI.whirl_transition_scene(scene_path)
		"none":
			game_pause()
			Load.change_scene_to_file(scene_path)

	
func update_self_game_condition():
	var map_filename = Load.current_scene.scene_file_path
	map_filename.erase(0, map_filename.rfind("Maps/") + 5)
	map_filename = map_filename.replace(".tscn", "")
	
	now_map_name = map_filename
	print(now_map_name)
	if not game_self_switches.has(now_map_name):
		game_self_switches[now_map_name] = {}
		
	



var now_game_section = null
func enter_section(section_name, need_save = true, has_animation = true):
	if now_game_section == null or now_game_section == section_name:
		
		need_save = false
	else:
		
		finish_section(now_game_section)
	
	print("enter_section: ", section_name)
	now_game_section = section_name
	EscMenu.refresh()
	
	if game_map.player:
		game_map.player.clear_section_playing_time()
	
	if need_save:
		await get_tree().process_frame
		save_game(has_animation)

func finish_section(section_name):
	print("finish_section: ", section_name, " spend time: ", GA.section_data.spend_time)
	GA.submit()
	GA.clear_data()
	pass


func refresh_map():
	if game_map and is_instance_valid(game_map) and game_map.is_inited:

		game_map.refresh()


var all_map_status = {}
func save_map_status():
	if not game_map or not is_instance_valid(game_map): return
	
	var map_filename = get_tree().current_scene.scene_file_path
	print("save_map_status:", map_filename)
	map_filename.erase(0, map_filename.rfind("Maps/") + 5)
	map_filename = map_filename.replace(".tscn", "")
	
	all_map_status[map_filename] = game_map.save_status()

func load_map_status():
	var map_filename = get_tree().current_scene.scene_file_path
	map_filename.erase(0, map_filename.rfind("Maps/") + 5)
	map_filename = map_filename.replace(".tscn", "")
	
	if all_map_status.has(map_filename):
		game_map.load_status(all_map_status[map_filename])
	
func clear_all_map_status():
	all_map_status = {}
	
signal save_completed
func save_game(has_animation = true):
	save_map_status()
	
	var save_data = {}
	save_data.game_switches = game_switches
	save_data.game_variables = game_variables
	save_data.game_self_switches = game_self_switches
	save_data.now_map_name = now_map_name
	save_data.now_game_section = now_game_section
	save_data.player_status = {
		"has_backspace_power": player_status.has_backspace_power, 
		"has_push_power": player_status.has_push_power, 
		"has_split_power": player_status.has_split_power, 
		"has_ctrl_z_power": player_status.has_ctrl_z_power, 
		"opacity": player_status.opacity
	}
	if game_map and is_instance_valid(game_map) and game_map.player:
		save_data.player_status["pos"] = {"x": game_map.player.now_pos.x, "y": game_map.player.now_pos.y}
		save_data.player_status["dir"] = game_map.player.direction
	
	save_data.all_map_status = all_map_status

	
	
	var f = open_encrypted_save_file("user://save.wg", FileAccess.WRITE)
	if not f:
		push_error("Failed to open save file for writing: user://save.wg error: " + str(FileAccess.get_open_error()))
		emit_signal("save_completed")
		return
	f.store_var(save_data)
	f.close()
	
	print("saved")
	
	if has_animation:
		UI.show_save_hint()
	
	
	
	
	
	
	
	emit_signal("save_completed")


func load_game(trans_ani = "fade"):
	var pt = Time.get_ticks_msec()
	
	if not FileAccess.file_exists("user://save.wg"):
		return
	
	
	var f = open_encrypted_save_file("user://save.wg", FileAccess.READ)
	if not f:
		return
	var save_data = f.get_var()
	f.close()

	
	
	game_switches = save_data.game_switches
	game_variables = save_data.game_variables
	game_self_switches = save_data.game_self_switches
	now_map_name = save_data.now_map_name
	now_game_section = save_data.now_game_section
	all_map_status = save_data.all_map_status
	
	player_status.has_backspace_power = save_data.player_status.has_backspace_power
	player_status.has_push_power = save_data.player_status.has_push_power
	player_status.has_split_power = save_data.player_status.has_split_power
	player_status.has_ctrl_z_power = save_data.player_status.has_ctrl_z_power
	player_status.opacity = save_data.player_status.opacity
	
	for key in all_map_status.keys():
		print(key, ": ", all_map_status[key].keys().size())
	
	var pos = Vector2()
	if save_data.player_status.has("pos"):
		pos = Vector2(save_data.player_status.pos.x, save_data.player_status.pos.y)
	map_transport(now_map_name, pos, false, trans_ani)
	
	var nt = Time.get_ticks_msec()
	print("load_time: ", nt - pt)

func load_to_check_now_map_name():
	if not FileAccess.file_exists("user://save.wg"):
		return null
	
	var f = open_encrypted_save_file("user://save.wg", FileAccess.READ)
	if not f:
		return null
	var save_data = f.get_var()
	f.close()
	
	return save_data.now_map_name

func preload_map_in_load_flie():
	if not FileAccess.file_exists("user://save.wg"):
		return

	var f = open_encrypted_save_file("user://save.wg", FileAccess.READ)
	if not f:
		return
	var save_data = f.get_var()
	f.close()
	
	var scene_path = "res://Scenes/Maps/" + save_data.now_map_name + ".tscn"
	
	Load.preload_scene(scene_path)



func start_game():
	clear_all_data()
	print("clear_all_data")
	map_transport("第一章/01_開頭", null, false)

func enter_chapter(index):
	clear_all_data()
	print("clear_all_data")
	match int(index):
		1:
			map_transport("第一章/01_開頭", null, false)
		2:
			map_transport("第二章/00_第二章字卡", null, false)
		3:
			map_transport("第三章/00_第三章字卡", null, false)
		4:
			map_transport("第四章/00_第四章字卡", null, false)
		5:
			map_transport("第五章/00_第五章字卡", null, false)
		6:
			Global.set_game_switch("ch6_開發名單_結束", true)
			map_transport("第六章/01_偽結局_開發人員名單", null, false)
		7:
			map_transport("第七章/00_第七章字卡", null, false)
		8:
			map_transport("第八章/心智打字機", null, false)


func clear_all_data():
	game_switches = {}
	game_variables = {}
	game_self_switches = {}
	now_map_name = null
	now_game_section = null
	all_map_status = {}

	player_status.has_backspace_power = false
	player_status.has_push_power = false
	player_status.has_split_power = false
	player_status.has_ctrl_z_power = false
	
	GA.clear_data()



func ctrl_z():
	print("ctrl z")
	if GA.section_data.has("undo_count"):
		GA.section_data.undo_count += 1
	load_game("whirl")

func ctrl_s():
	print("ctrl s")




func screen_shot():
	UI.get_node("螢幕整體暗度調整").visible = false

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var img = get_viewport().get_texture().get_image()
	await get_tree().process_frame
	await get_tree().process_frame


	img.flip_y()
	




	
	
	var desktop_path = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	var dir = DirAccess.open(desktop_path)
	if not dir.dir_exists("/wordgame_screenshot"):
		dir.make_dir("wordgame_screenshot")
		
	var date = Time.get_datetime_dict_from_system()
	var date_string = "%s%02d%02d%02d%02d%02d" % [date.year, date.month, date.day, date.hour, date.minute, date.second]
	
	var file_path = desktop_path + "/wordgame_screenshot/" + "screenshot_" + date_string + ".png"
	img.save_png(file_path)
	
	print("screen shot: " + file_path)
	UI.get_node("螢幕整體暗度調整").visible = true

var debug_mode_count = 0
func toggle_debug_mode():
	debug_mode_count += 1
	if debug_mode_count != 3: return
	
	if OS.has_feature("standalone") and not is_dev:
		check_is_dev_steam_id(steam_id)
		await self.check_is_dev_steam_id_finished
		if not is_dev:
			print("not dev!")
			return
	
	debug_mode_count = 0
	is_in_debug_mode = not is_in_debug_mode
	player_status.has_backspace_power = true
	player_status.has_push_power = true
	player_status.has_split_power = true
	player_status.has_ctrl_z_power = true
	if is_in_debug_mode:
		Sound.play_se("res://Sounds/se/typewriter/Bell中音.wav")
		print("debug mode on")
	else:
		Sound.play_se("res://Sounds/se/typewriter/Bell中音.wav")
		print("debug mode off")

var is_game_pause = false
func game_pause_toggle():
	is_game_pause = not is_game_pause
	get_tree().paused = is_game_pause

func game_pause():
	print("game_pause")
	is_game_pause = true
	get_tree().paused = is_game_pause
	
func game_resume():
	print("game_resume")
	is_game_pause = false
	get_tree().paused = is_game_pause

func _input(ev):






	if Input.is_action_just_pressed("ui_debug"):
		toggle_debug_mode()
	if Input.is_action_just_pressed("ui_translate") and Global.settings.has_ts_mode:
		if not Global.get_game_switch("禁用簡繁轉換中"):
			self.is_simplified = not self.is_simplified
			emit_signal("on_translate")
		
var is_visit_title_screen_by_return = false
var is_visit_title_screen_by_killed = false
func return_to_title_screen(transition_type = "fade"):
	is_visit_title_screen_by_return = true
	

	var scene_path = "res://Scenes/UI/MainMenu.tscn"
	
	match transition_type:
		"fade":
			UI.fade_transition_scene(scene_path)
		"whirl":
			UI.whirl_transition_scene(scene_path)
		"none":
			is_visit_title_screen_by_killed = true
			game_pause()

			Load.change_scene_to_file(scene_path)
			game_resume()
		

var settings = {
	"se_level": 3, 
	"bgm_level": 3, 
	"light_level": 1, 
	"has_ts_mode": 0, 
	"lang": 0, 
	"fullscreen": 1, 
	"skin": 0
}

func save_settings():
	if not ensure_user_save_dir():
		return
	var save_file = FileAccess.open("user://settings.wg", FileAccess.WRITE)
	if not save_file:
		push_error("Failed to open settings file for writing: user://settings.wg error: " + str(FileAccess.get_open_error()))
		return
	save_file.store_line(JSON.new().stringify(settings))
	save_file.close()
	
	print("settings saved")
	
	refresh_settings()
	
func load_settings():
	if not FileAccess.file_exists("user://settings.wg"):
		if not Global.is_steam_lang_zh:
			settings["has_ts_mode"] = 1
			settings["lang"] = 0
		refresh_settings()
		return

	
	var save_file = FileAccess.open("user://settings.wg", FileAccess.READ)
	if not save_file:
		return
	var test_json_conv = JSON.new()
	test_json_conv.parse(save_file.get_line())
	var save_data = test_json_conv.get_data()
	save_file.close()
	
	for key in save_data:
		if settings.has(key):
			settings[key] = save_data[key]
	
	if Global.is_steam_lang_zh:
		settings["has_ts_mode"] = 0
		settings["lang"] = 0
		
	if not is_now_skin_vaild(settings.get("skin")):
		settings["skin"] = 0
		print("now_skin not vaild")


	
	print(settings)
	
	refresh_settings()
	
	print("settings loaded")

func refresh_settings():
	Sound.set_bgm_volume(settings.bgm_level)
	Sound.set_se_volume(settings.se_level)
	UI.refresh_screen_light()
	is_simplified = (settings.get("has_ts_mode", 0) == 1) and (settings.get("lang", 0) == 1)
	toggle_fullscreen(settings.get("fullscreen", 1) == 1)
	print("refresh_settings")

var is_fullscreen_init = false
func toggle_fullscreen(switch):
	var target_mode = Window.MODE_EXCLUSIVE_FULLSCREEN if switch else Window.MODE_WINDOWED
	if is_fullscreen_init and get_window().mode == target_mode:
		return
	
	is_fullscreen_init = true
	var screen_size = DisplayServer.screen_get_size()
	await get_tree().process_frame
	get_window().mode = target_mode
	if not switch:
		var game_ratio = 1200.0 / 1920.0
		var screen_ratio = screen_size.y / screen_size.x
		
		var max_percent = 0.7
		
		var new_screen_size = Vector2(screen_size.x * (screen_ratio / game_ratio), screen_size.y) * max_percent
		get_window().set_size(new_screen_size)
		get_window().position = screen_size / 2.0 - new_screen_size / 2.0

var chapter_progress = 0
func set_chapter_progress(i):
	if chapter_progress < i:
		chapter_progress = i
		save_game_progress()

var now_game_progress = ""
func set_now_game_progress(progress):
	now_game_progress = progress
	save_game_progress()

var skins_state = ""
const SAVE_PASSWORD = "wordgame"
const SAVE_FILE_NAMES = ["save.wg", "game.wg", "settings.wg"]
const ENCRYPTED_HEADER_MAGIC = 0x43454447
const ENCRYPTED_HEADER_SIZE = 44

func ensure_user_save_dir() -> bool:
	var save_dir = DirAccess.open("user://")
	if save_dir:
		return true
	var user_path = ProjectSettings.globalize_path("user://")
	var err = DirAccess.make_dir_recursive_absolute(user_path)
	if err != OK:
		push_error("Failed to create save directory: " + user_path + " error: " + str(err))
		return false
	return true

func migrate_legacy_user_save_files() -> void:
	if not ensure_user_save_dir():
		return
	var current_dir = OS.get_user_data_dir()
	var legacy_name = str(ProjectSettings.get_setting("application/config/name", ""))
	if legacy_name.is_empty():
		return
	var legacy_dir = current_dir.get_base_dir().path_join(legacy_name)
	if legacy_dir == current_dir or not DirAccess.dir_exists_absolute(legacy_dir):
		return
	for file_name in SAVE_FILE_NAMES:
		var source_path = legacy_dir.path_join(file_name)
		var target_path = current_dir.path_join(file_name)
		if not FileAccess.file_exists(source_path) or FileAccess.file_exists(target_path):
			continue
		var source_file = FileAccess.open(source_path, FileAccess.READ)
		if not source_file:
			push_warning("Failed to read legacy save file: " + source_path)
			continue
		var target_file = FileAccess.open(target_path, FileAccess.WRITE)
		if not target_file:
			push_warning("Failed to migrate legacy save file to: " + target_path)
			source_file.close()
			continue
		target_file.store_buffer(source_file.get_buffer(source_file.get_length()))
		target_file.close()
		source_file.close()

func open_encrypted_save_file(path: String, mode: int):
	if mode != FileAccess.READ and not ensure_user_save_dir():
		return null
	if mode == FileAccess.READ:
		if not FileAccess.file_exists(path):
			return null
		var raw_file = FileAccess.open(path, FileAccess.READ)
		if not raw_file:
			return null
		var file_length = raw_file.get_length()
		var is_valid_encrypted_file = false
		if file_length >= ENCRYPTED_HEADER_SIZE and raw_file.get_32() == ENCRYPTED_HEADER_MAGIC:
			raw_file.seek(20)
			var data_length = raw_file.get_64()
			var encrypted_length = data_length
			if encrypted_length % 16 != 0:
				encrypted_length += 16 - (encrypted_length % 16)
			is_valid_encrypted_file = file_length >= ENCRYPTED_HEADER_SIZE + encrypted_length
		raw_file.close()
		if not is_valid_encrypted_file:
			print_verbose("Ignoring corrupt or legacy save file: " + path)
			return null
	return FileAccess.open_encrypted_with_pass(path, mode, SAVE_PASSWORD)

func save_game_progress():
	var save_data = {
		"chapter_progress": chapter_progress, 
		"now_game_progress": now_game_progress, 
		"skins_state": skins_state
	}
	var f = open_encrypted_save_file("user://game.wg", FileAccess.WRITE)
	if not f:
		push_error("Failed to open progress file for writing: user://game.wg error: " + str(FileAccess.get_open_error()))
		return
	f.store_var(save_data)
	f.close()
	
	print("game progress saved:", save_data)
	
func load_game_progress():
	if not FileAccess.file_exists("user://game.wg"):
		return
		
	var f = open_encrypted_save_file("user://game.wg", FileAccess.READ)
	if not f:
		return
	var data = f.get_var()
	f.close()
	
	chapter_progress = data.get("chapter_progress", 0)
	now_game_progress = data.get("now_game_progress", "")
	skins_state = data.get("skins_state", "")
	
	var hashed_id = get_hashed_steam_id(str(steam_id))
	if not (hashed_id in skins_state):
		print("skins_state id error!")
		skins_state = ""
		
	

	
	print("game progress loaded: ", data)

func is_now_skin_vaild(now_skin):
	var has_skins = [0]
	var _skin_state = 0
	
	if skins_state != "":
		_skin_state = int(skins_state[len(skins_state) - 1])
	
	if _skin_state == 1: has_skins = [0, 2]
	if _skin_state == 2: has_skins = [0, 1, 2]
	if _skin_state == 3: has_skins = [0, 1]
	
	print("_skin_state:", _skin_state, " has_skins:", has_skins, " now_skin:", int(now_skin))
	
	return int(now_skin) in has_skins

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()
		
func quit_game():
	print("quit game!")
	
	save_settings()
	
	if GA.section_data.has("leave_count"):
		GA.section_data.leave_count += 1
	GA.save_ga_data()
	get_tree().quit()
	




var is_simplified = false: set = _on_set_is_simplified
var ts_dictionary = {}

var ts_white_list = ""
func read_ts_dictionary():
	var file = FileAccess.open("res://Datas/TSCharacters.txt", FileAccess.READ)
	if not file:
		return
	while not file.eof_reached():
		var line = file.get_line()
		var pair = line.split("\t")
		if pair.size() < 2:
			continue
		ts_dictionary[pair[0]] = pair[1][0]
	file.close()

func t_to_s(text):
	var s_text = ""
	for i in len(text):
		if text[i] in ts_white_list:
			s_text += text[i]
		else:
			s_text += ts_dictionary.get(text[i], text[i])
	
	return s_text


func _on_set_is_simplified(value):
	if is_simplified != value:
		for word_sprite in get_tree().get_nodes_in_group("word_sprite"):
			word_sprite.update_draw()
	
	is_simplified = value
	if is_simplified:
		settings.lang = 1
	else:
		settings.lang = 0
	pass

func kill_player(death_sentence = "", death_sentence_pos = [0, 0]):
	game_map.player.lock()
	
	if GA.section_data.has("death_count"):
		GA.section_data.death_count += 1
	
	if death_sentence:
		set_game_variable("死亡句子", [death_sentence, death_sentence_pos])
		set_game_switch("有死亡句子", true)
	
	game_pause()
	var dead_pos = game_map.player.get_pos_in_camera()
	
	var real_dead_pos = game_map.player.get_real_pos_in_camera()
	set_game_variable("死亡位置", [real_dead_pos.x, real_dead_pos.y])

	await get_tree().create_timer(1).timeout
	

	map_transport("系統/死亡畫面", dead_pos, false, "none")


func set_achievement(ach_name):
	print("set_achievement:", ach_name)
	if not steam_api:
		return
	steam_api.setAchievement(ach_name)
	steam_api.storeStats()
	
func clear_achievement(ach_name):
	print("clear_achievement:", ach_name)
	if not steam_api:
		return
	steam_api.clearAchievement(ach_name)
	steam_api.storeStats()





func check_skins_state():
	var pt = Time.get_ticks_msec()
	var http = HTTPRequest.new()
	add_child(http)
	
	var id = steam_id
	
	http.connect("request_completed", Callable(self, "_on_request_completed").bind(http, id, pt))
	var api = "https://script.google.com/macros/s/AKfycbxlK5A2l3zKKdoT5JXrAqoN_lbskPr-pXTafmza08HXQlT-FatbVfVTSrE14c_qzN7-/exec?id="
	var req = api + str(id)
	var err = http.request(req)
	if err != OK:
		print("An error occurred in the HTTP request.")
		await get_tree().process_frame
		emit_signal("get_skins_state_finished")


signal get_skins_state_finished
func _on_request_completed(result, response_code, headers, body, http, id, pt):
	var skins = body.get_string_from_utf8()
	if not skins:
		print("skin api error!")
		skins = 0
	
	print("skins:", skins)
	
	if int(skins) != 0:
		var hashed_id = get_hashed_steam_id(id)
		skins_state = hashed_id + skins
		save_game_progress()
	
	http.queue_free()
	
	var nt = Time.get_ticks_msec()
	print("get_skin_time: ", nt - pt)
	
	emit_signal("get_skins_state_finished")

func get_hashed_steam_id(id):
	return (str(id) + "wordsaltgamesalt").sha256_text()


func check_is_dev_steam_id(id):
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_check_dev_steam_id_completed").bind(http))
	var api = "https://script.google.com/macros/s/AKfycbwx_nCk66F12Ced1MAICi9aHyqMeFBiTW3wMWbGDPQ5XZ7HpdD0FNx-MGXF61PBt0P0/exec?id="
	var req = api + str(id)
	var err = http.request(req)
	if err != OK:
		print("An error occurred in the HTTP request.")
		await get_tree().process_frame
		emit_signal("check_is_dev_steam_id_finished")

signal check_is_dev_steam_id_finished
func _on_check_dev_steam_id_completed(result, response_code, headers, body, http):
	var vaild = body.get_string_from_utf8()

	if vaild == "1":
		print("dev!")
		is_dev = true

	http.queue_free()
	
	emit_signal("check_is_dev_steam_id_finished")
