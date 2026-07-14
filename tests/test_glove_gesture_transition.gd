extends SceneTree

const GloveLevel = preload("res://levels/glove/glove_level.gd")
const GridWorld = preload("res://core/grid_world.gd")
const GloveLayouts = preload("res://scripts/levels/glove/glove_layouts.gd")

func _init() -> void:
	var world := GridWorld.new()
	world.load_level(GloveLevel.build_level())
	_finish_pending_effects(world)
	world.interact_front()
	_finish_pending_effects(world)
	var zero = world.find_first_entity_by_text("零")
	var one = world.find_first_entity_by_text("一")
	var failures: Array[String] = []
	if zero == null or one == null:
		failures.append("gesture transition setup requires zero and one")
	else:
		world.move_entity_to(zero.id, Vector2i(25, 16))
		world.move_entity_to(one.id, Vector2i(26, 17))
		if not world.has_pending_timed_effect():
			failures.append("a gesture change schedules the delayed hand switch")
		if not world.player_input_locked:
			failures.append("a gesture change locks player input during the flash")
		if absf(world.pending_timed_delay - 0.5) > 0.001:
			failures.append("a gesture change switches the hand after the 0.5-second flash-in")
		var request: Dictionary = world.consume_gesture_transition_request()
		if request.is_empty() or absf(float(request.get("duration", 0.0)) - 1.0) > 0.001:
			failures.append("a gesture change requests a 1-second visual transition")
		world.resolve_pending_timed_effect()
		if world.player_input_locked:
			failures.append("the new hand layout unlocks input after the transition switch")
		var hand_cell = world.get_any_entity_at(GloveLayouts.hand_cells("one")[0])
		if hand_cell == null or hand_cell.text != "掌":
			failures.append("the one hand layout appears at the midpoint switch")
	if failures.is_empty():
		print("glove gesture transition tests passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)

func _finish_pending_effects(world: RefCounted) -> void:
	var remaining_steps := 32
	while world.has_pending_timed_effect() and remaining_steps > 0:
		world.resolve_pending_timed_effect()
		remaining_steps -= 1
