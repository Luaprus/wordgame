var queue = []
var pending = {}

const TIME_OUT = 600

func start():
	pass

func queue_resource(path, p_in_front = false):
	if path in pending:
		return
	if ResourceLoader.has_cached(path):
		pending[path] = ResourceLoader.load(path)
		return

	var err = ResourceLoader.load_threaded_request(path)
	if err != OK:
		pending[path] = ResourceLoader.load(path)
		return

	if p_in_front:
		queue.insert(0, path)
	else:
		queue.push_back(path)
	pending[path] = null

func cancel_resource(path):
	if path in pending:
		queue.erase(path)
		pending.erase(path)

func get_progress(path):
	if not (path in pending):
		return -1
	if pending[path] != null:
		return 1.0

	var progress = []
	var status = ResourceLoader.load_threaded_get_status(path, progress)
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			return 1.0
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if progress.size() > 0:
				return float(progress[0])
			return 0.0
		_:
			return -1

func is_ready(path):
	if not (path in pending):
		return false
	if pending[path] != null:
		return true
	return ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED

func _wait_for_resource(path):
	var time_count = 0
	while time_count < TIME_OUT:
		var status = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			return ResourceLoader.load_threaded_get(path)
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			break
		OS.delay_msec(16)
		time_count += 1

	print("wait_for_resource: TIMEOUT or failed! ", path)
	cancel_resource(path)
	return ResourceLoader.load(path)

func get_resource(path):
	if path in pending:
		if pending[path] != null:
			var cached_res = pending[path]
			pending.erase(path)
			return cached_res

		if path in queue:
			queue.erase(path)
		var res = _wait_for_resource(path)
		pending.erase(path)
		return res

	return ResourceLoader.load(path)
