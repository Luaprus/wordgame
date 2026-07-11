@tool
extends Node

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS


func str_to_var(string):
	
	
	
	
	if string.find("s:") != - 1:
		return {"type": "switch", "value": string.split("s:")[1]}
	if string.find("self:") != - 1:
		return {"type": "self_switch", "value": string.split("self:")[1]}
	if string.find("v:") != - 1:
		return {"type": "variable", "value": string.split("v:")[1]}
	
	if string == "true":
		return {"type": "boolean", "value": true}
	if string == "false":
		return {"type": "boolean", "value": false}
		
	var regex = RegEx.new()
	regex.compile("^[0-9]+([\\,\\.][0-9]+)?$")
	var result = regex.search(string)
	if result:
		return {"type": "number", "value": int(string)}
	else:
		return {"type": "string", "value": string}

func get_value_from_str(string):
	if typeof(string) == TYPE_BOOL:
		return string
	var v = str_to_var(str(string))
	if v.type == "switch":
		return Global.get_game_switch(v.value)
	if v.type == "variable":
		return Global.get_game_variable(v.value)
	else:
		return v.value

func is_str_condition_vaild(str_condition, event_name):
	
	
	var conditions = split_string_with_multiple_delimiters(str_condition, ["&&", "||"])
	var logical_operators = ["||"] + get_logical_operators_from_string(str_condition)

	var is_vaild = false
	for index in range(conditions.size()):
		var condition = str_to_condition(conditions[index])

		if condition[0].type == "switch":
			condition[0].value = Global.get_game_switch(condition[0].value)
		if condition[0].type == "self_switch":
			condition[0].value = Global.get_game_self_switch(event_name, condition[0].value)
		if condition[0].type == "variable":
			condition[0].value = Global.get_game_variable(condition[0].value)
			
		if condition[2].type == "switch":
			condition[2].value = Global.get_game_switch(condition[2].value)
		if condition[2].type == "self_switch":
			condition[2].value = Global.get_game_self_switch(event_name, condition[2].value)
		if condition[2].type == "variable":
			condition[2].value = Global.get_game_variable(condition[2].value)

		var result = compare(condition[0].value, condition[1], condition[2].value)

		match logical_operators[index]:
			"&&":
				is_vaild = is_vaild and result
			"||":
				is_vaild = is_vaild or result



	return is_vaild

	
func str_to_condition(string):
	
	
	

	for operator in ["==", "!=", ">=", "<=", ">", "<"]:
		if string.find(operator) != - 1:
			var c1 = string.split(operator)[0].strip_edges()
			var c2 = string.split(operator)[1].strip_edges()
			
			c1 = str_to_var(c1)
			c2 = str_to_var(c2)
			
			return [c1, operator, c2]
			


func compare(c1, op, c2):
	if typeof(c1) == TYPE_STRING or typeof(c2) == TYPE_STRING:
		c1 = str(c1)
		c2 = str(c2)
	var result
	match op:
		"==":
			result = c1 == c2
		"!=":
			result = c1 != c2
		"<":
			result = c1 < c2
		"<=":
			result = c1 <= c2
		">":
			result = c1 > c2
		">=":
			result = c1 >= c2
	return result
	

func split_string_with_multiple_delimiters(string, delimiters):
	var result = []
	var delimiter = delimiters[0]
	var poped_delimiters = delimiters.slice(1, delimiters.size())
	var splited_array = string.split(delimiter)

	if poped_delimiters.size() > 0:
		for splited_str in splited_array:
			result += split_string_with_multiple_delimiters(splited_str, poped_delimiters)
	else:
		result += Array(splited_array)
	
	return result

func get_logical_operators_from_string(string):
	var ops = []

	var regex = RegEx.new()
	regex.compile("(&{2})|(\\|{2})")
	var result_array = regex.search_all(string)
	if result_array:
		for result in result_array:
			ops.append(result.get_string())

	return ops

func flatten_array(array):
	var flatted_array = []
	if typeof(array) == TYPE_ARRAY:
		for child in array:
			flatted_array += flatten_array(child)
		return flatted_array
	else:
		return [array]
		
		




func get_node_property(from: Node, path: NodePath):

	var node_path = get_as_node_path(path)
	var property_path = NodePath(str(path.get_concatenated_subnames())).get_as_property_path()
	return from.get_node(node_path).get_indexed(property_path)

func get_as_node_path(path: NodePath) -> NodePath:

	var node_path = str(path)
	var property_path = str(path.get_concatenated_subnames())
	node_path.erase(str(path).length() - property_path.length() - 1, property_path.length() + 1)
	return NodePath(node_path)


func direction_to_vector(d):
	var x = 1 if d == 6 else - 1 if d == 4 else 0
	var y = 1 if d == 2 else - 1 if d == 8 else 0
	return Vector2(x, y)

func vector_to_direction(vector):
	var d = 0
	
	if vector == Vector2.ZERO:
		return 0
	
	var is_h_first = abs(vector.x) >= abs(vector.y)
	
	if vector.y > 0:
		d = 2
	else:
		d = 8
		
	if is_h_first:
		if vector.x > 0:
			d = 6
		else:
			d = 4
	
	return d

func print_map_text(mode = "horizontal"):
	var map_text_array = Global.game_map.get_map_text_array(mode)
	
	var map_text = ""
	for m_row in map_text_array:
		for m_ceil in m_row:
			if m_ceil != null:
				map_text += m_ceil
			else:
				map_text += "＿"
		map_text += "\n"
	print(map_text)

func _unhandled_input(event):
	return
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_F3:
			print_map_text("horizontal")
		if event.pressed and event.keycode == KEY_F4:
			print_map_text("vertical")
		if event.pressed and event.keycode == KEY_F5:
			print(Global.game_switches)


func num_to_chinese_word(num):
	var str_num = str(num)
	var length = str_num.length()
	if length > 2:
		return "九十九"
	if length == 1:
		var word1 = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"][int(str_num[0])]
		return word1
	if length == 2:
		var word1 = ["", "", "二", "三", "四", "五", "六", "七", "八", "九"][int(str_num[0])]
		var word2 = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"][int(str_num[1])]
		return word1 + "十" + word2
	
































func halfwidth_to_fullwidth(input):
	var half = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!\"#$%&()*+,-./:;<=>?@[]^_`{|}~"
	var full = "０１２３４５６７８９ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ！゛＃＄％＆（）＊＋、ー。／：；〈＝〉？＠［］＾＿‘｛｜｝～"
	var output = ""
	for t in input:
		if half.find(t) == - 1:
			output += t
		else:
			output += full[half.find(t)]
	return output
