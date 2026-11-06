class_name TouchJoystick
extends Control
## On-screen thumbstick. It remembers which finger grabbed it (by index), so a
## second finger, such as the one on the fire button, never disturbs it.
## Touch handling follows the Godot docs for InputEventScreenTouch / ScreenDrag:
## https://docs.godotengine.org/en/stable/classes/class_inputeventscreentouch.html

signal output_changed(value: Vector2)

@export var base_size: float = 360.0
@export var knob_size: float = 160.0
## Stick deflection below this (0 to 1) is ignored, which stops thumb jitter.
@export_range(0.0, 0.5) var dead_zone: float = 0.1
## 1.0 = linear. Higher values give finer control near the centre.
@export_range(1.0, 3.0) var response_exponent: float = 1.5
@export_range(0.0, 1.0) var idle_alpha: float = 0.6

## x: -1 (left) to 1 (right). y: -1 (down) to 1 (up).
var output: Vector2 = Vector2.ZERO

var _touch_index: int = -1

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Knob


func _ready() -> void:
	base.size = Vector2.ONE * base_size
	knob.size = Vector2.ONE * knob_size
	resized.connect(_reset_visuals)
	_reset_visuals()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Only grab a finger if we aren't already tracking one.
		if _touch_index == -1:
			_touch_index = event.index
			modulate.a = 1.0
			_update_stick(event.position)
	elif event.index == _touch_index:
		_release()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _touch_index:
		_update_stick(event.position)


func _update_stick(touch_position: Vector2) -> void:
	var radius := base.size.x / 2.0
	var center := size / 2.0

	# Keep the knob inside the base circle.
	var offset := (touch_position - center).limit_length(radius)
	knob.position = center + offset - knob.size / 2.0

	# Normalise to -1..1. Screen y points down, so flip it: up = positive.
	var raw := offset / radius
	_set_output(_apply_response(Vector2(raw.x, -raw.y)))


func _apply_response(value: Vector2) -> Vector2:
	var length := value.length()
	if length < dead_zone:
		return Vector2.ZERO
	# Rescale so output starts from 0 right after the dead zone, then shape it.
	var scaled := remap(length, dead_zone, 1.0, 0.0, 1.0)
	return value.normalized() * pow(scaled, response_exponent)


func _release() -> void:
	_touch_index = -1
	_reset_visuals()
	_set_output(Vector2.ZERO)


func _set_output(value: Vector2) -> void:
	if value.is_equal_approx(output):
		return
	output = value
	output_changed.emit(output)


func _reset_visuals() -> void:
	base.position = (size - base.size) / 2.0
	knob.position = (size - knob.size) / 2.0
	modulate.a = idle_alpha
