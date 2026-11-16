extends Control
## Lets the player pick a level. Buttons are generated from GameManager's data.

@onready var level_list: VBoxContainer = %LevelList
@onready var back_button: Button = %BackButton


func _ready() -> void:
	for i in GameManager.LEVEL_NAMES.size():
		var button := Button.new()
		button.text = GameManager.LEVEL_NAMES[i]
		button.custom_minimum_size = Vector2(600, 120)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(_on_level_pressed.bind(i))
		level_list.add_child(button)
	back_button.pressed.connect(GameManager.go_to_main_menu)
	AudioManager.play_music(&"music_menu")


func _on_level_pressed(index: int) -> void:
	GameManager.selected_level_index = index
	GameManager.go_to_main_menu()
