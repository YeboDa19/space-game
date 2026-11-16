class_name LevelBase
extends Node3D
## Base script for every level: spawns the player, camera, HUD and enemies, feeds
## player input from the touch controls, tracks time and kills, opens the exit,
## and ends the level (game over or completion) exactly once.

signal kills_changed(kills: int, target: int)
signal objective_completed

enum LevelState { PLAYING, FAILED, COMPLETED }

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const CAMERA_SCENE: PackedScene = preload("res://scenes/player/chase_camera.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/hud.tscn")
const GAME_OVER_SCENE: PackedScene = preload("res://scenes/ui/game_over.tscn")
const LEVEL_COMPLETE_SCENE: PackedScene = preload("res://scenes/ui/level_complete.tscn")
const ENEMY_GROUP := &"enemies"
const BOUNDARY_WARNING := "Leaving the combat zone! Turn back!"
## Seconds the game keeps running after dying / reaching the exit, before the
## overlay appears (so the explosion and the fly-through are visible).
const DEATH_DELAY := 1.4
const COMPLETE_DELAY := 0.6

const EXPLOSION_SCENE: PackedScene = preload("res://scenes/effects/explosion.tscn")
const HIT_SPARK_SCENE: PackedScene = preload("res://scenes/effects/hit_spark.tscn")
const MUZZLE_FLASH_SCENE: PackedScene = preload("res://scenes/effects/muzzle_flash.tscn")

## Music for this level (a name from AudioManager's SOUND_PATHS).
@export var music_track: StringName = &"music_level"
## Dust particles that follow the camera (space_dust.tscn or canyon_dust.tscn).
@export var ambient_particles: PackedScene

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

var _state: LevelState = LevelState.PLAYING

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
	AudioManager.play_music(music_track)
	_prewarm_effects()


func _process(delta: float) -> void:
	# The clock stops the instant the level ends, even during the delay before
	# the overlay appears, so the time shown is exactly the time taken.
	if _state == LevelState.PLAYING:
		elapsed_time += delta


func _physics_process(_delta: float) -> void:
	if player == null or hud == null:
		return
	_feed_player_input()


## Ends the level as a failure right now (used by the temporary debug buttons).
func show_game_over() -> void:
	_end_level(LevelState.FAILED, 0.0)


## Ends the level as a success right now (used by the temporary debug buttons).
func show_level_complete() -> void:
	_end_level(LevelState.COMPLETED, 0.0)


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
	player.died.connect(_end_level.bind(LevelState.FAILED, DEATH_DELAY))


func _spawn_camera() -> void:
	chase_camera = CAMERA_SCENE.instantiate() as ChaseCamera
	add_child(chase_camera)
	chase_camera.target = player
	chase_camera.snap_to_target()
	if ambient_particles:
		var dust := ambient_particles.instantiate() as Node3D
		chase_camera.add_child(dust)
		dust.position = Vector3(0.0, 0.0, -40.0) # centred ahead of the camera
	player.damaged.connect(_on_player_damaged)
	player.died.connect(chase_camera.add_trauma.bind(1.0))


func _spawn_hud() -> void:
	hud = HUD_SCENE.instantiate() as HUD
	add_child(hud)
	hud.bind_level(self)


func _setup_exit_zone() -> void:
	exit_zone.player_entered.connect(_end_level.bind(LevelState.COMPLETED, COMPLETE_DELAY))
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


## Ends the level once. Whoever gets here first wins: if you die and reach the
## exit in the same moment, only the first event counts.
func _end_level(result: LevelState, delay: float) -> void:
	if _state != LevelState.PLAYING:
		return
	_state = result # stops the clock immediately
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	_show_overlay(result)


func _show_overlay(result: LevelState) -> void:
	hud.hide()
	if result == LevelState.COMPLETED:
		var level_index := GameManager.selected_level_index
		var is_record := GameManager.submit_time(level_index, elapsed_time)
		var screen := LEVEL_COMPLETE_SCENE.instantiate() as LevelCompleteScreen
		overlay_layer.add_child(screen)
		screen.set_results(elapsed_time, GameManager.get_best_time(level_index), is_record)
	else:
		overlay_layer.add_child(GAME_OVER_SCENE.instantiate())
	AudioManager.play_sfx(&"level_complete" if result == LevelState.COMPLETED else &"game_over")
	AudioManager.duck_music()
	get_tree().paused = true


## Copies the touch controls (and the PC keyboard fallback) into the player.
func _feed_player_input() -> void:
	var controls := hud.touch_controls
	player.steer_input = (controls.get_steer() + KeyboardInput.get_steer()).limit_length(1.0)
	player.is_firing = controls.is_firing() or KeyboardInput.is_firing()
	player.speed_modifier = controls.get_speed_modifier() * KeyboardInput.get_speed_modifier()

func _on_player_damaged(amount: int) -> void:
	chase_camera.add_trauma(clampf(amount / 25.0, 0.3, 1.0))


## Spawns each effect once, far out of sight, so the first real explosion or
## shot doesn't cause a stutter while the phone prepares the shaders.
func _prewarm_effects() -> void:
	for effect_scene in [EXPLOSION_SCENE, HIT_SPARK_SCENE, MUZZLE_FLASH_SCENE]:
		var effect := effect_scene.instantiate() as Node3D
		add_child(effect)
		effect.global_position = Vector3(0.0, -10000.0, 0.0)
