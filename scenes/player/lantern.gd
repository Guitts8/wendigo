class_name Lantern
extends Node3D
## Lanterna do jogador. Gasta Luz enquanto acesa, apaga sozinha quando a Luz
## acaba e começa a falhar perto do fim.

@export var player: Player
## Abaixo desta Luz a lanterna começa a falhar.
@export var low_light_threshold: float = 15.0
@export var spot_energy: float = 3.0
@export var glow_energy: float = 0.4

var is_on: bool = false

var _noise: FastNoiseLite = FastNoiseLite.new()
var _time: float = 0.0

@onready var _spot: SpotLight3D = $Spot
@onready var _glow: OmniLight3D = $Glow


func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 1.0
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
	var strength: float = 1.0
	var light: float = SurvivalStats.get_value(SurvivalStats.Stat.LIGHT)
	if light < low_light_threshold:
		# Falhas bruscas, mais fortes quanto mais perto do fim.
		var flicker: float = _noise.get_noise_1d(_time * 12.0) * 0.5 + 0.5
		strength = lerpf(1.0, flicker, 1.0 - light / low_light_threshold)
	_spot.light_energy = spot_energy * strength
	_glow.light_energy = glow_energy * strength


func set_on(value: bool) -> void:
	if value == is_on:
		return
	is_on = value
	_apply_visibility()
	SurvivalStats.lantern_on = is_on
	Events.lantern_toggled.emit(is_on, global_position)


func _apply_visibility() -> void:
	_spot.visible = is_on
	_glow.visible = is_on


func _on_light_depleted() -> void:
	set_on(false)
