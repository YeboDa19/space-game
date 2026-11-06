extends Control
## Shown when the player's health reaches zero.

@onready var continue_button: Button = %ContinueButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	continue_button.pressed.connect(GameManager.restart_level)
	quit_button.pressed.connect(GameManager.go_to_main_menu)
