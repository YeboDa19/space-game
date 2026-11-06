extends MeshInstance3D
## Scrolls the river texture so the water appears to flow.

@export var scroll_speed: Vector2 = Vector2(0.0, 0.05)


func _process(delta: float) -> void:
	var material := get_active_material(0) as StandardMaterial3D
	if material:
		material.uv1_offset += Vector3(scroll_speed.x, scroll_speed.y, 0.0) * delta
