extends CanvasLayer
## Tela preta para transições (dormir, cenas do tutorial). Fica acima do jogo
## e abaixo da tela de morte. Ignora Engine.time_scale (o sono acelera o tempo).

var _tween: Tween

@onready var _black: ColorRect = $Black


func _ready() -> void:
	set_black(false)


func is_black() -> bool:
	return _black.modulate.a >= 0.999


func set_black(value: bool) -> void:
	if _tween:
		_tween.kill()
	_black.modulate.a = 1.0 if value else 0.0


## Escurece até o preto. Use com await.
func fade_out(duration: float) -> void:
	await _fade_to(1.0, duration)


## Clareia a partir do preto. Use com await.
func fade_in(duration: float) -> void:
	await _fade_to(0.0, duration)


func _fade_to(alpha: float, duration: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_ignore_time_scale(true)
	_tween.tween_property(_black, ^"modulate:a", alpha, maxf(duration, 0.01))
	await _tween.finished
