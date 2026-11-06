class_name ExitZone
extends Area3D
## The level exit. Hidden and inactive until the objective is complete.

signal player_entered

const OBJECTIVE_GROUP := &"objective_markers"

var is_active: bool = false

var _pulse_tween: Tween

@onready var ring: Node3D = $Ring


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	set_active(false)


## Shows or hides the exit. While active it also joins the HUD's objective marker group.
func set_active(active: bool) -> void:
	is_active = active
	visible = active
	# Physics flags can't change during a physics callback, so defer.
	set_deferred("monitoring", active)

	if active:
		add_to_group(OBJECTIVE_GROUP)
		_start_pulse()
	else:
		if is_in_group(OBJECTIVE_GROUP):
			remove_from_group(OBJECTIVE_GROUP)
		if _pulse_tween:
			_pulse_tween.kill()


func _start_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(ring, "scale", Vector3.ONE * 1.08, 0.8).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(ring, "scale", Vector3.ONE, 0.8).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node3D) -> void:
	if is_active and body is Player:
		player_entered.emit()
