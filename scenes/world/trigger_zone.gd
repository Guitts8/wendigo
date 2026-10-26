class_name TriggerZone
extends Area3D
## Área do roteiro: avisa no Events quando o jogador entra.
## Máscara de colisão: camada "player".

@export var trigger_id: StringName = &""
## Dispara só na primeira vez.
@export var one_shot: bool = true

var _fired: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body is Player or (one_shot and _fired):
		return
	_fired = true
	Events.trigger_entered.emit(trigger_id)
