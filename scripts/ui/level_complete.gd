class_name LevelCompleteScreen
extends Control
## Shown when the player reaches the exit. Displays the time, the best time and
## the Replay / Main Menu choice.

@onready var time_label: Label = %TimeLabel
@onready var best_label: Label = %BestLabel
@onready var record_label: Label = %RecordLabel
@onready var replay_button: Button = %ReplayButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	replay_button.pressed.connect(_on_choice.bind(GameManager.restart_level))
	menu_button.pressed.connect(_on_choice.bind(GameManager.go_to_main_menu))
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)


## Called by the level right AFTER adding this screen to the tree.
func set_results(seconds: float, best_seconds: float, is_record: bool) -> void:
	time_label.text = "Time: %s" % GameManager.format_time(seconds)
	best_label.text = "Best: %s" % GameManager.format_time(best_seconds)
	record_label.visible = is_record


func _on_choice(action: Callable) -> void:
	replay_button.disabled = true
	menu_button.disabled = true
	action.call()
