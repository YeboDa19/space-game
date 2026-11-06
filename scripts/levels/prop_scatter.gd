class_name PropScatter
extends Node3D
## Scatters copies of the given scenes (asteroids, rocks, cliffs) randomly inside
## a box centred on this node. A fixed seed gives the same layout on every run.

const KEEP_CLEAR_GROUP := &"keep_clear"

@export var prop_scenes: Array[PackedScene] = []
@export var count: int = 50
## Size of the box (world units) the props are scattered in.
@export var area_size: Vector3 = Vector3(1200.0, 300.0, 1800.0)
@export var min_scale: float = 0.8
@export var max_scale: float = 3.0
## false = random rotation on all axes (asteroids); true = spin around Y only (cliffs, rocks).
@export var yaw_only: bool = false
## Props closer than this to any node in the "keep_clear" group are skipped.
@export var keep_clear_radius: float = 80.0
## Hide props farther than this from the camera (0 = never). Helps mobile performance.
@export var cull_distance: float = 0.0
@export var random_seed: int = 1


func _ready() -> void:
	if prop_scenes.is_empty():
		push_warning("%s has no prop scenes assigned." % name)
		return
	_scatter()


func _scatter() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	var clear_points := _get_keep_clear_points()

	var placed := 0
	var attempts := 0
	while placed < count and attempts < count * 20:
		attempts += 1
		var local_position := Vector3(
			rng.randf_range(-0.5, 0.5) * area_size.x,
			rng.randf_range(-0.5, 0.5) * area_size.y,
			rng.randf_range(-0.5, 0.5) * area_size.z,
		)
		if _is_too_close(to_global(local_position), clear_points):
			continue
		_place_prop(rng, local_position)
		placed += 1


func _place_prop(rng: RandomNumberGenerator, local_position: Vector3) -> void:
	var prop_scene := prop_scenes[rng.randi() % prop_scenes.size()]
	var prop := prop_scene.instantiate() as Node3D
	add_child(prop)
	prop.position = local_position
	if yaw_only:
		prop.rotation.y = rng.randf_range(0.0, TAU)
	else:
		prop.rotation = Vector3(
			rng.randf_range(0.0, TAU),
			rng.randf_range(0.0, TAU),
			rng.randf_range(0.0, TAU),
		)
	prop.scale = Vector3.ONE * rng.randf_range(min_scale, max_scale)
	if cull_distance > 0.0:
		_apply_cull_distance(prop)


func _get_keep_clear_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for node in get_tree().get_nodes_in_group(KEEP_CLEAR_GROUP):
		if node is Node3D:
			points.append((node as Node3D).global_position)
	return points


func _is_too_close(world_position: Vector3, clear_points: Array[Vector3]) -> bool:
	for point in clear_points:
		if world_position.distance_to(point) < keep_clear_radius:
			return true
	return false


func _apply_cull_distance(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).visibility_range_end = cull_distance
	for child in node.get_children():
		_apply_cull_distance(child)
