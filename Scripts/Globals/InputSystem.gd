extends Node

var input_direction = 0
var pre_input_direction = 0
var holding_same_direction_frames = 0

var _preferredAxis

var is_lock = false
func lock():
	is_lock = true
	input_direction = 0

func unlock():
	is_lock = false


func _ready():
	pass


func _physics_process(delta):

	if not is_lock:
		_updateDirection()

func _updateDirection():
	pre_input_direction = input_direction
	
	var x = signX()
	var y = signY()
	if (x != 0 and y != 0):
		if (_preferredAxis == "x"):
			y = 0
		else:
			x = 0
	elif (x != 0):
		_preferredAxis = "y"
	elif (y != 0):
		_preferredAxis = "x"
	input_direction = makeNumpadDirection(x, y)
	

func signX():
	var x = 0
	if (Input.is_action_pressed("ui_left")):
		x = x - 1
	if (Input.is_action_pressed("ui_right")):
		x = x + 1
	return x

func signY():
	var y = 0
	if (Input.is_action_pressed("ui_up")):
		y = y - 1
	if (Input.is_action_pressed("ui_down")):
		y = y + 1
	return y

func makeNumpadDirection(x, y):
	if (x != 0 or y != 0):
		return 5 - y * 3 + x
	return 0
	
	
func is_holding_direction():
	return holding_same_direction_frames > 10

func is_direct_change_direction():
	return pre_input_direction != 0
	
func is_press_ctrlz():
	if Input.is_action_just_pressed("ui_ctrl") and Input.is_action_pressed("ui_z"):
		return true
	if Input.is_action_pressed("ui_ctrl") and Input.is_action_just_pressed("ui_z"):
		return true
	if Input.is_action_just_pressed("ui_ctrl") and Input.is_action_just_pressed("ui_z"):
		return true
	if Input.is_action_just_pressed("ui_joy_undo"):
		return true
	return false
	
func is_press_ctrls():
	if Input.is_action_just_pressed("ui_ctrl") and Input.is_action_pressed("ui_s"):
		return true
	if Input.is_action_pressed("ui_ctrl") and Input.is_action_just_pressed("ui_s"):
		return true
	if Input.is_action_just_pressed("ui_ctrl") and Input.is_action_just_pressed("ui_s"):
		return true
	return false
	
func is_press_backspace():
	if Input.is_action_just_pressed("ui_delete") or Input.is_action_just_pressed("ui_joy_delete"):
		return true
	return false

func is_press_tab():
	if Input.is_action_just_pressed("ui_tab") or Input.is_action_just_pressed("ui_joy_split"):
		return true
	return false

func is_press_alt():
	if Input.is_action_just_pressed("ui_alt") or Input.is_action_just_pressed("ui_joy_pull"):
		return true
	return false
	
func is_press_esc():
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_joy_menu"):
		return true
	return false
