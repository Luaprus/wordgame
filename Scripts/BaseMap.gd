extends TileMap

const PlayerResourse = preload("res://Scenes/Player/Player.tscn")
const EventResourse = preload("res://Scenes/Events/Event.tscn")

var event_table = {}


func get_cell_size():
	if tile_set:
		return Vector2(tile_set.tile_size)
	return Vector2(60, 60)


func set_cell_compat(x, y, source_id):
	set_cell(0, Vector2i(int(x), int(y)), source_id, Vector2i.ZERO)


func get_cellv(pos):
	return get_cell_source_id(0, Vector2i(int(pos.x), int(pos.y)))


func add_event_in_table(pos, event_path):
	if event_table.has(pos):
		if not event_table[pos].has(event_path):
			event_table[pos].append(event_path)
	else:
		event_table[pos] = [event_path]


func remove_event_in_table(pos, event_path):
	if event_table.has(pos):
		if event_table[pos].has(event_path):
			event_table[pos].erase(event_path)


func update_event_in_table(prev_pos, new_pos, event_path):
	remove_event_in_table(prev_pos, event_path)
	add_event_in_table(new_pos, event_path)


func refresh():
	for event in get_tree().get_nodes_in_group("events"):
		event.refresh_if_need()


func delete_event_by_id(event_id):
	for event in get_tree().get_nodes_in_group("events"):
		if event.get_instance_id() == event_id and is_ancestor_of(event):
			if event.is_in_group("exist_event"):
				event.transport_to(Vector2(-10, -10))
			else:
				event.queue_free()


func get_event_by_pos(pos):
	for event in get_tree().get_nodes_in_group("events"):
		if event.is_at_pos(pos) and is_ancestor_of(event) and event.existing:
			return event
	return null


func get_events_by_pos(pos):
	for event in get_tree().get_nodes_in_group("events"):
		if event.is_at_pos(pos) and is_ancestor_of(event) and event.existing:
			return event
	return null


func get_event_by_name(_name):
	for event in get_tree().get_nodes_in_group("events"):
		if event.get_name() == _name and is_ancestor_of(event) and event.existing:
			return event
	return null


func set_event_exist(_name, to_exist):
	for event in get_tree().get_nodes_in_group("events"):
		if event.get_name() == _name and is_ancestor_of(event):
			event.exist(to_exist)


func get_events_by_group(group_name):
	var events = []
	for event in get_tree().get_nodes_in_group(group_name):
		if is_ancestor_of(event) and event.existing:
			events.append(event)
	if events.size() > 0:
		return events
	return null


func is_in_bound(pos):
	return true


func can_pass(pos):
	var cell = get_cellv(pos)
	if cell > 0:
		return true
	return false


func type(text, pos, tags = [], auto_init = true, custom_path = ""):
	var word = add_new_event(pos, auto_init, custom_path)
	word.text = text

	if tags:
		for tag in tags:
			word.add_to_group(str(Util.get_value_from_str(tag)))

	return word


func add_new_event(pos, auto_init = true, custom_path = ""):
	var event = EventResourse.instantiate()
	event.position = map_to_local(pos)
	event.add_to_group("generated_in_runtime")

	if not custom_path:
		add_child(event)
	else:
		get_node(custom_path).add_child(event)

	if auto_init:
		event.init()

	return event
