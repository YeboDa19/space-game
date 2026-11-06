class_name ChaseCamera
extends Camera3D
## Third-person chase camera in the style of EverSpace 2: follows behind and
## above the ship, lags slightly in turns, looks ahead and widens FOV with speed.

@export var position_smoothing: float = 6.0
@export var look_ahead_distance: float = 40.0
@export var base_fov: float = 60.0
@export var max_fov_boost: float = 15.0
@export var fov_smoothing: float = 3.0

var target: Player


func _ready() -> void:
	current = true
	fov = base_fov


# Runs in the physics step, after the player (it comes later in the tree),
# so the camera always follows the player's latest position.
func _physics_process(delta: float) -> void:
	if target == null:
		return

	var weight := 1.0 - exp(-position_smoothing * delta)
	global_position = global_position.lerp(_get_desired_position(), weight)
	_look_ahead_of_target()

	var speed_ratio := clampf(target.current_speed / target.max_speed, 0.0, 1.5)
	var target_fov := base_fov + max_fov_boost * speed_ratio
	fov = lerpf(fov, target_fov, 1.0 - exp(-fov_smoothing * delta))


## Jumps straight to the follow position (use right after spawning).
func snap_to_target() -> void:
	global_position = _get_desired_position()
	_look_ahead_of_target()


func _get_desired_position() -> Vector3:
	# Offset is in the ship's local space, so the camera swings behind it.
	return target.global_position + target.global_transform.basis * target.ship_data.camera_offset


func _look_ahead_of_target() -> void:
	var forward := -target.global_transform.basis.z
	var look_point := target.global_position + forward * look_ahead_distance
	if not global_position.is_equal_approx(look_point):
		look_at(look_point, Vector3.UP)
