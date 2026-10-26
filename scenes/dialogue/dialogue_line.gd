class_name DialogueLine
extends Resource
## Uma fala com legenda. Fala sem "speaker" é pensamento do jogador.
## O áudio é opcional: sem ele, a duração vem do tamanho do texto.

const BASE_DURATION: float = 1.2
const SECONDS_PER_CHAR: float = 0.055
const MIN_DURATION: float = 2.0
const MAX_DURATION: float = 8.0

@export var speaker: String = ""
@export_multiline var text: String = ""
@export var audio: AudioStream
## Segundos na tela; 0 = automático.
@export var duration: float = 0.0

# Preenchidos pelo autoload Dialogue ao carregar.
var sequence_key: StringName = &""
var is_last_in_sequence: bool = false


func is_thought() -> bool:
	return speaker.is_empty()


func get_duration() -> float:
	if duration > 0.0:
		return duration
	if audio:
		return audio.get_length() + 0.3
	return clampf(BASE_DURATION + text.length() * SECONDS_PER_CHAR, MIN_DURATION, MAX_DURATION)
