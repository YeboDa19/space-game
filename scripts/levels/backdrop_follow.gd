extends Node3D
## Keeps distant scenery (planet, sun, mountains) centred on the camera, so it
## behaves like a real far-away object instead of drifting as you fly.


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera:
		global_position = camera.global_position
