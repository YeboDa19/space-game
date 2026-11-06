class_name SteerMath
extends RefCounted
## Small vector helpers shared by the steering behaviours and the enemies.


static func random_unit_vector() -> Vector3:
	var vector := Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	if vector.length_squared() < 0.0001:
		return Vector3.FORWARD
	return vector.normalized()


## An "up" vector that is safe to use with look_at / looking_at for this direction.
static func safe_up(direction: Vector3) -> Vector3:
	if absf(direction.normalized().dot(Vector3.UP)) > 0.99:
		return Vector3.RIGHT
	return Vector3.UP


## Tilts a direction by a random angle of up to max_degrees.
static func spread_direction(direction: Vector3, max_degrees: float) -> Vector3:
	var axis := direction.cross(random_unit_vector())
	if axis.length_squared() < 0.0001:
		return direction
	return direction.rotated(axis.normalized(), deg_to_rad(randf_range(0.0, max_degrees)))
