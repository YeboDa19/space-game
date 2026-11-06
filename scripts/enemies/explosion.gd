extends GPUParticles3D
## One-shot explosion that removes itself when the burst has finished.


func _ready() -> void:
	emitting = true
	await get_tree().create_timer(lifetime + 0.5).timeout
	queue_free()
