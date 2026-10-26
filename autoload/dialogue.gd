extends Node
## Falas com legenda, carregadas de data/dialogue/*.json no formato:
##   { "chave": [ { "speaker": "Colega", "text": "...", "audio": "res://...", "duration": 0 } ] }
## "speaker" vazio ou ausente = pensamento do jogador; "audio" e "duration" são opcionais.
## play() enfileira a sequência depois da que estiver tocando.

signal line_started(line: DialogueLine)
signal line_finished(line: DialogueLine)
signal sequence_finished(key: StringName)

const DIALOGUE_FILES: PackedStringArray = ["res://data/dialogue/tutorial.json"]

var current_line: DialogueLine = null

var _sequences: Dictionary[StringName, Array] = {}
var _queue: Array[DialogueLine] = []
var _time_left: float = 0.0
var _audio: AudioStreamPlayer


func _ready() -> void:
	_audio = AudioStreamPlayer.new()
	add_child(_audio)
	for path: String in DIALOGUE_FILES:
		_load_file(path)


func _process(delta: float) -> void:
	if current_line == null:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_finish_current()


func has_sequence(key: StringName) -> bool:
	return _sequences.has(key)


func is_playing() -> bool:
	return current_line != null


## Toca a sequência. interrupt = true descarta o que estiver tocando ou na fila.
func play(key: StringName, interrupt: bool = false) -> bool:
	if not has_sequence(key):
		push_warning("Diálogo inexistente: %s" % key)
		return false
	if interrupt:
		stop()
	_queue.append_array(_sequences[key])
	if current_line == null:
		_start_next()
	return true


func stop() -> void:
	_queue.clear()
	_audio.stop()
	if current_line:
		var line: DialogueLine = current_line
		current_line = null
		line_finished.emit(line)


func _finish_current() -> void:
	var line: DialogueLine = current_line
	current_line = null
	line_finished.emit(line)
	if line.is_last_in_sequence:
		sequence_finished.emit(line.sequence_key)
	_start_next()


func _start_next() -> void:
	if _queue.is_empty():
		return
	current_line = _queue.pop_front()
	_time_left = current_line.get_duration()
	if current_line.audio:
		_audio.stream = current_line.audio
		_audio.play()
	line_started.emit(current_line)


func _load_file(path: String) -> void:
	var json: JSON = load(path) as JSON
	if json == null or not json.data is Dictionary:
		push_error("Arquivo de diálogo inválido: %s" % path)
		return
	var data: Dictionary = json.data
	for raw_key: Variant in data:
		var key: StringName = StringName(str(raw_key))
		var lines: Array[DialogueLine] = []
		for entry: Variant in data[raw_key]:
			if entry is Dictionary:
				lines.append(_make_line(key, entry))
		if lines.is_empty():
			continue
		lines[-1].is_last_in_sequence = true
		_sequences[key] = lines


func _make_line(key: StringName, entry: Dictionary) -> DialogueLine:
	var line: DialogueLine = DialogueLine.new()
	line.sequence_key = key
	line.speaker = str(entry.get("speaker", ""))
	line.text = str(entry.get("text", ""))
	line.duration = float(entry.get("duration", 0.0))
	var audio_path: String = str(entry.get("audio", ""))
	if not audio_path.is_empty():
		line.audio = load(audio_path) as AudioStream
	return line
