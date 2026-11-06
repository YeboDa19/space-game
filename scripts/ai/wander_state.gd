class_name WanderState
extends EnemyState
## Roams the level: follows a path to a random destination (flight navigation)
## with some wander steering mixed in. Switches to Chase when the player is near.

const RETRY_INTERVAL := 3.0
const PATH_ATTEMPTS := 6
const WANDER_WEIGHT_ON_PATH := 0.3
const AVOID_WEIGHT := 2.0

var _follow_path := SteerFollowPath.new()
var _wander := SteerWander.new()
var _avoid: SteerAvoidObstacles
var _blend := SteerBlend.new()
var _retry_timer: float = 0.0
var _is_built: bool = false


func enter() -> void:
	if not _is_built:
		_build_behaviours()
	_follow_path.clear()
	_retry_timer = 0.0


func physics_update(delta: float) -> void:
	if enemy.distance_to_player() < enemy.data.detection_range:
		state_machine.transition_to(&"Chase")
		return

	# Reached the destination (or never had a path): choose a new one.
	if _follow_path.is_finished():
		_retry_timer -= delta
		if _retry_timer <= 0.0:
			_pick_new_destination()

	# On a path: follow it with a little wander. Otherwise: pure wander.
	var on_path := _follow_path.has_path()
	_blend.set_weight(_follow_path, 1.0 if on_path else 0.0)
	_blend.set_weight(_wander, WANDER_WEIGHT_ON_PATH if on_path else 1.0)
	enemy.apply_steering(_blend.calculate(enemy.agent, delta), delta)


func _build_behaviours() -> void:
	_avoid = SteerAvoidObstacles.new(enemy)
	_blend.add(_follow_path, 1.0)
	_blend.add(_wander, 1.0)
	_blend.add(_avoid, AVOID_WEIGHT)
	_is_built = true


## Asks the flight navigation plugin for a path to a random point near home.
func _pick_new_destination() -> void:
	for _attempt in PATH_ATTEMPTS:
		var destination := enemy.home_position + _random_offset(enemy.data.wander_radius)
		var path := FlightPathProvider.find_path(get_tree(), enemy.global_position, destination)
		if not path.is_empty():
			_follow_path.set_path(path)
			_retry_timer = 0.0
			return
	# No usable path (no navigation, or unlucky points): wander freely for a while.
	_retry_timer = RETRY_INTERVAL


func _random_offset(radius: float) -> Vector3:
	var offset := SteerMath.random_unit_vector() * radius * randf_range(0.3, 1.0)
	offset.y *= 0.4
	return offset
