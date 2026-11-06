class_name Laser
extends Area3D
## A projectile that flies forward, damages whatever it hits, then frees itself.
## Approach based on the KidsCanCode "3D shooting" recipe:
## https://kidscancode.org/godot_recipes/3.x/3d/3d_shooting/index.html

const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_ENEMY := 4
const LAYER_PLAYER_PROJECTILE := 8
const LAYER_ENEMY_PROJECTILE := 16

@export var speed: float = 150.0
@export var damage: int = 10
@export var lifetime: float = 3.0
@export var player_material: Material
@export var enemy_material: Material

var _age: float = 0.0

@onready var mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += -global_transform.basis.z * speed * delta
	_age += delta
	if _age >= lifetime:
		queue_free()


## Configures who fired this laser, which decides what it can hit.
func setup(from_player: bool, new_damage: int) -> void:
	damage = new_damage
	if from_player:
		collision_layer = LAYER_PLAYER_PROJECTILE
		collision_mask = LAYER_WORLD | LAYER_ENEMY
		mesh.material_override = player_material
	else:
		collision_layer = LAYER_ENEMY_PROJECTILE
		collision_mask = LAYER_WORLD | LAYER_PLAYER
		mesh.material_override = enemy_material


func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
