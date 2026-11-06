class_name EnemyStateMachine
extends Node
## Holds the current state and forwards physics updates to it.
## Pattern: https://www.gdquest.com/tutorial/godot/design-patterns/finite-state-machine/

signal state_changed(state_name: StringName)

var current_state: EnemyState


## Gives every child state its references, then enters the first state.
func setup(owner_enemy: Enemy, initial_state: StringName) -> void:
	for child in get_children():
		var state := child as EnemyState
		if state:
			state.enemy = owner_enemy
			state.state_machine = self
	transition_to(initial_state)


func _physics_process(delta: float) -> void:
	if current_state == null:
		return
	current_state.enemy.sync_agent()
	current_state.physics_update(delta)


func transition_to(state_name: StringName) -> void:
	var next_state := get_node_or_null(NodePath(state_name)) as EnemyState
	if next_state == null:
		push_error("EnemyStateMachine: no state named '%s'." % state_name)
		return
	if next_state == current_state:
		return
	if current_state:
		current_state.exit()
	current_state = next_state
	current_state.enter()
	state_changed.emit(state_name)
