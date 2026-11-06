class_name EnemyData
extends Resource
## Stats and references for one type of enemy. Create one .tres per type.

@export var display_name: String = "Enemy"

@export_group("Visuals")
@export var model_scene: PackedScene
@export var model_scale: float = 1.0
## Rotate the model so its nose points along -Z (Godot's forward).
@export var model_rotation_degrees: Vector3 = Vector3.ZERO
@export var hitbox_size: Vector3 = Vector3(6.0, 2.0, 8.0)
## Where lasers come out, relative to the enemy (nose is -Z).
@export var muzzle_offset: Vector3 = Vector3(0.0, 0.0, -4.0)

@export_group("Movement")
@export var max_speed: float = 55.0
@export var max_acceleration: float = 80.0
## How quickly the ship turns to face its direction (higher = snappier).
@export var turn_speed: float = 3.0

@export_group("Senses")
@export var detection_range: float = 450.0
@export var attack_range: float = 220.0
## Must be bigger than detection_range, to prevent flickering between states.
@export var lose_range: float = 750.0
@export var wander_radius: float = 350.0

@export_group("Combat")
@export var max_health: int = 30
@export var fire_cooldown: float = 0.9
@export var laser_damage: int = 6
@export var laser_speed: float = 110.0
## Random aim error in degrees (lower = more accurate).
@export var spread_degrees: float = 5.0
## 0 = shoot where the player is, 1 = perfectly lead the player's movement.
@export_range(0.0, 1.0) var aim_lead: float = 0.5
