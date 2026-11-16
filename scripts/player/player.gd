class_name Player
extends CharacterBody3D
## The player's ship. Builds itself from the ShipData chosen in the menus,
## flies with arcade controls and fires lasers.
## Flight approach adapted from the KidsCanCode "3D spaceship" recipe:
## https://kidscancode.org/godot_recipes/3.x/3d/spaceship/index.html

signal health_changed(current: int, maximum: int)
signal died
signal damaged(amount: int)

const LASER_SCENE: PackedScene = preload("res://scenes/projectiles/laser.tscn")
const MUZZLE_NAMES: Array[String] = ["MuzzleLeft", "MuzzleRight"]
const EXPLOSION_SCENE: PackedScene = preload("res://scenes/effects/explosion.tscn")
const ENGINE_TRAIL_SCENE: PackedScene = preload("res://scenes/effects/engine_trail.tscn")
const MUZZLE_FLASH_SCENE: PackedScene = preload("res://scenes/effects/muzzle_flash.tscn")

const START_SPEED_RATIO := 0.2
const MAX_PITCH_DEGREES := 70.0
const PITCH_FACTOR := 0.8
const STEER_SMOOTHING := 8.0
const MAX_BANK_DEGREES := 40.0
const BANK_SMOOTHING := 6.0

const CRASH_DAMAGE := 10
const CRASH_COOLDOWN := 0.8
const CRASH_SPEED_KEEP := 0.3
const KNOCKBACK_SPEED := 25.0
const KNOCKBACK_DECAY := 60.0

## Lasers converge on a point this far ahead, so both guns aim at the crosshair.
const AIM_DISTANCE := 80.0

@export var laser_damage: int = 10
@export var fire_cooldown: float = 0.15

## Set by the input layer (keyboard for now, touch joystick in Phase 5).
var steer_input: Vector2 = Vector2.ZERO
var is_firing: bool = false
var speed_modifier: float = 1.0

var ship_data: ShipData
var max_speed: float
var acceleration: float
var turn_rate: float
var max_health: int
var health: int
var is_dead: bool = false
var current_speed: float = 0.0

var muzzles: Array[Marker3D] = []
var engine_glow: GPUParticles3D

var _yaw: float = 0.0
var _pitch: float = 0.0
var _smoothed_steer: Vector2 = Vector2.ZERO
var _knockback: Vector3 = Vector3.ZERO
var _crash_cooldown_left: float = 0.0
var _fire_cooldown_left: float = 0.0
var _next_muzzle: int = 0

var _laser_sound: AudioStreamPlayer3D
var _engine_sound: AudioStreamPlayer3D

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var ship_mount: Node3D = $ShipMount
@onready var engine_light: OmniLight3D = $ShipMount/EngineLight

func _ready() -> void:
	add_to_group("player")
	setup(GameManager.get_selected_ship())
	_laser_sound = AudioManager.create_player_3d(&"laser_player", 2)
	add_child(_laser_sound)
	_engine_sound = AudioManager.create_player_3d(&"engine_loop", 1)
	add_child(_engine_sound)
	_engine_sound.play()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_update_steering(delta)
	_update_speed(delta)
	_move(delta)
	_handle_collisions(delta)
	_update_visuals(delta)
	_update_firing(delta)


## Applies a ship's stats and builds its visuals.
func setup(data: ShipData) -> void:
	ship_data = data
	max_speed = data.max_speed
	acceleration = data.acceleration
	turn_rate = data.turn_rate
	max_health = data.max_health
	health = max_health
	is_dead = false
	current_speed = max_speed * START_SPEED_RATIO
	_build_ship(data.scene)


## Call after moving the player to its spawn point, so flying starts in that direction.
func sync_orientation_from_transform() -> void:
	_yaw = rotation.y
	_pitch = rotation.x


func take_damage(amount: int) -> void:
	if is_dead:
		return
	damaged.emit(amount)
	AudioManager.play_sfx(&"player_hit", 0.1)
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		_die()

func _die() -> void:
	AudioManager.play_sfx_3d(&"explosion", global_position)
	_engine_sound.stop()
	engine_light.visible = false
	is_dead = true
	ship_mount.visible = false
	# Physics changes can't happen inside a collision callback, so defer.
	collision_shape.set_deferred("disabled", true)

	var explosion := EXPLOSION_SCENE.instantiate() as Node3D
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	died.emit()

func _build_ship(ship_scene: PackedScene) -> void:
	var ship := ship_scene.instantiate() as Node3D
	ship_mount.add_child(ship)

	# The ship scene stores its hitbox as data; copy it onto our physics body.
	var hitbox := ship.get_node("Hitbox") as CollisionShape3D
	collision_shape.shape = hitbox.shape
	collision_shape.transform = hitbox.transform
	hitbox.queue_free()

	muzzles.clear()
	for muzzle_name in MUZZLE_NAMES:
		muzzles.append(ship.get_node(muzzle_name) as Marker3D)

	engine_glow = ship.get_node("EngineGlow") as GPUParticles3D
	
	var trail := ENGINE_TRAIL_SCENE.instantiate() as EngineTrail
	ship.add_child(trail)
	trail.position = engine_glow.position
	trail.set_color(ship_data.engine_color)
	engine_light.light_color = ship_data.engine_color


func _update_steering(delta: float) -> void:
	# Smooth the raw input so the ship eases into turns instead of snapping.
	var weight := 1.0 - exp(-STEER_SMOOTHING * delta)
	_smoothed_steer = _smoothed_steer.lerp(steer_input, weight)

	# Positive rotation about Y turns LEFT, so a right input reduces yaw.
	_yaw -= _smoothed_steer.x * turn_rate * delta
	_pitch += _smoothed_steer.y * turn_rate * PITCH_FACTOR * delta
	var max_pitch := deg_to_rad(MAX_PITCH_DEGREES)
	_pitch = clampf(_pitch, -max_pitch, max_pitch)

	# Rebuilding the basis each frame means the ship can never roll or flip.
	basis = Basis.from_euler(Vector3(_pitch, _yaw, 0.0))


func _update_speed(delta: float) -> void:
	var target_speed := max_speed * speed_modifier
	current_speed = move_toward(current_speed, target_speed, acceleration * delta)


func _move(delta: float) -> void:
	velocity = -global_transform.basis.z * current_speed + _knockback
	_knockback = _knockback.move_toward(Vector3.ZERO, KNOCKBACK_DECAY * delta)
	move_and_slide()


func _handle_collisions(delta: float) -> void:
	_crash_cooldown_left = maxf(_crash_cooldown_left - delta, 0.0)
	if get_slide_collision_count() == 0 or _crash_cooldown_left > 0.0:
		return

	var collision := get_slide_collision(0)
	_crash_cooldown_left = CRASH_COOLDOWN
	current_speed *= CRASH_SPEED_KEEP
	_knockback = collision.get_normal() * KNOCKBACK_SPEED
	take_damage(CRASH_DAMAGE)


func _update_visuals(delta: float) -> void:
	# Bank the visual model (not the physics body) into the turn.
	var target_bank := -_smoothed_steer.x * deg_to_rad(MAX_BANK_DEGREES)
	var weight := 1.0 - exp(-BANK_SMOOTHING * delta)
	ship_mount.rotation.z = lerp_angle(ship_mount.rotation.z, target_bank, weight)
	var speed_ratio := clampf(current_speed / max_speed, 0.0, 1.5)
	_engine_sound.pitch_scale = 0.7 + 0.5 * speed_ratio
	engine_light.light_energy = 0.8 + 0.8 * speed_ratio

	if engine_glow:
		engine_glow.amount_ratio = clampf(current_speed / max_speed, 0.2, 1.0)


func _update_firing(delta: float) -> void:
	_fire_cooldown_left = maxf(_fire_cooldown_left - delta, 0.0)
	if is_firing and _fire_cooldown_left <= 0.0:
		_fire_laser()
		_fire_cooldown_left = fire_cooldown


func _fire_laser() -> void:
	# Alternate between the left and right guns.
	var muzzle := muzzles[_next_muzzle]
	var flash := MUZZLE_FLASH_SCENE.instantiate() as Node3D
	muzzle.add_child(flash)
	_laser_sound.pitch_scale = randf_range(0.92, 1.08)
	_laser_sound.play()
	_next_muzzle = (_next_muzzle + 1) % muzzles.size()

	var laser := LASER_SCENE.instantiate() as Laser
	# Add to the level, NOT the ship, or the laser would move with the ship.
	get_parent().add_child(laser)
	laser.global_position = muzzle.global_position
	var aim_point := global_position - global_transform.basis.z * AIM_DISTANCE
	laser.look_at(aim_point, Vector3.UP)
	laser.setup(true, laser_damage)

## Gently turns the ship toward a world point. Used by the level boundary.
func steer_toward(point: Vector3, strength: float, delta: float) -> void:
	var direction := (point - global_position).normalized()
	var max_pitch := deg_to_rad(MAX_PITCH_DEGREES)
	var target_yaw := atan2(-direction.x, -direction.z)
	var target_pitch := clampf(asin(clampf(direction.y, -1.0, 1.0)), -max_pitch, max_pitch)
	var weight := clampf(strength * delta, 0.0, 1.0)
	_yaw = lerp_angle(_yaw, target_yaw, weight)
	_pitch = lerpf(_pitch, target_pitch, weight)
