extends CanvasLayer

signal opened
signal closed

var is_open := false


func open() -> void:
	is_open = true
	opened.emit()


func close() -> void:
	is_open = false
	closed.emit()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func show_menu() -> void:
	open()


func hide_menu() -> void:
	close()
