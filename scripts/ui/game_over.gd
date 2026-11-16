extends Control
## Shown when the player's health reaches zero.

@onready var continue_button: Button = %ContinueButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	continue_button.pressed.connect(_on_choice.bind(GameManager.restart_level))
	quit_button.pressed.connect(_on_choice.bind(GameManager.go_to_main_menu))
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)


func _on_choice(action: Callable) -> void:
	# Disable both buttons so a double tap can't change the scene twice.
	continue_button.disabled = true
	quit_button.disabled = true
	action.call()
