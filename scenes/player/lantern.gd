class_name Lantern
extends Node3D
## Lampião do jogador. Ilumina em volta (não numa direção só), gasta Luz
## enquanto aceso, apaga sozinho quando o combustível acaba e falha perto do fim.
## Aceso, aparece na mão; apagado, fica guardado.

@export var player: Player
## Abaixo desta Luz a chama começa a falhar.
@export var low_light_threshold: float = 15.0
@export var light_energy: float = 1.6
@export var glass_emission_energy: float = 2.0
## Oscilação normal da chama (0 = luz parada).
@export var flame_flicker: float = 0.08

var is_on: bool = false

var _noise: FastNoiseLite = FastNoiseLite.new()
var _time: float = 0.0
var _glass_material: StandardMaterial3D

@onready var _light: OmniLight3D = $Light
@onready var _model: Node3D = $Model
@onready var _glass: MeshInstance3D = $Model/Glass


func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 1.0
	_glass_material = _glass.mesh.surface_get_material(0) as StandardMaterial3D
	_apply_visibility()
	SurvivalStats.light_depleted.connect(_on_light_depleted)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"lantern") or not player.input_enabled:
		return
	get_viewport().set_input_as_handled()
	if is_on:
		set_on(false)
	elif SurvivalStats.get_value(SurvivalStats.Stat.LIGHT) > 0.0:
		set_on(true)


func _process(delta: float) -> void:
	if not is_on:
		return
	_time += delta
	var strength: float = 1.0 + _noise.get_noise_1d(_time * 8.0) * flame_flicker
	var light: float = SurvivalStats.get_value(SurvivalStats.Stat.LIGHT)
	if light < low_light_threshold:
		# A chama engasga, mais forte quanto mais perto do fim.
		var sputter: float = _noise.get_noise_1d(_time * 12.0 + 100.0) * 0.5 + 0.5
		strength *= lerpf(1.0, sputter, 1.0 - light / low_light_threshold)
	_light.light_energy = light_energy * strength
	if _glass_material:
		_glass_material.emission_energy_multiplier = glass_emission_energy * strength


func set_on(value: bool) -> void:
	if value == is_on:
		return
	is_on = value
	_apply_visibility()
	SurvivalStats.lantern_on = is_on
	Events.lantern_toggled.emit(is_on, global_position)


func _apply_visibility() -> void:
	_light.visible = is_on
	_model.visible = is_on


func _on_light_depleted() -> void:
	set_on(false)
