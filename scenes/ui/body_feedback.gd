class_name BodyFeedback
extends CanvasLayer
## HUD mínimo: o estado do corpo aparece na câmera, não em barras.
## Frio: vinheta, tom azulado, dessaturação, visão turva e tremor.
## Fome: tremor e visão escurecendo em pulsos. Respiração visível no frio.

@export var camera: Camera3D
@export var breath: GPUParticles3D

@export_group("Frio")
## Abaixo deste calor os efeitos começam.
@export var cold_effects_below: float = 60.0
## Abaixo deste calor o corpo treme.
@export var shiver_below: float = 30.0
## Abaixo deste calor a visão começa a apagar.
@export var blackout_below: float = 10.0

@export_group("Fome")
@export var starving_effects_below: float = 15.0

@export_group("Tremor e respiração")
@export var max_shake_degrees: float = 1.2
@export var breath_interval: float = 3.5
@export var breath_interval_exerting: float = 1.8
## Com calor abaixo disto a respiração aparece mesmo no abrigo.
@export var breath_below_warmth: float = 50.0

var _material: ShaderMaterial
var _noise: FastNoiseLite = FastNoiseLite.new()
var _time: float = 0.0
var _breath_timer: float = 0.0

@onready var _overlay: ColorRect = $Overlay


func _ready() -> void:
	_material = _overlay.material as ShaderMaterial
	_noise.seed = randi()
	_noise.frequency = 1.0


func _process(delta: float) -> void:
	_time += delta
	var warmth: float = SurvivalStats.get_value(SurvivalStats.Stat.WARMTH)
	var hunger: float = SurvivalStats.get_value(SurvivalStats.Stat.HUNGER)
	var cold: float = _below(warmth, cold_effects_below)
	var blackout: float = _below(warmth, blackout_below)
	var starving: float = _below(hunger, starving_effects_below)
	var hunger_pulse: float = starving * (0.5 + 0.5 * sin(_time * 2.0))

	_material.set_shader_parameter(&"vignette", clampf(cold * 0.8 + starving * 0.3, 0.0, 1.0))
	_material.set_shader_parameter(&"desaturation", cold * 0.6)
	_material.set_shader_parameter(&"tint_amount", cold * 0.5)
	_material.set_shader_parameter(&"blur", cold * cold * 2.5)
	_material.set_shader_parameter(&"darkness", maxf(blackout * 0.6, hunger_pulse * 0.25))

	if SurvivalStats.is_dead:
		return
	_update_shake(maxf(_below(warmth, shiver_below), starving))
	_update_breath(delta, warmth)


## 0 com o valor no limite ou acima, 1 com o valor em zero.
func _below(value: float, limit: float) -> float:
	return clampf((limit - value) / limit, 0.0, 1.0)


func _update_shake(strength: float) -> void:
	if camera == null:
		return
	var amplitude: float = deg_to_rad(max_shake_degrees) * strength
	camera.rotation.x = _noise.get_noise_2d(_time * 25.0, 0.0) * amplitude
	camera.rotation.z = _noise.get_noise_2d(0.0, _time * 25.0) * amplitude


func _update_breath(delta: float, warmth: float) -> void:
	if breath == null:
		return
	if not SurvivalStats.is_cold_exposed() and warmth >= breath_below_warmth:
		_breath_timer = 0.0
		return
	_breath_timer -= delta
	if _breath_timer <= 0.0:
		_breath_timer = breath_interval_exerting if SurvivalStats.is_exerting else breath_interval
		breath.restart()
