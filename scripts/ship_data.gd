class_name ShipData
extends Resource
## Stats and references for a selectable player ship.

@export var display_name: String = "Ship"
@export var max_speed: float = 50.0
@export var acceleration: float = 20.0
@export var turn_rate: float = 1.5
@export var max_health: int = 100
@export var engine_color: Color = Color(0.3, 0.8, 1.0)

## The ship scene
@export var scene: PackedScene
@export var preview_image: Texture2D

## Adjusts the model size on the ship select screen.
@export var preview_scale: float = 1.0
   
## Camera position relative to the ship (x right, y up, z behind).
@export var camera_offset: Vector3 = Vector3(0.0, 3.0, 9.0)
