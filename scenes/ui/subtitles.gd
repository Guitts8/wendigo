class_name Subtitles
extends CanvasLayer
## Legendas das falas do autoload Dialogue. Pensamentos do jogador em itálico.

@onready var _panel: Control = $Root/Panel
@onready var _label: RichTextLabel = %Text


func _ready() -> void:
	_panel.visible = false
	Dialogue.line_started.connect(_on_line_started)
	Dialogue.line_finished.connect(_on_line_finished)


func _on_line_started(line: DialogueLine) -> void:
	var text: String = line.text.replace("[", "[lb]")
	if line.is_thought():
		_label.text = "[center][i]%s[/i][/center]" % text
	else:
		_label.text = "[center][b]%s:[/b] %s[/center]" % [line.speaker, text]
	_panel.visible = true


func _on_line_finished(_line: DialogueLine) -> void:
	_panel.visible = false
