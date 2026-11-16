extends Control
## Main menu: start the game or open the ship and level sub menus.

const SHIP_SELECT_PATH := "res://scenes/ui/ship_select.tscn"
const LEVEL_SELECT_PATH := "res://scenes/ui/level_select.tscn"

@onready var selection_label: Label = %SelectionLabel
@onready var play_button: Button = %PlayButton
@onready var ship_button: Button = %ShipButton
@onready var level_button: Button = %LevelButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	play_button.pressed.connect(GameManager.start_level)
	ship_button.pressed.connect(_change_scene.bind(SHIP_SELECT_PATH))
	level_button.pressed.connect(_change_scene.bind(LEVEL_SELECT_PATH))
	quit_button.pressed.connect(get_tree().quit)
	_update_selection_label()
	AudioManager.play_music(&"music_menu")


func _update_selection_label() -> void:
	var ship := GameManager.get_selected_ship()
	selection_label.text = "Ship: %s  |  %s" % [
		ship.display_name,
		GameManager.get_selected_level_name(),
	]


func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)
