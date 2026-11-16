extends GPUParticles3D
## One-shot particle effect that removes itself when it has finished.


func _ready() -> void:
	one_shot = true
	finished.connect(queue_free)
	emitting = true
