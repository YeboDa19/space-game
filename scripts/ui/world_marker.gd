class_name WorldMarker
extends VBoxContainer
## One floating icon with an optional distance read-out.

@onready var icon_rect: TextureRect = %Icon
@onready var distance_label: Label = %DistanceLabel


func setup(texture: Texture2D, tint: Color, show_distance: bool) -> void:
	icon_rect.texture = texture
	icon_rect.modulate = tint
	distance_label.modulate = tint
	distance_label.visible = show_distance


func set_distance(meters: float) -> void:
	distance_label.text = "%d m" % int(meters)


## Offset from the marker's top-left to the icon's centre, so the icon (not the
## whole marker including the label) sits exactly on the target point.
func get_anchor_offset() -> Vector2:
	return icon_rect.position + icon_rect.size / 2.0
