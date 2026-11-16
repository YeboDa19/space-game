extends Control
## Ship selection screen with rotating 3D preview and stat bars.

const ROTATION_SPEED := 0.8

@onready var model_pivot: Node3D = %ModelPivot
@onready var name_label: Label = %NameLabel
@onready var speed_label: Label = %SpeedLabel
@onready var speed_bar: ProgressBar = %SpeedBar
@onready var accel_label: Label = %AccelLabel
@onready var accel_bar: ProgressBar = %AccelBar
@onready var previous_button: Button = %PreviousButton
@onready var next_button: Button = %NextButton
@onready var confirm_button: Button = %ConfirmButton
@onready var back_button: Button = %BackButton

var _index: int = 0
var _current_model: Node3D


func _ready() -> void:
	_index = GameManager.selected_ship_index
	previous_button.pressed.connect(_change_ship.bind(-1))
	next_button.pressed.connect(_change_ship.bind(1))
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(GameManager.go_to_main_menu)
	speed_bar.max_value = GameManager.MAX_SPEED_STAT
	accel_bar.max_value = GameManager.MAX_ACCELERATION_STAT
	_show_ship()
	AudioManager.play_music(&"music_menu")


func _process(delta: float) -> void:
	model_pivot.rotate_y(ROTATION_SPEED * delta)


func _change_ship(direction: int) -> void:
	_index = wrapi(_index + direction, 0, GameManager.ships.size())
	_show_ship()


func _show_ship() -> void:
	var data := GameManager.ships[_index]

	if _current_model:
		_current_model.queue_free()
	_current_model = data.scene.instantiate() as Node3D
	_current_model.scale = Vector3.ONE * data.preview_scale
	model_pivot.add_child(_current_model)

	name_label.text = data.display_name
	speed_label.text = "Max Speed: %d" % int(data.max_speed)
	speed_bar.value = data.max_speed
	accel_label.text = "Acceleration: %d" % int(data.acceleration)
	accel_bar.value = data.acceleration


func _on_confirm_pressed() -> void:
	GameManager.selected_ship_index = _index
	GameManager.go_to_main_menu()
