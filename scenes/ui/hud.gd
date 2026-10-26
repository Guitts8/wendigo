class_name Hud
extends CanvasLayer
## HUD mínimo: só a mira e o texto de interação.
## Medidores ficam no diário/inventário (Fase 2), nunca fixos na tela.

@export var interactor: Interactor

var _interact_key: String = ""

@onready var _prompt_label: Label = %PromptLabel


func _ready() -> void:
	_interact_key = _get_action_key_label(&"interact")


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


## Nome da primeira tecla ligada à ação (posição física, layout US).
func _get_action_key_label(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		var key_event: InputEventKey = event as InputEventKey
		if key_event:
			return key_event.as_text_physical_keycode()
	return "?"
