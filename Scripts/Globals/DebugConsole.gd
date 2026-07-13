extends Control

@onready var expression = Expression.new()

var user_code = ""


func _ready():
	init_map_option()
	pass
	
var debug_mode_count = 0
	
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_F2:
			debug_mode_count += 1
			if debug_mode_count != 3: return
			
			if OS.has_feature("standalone") and not Global.is_dev:
				Global.check_is_dev_steam_id(Global.steam_id)
				await Global.check_is_dev_steam_id_finished
				if not Global.is_dev:
					print("not dev!")
					return
			
			debug_mode_count = 0
			if visible:
				hide_console()
			else:
				show_console()

const TIMER_LIMIT = 1.0
var timer = 0.0

func _process(delta):
	timer += delta
	if timer > TIMER_LIMIT:
		timer = 0.0
		$FPS.text = "fps: " + str(Performance.get_monitor(Performance.TIME_FPS))
		$MEM.text = "mem: " + str(snapped(Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0, 0.01)) + "mb"
		$OBJ.text = "obj: " + str(Performance.get_monitor(Performance.OBJECT_COUNT))
		$NODE.text = "node: " + str(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))

func show_console():
	Input.set_custom_mouse_cursor(null)
	visible = true

func hide_console():
	Input.set_custom_mouse_cursor(load("res://Sprites/tranparent_1x1.png"))
	visible = false


func _on_btn_load_pressed():
	if EscMenu.is_open:
		EscMenu.close_leave_menu()
		EscMenu.close_menu_quick()
	Global.ctrl_z()
	pass

var maps = {
	"第一章": [
		"00_第一章字卡", 
		"01_開頭", 
		"02_長廊", 
		"03_房間", 
		"04_克里皮", 
		"05_立可復關燈", 
		"06_立可復", 
		"07_立可復老人", 
		"08_克里皮結尾", 
		"09_第一章結束", 
		"XX_再生父母之塔"
	], 
	"第二章": [
		"00_第二章字卡", 
		"00_沙漠過場", 
		"01_庫爾堤樹林", 
		"02_初戰無名怪", 
		"03_庫爾堤村口", 
		"04_初戰蛇妖", 
		"05_聖劍寶庫", 
		"06_墜落", 
		"07_史萊姆洞窟", 
		"08_離開洞窟", 
		"09_遇見艾斯", 
		"10_修復村莊", 
		"11_再戰蛇妖", 
		"12_擊敗蛇妖", 
		"13_避難洞窟", 
		"14_第二章結束"
	], 
	"第三章": [
		"00_第三章字卡", 
		"00_木林森過場", 
		"01_開場", 
		"02_1_幻覺", 
		"02_2_腳印", 
		"02_勇者之村", 
		"03_酒館", 
		"04_手套教學", 
		"05_宿命小徑", 
		"09_人骨教堂外", 
		"10_人骨教堂", 
		"11_添譜來堂_開場", 
		"13_添譜來堂_方塊", 
		"14_添譜來堂_拳頭轉場", 
		"15_添譜來堂_拳頭", 
		"16_添譜來堂_尾聲", 
		"17_第三章結束", 
		"99_測試用任意門"
	], 
	"第四章": [
		"00_第四章字卡", 
		"01_修道院_外面", 
		"02_修道院_入口", 
		"05_修道院_離開", 
		"06_前哨_峽谷", 
		"07_前哨_旋轉鎖", 
		"08_前哨_營區", 
		"09_前哨_迷宮", 
		"10_寶庫_旋轉鎖", 
		"11_寶庫_無光穹頂", 
		"12_寶庫_穹頂", 
		"13_寶庫_頭盔教學", 
		"14_寶庫_巨人現身", 
		"15_1_新河岸幻覺_第一關", 
		"15_2_新河岸幻覺_第二關", 
		"15_3_新河岸幻覺_第三關", 
		"15_4_新河岸幻覺_第四關", 
		"15_5_新河岸幻覺_第五關", 
		"15_6_新河岸幻覺_第六關", 
		"15_7_新河岸幻覺_尾聲", 
		"18_河岸幻覺_離開", 
		"19_初戰巨人_現身", 
		"20_初戰巨人_出腳", 
		"21_初戰巨人_出拳", 
		"22_初戰巨人_脫逃", 
		"23_再戰巨人_開場", 
		"24_再戰巨人_戰鬥", 
		"25_再戰巨人_尾聲", 
		"26_第四章結束"
	], 
	"第五章": [
		"00_第五章字卡", 
		"01_魔龍城外_開場", 
		"02_魔龍城外_城堡", 
		"03_魔龍城外_門前", 
		"04_魔龍城外_藍字", 
		"05_蛇妖_蛇型樓梯", 
		"06_蛇妖_一階", 
		"07_蛇妖_二階", 
		"08_蛇妖_二階之二", 
		"09_蛇妖_三階", 
		"10_蛇妖_轉移用空地圖", 
		"11_蛇妖_四階", 
		"12_頂樓密室_大廳", 
		"13_頂樓密室_宴會廳", 
		"14_頂樓密室_露台", 
		"15_頂樓密室_公主房間", 
		"16_畫作長廊_長廊", 
		"17_畫作長廊_畫作一", 
		"18_畫作長廊_畫作二", 
		"19_畫作長廊_畫作三", 
		"20_畫作長廊_完成長廊", 
		"21_畫作長廊_長廊盡頭", 
		"22_議事廳_廳內", 
		"23_議事廳_看巨人轉場", 
		"24_議事廳_說故事", 
		"25_議事廳_巨人說愛", 
		"26_議事廳_踩巨人", 
		"27_天臺_溫室花園", 
		"28_天臺_魔龍登場", 
		"29_天臺_決戰魔龍", 
		"99_測試用任意門"
	], 
	"第六章": [
		"01_偽結局_開發人員名單", 
		"01_1_偽結局_假標題", 
		"02_偽結局_變成人", 
		"03_偽結局_對的人", 
		"04_偽結局_目錄頁", 
		"05_偽結局_尾聲", 
		"06_遊覽車_第五章字卡", 
		"07_遊覽車_議事廳", 
		"08_遊覽車_第二章字卡", 
		"09_遊覽車_避難洞窟", 
		"10_遊覽車_第四章字卡", 
		"11_遊覽車_營區", 
		"12_遊覽車_第一章字卡", 
		"13_遊覽車_立可復", 
		"14_遊覽車_克里皮", 
		"15_遊覽車_第三章字卡", 
		"16_遊覽車_酒館", 
		"17_遊覽車_尾聲", 
		"18_第六章結束"
	], 
	"第七章": [
		"00_第七章字卡", 
		"01_魔龍_登場", 
		"02_魔龍_冰封", 
		"03_魔龍_人民", 
		"04_魔龍_魔物", 
		"05_魔龍_荊棘", 
		"06_魔龍_攀登", 
		"07_魔龍_迷陣", 
		"08_魔龍_裂甲", 
		"09_魔龍_黑洞", 
		"10_內部_墜落", 
		"11_內部_無字", 
		"12_內部_核心", 
		"13_內部_公主分身", 
		"14_內部_送行", 
		"15_終戰", 
		"16_尾聲_天臺", 
		"17_尾聲_花園", 
		"18_尾聲_選擇"
	], 
	"第八章": [
		"心智打字機", 
		"家", 
		"結局", 
		"Credit"
	]
}
func init_map_option():
	$"OptionButton".add_item("--第一章--")
	for map in maps["第一章"]:
		$"OptionButton".add_item(map)
	$"OptionButton".add_item("--第二章--")
	for map in maps["第二章"]:
		$"OptionButton".add_item(map)
	$"OptionButton".add_item("--第三章--")
	for map in maps["第三章"]:
		$"OptionButton".add_item(map)
	$"OptionButton".add_item("--第四章--")
	for map in maps["第四章"]:
		$"OptionButton".add_item(map)
	$"OptionButton".add_item("--第五章--")
	for map in maps["第五章"]:
		$"OptionButton".add_item(map)
	$"OptionButton".add_item("--第六章--")
	for map in maps["第六章"]:
		$"OptionButton".add_item(map)
	$"OptionButton".add_item("--第七章--")
	for map in maps["第七章"]:
		$"OptionButton".add_item(map)
	$"OptionButton".add_item("--第八章--")
	for map in maps["第八章"]:
		$"OptionButton".add_item(map)

func _on_btn_change_map_pressed():
	var map_name = $"OptionButton".get_item_text($"OptionButton".get_selected_id())
	
	if map_name in maps["第一章"]:
		map_name = "第一章/" + map_name
	elif map_name in maps["第二章"]:
		map_name = "第二章/" + map_name
	elif map_name in maps["第三章"]:
		map_name = "第三章/" + map_name
	elif map_name in maps["第四章"]:
		map_name = "第四章/" + map_name
	elif map_name in maps["第五章"]:
		map_name = "第五章/" + map_name
	elif map_name in maps["第六章"]:
		map_name = "第六章/" + map_name
	elif map_name in maps["第七章"]:
		map_name = "第七章/" + map_name
	elif map_name in maps["第八章"]:
		map_name = "第八章/" + map_name
	else:
		return
		
	print(map_name)
	if EscMenu.is_open:
		EscMenu.close_leave_menu()
		EscMenu.close_menu_quick()
	if not $checkbox_dont_clear_save.pressed:
		Global.clear_all_data()
	Global.map_transport(map_name, null, false, "fade", null)


func _on_btn_clear_ach_pressed():
	var all_ach = ["1-1", "1-2", "1-3", "1-4", "2-1", "2-2", "2-3", "2-4", "2-5", "3-1", "3-2", "3-3", "3-4", "3-5", "3-6", "4-1", "4-2", "4-3", "4-4", "4-5", "4-6", "4-7", "4-8", "4-9", "5-1", "5-2", "5-3", "5-4", "5-5", "5-6", "5-7", "6-1", "6-2", "6-3", "6-4", "6-5", "6-6", "6-7", "6-8", "6-9", "7-1", "7-2", "7-3", "7-4", "7-5", "7-6", "8-1", "8-2", "8-3", "8-4", "8-5", "8-6", "8-7", "8-8", "8-9", "8-10", "8-11", "8-12", "8-13", "8-14", "8-15"]
	for ach in all_ach:
		Global.clear_achievement(ach)


func _on_btn_open_user_dir_pressed():
	print(ProjectSettings.globalize_path("user://"))
	OS.shell_open("file://" + ProjectSettings.globalize_path("user://"))
	pass



func _on_btn_edit_var_pressed():
	if $switch_editor.visible:
		$switch_editor.close()
		$variable_editor.close()
	else:
		$switch_editor.open()
		$variable_editor.open()
