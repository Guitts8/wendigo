class_name Campfire
extends Interactable
## Fogueira: recebe lenha do inventário, acende e queima o combustível com o tempo.
## Lenha numa fogueira apagada já acende (fósforos/isqueiro podem entrar depois).

signal lit_changed(is_lit: bool)

@export var fuel_item_id: StringName = &"firewood"
## Segundos de fogo que cada lenha adiciona.
@export var fuel_per_item: float = 90.0
## Combustível máximo em segundos.
@export var max_fuel: float = 300.0
## Se true, começa acesa com uma lenha.
@export var start_lit: bool = false

@export_group("Luz")
@export var base_light_energy: float = 2.5
## Abaixo desta quantidade de combustível (s) o fogo começa a enfraquecer.
@export var low_fuel_threshold: float = 30.0
@export var flicker_strength: float = 0.2
@export var flicker_speed: float = 6.0

@export_group("Textos")
@export var add_fuel_text: String = "Colocar lenha"
@export var need_fuel_text: String = "Precisa de lenha"
@export var full_text: String = "A fogueira está cheia"

var fuel: float = 0.0
var is_lit: bool = false

var _noise: FastNoiseLite = FastNoiseLite.new()
var _time: float = 0.0

@onready var _flames: GPUParticles3D = $Flames
@onready var _light: OmniLight3D = $FireLight


func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 1.0
	if start_lit:
		fuel = fuel_per_item
		_set_lit(true)
	else:
		_set_lit(false)


func _process(delta: float) -> void:
	if not is_lit:
		return
	fuel = maxf(fuel - delta, 0.0)
	if fuel <= 0.0:
		_set_lit(false)
		return
	_update_fire_visuals(delta)


func get_prompt(player: Player) -> String:
	if _is_full():
		return full_text
	if not player.inventory.has(fuel_item_id):
		return need_fuel_text
	return add_fuel_text if is_lit else prompt_text


func can_interact(player: Player) -> bool:
	return not _is_full() and player.inventory.has(fuel_item_id)


func interact(player: Player) -> void:
	if not can_interact(player):
		return
	player.inventory.remove(fuel_item_id)
	fuel = minf(fuel + fuel_per_item, max_fuel)
	if not is_lit:
		_set_lit(true)


## Intensidade do fogo de 0 a 1. Útil para calor (Fase 2) e medo do wendigo (Fase 4).
func get_intensity() -> float:
	if not is_lit:
		return 0.0
	return clampf(fuel / low_fuel_threshold, 0.0, 1.0)


func _is_full() -> bool:
	return fuel + fuel_per_item > max_fuel


func _set_lit(value: bool) -> void:
	var changed: bool = value != is_lit
	is_lit = value
	_flames.emitting = is_lit
	_light.visible = is_lit
	if is_lit:
		_update_fire_visuals(0.0)
	if not changed:
		return
	lit_changed.emit(is_lit)
	if is_lit:
		Events.campfire_lit.emit(self)
	else:
		Events.campfire_extinguished.emit(self)


func _update_fire_visuals(delta: float) -> void:
	_time += delta
	var intensity: float = lerpf(0.3, 1.0, get_intensity())
	var flicker: float = 1.0 + _noise.get_noise_1d(_time * flicker_speed) * flicker_strength
	_light.light_energy = base_light_energy * intensity * flicker
	_flames.amount_ratio = intensity
