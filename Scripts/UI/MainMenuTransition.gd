extends CanvasLayer

var _fade_panel: ColorRect


func _ready() -> void:
	layer = 100
	_fade_panel = ColorRect.new()
	_fade_panel.name = "FadePanel"
	_fade_panel.color = Color.BLACK
	_fade_panel.modulate.a = 0.0
	_fade_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade_panel)


func fade_transition_scene(scene: String, fade_time: float = 0.45) -> Tween:
	var tween := create_tween()
	_fade_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	tween.tween_property(_fade_panel, "modulate:a", 1.0, fade_time).from(_fade_panel.modulate.a)
	tween.finished.connect(func():
		if ResourceLoader.exists(scene):
			get_tree().change_scene_to_file(scene)
		var tween_out := create_tween()
		tween_out.tween_property(_fade_panel, "modulate:a", 0.0, fade_time).from(1.0)
		tween_out.finished.connect(func(): _fade_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE)
	)
	return tween


func fade_fast_transition_scene(scene: String) -> Tween:
	return fade_transition_scene(scene, 0.25)


func fade_white_transition_scene(scene: String) -> Tween:
	_fade_panel.color = Color.WHITE
	var tween := fade_transition_scene(scene, 0.45)
	tween.finished.connect(func(): _fade_panel.color = Color.BLACK)
	return tween


func refresh_screen_light() -> void:
	pass


func show_black_bar() -> void:
	pass


func hide_black_bar() -> void:
	pass


func show_save_hint() -> void:
	pass


func show_esc_hint() -> void:
	pass


func hide_esc_hint() -> void:
	pass


func hide_esc_hint_after_a_while() -> void:
	pass


func show_esc_menu_hint() -> void:
	pass
