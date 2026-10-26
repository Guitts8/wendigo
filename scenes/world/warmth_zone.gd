class_name WarmthZone
extends Area3D
## Área que muda o calor do jogador: fonte de calor (fogueira) e/ou abrigo
## (corta vento e nevasca). O jogador soma todas as zonas em que está.
## Máscara de colisão: camada "player".

## Calor ganho por segundo com a fonte em força total.
@export var heat_per_second: float = 0.0
@export var is_shelter: bool = false
## Se definido, o calor acompanha a intensidade da fogueira (zero apagada).
@export var campfire: Campfire


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func get_heat() -> float:
	if campfire:
		return heat_per_second * campfire.get_intensity()
	return heat_per_second


func _on_body_entered(body: Node3D) -> void:
	var player: Player = body as Player
	if player:
		player.enter_warmth_zone(self)


func _on_body_exited(body: Node3D) -> void:
	var player: Player = body as Player
	if player:
		player.exit_warmth_zone(self)
