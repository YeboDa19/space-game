class_name AttackState
extends EnemyState
## Circles the player at a comfortable distance, faces them and fires lasers.

const EXIT_RANGE_FACTOR := 1.15
const PREFERRED_DISTANCE_FACTOR := 0.65
const AIM_CONE_DOT := 0.96 # about 16 degrees
const ORBIT_ANGLE := 0.5
const AVOID_WEIGHT := 2.0

var _arrive := SteerArrive.new()
var _avoid: SteerAvoidObstacles
var _blend := SteerBlend.new()
var _orbit_direction: float = 1.0
var _flip_timer: float = 0.0
var _fire_cooldown: float = 0.0
var _is_built: bool = false


func enter() -> void:
	if not _is_built:
		_build_behaviours()
	_flip_timer = 0.0
	# A random delay before the first shot, so a group doesn't fire in unison.
	_fire_cooldown = randf_range(0.3, enemy.data.fire_cooldown)


func physics_update(delta: float) -> void:
	var distance := enemy.distance_to_player()
	if distance > enemy.data.lose_range:
		state_machine.transition_to(&"Wander")
		return
	# Leaving at a bigger range than entering prevents flickering between states.
	if distance > enemy.data.attack_range * EXIT_RANGE_FACTOR:
		state_machine.transition_to(&"Chase")
		return

	_update_orbit_target(delta)
	# Move by steering, but face the player (not the velocity) so we can shoot.
	enemy.apply_steering(_blend.calculate(enemy.agent, delta), delta, false)
	enemy.face_direction(enemy.get_direction_to_player(), delta)
	_update_firing(delta)


func _build_behaviours() -> void:
	_avoid = SteerAvoidObstacles.new(enemy)
	_blend.add(_arrive, 1.0)
	_blend.add(_avoid, AVOID_WEIGHT)
	_is_built = true


## Moves the arrive target around a circle centred on the player.
func _update_orbit_target(delta: float) -> void:
	_flip_timer -= delta
	if _flip_timer <= 0.0:
		_orbit_direction = 1.0 if randf() < 0.5 else -1.0
		_flip_timer = randf_range(2.0, 4.0)

	var player_position := enemy.player.global_position
	var radial := (enemy.global_position - player_position).normalized()
	radial = radial.rotated(Vector3.UP, _orbit_direction * ORBIT_ANGLE)
	var preferred_distance := enemy.data.attack_range * PREFERRED_DISTANCE_FACTOR
	var height_wobble := sin(Time.get_ticks_msec() * 0.001) * 15.0
	_arrive.target_position = player_position + radial * preferred_distance + Vector3(0.0, height_wobble, 0.0)


func _update_firing(delta: float) -> void:
	_fire_cooldown -= delta
	if _fire_cooldown > 0.0:
		return
	# Only shoot when facing the player (dot product check) with a clear line.
	if enemy.is_aimed_at_player(AIM_CONE_DOT) and enemy.can_see_player():
		enemy.fire_laser()
		_fire_cooldown = enemy.data.fire_cooldown
