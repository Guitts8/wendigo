class_name GameOver
extends CanvasLayer
## Tela de morte: mostra a causa e reinicia o nível.

@export var show_delay: float = 1.5
@export var fade_duration: float = 1.5

@onready var _root: Control = $Root
@onready var _cause_label: Label = %CauseLabel
@onready var _retry_button: Button = %RetryButton


func _ready() -> void:
	_root.visible = false
	SurvivalStats.died.connect(_on_died)
	_retry_button.pressed.connect(_on_retry_pressed)


func _on_died(cause: int) -> void:
	_cause_label.text = _get_cause_text(cause)
	await get_tree().create_timer(show_delay).timeout
	_root.modulate.a = 0.0
	_root.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_retry_button.grab_focus()
	create_tween().tween_property(_root, ^"modulate:a", 1.0, fade_duration)


func _get_cause_text(cause: int) -> String:
	match cause:
		SurvivalStats.DeathCause.COLD:
			return "Você morreu de frio."
		SurvivalStats.DeathCause.STARVATION:
			return "Você morreu de fome."
		SurvivalStats.DeathCause.WENDIGO:
			return "Algo encontrou você."
	return "Você morreu."


func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
