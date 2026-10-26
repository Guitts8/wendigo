class_name HidingSpot
extends Area3D
## Esconderijo: o jogador dentro desta área conta como escondido.
## O id identifica o lugar no registro do tutorial (o wendigo checa os favoritos).
## Máscara de colisão: camada "player".

@export var spot_id: StringName = &""


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	var player: Player = body as Player
	if player:
		player.enter_hiding_spot(self)
		Events.hiding_spot_entered.emit(spot_id, global_position)


func _on_body_exited(body: Node3D) -> void:
	var player: Player = body as Player
	if player:
		player.exit_hiding_spot(self)
		Events.hiding_spot_exited.emit(spot_id, global_position)
