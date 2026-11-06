class_name SteerFollowPath
extends SteerBehavior
## Follow a list of waypoints (for example from the flight navigation plugin).

## A waypoint counts as reached inside this distance. Make it a bit bigger
## than the navigation voxels so the ship cuts corners smoothly.
var reach_radius: float = 30.0

var _points: PackedVector3Array = PackedVector3Array()
var _index: int = 0


func set_path(points: PackedVector3Array) -> void:
	_points = points
	_index = 0


func clear() -> void:
	_points = PackedVector3Array()
	_index = 0


func has_path() -> bool:
	return _index < _points.size()


func is_finished() -> bool:
	return not has_path()


func calculate(agent: SteerAgent, _delta: float) -> Vector3:
	# Skip every waypoint we have already reached.
	while _index < _points.size() and agent.position.distance_to(_points[_index]) < reach_radius:
		_index += 1
	if _index >= _points.size():
		return Vector3.ZERO
	return _seek_acceleration(agent, _points[_index])
