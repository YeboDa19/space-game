extends Node
## Global audio: music that survives scene changes, plus pooled sound effects.
## Registered as the "AudioManager" autoload. The pools limit how many sounds can
## play at once (polyphony), so a firefight can't create dozens of voices.

const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const POOL_SIZE_2D := 6
const POOL_SIZE_3D := 10
const SFX_MAX_DISTANCE := 400.0
const SFX_UNIT_SIZE := 30.0
const MUSIC_FADE_TIME := 0.8

## EDIT THESE PATHS to match YOUR files. A missing file only prints a warning.
const SOUND_PATHS := {
	&"music_menu": "res://assets/Audio/music_menu.wav",
	&"music_level": "res://assets/Audio/music_level.wav",
	&"music_level_planet": "res://assets/Audio/music_level.wav",
	&"laser_player": "res://assets/Audio/laser_player.ogg",
	&"laser_enemy": "res://assets/Audio/laser_enemy.ogg",
	&"explosion": "res://assets/Audio/explosion.ogg",
	&"player_hit": "res://assets/Audio/hit.ogg",
	&"enemy_hit": "res://assets/Audio/hit.ogg",
	&"ui_click": "res://assets/Audio/ui_click.ogg",
	&"level_complete": "res://assets/Audio/music_menu.wav",
	&"game_over": "res://assets/audio/game_over.ogg",
	&"engine_loop": "res://assets/Audio/engine_loop.ogg",
	&"warning": "res://assets/audio/warning.ogg",
}

var _sounds: Dictionary = {}
var _music_player: AudioStreamPlayer
var _music_tween: Tween
var _current_music: StringName = &""
var _pool_2d: Array[AudioStreamPlayer] = []
var _pool_3d: Array[AudioStreamPlayer3D] = []
var _next_2d: int = 0
var _next_3d: int = 0


func _ready() -> void:
	# Keep playing while the game is paused (game over / level complete screens).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_sounds()
	_create_players()
	get_tree().node_added.connect(_on_node_added)


## Starts a music track. Does nothing if that track is already playing, so music
## carries on across menu screens instead of restarting.
func play_music(track: StringName) -> void:
	print("play_music: ", track, " found: ", _sounds.has(track))
	if track == _current_music and _music_player.playing:
		return
	var stream: AudioStream = _sounds.get(track)
	if stream == null:
		return
	_current_music = track
	if _music_tween:
		_music_tween.kill()
	_music_player.stream = stream
	_music_player.volume_db = -40.0
	_music_player.play()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", 0.0, MUSIC_FADE_TIME)


## Lowers the music (for the game over / level complete screens).
func duck_music(level_db: float = -14.0, time: float = 0.5) -> void:
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", level_db, time)


## Plays a non-positional sound (UI, damage taken, jingles).
func play_sfx(sound: StringName, pitch_variation: float = 0.0) -> void:
	var stream: AudioStream = _sounds.get(sound)
	if stream == null:
		return
	var player := _pool_2d[_next_2d]
	_next_2d = (_next_2d + 1) % _pool_2d.size()
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()


## Plays a positional sound at a world position (explosions).
func play_sfx_3d(sound: StringName, position: Vector3, pitch_variation: float = 0.0) -> void:
	var stream: AudioStream = _sounds.get(sound)
	if stream == null:
		return
	var player := _pool_3d[_next_3d]
	_next_3d = (_next_3d + 1) % _pool_3d.size()
	player.stream = stream
	player.global_position = position
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()


## Creates a configured positional player to attach to a ship, so its sound
## follows the ship (laser fire, engine hum).
func create_player_3d(sound: StringName, polyphony: int = 2) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = _sounds.get(sound)
	player.bus = SFX_BUS
	player.max_distance = SFX_MAX_DISTANCE
	player.unit_size = SFX_UNIT_SIZE
	player.max_polyphony = polyphony
	return player


func _load_sounds() -> void:
	for sound_name in SOUND_PATHS:
		var path: String = SOUND_PATHS[sound_name]
		if ResourceLoader.exists(path):
			_sounds[sound_name] = load(path)
		else:
			push_warning("AudioManager: missing sound file %s" % path)


func _create_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)

	for _i in POOL_SIZE_2D:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_pool_2d.append(player)

	for _i in POOL_SIZE_3D:
		var player := AudioStreamPlayer3D.new()
		player.bus = SFX_BUS
		player.max_distance = SFX_MAX_DISTANCE
		player.unit_size = SFX_UNIT_SIZE
		add_child(player)
		_pool_3d.append(player)


## Every button in the game (menus, overlays) gets a click sound automatically.
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(play_sfx.bind(&"ui_click"))
