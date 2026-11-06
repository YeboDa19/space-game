class_name SteerBehavior
extends RefCounted
## Base class of all steering behaviours. A behaviour looks at the agent and
## returns the linear acceleration it wants. The owner applies it to its body.


## Override in subclasses.
func calculate(_agent: SteerAgent, _delta: float) -> Vector3:
	return Vector3.ZERO


## Classic "seek": steer so the velocity turns toward the target (Reynolds).
func _seek_acceleration(agent: SteerAgent, target_position: Vector3) -> Vector3:
	var to_target := target_position - agent.position
	if to_target.length_squared() < 0.0001:
		return Vector3.ZERO
	var desired_velocity := to_target.normalized() * agent.max_speed
	return (desired_velocity - agent.velocity).limit_length(agent.max_acceleration)
