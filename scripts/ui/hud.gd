class_name HUD
extends CanvasLayer
## Heads-up display: health, objective, timer, crosshair, world markers and the
## on-screen touch controls. Call bind_level() once after adding it to a level.

const HEALTH_COLOR_FULL := Color(0.2, 0.9, 0.4)
const HEALTH_COLOR_LOW := Color(0.95, 0.2, 0.2)
const HEALTH_BAR_TWEEN_TIME := 0.25
const FLASH_TIME := 0.4
const OBJECTIVE_DONE_TEXT := "Head to the exit marker!"
const OBJECTIVE_DONE_COLOR := Color(1.0, 0.9, 0.3)

@onready var touch_controls: TouchControls = %TouchControls
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var timer_label: Label = %TimerLabel
@onready var damage_flash: ColorRect = %DamageFlash
@onready var warning_label: Label = %WarningLabel

var _level: LevelBase
var _last_health: int = -1
var _health_fill: StyleBoxFlat
var _health_tween: Tween
var _flash_tween: Tween
var _warning_tween: Tween


func _ready() -> void:
	_setup_health_bar_style()
	damage_flash.modulate.a = 0.0


func _process(_delta: float) -> void:
	if _level:
		timer_label.text = _format_clock(_level.elapsed_time)


## Connects the HUD to a level and its player.
func bind_level(level: LevelBase) -> void:
	_level = level
	level.player.health_changed.connect(_on_health_changed)
	level.kills_changed.connect(_on_kills_changed)
	level.objective_completed.connect(_on_objective_completed)

	# Show the starting values (the signals only fire on change).
	_on_health_changed(level.player.health, level.player.max_health)
	_on_kills_changed(level.kills, level.kill_target)


func _setup_health_bar_style() -> void:
	# Duplicate so changing the colour doesn't affect other ProgressBars (ship select).
	var fill := health_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	if fill == null:
		fill = StyleBoxFlat.new()
	fill.set_corner_radius_all(6)
	health_bar.add_theme_stylebox_override("fill", fill)
	_health_fill = fill


func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_label.text = "%d / %d" % [current, maximum]
	_health_fill.bg_color = HEALTH_COLOR_LOW.lerp(HEALTH_COLOR_FULL, float(current) / maximum)

	if _last_health < 0:
		# First call: just set the bar, no animation or flash.
		health_bar.value = current
	else:
		if current < _last_health:
			_flash_damage()
		_animate_health_bar(current)
	_last_health = current


func _animate_health_bar(target_value: float) -> void:
	if _health_tween:
		_health_tween.kill()
	_health_tween = create_tween()
	_health_tween.tween_property(health_bar, "value", target_value, HEALTH_BAR_TWEEN_TIME)


func _flash_damage() -> void:
	if _flash_tween:
		_flash_tween.kill()
	damage_flash.modulate.a = 1.0
	_flash_tween = create_tween()
	_flash_tween.tween_property(damage_flash, "modulate:a", 0.0, FLASH_TIME)


func _on_kills_changed(kills: int, target: int) -> void:
	# The final kill also triggers objective_completed, which sets its own text.
	if kills < target:
		objective_label.text = "Enemies destroyed: %d / %d" % [kills, target]


func _on_objective_completed() -> void:
	objective_label.text = OBJECTIVE_DONE_TEXT
	objective_label.modulate = OBJECTIVE_DONE_COLOR
	# A quick pulse so the player notices.
	objective_label.pivot_offset = objective_label.size / 2.0
	var tween := create_tween()
	tween.tween_property(objective_label, "scale", Vector2.ONE * 1.25, 0.15)
	tween.tween_property(objective_label, "scale", Vector2.ONE, 0.25)


func _format_clock(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds / 60.0), int(seconds) % 60]
	
## Shows a blinking warning message (e.g. when leaving the arena).
func show_warning(text: String) -> void:
	warning_label.text = text
	warning_label.visible = true
	if _warning_tween:
		_warning_tween.kill()
	_warning_tween = create_tween().set_loops()
	_warning_tween.tween_property(warning_label, "modulate:a", 0.3, 0.4)
	_warning_tween.tween_property(warning_label, "modulate:a", 1.0, 0.4)

func hide_warning() -> void:
	if _warning_tween:
		_warning_tween.kill()
	warning_label.visible = false
