extends Node
## Global game state and scene navigation. Registered as the "GameManager" autoload.

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
