class_name FlightPathProvider
extends RefCounted
## One place that talks to the Flight Navigation 3D plugin.
## Plugin: https://github.com/RevolNoom/godot_flight_navigation_3d
## The level's FlightNavigation3D node must be in the group "flight_navigation".

const NAVIGATION_GROUP := &"flight_navigation"


## Returns waypoints (global positions) from `from` to `to`, or an empty
## array if there is no navigation, no route, or an end point is inside geometry.
static func find_path(tree: SceneTree, from: Vector3, to: Vector3) -> PackedVector3Array:
	var navigation := tree.get_first_node_in_group(NAVIGATION_GROUP)
	if navigation == null or not navigation.has_method("find_path"):
		return PackedVector3Array()
	return navigation.find_path(from, to)
