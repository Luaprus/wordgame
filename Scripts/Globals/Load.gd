extends Node

var queue

var current_scene = null

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)
	print(current_scene.scene_file_path)
	
	set_process(false)
	queue = preload("res://Scripts/Globals/resource_queue.gd").new()
	queue.start()

var prev_progress = {}
func _process(delta):
	for path in queue.pending:
		var pg = queue.get_progress(path)
		if prev_progress.has(path):
			if pg != prev_progress[path]:
				print(path, ": ", pg * 100, "%")
		prev_progress[path] = pg
		
		if pg == 1:
			prev_progress.erase(path)
			set_process(false)
	
	if queue.pending.size() == 0:
		set_process(false)
	
func preload_scene(path):
	queue.queue_resource(path)
	set_process(true)
	
func change_scene_to_file(path):
	call_deferred("_deferred_change_scene", path)
	
	




	
	
	

	




	




	
	





	
func _deferred_change_scene(path):
	var pt = Time.get_ticks_msec()
	


	print("current_scene")
	print(current_scene.scene_file_path)
	if current_scene:
		current_scene.free()
	
	var pt1 = Time.get_ticks_msec()
	var s = queue.get_resource(path)
	var nt1 = Time.get_ticks_msec()
	print("get_resource_time: ", nt1 - pt1)
	
	current_scene = s.instantiate()
	
	var pt2 = Time.get_ticks_msec()
	get_tree().get_root().add_child(current_scene)
	var nt2 = Time.get_ticks_msec()
	print("add_child_time: ", nt2 - pt2)
	
	
	
	get_tree().set_current_scene(current_scene)
	
	var nt = Time.get_ticks_msec()
	print("load_scene_time: ", nt - pt)
