class_name TouchControls
extends Control
## The on-screen controls: a virtual joystick and a fire button.
## The level polls get_steer() / is_firing() each physics frame.

const IDLE_ALPHA := 0.7
const BOOST_MULTIPLIER := 1.5
const BRAKE_MULTIPLIER := 0.5

## Pull down = nose up, like a real flight stick, if you prefer it.
@export var invert_pitch: bool = false

@onready var joystick: TouchJoystick = %Joystick
@onready var fire_button: TouchScreenButton = %FireButton
@onready var boost_button: TouchScreenButton = %BoostButton
@onready var brake_button: TouchScreenButton = %BrakeButton

func get_speed_modifier() -> float:
	if boost_button.is_pressed():
		return BOOST_MULTIPLIER
	if brake_button.is_pressed():
		return BRAKE_MULTIPLIER
	return 1.0

func _ready() -> void:
	_set_button_feedback(fire_button, false)
	fire_button.pressed.connect(_set_button_feedback.bind(fire_button, true))
	fire_button.released.connect(_set_button_feedback.bind(fire_button, false))


## Steering vector. x: right is positive. y: up (nose up) is positive.
func get_steer() -> Vector2:
	var value := joystick.output
	if invert_pitch:
		value.y = -value.y
	return value


func is_firing() -> bool:
	return fire_button.is_pressed()


func _set_button_feedback(button: TouchScreenButton, is_down: bool) -> void:
	button.modulate.a = 1.0 if is_down else IDLE_ALPHA
