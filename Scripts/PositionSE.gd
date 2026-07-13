extends AudioStreamPlayer2D





var event
var player
var is_loop = false
var db = 0

var limiter = 20.0







func _ready():
	set_as_top_level(true)
	if player == null:
		player = _get_global_player()
	pass


func _process(delta):
	if player == null:
		player = _get_global_player()
	if event and player:
		volume_db = db
		var from = event.now_pos
		var listener = player.now_pos
		var pan = min(max(from.x - listener.x, - limiter), limiter) / limiter
		
		position.x = (from.x - listener.x) * 60 + player.get_node("Camera3D").position.x
		position.y = (from.y - listener.y) * 60 + player.get_node("Camera3D").position.y

		var dist = position.distance_to(player.get_node("Camera3D").position)
		var per = (1 - dist / max_distance)
		$Sprite2D.modulate = Color(1, 1, 1, per)

func _on_PositionSE_finished():
	if is_loop:
		play()
	else:
		queue_free()


func _get_global_player():
	var global_singleton := get_node_or_null("/root/Global")
	if global_singleton == null:
		return null
	var game_map = global_singleton.get("game_map")
	if game_map == null:
		return null
	return game_map.get("player")
		
