class_name SteerBlend
extends SteerBehavior
## Combines several behaviours with weights, like GSAIBlend in the GDQuest framework.
## A weight of 0 switches a behaviour off.

var _behaviors: Array[SteerBehavior] = []
var _weights: Array[float] = []


func add(behavior: SteerBehavior, weight: float = 1.0) -> void:
	_behaviors.append(behavior)
	_weights.append(weight)


func set_weight(behavior: SteerBehavior, weight: float) -> void:
	var index := _behaviors.find(behavior)
	if index >= 0:
		_weights[index] = weight


func calculate(agent: SteerAgent, delta: float) -> Vector3:
	var total := Vector3.ZERO
	for i in _behaviors.size():
		if _weights[i] > 0.0:
			total += _behaviors[i].calculate(agent, delta) * _weights[i]
	return total.limit_length(agent.max_acceleration)
