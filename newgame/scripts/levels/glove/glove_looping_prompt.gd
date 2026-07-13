extends RefCounted

const TEXT := "··来吧"
const STEP_SECONDS := 0.2

var text := TEXT
var step_seconds := STEP_SECONDS
var elapsed := 0.0
var frame_index := 0

func _init(value: String = TEXT, interval: float = STEP_SECONDS) -> void:
	text = value
	step_seconds = interval

func visible_text() -> String:
	return "" if frame_index >= text.length() else text.left(frame_index + 1)

func advance(delta: float) -> bool:
	elapsed += delta
	var changed := false
	while elapsed >= step_seconds:
		elapsed -= step_seconds
		frame_index = (frame_index + 1) % (text.length() + 1)
		changed = true
	return changed
