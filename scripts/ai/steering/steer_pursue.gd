class_name SteerPursue
extends SteerBehavior
## Chase a moving target by aiming where it WILL be (smarter than plain seek).

var target: Node3D
var max_prediction_time: float = 1.5


func calculate(agent: SteerAgent, _delta: float) -> Vector3:
	if not is_instance_valid(target):
		return Vector3.ZERO

	var target_velocity := Vector3.ZERO
	if target is CharacterBody3D:
		target_velocity = (target as CharacterBody3D).velocity

	var distance := agent.position.distance_to(target.global_position)
	var prediction_time := minf(distance / maxf(agent.max_speed, 1.0), max_prediction_time)
	var predicted_position := target.global_position + target_velocity * prediction_time
	return _seek_acceleration(agent, predicted_position)
