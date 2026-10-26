class_name Hud
extends CanvasLayer
## HUD mínimo: só a mira e o texto de interação.
## Medidores ficam no diário/inventário (Fase 2), nunca fixos na tela.

@export var interactor: Interactor
## Segundos que o aviso de anotação nova fica na tela.
@export var objective_toast_seconds: float = 4.0

var _interact_key: String = ""
var _toast_tween: Tween

@onready var _prompt_label: Label = %PromptLabel
@onready var _objective_toast: Label = %ObjectiveToast


func _ready() -> void:
	_interact_key = _get_action_key_label(&"interact")
	_objective_toast.modulate.a = 0.0
	Events.objective_changed.connect(_on_objective_changed)


func _process(_delta: float) -> void:
	# Some com o diário aberto ou depois da morte.
	visible = interactor != null and interactor.player.input_enabled
	if not visible:
		return
	var text: String = interactor.get_prompt_text()
	_prompt_label.visible = not text.is_empty()
	if text.is_empty():
		return
	# Sem a tecla quando a ação não está disponível ("Precisa de lenha").
	if interactor.can_interact_with_target():
		_prompt_label.text = "[%s] %s" % [_interact_key, text]
	else:
		_prompt_label.text = text


func _on_objective_changed(text: String) -> void:
	if text.is_empty():
		return
	_objective_toast.text = "Diário: %s" % text
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_objective_toast, ^"modulate:a", 1.0, 0.4)
	_toast_tween.tween_interval(objective_toast_seconds)
	_toast_tween.tween_property(_objective_toast, ^"modulate:a", 0.0, 0.8)


## Nome da primeira tecla ligada à ação (posição física, layout US).
func _get_action_key_label(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		var key_event: InputEventKey = event as InputEventKey
		if key_event:
			return key_event.as_text_physical_keycode()
	return "?"
