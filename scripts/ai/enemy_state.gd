class_name EnemyState
extends Node
## Base class for enemy states. The state machine fills in `enemy` and `state_machine`.
## Pattern: https://www.gdquest.com/tutorial/godot/design-patterns/finite-state-machine/

var enemy: Enemy
var state_machine: EnemyStateMachine


## Called once when the state becomes active.
func enter() -> void:
	pass


## Called once when the state is left.
func exit() -> void:
	pass


## Called every physics frame while the state is active.
func physics_update(_delta: float) -> void:
	pass
