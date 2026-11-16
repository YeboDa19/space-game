class_name EngineTrail
extends GPUParticles3D
## A streak of world-space particles that stays behind a moving engine.


func set_color(color: Color) -> void:
	var base := process_material as ParticleProcessMaterial
	if base == null:
		return
	# Duplicate so each ship gets its own colour without changing the others.
	var unique := base.duplicate() as ParticleProcessMaterial
	unique.color = color
	process_material = unique
