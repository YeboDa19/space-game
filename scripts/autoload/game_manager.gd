extends Node
## Global game state and scene navigation. Registered as the "GameManager" autoload.

const SAVE_PATH := "user://save.cfg"

var best_times: Dictionary = {}

const MAIN_MENU_PATH := "res://scenes/ui/main_menu.tscn"

const SHIP_PATHS: Array[String] = [
	"res://data/ships/executioner.tres",
	"res://data/ships/imperial.tres",
	"res://data/ships/zenith.tres",
]

const LEVEL_NAMES: Array[String] = [
	"Level 1: Space",
	"Level 2: Planet Surface",
]

const LEVEL_PATHS: Array[String] = [
	"res://scenes/levels/level_space.tscn",
	"res://scenes/levels/level_planet.tscn",
]

## Upper limits used to fill the stat bars on the ship select screen.
const MAX_SPEED_STAT := 80.0
const MAX_ACCELERATION_STAT := 35.0

var selected_ship_index: int = 0
var selected_level_index: int = 0
var ships: Array[ShipData] = []


func _ready() -> void:
	for path in SHIP_PATHS:
		ships.append(load(path) as ShipData)
		
	_load_best_times()


func get_selected_ship() -> ShipData:
	return ships[selected_ship_index]


func get_selected_level_name() -> String:
	return LEVEL_NAMES[selected_level_index]


func start_level() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(LEVEL_PATHS[selected_level_index])


func restart_level() -> void:
	# Same scene again = level restarts from scratch.
	start_level()


func go_to_main_menu() -> void:
	# Always unpause first: overlays pause the tree.
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


## Formats seconds as mm:ss.mmm (e.g. 02:05.340).
func format_time(seconds: float) -> String:
	var minutes := int(seconds / 60.0)
	var secs := int(seconds) % 60
	var millis := int((seconds - floorf(seconds)) * 1000.0)
	return "%02d:%02d.%03d" % [minutes, secs, millis]
	
## Best time for a level in seconds, or -1.0 if it has never been completed.
func get_best_time(level_index: int) -> float:
	return best_times.get(level_index, -1.0)


## Stores a finished time. Returns true if it is a new record.
func submit_time(level_index: int, seconds: float) -> bool:
	var best := get_best_time(level_index)
	if best >= 0.0 and seconds >= best:
		return false
	best_times[level_index] = seconds
	_save_best_times()
	return true


func _save_best_times() -> void:
	var config := ConfigFile.new()
	for level_index in best_times:
		config.set_value("best_times", str(level_index), best_times[level_index])
	config.save(SAVE_PATH)


func _load_best_times() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	for key in config.get_section_keys("best_times"):
		best_times[int(key)] = config.get_value("best_times", key)
