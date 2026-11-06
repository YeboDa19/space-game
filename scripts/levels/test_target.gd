extends StaticBody3D
## TEMPORARY: stand-in enemy to test lasers, the HUD markers and the kill counter.
## Replaced by real enemies in Phase 8.

signal died

@export var health: int = 30


func _ready() -> void:
	add_to_group("enemies")


func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0 and not is_queued_for_deletion():
		died.emit()
		queue_free()
