extends "res://Scripts/Event.gd"

const WordSnakeCrashScatter := preload("res://Scripts/Animations/WordSnakeCrashScatter.gd")


func been_snake_crash() -> void:
	await _snake_crash_component().crash()


func crash_by_collision() -> void:
	await been_snake_crash()


func _snake_crash_component() -> Node:
	if has_node("WordSnakeCrashScatter"):
		return $WordSnakeCrashScatter

	var component := Node.new()
	component.name = "WordSnakeCrashScatter"
	component.set_script(WordSnakeCrashScatter)
	add_child(component)
	return component
