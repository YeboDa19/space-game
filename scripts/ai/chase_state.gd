class_name ChaseState
extends EnemyState
## Pursues the player. If a rock is in the way, follows a navigation path instead.

const REPATH_INTERVAL := 0.8
const AVOID_WEIGHT := 2.0

var _pursue := SteerPursue.new()
var _follow_path := SteerFollowPath.new()
var _avoid: SteerAvoidObstacles
var _blend := SteerBlend.new()
var _repath_timer: float = 0.0
var _is_built: bool = false


func enter() -> void:
	if not _is_built:
		_build_behaviours()
	_pursue.target = enemy.player
	_follow_path.clear()
	_repath_timer = 0.0


func physics_update(delta: float) -> void:
	var distance := enemy.distance_to_player()
	if distance > enemy.data.lose_range:
		state_machine.transition_to(&"Wander")
		return
	if distance < enemy.data.attack_range:
		state_machine.transition_to(&"Attack")
		return

	var use_path := false
	if enemy.can_see_player():
		_follow_path.clear()
	else:
		# Blocked: re-request a path now and then (not every frame).
		_repath_timer -= delta
		if _repath_timer <= 0.0:
			_repath_timer = REPATH_INTERVAL
			_follow_path.set_path(FlightPathProvider.find_path(
				get_tree(), enemy.global_position, enemy.player.global_position
			))
		use_path = _follow_path.has_path()

	_blend.set_weight(_follow_path, 1.0 if use_path else 0.0)
	_blend.set_weight(_pursue, 0.0 if use_path else 1.0)
	enemy.apply_steering(_blend.calculate(enemy.agent, delta), delta)


func _build_behaviours() -> void:
	_avoid = SteerAvoidObstacles.new(enemy)
	_blend.add(_pursue, 1.0)
	_blend.add(_follow_path, 0.0)
	_blend.add(_avoid, AVOID_WEIGHT)
	_is_built = true
