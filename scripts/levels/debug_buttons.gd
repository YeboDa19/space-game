extends CanvasLayer
## TEMPORARY: debug info and test buttons. Removed before submission
## (Phase 9 replaces them with the real game-over and level-complete triggers).

@onready var level: LevelBase = get_parent()
@onready var info_label: Label = %InfoLabel
@onready var die_button: Button = %DieButton
@onready var win_button: Button = %WinButton
@onready var damage_button: Button = %DamageButton
@onready var kill_button: Button = %KillButton


func _ready() -> void:
	die_button.pressed.connect(level.show_game_over)
	win_button.pressed.connect(level.show_level_complete)
	damage_button.pressed.connect(_on_damage_pressed)
	kill_button.pressed.connect(level.register_kill)


func _process(_delta: float) -> void:
	var player := level.player
	if player == null:
		return
	info_label.text = "%s | Speed %d / %d | FPS %d" % [
		player.ship_data.display_name,
		int(player.current_speed),
		int(player.max_speed),
		Engine.get_frames_per_second(),
	]


func _on_damage_pressed() -> void:
	level.player.take_damage(20)
