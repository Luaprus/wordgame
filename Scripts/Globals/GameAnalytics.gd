
extends Node




""" Procedure -->
1. make an init call
	- check if game is disabled
	- calculate client timestamp offset from server time
2. start a session
3. add a user event (session start) to queue
4. add a business event + some design events to queue
5. submit events in queue
6. add some design events to queue
7. add session_end event to queue
8. submit events in queue
"""

const UUID = preload("res://Scripts/Globals/uuid.gd")


const PLATFORMS = {
	"Windows": "windows", 
	"X11": "linux", 
	"OSX": "mac_osx", 
	"Android": "android", 
	"iOS": "ios", 
	"HTML5": "webgl", 
}



var DEBUG = true
var returned
var response_data
var response_code

var uuid = UUID.v4()

var platform = PLATFORMS[OS.get_name()]

var os_version = PLATFORMS[OS.get_name()] + " "
var sdk_version = "rest api v2"
var device = OS.get_model_name().to_lower()
var manufacturer = OS.get_name().to_lower()


var build_version = "alpha 0.0.1"
var engine_version = "godot {major}.{minor}.{patch}".format(Engine.get_version_info())


var game_key = "5c6bcb5402204249437fb5a7a80a4959"
var secret_key = "16813a12f718bc5c620f56944e1abc3ea13ccbac"


var base_url = "http://sandbox-api.gameanalytics.com"
var url_init = "/v2/" + game_key + "/init"
var url_events = "/v2/" + game_key + "/events"


var use_gzip = false
var verbose_log = false



var state_config = {
	
	
	"client_ts_offset": 0, 
	
	"session_id": uuid, 
	
	"enabled": true, 
	
	"event_queue": []
}
var requests = HTTPClient.new()

func _ready():












	
	



	
	









	
	
	





	





























	
	pass























func add_to_event_queue(event_dict):


	
	
	
	if FileAccess.file_exists("user://event_queue"):
		var f = FileAccess.open("user://event_queue", FileAccess.READ)
		if not f:
			return
		state_config["event_queue"] = f.get_var()
		f.close()
	
	state_config["event_queue"].append(event_dict)
	
	
	var f = FileAccess.open("user://event_queue", FileAccess.WRITE)
	if not f:
		return
	f.store_var(state_config["event_queue"])
	f.close()


func request_init_2():
	
	if platform == "android":
		var output = []
		OS.execute("getprop", ["ro.build.version.release"], output, true)
		os_version = platform + " " + output[0].strip_edges()
	elif platform == "windows":
		manufacturer = "microsoft"
		var output = []
		
		OS.execute("cmd", ["/c", "ver"], output, true)
		if not output.is_empty():
			var rg = RegEx.new()
			
			rg.compile("(\\d+\\.\\d+\\.\\d+)")
			var result = rg.search(output[0])
			if result:
				os_version = result.get_string(1).strip_edges()
		os_version = platform + " " + os_version

	var init_payload = {
		"platform": platform, 
		"os_version": os_version, 
		"sdk_version": sdk_version
	}
	
	
	generate_new_session_id()
	
	
	url_init = "/v2/" + game_key + "/init"
	
	
	var init_payload_json = JSON.new().stringify(init_payload)

	var headers = [
		"Authorization: " + Marshalls.raw_to_base64(hmac_sha256(init_payload_json, secret_key)), 
		"Content-Type: application/json"]
	
	print(Marshalls.raw_to_base64(hmac_sha256(init_payload_json, secret_key)))
	
	
	var response_dict
	var status_code
		
	if DEBUG:
		print(base_url)
		print(url_init)
		print(init_payload_json)
		print(Marshalls.raw_to_base64(hmac_sha256(init_payload_json, secret_key)))
	
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_init_request_completed"))
	http.request(base_url + url_init, headers, HTTPClient.METHOD_POST, init_payload_json)
	await http.request_completed
	http.queue_free()

func _on_init_request_completed(result, response_code, headers, body):
	print(response_code)
	var test_json_conv = JSON.new()
	test_json_conv.parse(body.get_string_from_utf8())
	var json = test_json_conv.get_data()
	print(json)


func submit_events_2():
	
	
	url_events = "/v2/" + game_key + "/events"
	var event_list_json = JSON.new().stringify(state_config["event_queue"])

	
	if use_gzip:
		event_list_json = get_gzip_string(event_list_json)

	
	var headers = [
		"Authorization: " + Marshalls.raw_to_base64(hmac_sha256(event_list_json, secret_key)), 
		"Content-Type: application/json"]

	
	if use_gzip:
		headers.append("Content-Encoding: gzip")
		
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_submit_request_completed"))
	http.request(base_url + url_events, headers, HTTPClient.METHOD_POST, event_list_json)
	await http.request_completed
	http.queue_free()

func _on_submit_request_completed(result, response_code, headers, body):
	print(response_code)
	var test_json_conv = JSON.new()
	test_json_conv.parse(body.get_string_from_utf8())
	var json = test_json_conv.get_data()
	print(json)

	if response_code == 400:
		post_to_log("Submit events failed due to BAD_REQUEST.")
		state_config["event_queue"] = []
		DirAccess.remove_absolute("user://event_queue")
	elif response_code != 200:
		post_to_log("Submit events request did not succeed! Perhaps offline.. ")
	if response_code == 200:
		post_to_log("Events submitted !")
		
		
		state_config["event_queue"] = []
		DirAccess.remove_absolute("user://event_queue")
	else:
		post_to_log("Event submission FAILED!")



func request_init():
	
	if platform == "android":
		var output = []
		OS.execute("getprop", ["ro.build.version.release"], output, true)
		os_version = platform + " " + output[0].strip_edges()
	elif platform == "windows":
		manufacturer = "microsoft"
		var output = []
		
		OS.execute("cmd", ["/c", "ver"], output, true)
		if not output.is_empty():
			var rg = RegEx.new()
			
			rg.compile("(\\d+\\.\\d+\\.\\d+)")
			var result = rg.search(output[0])
			if result:
				os_version = result.get_string(1).strip_edges()
		os_version = platform + " " + os_version

	var init_payload = {
		"platform": platform, 
		"os_version": os_version, 
		"sdk_version": sdk_version
	}
	
	
	generate_new_session_id()
	
	
	url_init = "/v2/" + game_key + "/init"
	
	
	var init_payload_json = JSON.new().stringify(init_payload)

	var headers = [
		"Authorization: " + Marshalls.raw_to_base64(hmac_sha256(init_payload_json, secret_key)), 
		"Content-Type: application/json"]
	
	print(Marshalls.raw_to_base64(hmac_sha256(init_payload_json, secret_key)))
	
	
	var response_dict
	var status_code
		
	if DEBUG:
		print(base_url)
		print(url_init)
		print(init_payload_json)
		print(Marshalls.raw_to_base64(hmac_sha256(init_payload_json, secret_key)))
		
	
	var err = requests.connect_to_host(base_url, 80)

		
	while requests.get_status() == HTTPClient.STATUS_CONNECTING or requests.get_status() == HTTPClient.STATUS_RESOLVING:
		requests.poll()
		print("Connecting..")
		await get_tree().create_timer(0.5).timeout


	
	
	
	var init_response = requests.request(HTTPClient.METHOD_POST, url_init, headers, init_payload_json)



	while requests.get_status() == HTTPClient.STATUS_REQUESTING:
		
		requests.poll()
		print("Requesting..")
		await get_tree().create_timer(0.5).timeout

	
	if requests.has_response():
		
		headers = requests.get_response_headers_as_dictionary()
		print("code: ", requests.get_response_code())
		print("**headers:\\n", headers)

		

		if requests.is_response_chunked():
			
			print("Response is Chunked!")
		else:
			
			var bl = requests.get_response_body_length()
			print("Response Length: ", bl)

		

		var rb = PackedByteArray()

		while requests.get_status() == HTTPClient.STATUS_BODY:
			
			requests.poll()
			var chunk = requests.read_response_body_chunk()
			if chunk.size() == 0:
				

				await get_tree().create_timer(1.0).timeout
			else:
				rb = rb + chunk

		

		print("bytes got: ", rb.size())
		var text = rb.get_string_from_ascii()
		print("Text: ", text)
		
	
	status_code = requests.get_response_code()
	
	response_dict = JSON.new().stringify(init_response)












	
	var response_string = (status_code)

	if status_code == 401:
		post_to_log("Submit events failed due to UNAUTHORIZED.")
		post_to_log("Please verify your Authorization code is working correctly and that your are using valid game keys.")
		

	if status_code != 200:
		post_to_log("Init request did not return 200!")
		post_to_log(response_string)




		

	







	
	return status_code



func submit_events():
	
	
	url_events = "/v2/" + game_key + "/events"
	var event_list_json = JSON.new().stringify(state_config["event_queue"])








	
	if use_gzip:
		event_list_json = get_gzip_string(event_list_json)

	
	var headers = [
		"Authorization: " + Marshalls.raw_to_base64(hmac_sha256(event_list_json, secret_key)), 
		"Content-Type: application/json"]

	
	if use_gzip:
		headers.append("Content-Encoding: gzip")

	var err = requests.connect_to_host(base_url, 80)

		
	while requests.get_status() == HTTPClient.STATUS_CONNECTING or requests.get_status() == HTTPClient.STATUS_RESOLVING:
		requests.poll()
		print("Connecting..")
		OS.delay_msec(500)


	
	var events_response = requests.request(HTTPClient.METHOD_POST, url_events, headers, event_list_json)




	while requests.get_status() == HTTPClient.STATUS_REQUESTING:
		
		requests.poll()
		print("Requesting..")
		OS.delay_msec(500)
	
	if requests.has_response():
		
		headers = requests.get_response_headers_as_dictionary()
		print("code: ", requests.get_response_code())
		print("**headers:\\n", headers)

		

		if requests.is_response_chunked():
			
			print("Response is Chunked!")
		else:
			
			var bl = requests.get_response_body_length()
			print("Response Length: ", bl)

		

		var rb = PackedByteArray()

		while requests.get_status() == HTTPClient.STATUS_BODY:
			
			requests.poll()
			var chunk = requests.read_response_body_chunk()
			if chunk.size() == 0:
				
				OS.delay_usec(1000)
			else:
				rb = rb + chunk

		

		print("bytes got: ", rb.size())
		var text = rb.get_string_from_ascii()
		print("Text: ", text)

	
	var status_code = requests.get_response_code()
	
	



	

	
	
	var status_code_string = str(status_code)
	if status_code == 400:
		post_to_log(status_code_string)
		post_to_log("Submit events failed due to BAD_REQUEST.")
		
		
		state_config["event_queue"] = []
		DirAccess.remove_absolute("user://event_queue")









	elif status_code != 200:
		post_to_log(status_code_string)
		post_to_log("Submit events request did not succeed! Perhaps offline.. ")







	if status_code == 200:
		post_to_log("Events submitted !")
		
		
		state_config["event_queue"] = []
		DirAccess.remove_absolute("user://event_queue")

	else:
		post_to_log("Event submission FAILED!")

	return status_code





func generate_new_session_id():
	state_config["session_id"] = uuid
	print_verbose("Session Id: " + state_config["session_id"])


func update_client_ts_offset(server_ts):
	
	
	var now_ts = Time.get_unix_time_from_system()

	var client_ts = now_ts
	var offset = client_ts - server_ts

	

	
	if offset < 10:
		state_config["client_ts_offset"] = 0
	else:
		state_config["client_ts_offset"] = offset
	print_verbose("Client TS offset calculated to: " + str(offset))







func get_test_business_event_dict():
	var event_dict = {
		"category": "business", 
		"amount": 999, 
		"currency": "USD", 
		"event_id": "Weapon:SwordOfFire", 
		"cart_type": "MainMenuShop", 
		"transaction_num": 1, 
		"receipt_info": {"receipt": "xyz", "store": "apple"}
	}
	return event_dict


func get_test_user_event():
	var event_dict = {
		"category": "user"
	}
	return event_dict


func get_test_session_end_event(length_in_seconds):
	var event_dict = {
		"category": "session_end", 
		"length": length_in_seconds
	}
	return event_dict


func get_test_design_event(event_id, value):
	var event_dict = {
		"category": "design", 
		"event_id": event_id, 
		"value": value
	}
	merge_dir(event_dict, annotate_event_with_default_values())
	


	return event_dict
	
static func merge_dir(target, patch):
	for key in patch:
		target[key] = patch[key]

static func merge_dir2(target, patch):
	for key in patch:
		if target.has(key):
			var tv = target[key]
			if typeof(tv) == TYPE_DICTIONARY:
				merge_dir(tv, patch[key])
			else:
				target[key] = patch[key]
		else:
			target[key] = patch[key]
			
func get_gzip_string(string_for_gzip):
	var f = FileAccess.open_compressed("user://gzip", FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
	if not f:
		return ""

	f.store_string(string_for_gzip)
	f.close()

	f = FileAccess.open("user://gzip", FileAccess.READ)
	if not f:
		return ""
	
	
	var enc_text = f.get_as_text()
	
	f.close()






	return enc_text
	pass




func annotate_event_with_default_values():
	var now_ts = Time.get_datetime_dict_from_system()
	
	
	
	var client_ts = Time.get_unix_time_from_system()

	
	
	var idfa = OS.get_unique_id().to_lower()
	var idfv = "AEBE52E7-03EE-455A-B3C4-E57283966239"

	var default_annotations = {
		"v": 2, 
		"user_id": idfa, 
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		"client_ts": client_ts, 
		"sdk_version": sdk_version, 
		"os_version": os_version, 
		"manufacturer": manufacturer, 
		"device": device, 
		"platform": platform, 
		"session_id": state_config["session_id"], 
		"build": build_version, 
		"session_num": 1, 
		"engine_version": engine_version, 
		
		
	}
	
	
	return default_annotations

func print_verbose(message):
	print(message)
	if verbose_log:
		post_to_log(message)

func post_to_log(message):
	print(message)
	pass


func hmac_sha256(message, key):
	var x = 0
	var k
	
	if key.length() <= 64:
		k = key.to_utf8_buffer()

	
	if key.length() > 64:
		k = key.sha256_buffer()

	
	while k.size() < 64:
		k.append(convert_hex_to_dec("00"))

	var i = "".to_utf8_buffer()
	var o = "".to_utf8_buffer()
	var m = message.to_utf8_buffer()
	while x < 64:
		o.append(k[x] ^ 92)
		i.append(k[x] ^ 54)
		x += 1
		
	var inner = i + m
	
	var s = FileAccess.open("user://temp", FileAccess.WRITE)
	if not s:
		return ""
	s.store_buffer(inner)
	s.close()
	var z = FileAccess.get_sha256("user://temp")
	
	var outer = "".to_utf8_buffer()
	
	x = 0
	while x < 64:
		outer.append(convert_hex_to_dec(z.substr(x, 2)))
		x += 2
	
	outer = o + outer
	
	s = FileAccess.open("user://temp", FileAccess.WRITE)
	if not s:
		return ""
	s.store_buffer(outer)
	s.close()
	
	z = FileAccess.get_sha256("user://temp")
	
	outer = "".to_utf8_buffer()
	
	x = 0
	while x < 64:
		outer.append(convert_hex_to_dec(z.substr(x, 2)))
		x += 2
	
	var mm = outer
	return outer
	
func convert_hex_to_dec(h):
	var c = "0123456789ABCDEF"
	
	h = h.to_upper()
	
	var r = h.right(1)
	var l = h.left(1)
	
	var b0 = c.find(r)
	var b1 = c.find(l) * 16
	
	var x = b1 + b0
	return x
