class_name WorldMarkerLayer
extends Control
## Draws a 2D marker over every 3D node in a group (enemies, the exit...).
## Converts 3D to screen positions with Camera3D.unproject_position():
## https://docs.godotengine.org/en/stable/classes/class_camera3d.html

const MARKER_SCENE: PackedScene = preload("res://scenes/ui/world_marker.tscn")

@export var group_name: StringName = &"enemies"
@export var icon: Texture2D
@export var tint: Color = Color.WHITE
## How far above the node's origin the icon floats (world units).
@export var height_offset: float = 4.0
## Markers farther away than this are hidden. 0 = no limit.
@export var max_distance: float = 0.0
@export var show_distance: bool = true
## Pin markers for off-screen targets to the screen edge instead of hiding them.
@export var clamp_to_screen: bool = false
@export var edge_margin: float = 70.0

var _markers: Dictionary = {}


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var active: Array[Node3D] = []
	for node in get_tree().get_nodes_in_group(group_name):
		var target := node as Node3D
		if target == null:
			continue
		active.append(target)
		_update_marker(camera, target)
	_remove_stale_markers(active)


func _update_marker(camera: Camera3D, target: Node3D) -> void:
	var marker := _get_or_create_marker(target)
	var distance := camera.global_position.distance_to(target.global_position)
	if max_distance > 0.0 and distance > max_distance:
		marker.visible = false
		return

	var world_position := target.global_position + Vector3.UP * height_offset
	var screen_rect := get_viewport().get_visible_rect()
	var screen_position := camera.unproject_position(world_position)
	var is_behind := camera.is_position_behind(world_position)
	var is_on_screen := not is_behind and screen_rect.has_point(screen_position)

	if not is_on_screen:
		if not clamp_to_screen:
			marker.visible = false
			return
		screen_position = _pin_to_edge(screen_position, is_behind, screen_rect.size)

	marker.visible = true
	marker.position = screen_position - marker.get_anchor_offset()
	if show_distance:
		marker.set_distance(distance)


func _get_or_create_marker(target: Node3D) -> WorldMarker:
	if _markers.has(target):
		return _markers[target] as WorldMarker
	var marker := MARKER_SCENE.instantiate() as WorldMarker
	add_child(marker)
	marker.setup(icon, tint, show_distance)
	_markers[target] = marker
	return marker


## Frees the markers of targets that were destroyed or left the group.
func _remove_stale_markers(active: Array[Node3D]) -> void:
	for target in _markers.keys():
		if not is_instance_valid(target) or not active.has(target):
			(_markers[target] as WorldMarker).queue_free()
			_markers.erase(target)


## Places the marker on the screen edge in the direction of the target.
func _pin_to_edge(screen_position: Vector2, is_behind: bool, screen_size: Vector2) -> Vector2:
	var center := screen_size / 2.0
	var direction := screen_position - center
	# Points behind the camera project mirrored through the screen centre.
	if is_behind:
		direction = -direction
	if direction.length_squared() < 1.0:
		direction = Vector2.DOWN
	var half := center - Vector2.ONE * edge_margin
	var scale_x := half.x / maxf(absf(direction.x), 0.001)
	var scale_y := half.y / maxf(absf(direction.y), 0.001)
	return center + direction * minf(scale_x, scale_y)
