extends Node2D

enum CHAR_TYPES{PLAYER, EVENT}
@export var type: CHAR_TYPES = CHAR_TYPES.EVENT


@export var move_speed = 1 # (int, "Slow", "Normal", "Fast", "Very Fast")


@export var now_pos = Vector2(): set = on_now_pos_set

var moving_pos = Vector2()
var direction = 2

var through = false

var has_move_cooldown = true

var cooldown_count = 40
var max_cooldown_count = - 1

@export var can_push: bool
@export var can_delete: bool
@export var can_split: bool

@export var opacity = 1: set = on_opacity_set

func on_opacity_set(value):
	opacity = value
	self.modulate = Color(1, 1, 1, value)

func on_now_pos_set(value):
	var prev_pos = now_pos
	now_pos = value




var move_route = []
var move_route_index = 0
var wait_count = 0
var is_move_route_forcing = false
var is_movement_pause = false

var move_zone = []
var move_dead_zone = []

var can_pass_group = ""

var original_move_route
var original_move_route_index = 0


var locked = false


var can_move_enabled = true


var user_data = {}

var tileMap

func _ready():
	if Engine.is_editor_hint():
		return
		

	
	if is_inside_tree():
		_on_tree_entered()
	else:
		connect("tree_entered", Callable(self, "_on_tree_entered"))
		
		





func _on_tree_entered():
	tileMap = get_tree().get_nodes_in_group("map")[0]


	var x = round(global_position.x / 60.0)
	var y = round(global_position.y / 60.0)
	self.now_pos = Vector2(x, y)
	
	moving_pos = now_pos
	



	

	

func transport_to(pos):
	global_position = tileMap.map_to_local(pos)
	var x = round(global_position.x / 60.0)
	var y = round(global_position.y / 60.0)
	self.now_pos = Vector2(x, y)
	
	moving_pos = now_pos
	
func transport_add(pos):
	transport_to(now_pos + pos)
		
func fade_from_to(f_opacity, t_opacity, time):
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "opacity", t_opacity, time).from(f_opacity).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	return fade_tween
	
func fade_to(new_opacity, time):
	if time == 0:
		self.opacity = new_opacity

		return
	
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "opacity", new_opacity, time).from(self.opacity).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	return fade_tween

func lock():
	locked = true

func unlock():
	locked = false

func set_can_move(_can_move):
	can_move_enabled = _can_move

func is_moving():
	return now_pos != moving_pos
	
func is_stoping():
	return not is_moving() and not is_jumping() and not is_cooldowning()
	
func is_at_pos(pos):
	return now_pos == pos
	
func is_cooldowning():
	if is_in_group("no_cooldown"):
		return false
		


	return cooldown_count > 0

var is_cooldown_by_moving = false
func start_cooldown():
	cooldown_count += (60 - move_speed * 5) / 13
	if max_cooldown_count > - 1:
		cooldown_count = min(cooldown_count, max_cooldown_count)
	is_cooldown_by_moving = true

func cooldown():
	cooldown_count = max(cooldown_count - 1, 0)
	return cooldown_count > 0


func _physics_process(delta):
	if Engine.is_editor_hint():
		
		var temp = now_pos
		now_pos.x = floor(global_position.x / 60)
		now_pos.y = floor(global_position.y / 60)
		if temp != now_pos:
			notify_property_list_changed()
		return
	
	if not is_inside_tree():
		return
	
	if Global.is_game_pause:
		return
	

	on_physics_process(delta)

func on_physics_process(delta):
	
	
	
	
	
	
	var was_moving = is_moving()
	
	if is_stoping():
		update_stop()
		
	if is_jumping():
		update_jump()
	elif is_moving() and not is_cooldowning():
		update_move()
		
	if is_cooldowning():
		cooldown()

	if not is_moving():
		update_not_moving(was_moving)

	if is_shaking:
		update_shake()
	
signal move_success
signal move_fail
func move_straight(d):
	
	




	
	set_direction(d)

	set_physics_process(true)
	
	if can_pass(now_pos.x, now_pos.y, d):
		self.now_pos += direction_to_vector(d)
		emit_signal("move_success")
		return true
	else:
		check_event_trigger_touch_front(d)
		start_cooldown()
		emit_signal("move_fail")
		return false

func move_straight_to_point(x, y):
	x = int(Util.get_value_from_str(x))
	y = int(Util.get_value_from_str(y))
	var d = 0
	if now_pos.x != x:
		if now_pos.x < x:
			d = 6
		else:
			d = 4
	elif now_pos.y != y:
		if now_pos.y < y:
			d = 2
		else:
			d = 8
	if (d > 0):
		move_straight(d)
	if (now_pos.x != x or now_pos.y != y):
		move_route_index -= 1


func be_push(d):
	set_direction(d)
	
	set_physics_process(true)
	
	if can_pass(now_pos.x, now_pos.y, d):
		self.now_pos += direction_to_vector(d)
		return true
	emit_signal("move_fail")
	return false

func check_event_trigger_touch_front(d):
	var x2 = x_with_direction(now_pos.x, d);
	var y2 = y_with_direction(now_pos.y, d);
	check_event_trigger_touch(x2, y2);

func check_event_trigger_touch(x, y):
	var p = tileMap.player
	if p.can_push and p.is_at_pos(Vector2(x, y)):
		p.be_push(direction)
		
	var event = tileMap.get_event_by_pos(Vector2(x, y))
	if event and event.can_push:
		event.be_push(direction)

func update_stop():
	if is_move_route_forcing:
		update_routine_move()

func set_movement_pause(is_pause):
	is_movement_pause = is_pause
	pass

signal force_move_route_finished
func update_routine_move():
	if is_movement_pause: return
	
	if wait_count > 0:
		wait_count -= 1
	else:
		
		if move_route.size() > 0 and not is_move_route_forcing and move_route_index >= move_route.size():
			move_route_index = int(move_route_index) % move_route.size()
		

		
		if move_route_index >= move_route.size():
			if is_move_route_forcing:
				restore_org_move_route()
				emit_signal("force_move_route_finished")
				is_move_route_forcing = false
			return
		
		var command = move_route[move_route_index]
		if command:
			process_move_command(command)
			move_route_index += 1

func process_move_command(command):

	var params = command.get("parameters")


	
	match command["command"]:
		"print":
			print(params)
		"set_switch":
			Global.set_game_switch(params[0], params[1])
		"toggle_switch":
			Global.set_game_switch(params[0], not Global.get_game_switch(params[0]))
		"set_variable":
			Global.set_game_variable(params[0], params[1])
		"add_variable":
			Global.set_game_variable(params[0], Global.get_game_variable(params[0]) + params[1])
		"move_up":
			move_straight(8)
		"move_down":
			move_straight(2)
		"move_left":
			move_straight(4)
		"move_right":
			move_straight(6)
		"move_straight":
			move_straight(params)
		"move_random":
			var random_dir = (randi() % 4 + 1) * 2
			move_straight(random_dir)
		"move_toward_player":
			move_toward_player()
		"move_toward_event":
			move_toward_event_by_name(params)
		"move_to_point":
			move_to_point(params[0], params[1])
		"move_straight_to_point":
			move_straight_to_point(params[0], params[1])
		"move_to_event":
			move_to_event_by_name(params)
		"set_z_index":
			apply_z_index(params)
		"set_visible":
			apply_visible(params)
		"set_through":
			set_through(params)
		"set_move_speed":
			move_speed = int(params)
		"jump":
			if params:
				jump(params[0], params[1])
			else:
				jump()
		"jump_to_point":
			jump_to_point(params[0], params[1])
		"jump_random":
			var random_dir = (randi() % 4 + 1) * 2
			if can_pass(now_pos.x, now_pos.y, random_dir):
				var offset = direction_to_vector(random_dir)
				jump(offset.x, offset.y)
		"wait":
			wait_count = params - 1
		"wait_random_in_range":
			
			wait_count = randi() % int(params[1] - params[0]) + params[0]
		"play_se":
			
			var db = params.get("db", 0)
			var pan = params.get("pan", 0)
			Sound.play_se(params.path, db, pan)
		
		"set_dead_zone":
			
			
			
			if params:
				move_dead_zone = [params[0], params[1], params[2], params[3]]
			else:
				move_dead_zone = []
		"set_move_zone":
			
			
			
			if params:
				move_zone = [params[0], params[1], params[2], params[3]]
			else:
				move_zone = []
		"fade_to":
			var op
			var time
			if params:
				op = params.get("opacity", 0)
				time = params.get("time_sec", 1)
			else:
				op = 0
				time = 1
			fade_to(op, time)
		"queue_free":
			queue_free()
		"set_can_pass_group":
			if params:
				can_pass_group = params
			else:
				can_pass_group = ""
		"event_end_hint_jump":
			event_end_hint_jump()


func set_move_route(mr):

	move_route = mr
	move_route_index = 0
	is_move_route_forcing = false
	set_physics_process(true)

func force_move_route(mr):
	if not original_move_route:
		memorize_org_move_route()
	move_route = mr
	move_route_index = 0
	wait_count = 0
	is_move_route_forcing = true
	set_physics_process(true)
	

func memorize_org_move_route():
	original_move_route = move_route
	original_move_route_index = move_route_index
	
func restore_org_move_route():
	move_route = original_move_route
	move_route_index = original_move_route_index
	original_move_route = null






func set_direction(d):
	direction = d

func is_dashing():
	return false

func real_move_speed():
	if is_in_group("follower"):
		return Global.game_map.player.real_move_speed()
	elif is_dashing():
		return move_speed + 5
	else:
		return move_speed + 4

func distance_per_frame():
	return pow(2, real_move_speed()) / 256.0;

func update_move():
	if now_pos.x < moving_pos.x:
		moving_pos.x = max(moving_pos.x - distance_per_frame(), now_pos.x)
	elif now_pos.x > moving_pos.x:
		moving_pos.x = min(moving_pos.x + distance_per_frame(), now_pos.x)
	if now_pos.y < moving_pos.y:
		moving_pos.y = max(moving_pos.y - distance_per_frame(), now_pos.y)
	elif now_pos.y > moving_pos.y:
		moving_pos.y = min(moving_pos.y + distance_per_frame(), now_pos.y)
	
	global_position = Vector2(moving_pos.x * 60, moving_pos.y * 60)

signal move_finished
func update_not_moving(was_moving):
	if was_moving:
		emit_signal("move_finished")
		if has_move_cooldown:
			start_cooldown()
		if not is_in_group("no_check_rule"):
			tileMap.check_rule()

func x_with_direction(x, d):
	var move = 1 if d == 6 else - 1 if d == 4 else 0
	return x + move

func y_with_direction(y, d):
	var move = 1 if d == 2 else - 1 if d == 8 else 0
	return y + move
	
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

func can_pass(x, y, d):
	var x2 = x_with_direction(x, d)
	var y2 = y_with_direction(y, d)
	return can_pass_here(x2, y2, d)
	
func can_pass_here(x, y, d):
	if not can_move_enabled:
		return false
	if through:
		return true
	if not tileMap.is_in_bound(Vector2(x, y)):
		return false
	if not is_in_move_zone(Vector2(x, y)):
		return false
	if is_in_dead_zone(Vector2(x, y)):
		return false
	if "layer" in self:
		if self.layer != 1:
			return true
	if not tileMap.can_pass(Vector2(x, y)):
		return false
	if is_block_by_event_or_player(x, y):
		return false
	


		



		

	return true
	
func is_block_by_event_or_player(x, y):
	if type == CHAR_TYPES.EVENT:
		if self.layer == 1:
			if tileMap.player.now_pos == Vector2(x, y) and not ("player" in can_pass_group):
				return true

	var events = tileMap.get_events_by_pos(Vector2(x, y))
	var is_block = false
	for e in events:
		if e and e.layer == 1 and e.name != name:
			var is_in_can_pass_group = false
			if typeof(can_pass_group) == TYPE_STRING:
				is_in_can_pass_group = e.is_in_group(can_pass_group)
			elif typeof(can_pass_group) == TYPE_ARRAY:
				for group in can_pass_group:
					is_in_can_pass_group = is_in_can_pass_group or e.is_in_group(group)
			
			is_block = not is_in_can_pass_group
		
		if e and e.is_in_group("can_pass_on_it"):
			return false

	if is_block:
		return is_block
	

	
	var fixed_events = tileMap.fixed_map.get_events_by_pos(Vector2(x, y))
	for e in fixed_events:
		if e and e.layer == 1 and e.name != name:
			return true
	


	
	return false

func is_block_by_event_or_player_raycast(x, y, d):
	var org_p = Vector2(x_with_direction(x, 10 - d), y_with_direction(y, 10 - d))
	$Area2D/RayCast2D.global_position = org_p * 60 + Vector2(30, 30)
	$Area2D/RayCast2D.target_position = direction_to_vector(d) * 60
	$Area2D/RayCast2D.force_raycast_update()
	if $Area2D/RayCast2D.is_colliding():
		print($Area2D/RayCast2D.get_collider().get_parent().name, $Area2D/RayCast2D.get_collider_shape())
		return true
	return false


func apply_z_index(value):
	z_index = value

func apply_visible(is_visible):
	if is_visible:
		visible = true
	else:
		visible = false

	
func set_through(is_through):
	through = is_through
	

func move_toward_player():
	var target = tileMap.player
	move_toward_character(target)

func move_toward_event_by_name(event_name):
	var e = tileMap.interpreter.get_target_from_str(event_name)
	if e and "now_pos" in e:
		move_toward_character(e)

func move_toward_character(character):

	var d = find_direction_to_old(character.now_pos.x, character.now_pos.y)


	if (d > 0):
		move_straight(d)

func move_to_event_by_name(event_name):

	var e = tileMap.interpreter.get_target_from_str(event_name)
	if e and "now_pos" in e:
		move_to_point(e.now_pos.x, e.now_pos.y)


func move_to_point(x, y):
	x = int(Util.get_value_from_str(x))
	y = int(Util.get_value_from_str(y))
	var d = find_direction_to_old(x, y)
	if (d > 0):
		move_straight(d)
	if (now_pos.x != x or now_pos.y != y):
		move_route_index -= 1
	
	
func find_direction_to(goalX, goalY):
	var path = tileMap.find_path(now_pos, Vector2(goalX, goalY))
	if path.size() == 0:
		print("no")
		return 0
	return vector_to_direction(path[1] - path[0])

func find_direction_to_old(goalX, goalY):
	var searchLimit = 12
	var mapWidth = tileMap.bound.size.x
	var nodeList = []
	var openList = []
	var closedList = []
	var start = {}
	var best = start

	if (now_pos.x == goalX and now_pos.y == goalY):
		return 0

	start.parent = null
	start.x = now_pos.x
	start.y = now_pos.y
	start.g = 0
	start.f = abs(start.x - goalX) + abs(start.y - goalY)
	nodeList.append(start)
	openList.append(start.y * mapWidth + start.x)

	while (nodeList.size() > 0):
		var bestIndex = 0
		for i in range(nodeList.size()):
			if (nodeList[i].f < nodeList[bestIndex].f):
				bestIndex = i

		var current = nodeList[bestIndex]
		var x1 = current.x
		var y1 = current.y
		var pos1 = y1 * mapWidth + x1
		var g1 = current.g

		nodeList.remove_at(bestIndex)
		openList.remove_at(openList.find(pos1))
		closedList.append(pos1)

		if (current.x == goalX and current.y == goalY):
			best = current
			break

		if (g1 >= searchLimit):
			continue

		for j in range(4):
			var d = 2 + j * 2
			var x2 = x_with_direction(x1, d)
			var y2 = y_with_direction(y1, d)
			var pos2 = y2 * mapWidth + x2

			if (closedList.has(pos2)):
				continue
			if ( not can_pass(x1, y1, d)):
				continue

			var g2 = g1 + 1
			var index2 = openList.find(pos2)

			if (index2 < 0 or g2 < nodeList[index2].g):
				var neighbor
				if (index2 >= 0):
					neighbor = nodeList[index2]
				else:
					neighbor = {}
					nodeList.append(neighbor)
					openList.append(pos2)

				neighbor.parent = current
				neighbor.x = x2
				neighbor.y = y2
				neighbor.g = g2
				neighbor.f = g2 + abs(x2 - goalX) + abs(y2 - goalY)
				if ( not best or neighbor.f - neighbor.g < best.f - best.g):
					best = neighbor

	var node = best
	while (node.parent and node.parent != start):
		node = node.parent

	var deltaX1 = node.x - start.x
	var deltaY1 = node.y - start.y
	if (deltaY1 > 0):
		return 2
	elif (deltaX1 < 0):
		return 4
	elif (deltaX1 > 0):
		return 6
	elif (deltaY1 < 0):
		return 8


	var deltaX2 = now_pos.x - goalX
	var deltaY2 = now_pos.y - goalY
	if (abs(deltaX2) > abs(deltaY2)):
		if (deltaX2 > 0):
			return 4
		else:
			return 6
	elif (deltaY2 != 0):
		if (deltaY2 > 0):
			return 8
		else:
			return 2
	return 0

var has_sprite_animation = false
func set_animation(player: AnimationPlayer, animation_name: String, animation: Animation):
	var library: AnimationLibrary
	if player.has_animation_library(""):
		library = player.get_animation_library("")
	else:
		library = AnimationLibrary.new()
		player.add_animation_library("", library)
	if library.has_animation(animation_name):
		library.remove_animation(animation_name)
	library.add_animation(animation_name, animation)

func remove_animation(player: AnimationPlayer, animation_name: String):
	if player.has_animation_library(""):
		var library = player.get_animation_library("")
		if library.has_animation(animation_name):
			library.remove_animation(animation_name)

func play_sprite_animation(sprite_path, total_frames, time_length, reverse = false, width = 10):
	print("play")

	has_sprite_animation = true
	$WordSprite.update_draw()
	$WordSprite.set_texture(load(sprite_path))
	$WordSprite.hframes = min(total_frames, width)
	$WordSprite.vframes = ceil(total_frames / float(width))
	
	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	animation.length = time_length
	animation.track_set_path(track_index, ".:frame")
	for i in range(total_frames):
		animation.track_insert_key(track_index, i * time_length / total_frames, i)


	set_animation($WordSprite/AnimationPlayer, "sprite_animation", animation)
	$WordSprite/AnimationPlayer.current_animation = "sprite_animation"

	if reverse:
		$WordSprite/AnimationPlayer.play_backwards()
	else:
		$WordSprite/AnimationPlayer.play()


func set_loop_sprite_animation(sprite_path, total_frames, time_length, keyframes = null, delay = null):
	
	


	
	has_sprite_animation = true
	$WordSprite.update_draw()
	$WordSprite.set_texture(load(sprite_path))
	$WordSprite.hframes = min(total_frames, 10)
	$WordSprite.vframes = ceil(total_frames / 10.0)
	
	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	animation.length = time_length
	animation.track_set_path(track_index, ".:frame")
	animation.loop_mode = Animation.LOOP_LINEAR
	animation.track_set_interpolation_loop_wrap(track_index, false)
	animation.value_track_set_update_mode(track_index, Animation.UPDATE_CONTINUOUS)
	
	if keyframes:
		for keyframe in keyframes:
			var time = keyframe.t * time_length
			animation.track_insert_key(track_index, time, keyframe.f)
	else:
		animation.track_insert_key(track_index, 0, 0)
		animation.track_insert_key(track_index, time_length, total_frames)

	set_animation($WordSprite/AnimationPlayer, "sprite_animation", animation)
	$WordSprite/AnimationPlayer.current_animation = "sprite_animation"
	
	if delay != null:
		$WordSprite/AnimationPlayer.stop()

		await get_tree().create_timer(delay).timeout
		$WordSprite/AnimationPlayer.play()


func clear_sprite_animation():
	has_sprite_animation = false
	if $WordSprite/AnimationPlayer.has_animation("sprite_animation"):
		remove_animation($WordSprite/AnimationPlayer, "sprite_animation")
		$WordSprite.update_draw()


var jump_peak = 0
var jump_count = 0
func jump(x_delta = 0, y_delta = 0):
	if abs(x_delta) > abs(y_delta):
		if x_delta != 0:
			if x_delta > 0:
				set_direction(6)
			else:
				set_direction(4)
	else:
		if y_delta != 0:
			if y_delta > 0:
				set_direction(2)
			else:
				set_direction(8)
	
	self.now_pos.x += x_delta
	self.now_pos.y += y_delta
	
	var distance = round(sqrt(x_delta * x_delta + y_delta * y_delta))
	jump_peak = 10 + distance - real_move_speed()
	jump_count = jump_peak * 2
	
	set_physics_process(true)

func jump_to_point(x, y):
	x = int(Util.get_value_from_str(x))
	y = int(Util.get_value_from_str(y))
	jump(x - now_pos.x, y - now_pos.y)
	
func jump_height():
	return (jump_peak * jump_peak - pow(abs(jump_count - jump_peak), 2)) / 200.0









	

func is_jumping():
	return jump_count > 0
	
func update_jump():
	jump_count -= 1
	moving_pos.x = (moving_pos.x * jump_count + now_pos.x) / (jump_count + 1.0)
	moving_pos.y = (moving_pos.y * jump_count + now_pos.y) / (jump_count + 1.0) - jump_height()
	
	if jump_count == 0:
		moving_pos = now_pos

	global_position = Vector2(moving_pos.x * 60, moving_pos.y * 60)

func is_in_move_zone(pos):
	if not move_zone.size():
		return true
	else:
		var zone_bound = Rect2()
		zone_bound.position = Vector2(move_zone[0], move_zone[1])
		zone_bound.end = Vector2(move_zone[2], move_zone[3])
		if zone_bound.has_point(pos):
			return true
		else:
			return false

func is_in_dead_zone(pos):
	if not move_dead_zone.size():
		return false
	else:
		var dead_zone_bound = Rect2()
		dead_zone_bound.position = Vector2(move_dead_zone[0], move_dead_zone[1])
		dead_zone_bound.end = Vector2(move_dead_zone[2], move_dead_zone[3])
		if dead_zone_bound.has_point(pos):
			return true
		else:
			return false
			
func get_pos_in_camera():
	var c = tileMap.player.get_node("Camera3D")
	
	var c_ceil_pos = (c.position - Vector2(960, 540)) / 60.0
	return now_pos - c_ceil_pos

func get_real_pos_in_camera():
	var c = tileMap.player.get_node("Camera3D")
	
	var c_ceil_pos = (c.position - Vector2(960, 540))
	return global_position - c_ceil_pos
	
func add_loop_light():
	var LoopLightResourse = load("res://Scenes/Animations/LoopLight.tscn")
	add_child(LoopLightResourse.instantiate())

	
func remove_loop_light():
	if has_node("loop_light"):
		get_node("loop_light").queue_free()

func ring(time_sec):
	pass

var now_shake_frame = 0.0
var total_shake_frame = 0.0
var shake_distance = 10.0
var is_shaking = false

func shake(tf, d):
	total_shake_frame = tf
	shake_distance = d
	now_shake_frame = 0.0
	is_shaking = true
	
	set_physics_process(true)

func update_shake():
	var shake_offset = shake_distance * sin(now_shake_frame) * (total_shake_frame - now_shake_frame) / total_shake_frame
	$WordSprite.position.x = 30 + shake_offset
	
	now_shake_frame += 1
	
	if now_shake_frame > total_shake_frame:
		is_shaking = false
		

func get_direction_been_squeezed_when_overlap(pos, desire_dir = 2):
	if can_pass(pos.x, pos.y, desire_dir):
		is_stucking = false
		self.opacity = 1
		return desire_dir
	
	for d in [2, 8, 6, 4]:
		if can_pass(pos.x, pos.y, d):
			is_stucking = false
			self.opacity = 1
			return d

	




	var d = try_to_push_around(pos)
	if d:
		is_stucking = false
		self.opacity = 1
		return d
		
	
	for dd in [2, 4, 6, 8]:
		var player = Global.game_map.player
		if player.is_at_pos(pos + direction_to_vector(dd)):
			if player.been_squeezed_when_overlap(10 - dd):
				return dd
	
	is_stucking = true
	self.opacity = 0.3
	delay_clear_stuck()
	
	return 0


func get_force_direction_been_squeezed_when_overlap(pos, force_dir):
	if can_pass(pos.x, pos.y, force_dir):
		return force_dir
	else:
		
		if try_to_push_one_direction(pos, force_dir):
			return force_dir
		else:
			return 0

var is_stucking = false
func been_squeezed_when_overlap(from = 0):
	print("been_squeezed_when_overlap: ", now_pos)
	
	for d in [2, 8, 6, 4]:
		if can_pass(now_pos.x, now_pos.y, d):
			is_stucking = false
			print("is_not_stucking")
			self.opacity = 1
			move_straight(d)
			return true

	




	var d = try_to_push_around(now_pos, from)
	if not d:
		is_stucking = true
		self.opacity = 0.3
		print("is_stucking")
		delay_clear_stuck()
		return false
	else:
		is_stucking = false
		print("is_not_stucking")
		self.opacity = 1
		move_straight(d)
		return true
		
func delay_clear_stuck():
	await get_tree().process_frame

	is_stucking = false
	self.opacity = 1
	print("delay_clear_stuck")

var is_pushing_around = false
func try_to_push_around(center_pos, from = 0):
	for d in [2, 4, 6, 8]:
		if d == from: continue
		
		var pos = center_pos + direction_to_vector(d)
		
		
		if not can_pass_here(pos.x, pos.y, d):
			if not is_block_by_event_or_player(pos.x, pos.y):
				continue
				


		
		var es = Global.game_map.get_events_by_pos(pos)
		if Global.game_map.player.is_at_pos(pos):
			es.append(Global.game_map.player)
		var push_all_success = true
		for e in es:
			is_pushing_around = true
			if e.can_push and not e.is_pushing_around and not e.is_stucking and e.been_squeezed_when_overlap(10 - d):
				push_all_success = push_all_success and true
			else:
				push_all_success = false
			is_pushing_around = false
		if push_all_success:
			print("success: ", d)

			return d
	
	












	print("all fail")
	return false

func try_to_push_one_direction(center_pos, d):
	print("try_to_push_one_direction: ", d)
	var pos = center_pos + direction_to_vector(d)
	var es = Global.game_map.get_events_by_pos(pos)
	if Global.game_map.player.is_at_pos(pos):
		es.append(Global.game_map.player)
	var push_all_success = true
	for e in es:
		is_pushing_around = true
		if e.can_push and not e.is_pushing_around and not e.is_stucking and e.been_squeezed_when_overlap(10 - d):
			push_all_success = push_all_success and true
		else:
			push_all_success = false
		is_pushing_around = false
	if push_all_success:
		return true
	
	
	var player = Global.game_map.player
	if player.is_at_pos(pos):
		if player.been_squeezed_when_overlap(10 - d):
			return true

	return false

func update_real_position_to_map():
	var x = round(global_position.x / 60.0)
	var y = round(global_position.y / 60.0)
	self.now_pos = Vector2(x, y)
	moving_pos = now_pos

func event_end_hint_jump():
	var sp = get_node("Sprite2D")
	if has_node("erase_tofu") and get_node("erase_tofu").visible:
		sp = get_node("erase_tofu")
		get_node("Sprite2D").visible = false
	
	var has_sword = has_node("劍") and get_node("劍").visible
	if has_sword:
		get_node("劍").visible = false
	
	var y = sp.position.y
	var jump_tween = create_tween()
	jump_tween.tween_property(sp, "position:y", y - 30, 0.1).from(y).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	jump_tween.tween_property(sp, "position:y", y, 0.1).from(y - 30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	jump_tween.finished.connect(func():
		if has_node("erase_tofu") and get_node("erase_tofu").visible:
			get_node("Sprite2D").visible = true
	)
	return jump_tween

	if has_node("erase_tofu") and get_node("erase_tofu").visible:
		get_node("Sprite2D").visible = true
	if has_sword:
		get_node("劍").visible = true
