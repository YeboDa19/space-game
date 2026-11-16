extends Node3D
## Multi-part explosion: fireball + sparks + a brief light flash. Frees itself.

@onready var flash: OmniLight3D = $Flash
@onready var life_timer: Timer = $LifeTimer


func _ready() -> void:
	for child in get_children():
		if child is GPUParticles3D:
			(child as GPUParticles3D).emitting = true
	life_timer.timeout.connect(queue_free)
	create_tween().tween_property(flash, "light_energy", 0.0, 0.3)
