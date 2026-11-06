class_name LevelBase
extends Node3D
## Base script for every level: spawns the player, camera, HUD and enemies, feeds
## player input from the touch controls, tracks time and kills, opens the exit
## and shows the end-of-level overlays.

signal kills_changed(kills: int, target: int)
signal objective_completed

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const CAMERA_SCENE: PackedScene = preload("res://scenes/player/chase_camera.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/hud.tscn")
const GAME_OVER_SCENE: PackedScene = preload("res://scenes/ui/game_over.tscn")
const LEVEL_COMPLETE_SCENE: PackedScene = preload("res://scenes/ui/level_complete.tscn")
const ENEMY_GROUP := &"enemies"
const BOUNDARY_WARNING := "Leaving the combat zone! Turn back!"

## How many enemies must be destroyed before the exit opens.
@export var kill_target: int = 10
## Enemy scenes to spawn. Spawn points cycle through this list.
@export var enemy_scenes: Array[PackedScene] = []

var player: Player
var chase_camera: ChaseCamera
var hud: HUD
var elapsed_time: float = 0.0
var kills: int = 0
var objective_complete: bool = false

var _is_running: bool = true

@onready var overlay_layer: CanvasLayer = $OverlayLayer
@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var enemy_spawns: Node3D = $EnemySpawns
@onready var exit_zone: ExitZone = $ExitZone
@onready var boundary: LevelBoundary = $Boundary


func _ready() -> void:
	_spawn_player()
	_spawn_camera()
	_spawn_hud()
	_setup_exit_zone()
	_setup_boundary()
	# Enemies placed by hand are registered first; spawned ones register themselves.
	_register_existing_enemies()
	_spawn_enemies()


func _process(delta: float) -> void:
	if _is_running:
		elapsed_time += delta


func _physics_process(_delta: float) -> void:
	if player == null or hud == null:
		return
	_feed_player_input()


func show_game_over() -> void:
	if not _is_running:
		return
	_is_running = false
	get_tree().paused = true
	overlay_layer.add_child(GAME_OVER_SCENE.instantiate())


func show_level_complete() -> void:
	if not _is_running:
		return
	_is_running = false
	get_tree().paused = true
	var screen := LEVEL_COMPLETE_SCENE.instantiate()
	overlay_layer.add_child(screen)
	screen.set_time(elapsed_time)


## Call this for every enemy you spawn (the enemy must have a `died` signal).
func register_enemy(enemy: Node) -> void:
	if enemy.has_signal("died"):
		enemy.connect("died", register_kill)


## Counts one destroyed enemy and opens the objective when the target is met.
func register_kill() -> void:
	kills += 1
	kills_changed.emit(kills, kill_target)
	if kills >= kill_target and not objective_complete:
		objective_complete = true
		objective_completed.emit()


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	add_child(player)
	player.global_transform = player_spawn.global_transform
	player.sync_orientation_from_transform()
	player.died.connect(show_game_over)


func _spawn_camera() -> void:
	chase_camera = CAMERA_SCENE.instantiate() as ChaseCamera
	add_child(chase_camera)
	chase_camera.target = player
	chase_camera.snap_to_target()


func _spawn_hud() -> void:
	hud = HUD_SCENE.instantiate() as HUD
	add_child(hud)
	hud.bind_level(self)


func _setup_exit_zone() -> void:
	exit_zone.player_entered.connect(show_level_complete)
	objective_completed.connect(exit_zone.set_active.bind(true))


func _setup_boundary() -> void:
	boundary.player_left.connect(hud.show_warning.bind(BOUNDARY_WARNING))
	boundary.player_returned.connect(hud.hide_warning)


## Spawns one enemy at every spawn point, cycling through enemy_scenes.
func _spawn_enemies() -> void:
	if enemy_scenes.is_empty():
		return
	var spawn_points := enemy_spawns.get_children()
	if spawn_points.size() < kill_target:
		push_warning("%s: %d spawn points but a kill target of %d." % [
			name, spawn_points.size(), kill_target,
		])

	for i in spawn_points.size():
		var spawn_point := spawn_points[i] as Node3D
		var enemy_scene := enemy_scenes[i % enemy_scenes.size()]
		var enemy := enemy_scene.instantiate() as Node3D
		add_child(enemy)
		enemy.global_transform = spawn_point.global_transform
		register_enemy(enemy)


## Enemies placed directly in the level scene (not spawned later) join here.
func _register_existing_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		register_enemy(enemy)


## Copies the touch controls (and the PC keyboard fallback) into the player.
func _feed_player_input() -> void:
	var controls := hud.touch_controls
	player.steer_input = (controls.get_steer() + KeyboardInput.get_steer()).limit_length(1.0)
	player.is_firing = controls.is_firing() or KeyboardInput.is_firing()
	player.speed_modifier = controls.get_speed_modifier() * KeyboardInput.get_speed_modifier()
