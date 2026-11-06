class_name Enemy
extends CharacterBody3D
## A flying enemy. Stats come from an EnemyData resource, behaviour from the
## EnemyStateMachine child (Wander, Chase, Attack) and the steering library.

signal died

const LASER_SCENE: PackedScene = preload("res://scenes/projectiles/laser.tscn")
const EXPLOSION_SCENE: PackedScene = preload("res://scenes/effects/explosion.tscn")
const WORLD_MASK := 1
const MIN_SPEED_RATIO := 0.4

@export var data: EnemyData
## Shows the current state above the enemy (useful for debugging and the video).
@export var show_state_label: bool = true

var agent := SteerAgent.new()
var player: Player
var home_position: Vector3
var health: int = 0
var is_dead: bool = false

var forward: Vector3:
	get:
		return -global_transform.basis.z

var _is_initialized: bool = false

@onready var model_mount: Node3D = $ModelMount
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var muzzle: Marker3D = $Muzzle
@onready var state_label: Label3D = $StateLabel
@onready var state_machine: EnemyStateMachine = $StateMachine


func _ready() -> void:
	if data == null:
		push_error("%s has no EnemyData assigned." % name)
		return
	add_to_group("enemies")
	_apply_data()
	player = get_tree().get_first_node_in_group("player") as Player
	state_label.visible = show_state_label
	state_machine.state_changed.connect(_on_state_changed)


func _physics_process(_delta: float) -> void:
	# The level moves us to our spawn point right AFTER _ready(), so anything that
	# depends on our final position or heading waits until the first physics frame.
	if not _is_initialized and data != null:
		_initialize_after_spawn()


func take_damage(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	if health <= 0:
		_die()
	elif state_machine.current_state is WanderState:
		# Being shot makes a patrolling enemy hunt the player.
		state_machine.transition_to(&"Chase")


## Copies our body's data into the steering agent (called before each state update).
func sync_agent() -> void:
	agent.position = global_position
	agent.velocity = velocity
	agent.forward = forward


## Applies a steering acceleration and moves. Optionally turns to face the velocity.
func apply_steering(acceleration: Vector3, delta: float, face_velocity: bool = true) -> void:
	velocity += acceleration * delta
	velocity = velocity.limit_length(data.max_speed)

	# Flying ships never hover: keep a minimum forward speed.
	var min_speed := data.max_speed * MIN_SPEED_RATIO
	if velocity.length() < min_speed:
		var direction := forward
		if velocity.length() > 0.1:
			direction = velocity.normalized()
		velocity = direction * min_speed

	move_and_slide()
	if face_velocity:
		face_direction(velocity, delta)


## Smoothly turns the ship to look along `direction`.
func face_direction(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	var target_basis := Basis.looking_at(direction.normalized(), SteerMath.safe_up(direction))
	var current := basis.orthonormalized().get_rotation_quaternion()
	var weight := 1.0 - exp(-data.turn_speed * delta)
	basis = Basis(current.slerp(target_basis.get_rotation_quaternion(), weight))


func distance_to_player() -> float:
	if not is_instance_valid(player):
		return INF
	return global_position.distance_to(player.global_position)


func get_direction_to_player() -> Vector3:
	if not is_instance_valid(player):
		return forward
	return (player.global_position - global_position).normalized()


## True when no rock or cliff blocks the straight line to the player.
func can_see_player() -> bool:
	if not is_instance_valid(player):
		return false
	var query := PhysicsRayQueryParameters3D.create(
		global_position, player.global_position, WORLD_MASK
	)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## True when the player is inside a cone in front of us (dot product test).
func is_aimed_at_player(min_dot: float) -> bool:
	return forward.dot(get_direction_to_player()) > min_dot


func fire_laser() -> void:
	var laser := LASER_SCENE.instantiate() as Laser
	# Add to the level, not to the enemy, so the laser doesn't move with the ship.
	get_parent().add_child(laser)
	laser.global_position = muzzle.global_position
	laser.speed = data.laser_speed

	# Aim ahead of the player, then add some random error so shots can be dodged.
	var direction := (_get_aim_point() - muzzle.global_position).normalized()
	direction = SteerMath.spread_direction(direction, data.spread_degrees)
	laser.look_at(laser.global_position + direction, SteerMath.safe_up(direction))
	laser.setup(false, data.laser_damage)


func _get_aim_point() -> Vector3:
	var travel_time := global_position.distance_to(player.global_position) / data.laser_speed
	return player.global_position + player.velocity * travel_time * data.aim_lead


func _apply_data() -> void:
	health = data.max_health
	agent.max_speed = data.max_speed
	agent.max_acceleration = data.max_acceleration
	agent.radius = maxf(data.hitbox_size.x, data.hitbox_size.z) * 0.5

	var model := data.model_scene.instantiate() as Node3D
	model.scale = Vector3.ONE * data.model_scale
	model.rotation_degrees = data.model_rotation_degrees
	model_mount.add_child(model)

	var box := BoxShape3D.new()
	box.size = data.hitbox_size
	collision_shape.shape = box
	muzzle.position = data.muzzle_offset


func _initialize_after_spawn() -> void:
	_is_initialized = true
	home_position = global_position
	velocity = forward * data.max_speed * 0.6
	state_machine.setup(self, &"Wander")


func _die() -> void:
	is_dead = true
	var explosion := EXPLOSION_SCENE.instantiate() as Node3D
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	died.emit() # the level counts the kill
	queue_free()


func _on_state_changed(state_name: StringName) -> void:
	state_label.text = String(state_name)
