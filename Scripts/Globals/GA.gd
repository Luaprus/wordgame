extends Node

var GameAnalytics = load("res://Scripts/Globals/GameAnalytics.gd").new()

var disable = true







var section_data = {
	"spend_time": 0, 
	"undo_count": 0, 
	"interactive_count": 0, 
	"backspace_attempt_count": 0, 
	"push_attempt_count": 0, 
	"pull_attempt_count": 0, 
	"hint_count": 0, 
	"death_count": 0, 
	"leave_count": 0
}

func _ready():
	if disable:
		return
	init()
	load_ga_data()
	pass

func init():
	add_child(GameAnalytics)
	
	GameAnalytics.game_key = "3ec2c9f00877917700962c65ff85a77c"
	GameAnalytics.secret_key = "30a8607f1e4627eea58f229fdbcfef05912ccc44"
	GameAnalytics.base_url = "http://api.gameanalytics.com"
	
	var init_response = GameAnalytics.request_init_2()








func save_ga_data():
	if disable:
		return
	var save_file = FileAccess.open("user://ga_data.wg", FileAccess.WRITE)
	if not save_file:
		return
	save_file.store_line(JSON.new().stringify(section_data))
	save_file.close()
	
	print("ga data saved")
	
	
func load_ga_data():
	if disable:
		return
	
	if not FileAccess.file_exists("user://ga_data.wg"):
		print("no ga data")
		return false
	
	var save_file = FileAccess.open("user://ga_data.wg", FileAccess.READ)
	if not save_file:
		return false
	var test_json_conv = JSON.new()
	test_json_conv.parse(save_file.get_line())
	var save_data = test_json_conv.get_data()
	save_file.close()
	
	for key in save_data:
		if section_data.has(key):
			section_data[key] = int(save_data[key])
	
	print(section_data)
	
	print("ga data loaded")
	
	return true



func clear_data():
	for key in section_data:
		section_data[key] = 0



func submit():
	if disable:
		return
	
	for key in section_data:
		GameAnalytics.add_to_event_queue(GameAnalytics.get_test_design_event("section:" + Global.now_game_section + ":" + key, section_data[key]))
	GameAnalytics.submit_events_2()

	

	
