class_name KeyboardInput
extends RefCounted
## Keyboard fallback so the game can be tested on PC without touch.
## W/S = pitch, A/D = steer, Space = fire, E = boost, Q = brake.


static func get_steer() -> Vector2:
	var x := int(Input.is_physical_key_pressed(KEY_D)) - int(Input.is_physical_key_pressed(KEY_A))
	var y := int(Input.is_physical_key_pressed(KEY_W)) - int(Input.is_physical_key_pressed(KEY_S))
	return Vector2(x, y)


static func is_firing() -> bool:
	return Input.is_physical_key_pressed(KEY_SPACE)


static func get_speed_modifier() -> float:
	if Input.is_physical_key_pressed(KEY_E):
		return 1.5
	if Input.is_physical_key_pressed(KEY_Q):
		return 0.5
	return 1.0
