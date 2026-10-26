class_name Interactor
extends RayCast3D
## Raio que sai da câmera, encontra o Interactable mirado e chama interact().
## A máscara deve incluir "world" para que paredes bloqueiem a interação.

signal target_changed(target: Interactable)

@export var player: Player

var current_target: Interactable = null


func _physics_process(_delta: float) -> void:
	var new_target: Interactable = null
	if is_colliding():
		new_target = get_collider() as Interactable
	if new_target != current_target:
		current_target = new_target
		target_changed.emit(current_target)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and can_interact_with_target():
		current_target.interact(player)
		get_viewport().set_input_as_handled()


## Texto para o HUD; vazio quando não há alvo.
func get_prompt_text() -> String:
	if not _has_valid_target():
		return ""
	return current_target.get_prompt(player)


func can_interact_with_target() -> bool:
	return _has_valid_target() and current_target.can_interact(player)


func _has_valid_target() -> bool:
	# O alvo pode ter sido coletado (queue_free) antes do próximo raycast.
	return is_instance_valid(current_target) and not current_target.is_queued_for_deletion()
