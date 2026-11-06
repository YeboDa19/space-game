class_name SteerWander
extends SteerBehavior
## 3D wander: seek a point on a small sphere ahead of the agent, and let that
## point drift randomly. Gives smooth, meandering movement.

var circle_distance: float = 60.0
var circle_radius: float = 30.0
## How fast the wander point drifts (higher = twistier flight).
var drift_rate: float = 3.0

var _wander_direction: Vector3 = Vector3.FORWARD


func _init() -> void:
	_wander_direction = SteerMath.random_unit_vector()


func calculate(agent: SteerAgent, delta: float) -> Vector3:
	var drift := SteerMath.random_unit_vector() * drift_rate * delta
	_wander_direction = (_wander_direction + drift).normalized()
	# Flatten vertical wandering a little so enemies don't loop up and down.
	var flattened := Vector3(_wander_direction.x, _wander_direction.y * 0.4, _wander_direction.z).normalized()

	var heading := agent.forward
	if agent.velocity.length() > 1.0:
		heading = agent.velocity.normalized()
	var target := agent.position + heading * circle_distance + flattened * circle_radius
	return _seek_acceleration(agent, target)
