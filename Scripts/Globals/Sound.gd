extends Node

signal is_ready

const PositionSEResourse = preload("res://Scenes/SoundEffects/PositionSE.tscn")

var BGM
var current_bgm_path = ""

var BGM_layering
var current_bgm_layering_path = ""

var ENV
var current_env_path = ""

var SE_layer


var bgm_volume_level = 3
var se_volume_level = 3

func set_bgm_volume(level):
	bgm_volume_level = level
	

	
	var volume
	match int(bgm_volume_level):
		0:
			volume = linear_to_db(0)
		1:
			volume = linear_to_db(0.1)
		2:
			volume = linear_to_db(0.2)
		3:
			volume = linear_to_db(0.3)
		4:
			volume = linear_to_db(0.5)
		5:
			volume = linear_to_db(0.7)

	
	var bus_idx = AudioServer.get_bus_index("BGM")
	AudioServer.set_bus_volume_db(bus_idx, volume)

func set_se_volume(level):
	se_volume_level = level
	
	var volume
	match int(se_volume_level):
		0:
			volume = linear_to_db(0)
		1:
			volume = linear_to_db(0.2)
		2:
			volume = linear_to_db(0.4)
		3:
			volume = linear_to_db(0.6)
		4:
			volume = linear_to_db(0.8)
		5:
			volume = linear_to_db(1)
	
	var bus_idx = AudioServer.get_bus_index("SE")
	AudioServer.set_bus_volume_db(bus_idx, volume)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	BGM = AudioStreamPlayer.new()
	BGM.bus = "BGM"
	BGM.name = "BGM"
	set_bgm_volume(bgm_volume_level)
	
	add_child(BGM)
	
	BGM_layering = AudioStreamPlayer.new()
	BGM_layering.bus = "BGM"
	BGM_layering.name = "BGM_layering"
	BGM.add_child(BGM_layering)
	
	ENV = AudioStreamPlayer.new()
	ENV.bus = "BGM"
	ENV.name = "ENV"
	BGM.add_child(ENV)
	
	SE_layer = Node2D.new()
	SE_layer.position = Vector2(960, 540)
	add_child(SE_layer)
	set_se_volume(se_volume_level)
	
	print("Sound ready")
	emit_signal("is_ready")

func se_center_follow_camera(pos):
	SE_layer.position = pos

func play_se(path, db = 0, pan = 0, pitch = 1):
	if not ResourceLoader.exists(path): return
	
	var new_se = AudioStreamPlayer2D.new()
	SE_layer.add_child(new_se)

	new_se.position.y = 0
	new_se.position.x = 960 * pan
	
	new_se.stream = load(path)
	new_se.volume_db = db
	new_se.pitch_scale = pitch
	new_se.bus = "SE"
	new_se.play()
	new_se.finished.connect(new_se.queue_free)


func play_se_with_position(path, target, loop = false, max_dist = 800, db = 0):
	if not ResourceLoader.exists(path): return
	
	var p_SE = PositionSEResourse.instantiate()
	target.add_child(p_SE)
	p_SE.event = target
	p_SE.player = Global.game_map.player
	p_SE.stream = load(path)
	p_SE.max_distance = max_dist
	p_SE.db = db
	if loop:
		p_SE.is_loop = true
	p_SE.play()
	
func stop_bgm():
	BGM.stop()
	BGM_layering.stop()
	current_bgm_path = null
	current_bgm_layering_path = null
	
signal finished
func play_bgm(path, db = 0, pan = 0, layering_path = null):
	print("play_bgm: ", path)
	if not BGM:
		return
		
	var is_same_bgm = (current_bgm_path == path)
	var is_same_bgm_layering = (current_bgm_layering_path == layering_path)
	
	if not is_same_bgm:
		BGM.stream = load(path)
		BGM.volume_db = db
		BGM.play()
	
	current_bgm_path = path
	
	
	if not is_same_bgm_layering:
		if layering_path != null:
			BGM_layering.stream = load(layering_path)
			BGM_layering.volume_db = db
			BGM_layering.play(BGM.get_playback_position())
			current_bgm_layering_path = layering_path
			
			if is_same_bgm:
				fade_bgm_layering(1, 0, 1)
		else:
			if current_bgm_layering_path:
				fade_bgm_layering(1, null, 0)
				current_bgm_layering_path = null
	
	print("bgm_vol:", BGM.volume_db)
	print("play_bgm_succese: ", path)
	
func interpolate_bgm_volumn(v):
	BGM.volume_db = linear_to_db(v)

func interpolate_bgm_layering_volumn(v):
	BGM_layering.volume_db = linear_to_db(v)

func interpolate_env_volumn(v):
	ENV.volume_db = linear_to_db(v)

func fade_out_and_stop_bgm(time):
	var tween = fade_bgm(time, null, 0)
	tween.finished.connect(stop_bgm)

func fade_out_bgm(time):
	fade_bgm(time, null, 0)
	
func fade_in_bgm(time, to = 1):
	fade_bgm(time, 0, to)
	
func fade_bgm(time, from = null, to = null):
	print("fade_bgm")
	var from_l = from
	var to_l = to
	if from == null:
		from = db_to_linear(BGM.volume_db)
		from_l = db_to_linear(BGM_layering.volume_db)
	if to == null:
		to = db_to_linear(BGM.volume_db)
		to_l = db_to_linear(BGM_layering.volume_db)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_method(Callable(self, "interpolate_bgm_volumn"), from, to, time)
	tween.tween_method(Callable(self, "interpolate_bgm_layering_volumn"), from_l, to_l, time)
	tween.finished.connect(func(): emit_signal("finished"))
	return tween
	
func fade_bgm_layering(time, from = null, to = null):
	print("fade_bgm_layering")
	if from == null:
		from = db_to_linear(BGM_layering.volume_db)
	if to == null:
		to = db_to_linear(BGM_layering.volume_db)
	
	var tween = create_tween()
	tween.tween_method(Callable(self, "interpolate_bgm_layering_volumn"), from, to, time)
	tween.finished.connect(func(): emit_signal("finished"))
	return tween

func fade_bgm_esc_menu(is_fade_in = true):
	print("fade_bgm_esc_menu")
	var db = 0
	if is_fade_in:
		db = - 5
		
	var bus_idx = AudioServer.get_bus_index("BGM")
	var low_pass = AudioServer.get_bus_effect(bus_idx, 0)
	
	var low_pass_start = 1000
	var low_pass_end = 4000
	if is_fade_in:
		low_pass_start = 4000
		low_pass_end = 1000
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_method(Callable(self, "interpolate_bgm_volumn"), db_to_linear(BGM.volume_db), db_to_linear(db), 1)
	tween.tween_method(Callable(self, "interpolate_bgm_layering_volumn"), db_to_linear(BGM_layering.volume_db), db_to_linear(db), 1)
	tween.tween_method(Callable(self, "interpolate_env_volumn"), db_to_linear(ENV.volume_db), db_to_linear(db), 1)
	tween.tween_property(low_pass, "cutoff_hz", low_pass_end, 1).from(low_pass_start)
	tween.finished.connect(func():
		if not is_fade_in:
			low_pass.cutoff_hz = 10000
		emit_signal("finished")
	)
	return tween
	
	
func crossfade_bgm(path, time = 1.0, is_sync = false):
	if not current_bgm_path:
		play_bgm(path)
		return
	
	current_bgm_path = path
	
	var BGM_crossfade = AudioStreamPlayer.new()
	BGM_crossfade.bus = "BGM"
	BGM_crossfade.name = "BGM_crossfade"
	add_child(BGM_crossfade)
	
	BGM_crossfade.stream = load(path)
	BGM_crossfade.volume_db = linear_to_db(0)
	if is_sync:
		BGM_crossfade.play(BGM.get_playback_position())
	else:
		BGM_crossfade.play()
	
	var tween = create_tween()
	tween.tween_method(Callable(self, "interpolate_crossfade"), 0.0, 1.0, time)
	tween.finished.connect(func():
		BGM.stop()
		BGM.stream = BGM_crossfade.stream
		BGM.play(BGM_crossfade.get_playback_position())
		BGM.volume_db = BGM_crossfade.volume_db
		BGM_crossfade.queue_free()
	)
	return tween
	
func interpolate_crossfade(v):
	BGM.volume_db = linear_to_db(1 - v)
	get_node("BGM_crossfade").volume_db = linear_to_db(v)
	
func swap_bgm(path):
	var now = BGM.get_playback_position()
	BGM.stream = load(path)
	BGM.play(now)
	current_bgm_path = path
	
func set_low_pass(hz):
	var bus_idx = AudioServer.get_bus_index("BGM")
	var low_pass = AudioServer.get_bus_effect(bus_idx, 0)
	low_pass.cutoff_hz = hz

func fade_low_pass():
	var bus_idx = AudioServer.get_bus_index("BGM")
	var low_pass = AudioServer.get_bus_effect(bus_idx, 0)
	var tween = create_tween()
	tween.tween_property(low_pass, "cutoff_hz", 4000, 1)
	tween.finished.connect(func(): low_pass.cutoff_hz = 10000)
	return tween
	
func play_typing_se(char_type = null):
	var r
	var db = 0
	var pan = 0
	match char_type:
		"princess":
			r = ["A", "B", "C", "D", "F", "G", "H"][randi() % 7]
			Sound.play_se("res://Sounds/se/typewriter/SE_S_15_type_princess_" + r + ".wav", db, pan)
		"dragon":
			r = ["A", "B", "C", "D"][randi() % 4]
			Sound.play_se("res://Sounds/se/typewriter/SE_S_16_type_dragon_" + r + ".wav", db, pan)
		"snake":
			r = ["A", "B", "C"][randi() % 3]
			Sound.play_se("res://Sounds/se/typewriter/type_snake_" + r + ".wav", db, pan)
		"poet":
			r = ["A", "B", "C", "D"][randi() % 4]
			Sound.play_se("res://Sounds/se/typewriter/SE_S_14_type_poet_" + r + ".wav", db, pan)
		"giant_l":
			Sound.play_se("res://Sounds/se/typewriter/SE_S_16_type_dragon_A.wav", db, pan, 1.3)
		"giant_r":
			Sound.play_se("res://Sounds/se/typewriter/SE_S_16_type_dragon_A.wav", db, pan, 0.6)
		_:
			r = randi() % 4 + 1
			Sound.play_se("res://Sounds/se/typer_key_" + str(r) + ".wav", - 6, 0)
	
func set_reverb(enable = false, mix_rate = 0.12):
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_effect_enabled(bus_idx, 0, enable)
	var effect = AudioServer.get_bus_effect(bus_idx, 0)
	effect.wet = mix_rate
	

func stop_env():
	ENV.stop()
	current_env_path = null

func play_env(path, db = 0, pan = 0):
	print("play_env: ", path)
	if not ENV:
		return
	
	if current_env_path == path:
		print("env is same")
		return
	
	ENV.stream = load(path)
	ENV.volume_db = db
	ENV.play()
	
	current_env_path = path
	
	print("play_env_succese: ", path)
	
func fade_out_and_stop_env(time):
	var tween = fade_env(time, null, 0)
	tween.finished.connect(stop_env)

func fade_out_env(time):
	fade_env(time, null, 0)
	
func fade_in_env(time, to = 1):
	fade_env(time, 0, to)
	
func fade_env(time, from = null, to = null):
	print("fade_env")
	if from == null:
		from = db_to_linear(ENV.volume_db)
	if to == null:
		to = db_to_linear(ENV.volume_db)
	
	var tween = create_tween()
	tween.tween_method(Callable(self, "interpolate_env_volumn"), from, to, time)
	tween.finished.connect(func(): emit_signal("finished"))
	return tween

func crossfade_env(path, time = 1.0, is_sync = false):
	if not current_env_path:
		play_env(path)
		return
	
	current_env_path = path
	
	var ENV_crossfade = AudioStreamPlayer.new()
	ENV_crossfade.bus = "BGM"
	ENV_crossfade.name = "ENV_crossfade"
	add_child(ENV_crossfade)
	
	ENV_crossfade.stream = load(path)
	ENV_crossfade.volume_db = linear_to_db(0)
	if is_sync:
		ENV_crossfade.play(ENV.get_playback_position())
	else:
		ENV_crossfade.play()
	
	var tween = create_tween()
	tween.tween_method(Callable(self, "interpolate_crossfade_env"), 0.0, 1.0, time)
	tween.finished.connect(func():
		ENV.stop()
		ENV.stream = ENV_crossfade.stream
		ENV.play(ENV_crossfade.get_playback_position())
		ENV.volume_db = ENV_crossfade.volume_db
		ENV_crossfade.queue_free()
	)
	return tween
	
func interpolate_crossfade_env(v):
	ENV.volume_db = linear_to_db(1 - v)
	get_node("ENV_crossfade").volume_db = linear_to_db(v)
