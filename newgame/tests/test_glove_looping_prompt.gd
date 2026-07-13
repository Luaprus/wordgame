extends SceneTree

const GloveLoopingPrompt = preload("res://scripts/levels/glove/glove_looping_prompt.gd")

func _init() -> void:
	var prompt := GloveLoopingPrompt.new()
	var failures: Array[String] = []
	_assert_text(prompt.visible_text(), "·", "the brave prompt starts with its first dot", failures)
	prompt.advance(0.19)
	_assert_text(prompt.visible_text(), "·", "the brave prompt waits for its full character interval", failures)
	prompt.advance(0.01)
	_assert_text(prompt.visible_text(), "··", "the brave prompt appends its second dot", failures)
	prompt.advance(0.2)
	_assert_text(prompt.visible_text(), "··来", "the brave prompt appends 来", failures)
	prompt.advance(0.2)
	_assert_text(prompt.visible_text(), "··来吧", "the brave prompt appends 吧", failures)
	prompt.advance(0.2)
	_assert_text(prompt.visible_text(), "", "the brave prompt clears before repeating", failures)
	prompt.advance(0.2)
	_assert_text(prompt.visible_text(), "·", "the brave prompt restarts after the clear frame", failures)
	var gesture_prompt := GloveLoopingPrompt.new("改变")
	_assert_text(gesture_prompt.visible_text(), "改", "a looping prompt supports a custom suffix", failures)
	gesture_prompt.advance(0.2)
	_assert_text(gesture_prompt.visible_text(), "改变", "a custom suffix reveals one character per step", failures)
	if failures.is_empty():
		print("glove looping prompt tests passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)

func _assert_text(actual: String, expected: String, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s: expected=%s actual=%s" % [message, expected, actual])
