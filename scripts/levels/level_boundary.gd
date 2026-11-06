class_name LevelBoundary
extends Area3D
## A big invisible box around the playable zone. If the player flies out, a
## warning is shown and the ship is steered back toward the centre of the box.

signal player_left
signal player_returned

## How hard the ship is turned back at first, and how fast that grows each second.
@export var base_turn_strength: float = 1.5
@export var strength_growth: float = 1.0

var _player: Player
var _is_outside: bool = false
var _time_outside: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # the player layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if not _is_outside or not is_instance_valid(_player):
		return
	_time_outside += delta
	var strength := base_turn_strength + strength_growth * _time_outside
	_player.steer_toward(global_position, strength, delta)


func _on_body_entered(body: Node3D) -> void:
	if not body is Player:
		return
	_player = body as Player
	if _is_outside:
		_is_outside = false
		_time_outside = 0.0
		player_returned.emit()


func _on_body_exited(body: Node3D) -> void:
	if not body is Player:
		return
	_player = body as Player
	_is_outside = true
	_time_outside = 0.0
	player_left.emit()
