extends Control
## Shown when the player finishes the level. Displays the completion time.

@onready var time_label: Label = %TimeLabel
@onready var replay_button: Button = %ReplayButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	replay_button.pressed.connect(GameManager.restart_level)
	menu_button.pressed.connect(GameManager.go_to_main_menu)


## Called by the level right after instancing this screen.
func set_time(seconds: float) -> void:
	time_label.text = "Time: %s" % GameManager.format_time(seconds)
