class_name Bed
extends Interactable
## Cama: dormir pula até a manhã (o Sleeper do jogador acelera o tempo com a
## tela preta, então fogo, frio e fome continuam valendo durante o sono).

@export var bed_id: StringName = &"bed"
## Desligado: cama só decorativa (ex.: a cama do colega).
@export var can_sleep_here: bool = true
## A partir desta hora dá para dormir (até o amanhecer).
@export_range(0.0, 24.0) var sleep_from_hour: float = 19.0
@export var too_early_text: String = "Ainda é cedo para dormir"

## Se não estiver vazio, impede dormir e mostra este texto (usado pelo roteiro).
var lock_text: String = ""
## Libera dormir a qualquer hora (usado pelo roteiro).
var sleep_unlocked: bool = false


func get_prompt(_player: Player) -> String:
	if not can_sleep_here:
		return ""
	if not lock_text.is_empty():
		return lock_text
	if not is_sleep_time():
		return too_early_text
	return prompt_text


func can_interact(player: Player) -> bool:
	return can_sleep_here and lock_text.is_empty() and is_sleep_time() and not player.sleeper.is_sleeping


func interact(player: Player) -> void:
	if can_interact(player):
		player.sleeper.sleep(self)


func is_sleep_time() -> bool:
	return sleep_unlocked or WorldClock.hour >= sleep_from_hour or WorldClock.hour < WorldClock.dawn_hour
