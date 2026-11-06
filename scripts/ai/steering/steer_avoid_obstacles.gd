class_name SteerAvoidObstacles
extends SteerBehavior
## Casts rays ahead (one forward, four angled "whiskers") and pushes the agent
## away from whatever they hit. Updated 10 times a second to stay cheap.

var collision_mask: int = 1 # the "world" layer: asteroids, cliffs, ground
var look_ahead_time: float = 1.2
var min_look_ahead: float = 40.0
var whisker_angle_degrees: float = 30.0
var update_interval: float = 0.1

var _owner_body: CollisionObject3D
var _exclude: Array[RID] = []
var _cached_acceleration: Vector3 = Vector3.ZERO
var _timer: float = 0.0


func _init(owner_body: CollisionObject3D) -> void:
	_owner_body = owner_body
	_exclude = [owner_body.get_rid()]
	_timer = randf() * update_interval # so enemies don't all raycast on the same frame


func calculate(agent: SteerAgent, delta: float) -> Vector3:
	_timer -= delta
	if _timer <= 0.0:
		_timer = update_interval
		_cached_acceleration = _compute(agent)
	return _cached_acceleration


func _compute(agent: SteerAgent) -> Vector3:
	var space := _owner_body.get_world_3d().direct_space_state
	var speed := agent.velocity.length()
	var heading := agent.forward
	if speed > 1.0:
		heading = agent.velocity.normalized()
	var ray_length := maxf(min_look_ahead, speed * look_ahead_time)

	var avoidance := Vector3.ZERO
	for direction in _get_ray_directions(heading):
		var query := PhysicsRayQueryParameters3D.create(
			agent.position,
			agent.position + direction * ray_length,
			collision_mask,
			_exclude,
		)
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			continue
		# The closer the obstacle, the stronger the push away from its surface.
		var hit_distance := agent.position.distance_to(hit["position"])
		var closeness := 1.0 - hit_distance / ray_length
		avoidance += (hit["normal"] as Vector3) * closeness

	return avoidance.limit_length(1.0) * agent.max_acceleration


func _get_ray_directions(heading: Vector3) -> Array[Vector3]:
	var up := SteerMath.safe_up(heading)
	var right := heading.cross(up).normalized()
	var angle := deg_to_rad(whisker_angle_degrees)
	var directions: Array[Vector3] = []
	directions.append(heading)
	directions.append(heading.rotated(up, angle))
	directions.append(heading.rotated(up, -angle))
	directions.append(heading.rotated(right, angle))
	directions.append(heading.rotated(right, -angle))
	return directions
