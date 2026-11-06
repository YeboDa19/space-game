class_name SteerArrive
extends SteerBehavior
## Fly toward a point and slow down as you get close to it.

var target_position: Vector3 = Vector3.ZERO
var slowing_radius: float = 60.0
var arrival_tolerance: float = 4.0


func calculate(agent: SteerAgent, _delta: float) -> Vector3:
	var to_target := target_position - agent.position
	var distance := to_target.length()
	if distance < arrival_tolerance:
		# Close enough: brake.
		return (-agent.velocity).limit_length(agent.max_acceleration)
	var speed := agent.max_speed * clampf(distance / slowing_radius, 0.0, 1.0)
	var desired_velocity := to_target / distance * speed
	return (desired_velocity - agent.velocity).limit_length(agent.max_acceleration)
