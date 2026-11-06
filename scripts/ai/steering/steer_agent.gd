class_name SteerAgent
extends RefCounted
## Movement data for a steering agent. The owner updates it every physics frame.
## Architecture inspired by GDQuest's Godot Steering AI Framework (MIT):
## https://github.com/GDQuest/godot-steering-ai-framework

var position: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO
var forward: Vector3 = Vector3.FORWARD
var max_speed: float = 50.0
var max_acceleration: float = 80.0
var radius: float = 3.0
