extends Node
## Estado de sobrevivência do personagem atual: Calor, Fome, Luz e Corrupção.
##
## Valores de 0 a 100. "Fome" é a saciedade: 100 = alimentado, 0 = morrendo de fome.
## O jogador informa o contexto do corpo (abrigo, calor ambiente, esforço) a cada
## frame; o WorldClock informa noite e nevasca. Os ajustes ficam em survival_stats.tscn.

enum Stat { WARMTH, HUNGER, LIGHT, CORRUPTION }
enum DeathCause { COLD, STARVATION, WENDIGO }

## O estágio de um recurso mudou. Calor/Fome/Luz: 0 = bem, 3 = crítico.
## Corrupção: 0 = nenhuma, 1 leve, 2 média, 3 alta, 4 total.
signal stage_changed(stat: Stat, stage: int)
signal light_depleted
signal died(cause: DeathCause)

const MAX_VALUE: float = 100.0

@export_group("Valores iniciais")
@export_range(0.0, 100.0) var start_warmth: float = 100.0
@export_range(0.0, 100.0) var start_hunger: float = 80.0
@export_range(0.0, 100.0) var start_light: float = 100.0
@export_range(0.0, 100.0) var start_corruption: float = 0.0

@export_group("Calor")
## Perda por segundo ao ar livre, de dia, sem nevasca (0.21 ≈ zera em 8 min).
@export var outdoor_warmth_loss: float = 0.21
## Perda por segundo dentro de um abrigo.
@export var shelter_warmth_loss: float = 0.05
@export var night_cold_multiplier: float = 2.0
## Só vale ao ar livre: o abrigo corta o vento.
@export var blizzard_cold_multiplier: float = 2.0
## Com a fome zerada, o calor cai mais rápido.
@export var starving_cold_multiplier: float = 1.5
## Abaixo de cada limite, o estágio sobe (com frio, congelando, hipotermia).
@export var warmth_stage_thresholds: PackedFloat32Array = PackedFloat32Array([60.0, 30.0, 10.0])
## Abaixo deste calor o movimento fica mais lento.
@export var slow_below_warmth: float = 30.0
@export_range(0.1, 1.0) var min_speed_multiplier: float = 0.6

@export_group("Fome")
## Perda por segundo em repouso (0.067 ≈ zera em 25 min).
@export var hunger_loss: float = 0.067
@export var exertion_hunger_multiplier: float = 1.6
## Aplicado quando o calor está no estágio 2 (congelando) ou pior.
@export var cold_hunger_multiplier: float = 1.3
## Segundos com a fome zerada até morrer. 0 = morte imediata.
@export var starvation_grace_seconds: float = 60.0
@export var hunger_stage_thresholds: PackedFloat32Array = PackedFloat32Array([60.0, 30.0, 10.0])
@export_range(0.1, 1.0) var starving_speed_multiplier: float = 0.85

@export_group("Luz")
## Gasto por segundo com o lampião aceso (0.28 ≈ 6 min).
@export var lantern_light_loss: float = 0.28
@export var light_stage_thresholds: PackedFloat32Array = PackedFloat32Array([50.0, 15.0, 0.001])

@export_group("Corrupção")
## Ao atingir cada limite, o estágio sobe: leve, média, alta, total.
@export var corruption_stage_thresholds: PackedFloat32Array = PackedFloat32Array([25.0, 50.0, 75.0, 100.0])

# Contexto do corpo, definido a cada frame por quem conhece o mundo (o jogador).
var environment_heat: float = 0.0
var is_sheltered: bool = false
var is_exerting: bool = false
var lantern_on: bool = false

## Só drena com uma partida em andamento (o jogador chama reset()).
var active: bool = false
var is_dead: bool = false

var _values: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var _stages: PackedInt32Array = PackedInt32Array([0, 0, 0, 0])
var _rates: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var _starvation_time: float = 0.0


func _process(delta: float) -> void:
	if not active or is_dead:
		return
	_rates[Stat.WARMTH] = _compute_warmth_rate()
	_rates[Stat.HUNGER] = _compute_hunger_rate()
	_rates[Stat.LIGHT] = -lantern_light_loss if lantern_on else 0.0
	add(Stat.WARMTH, _rates[Stat.WARMTH] * delta)
	add(Stat.HUNGER, _rates[Stat.HUNGER] * delta)
	add(Stat.LIGHT, _rates[Stat.LIGHT] * delta)

	_update_starvation(delta)
	if get_value(Stat.WARMTH) <= 0.0:
		kill(DeathCause.COLD)


## Começa uma partida nova com os valores iniciais.
func reset() -> void:
	_values = PackedFloat32Array([start_warmth, start_hunger, start_light, start_corruption])
	for stat: int in Stat.values():
		_stages[stat] = _compute_stage(stat, _values[stat])
		_rates[stat] = 0.0
	environment_heat = 0.0
	is_sheltered = false
	is_exerting = false
	lantern_on = false
	_starvation_time = 0.0
	is_dead = false
	active = true


func get_value(stat: Stat) -> float:
	return _values[stat]


func get_stage(stat: Stat) -> int:
	return _stages[stat]


## Variação por segundo no último frame (para depuração).
func get_rate(stat: Stat) -> float:
	return _rates[stat]


func set_value(stat: Stat, value: float) -> void:
	var old_value: float = _values[stat]
	var new_value: float = clampf(value, 0.0, MAX_VALUE)
	_values[stat] = new_value
	if stat == Stat.LIGHT and old_value > 0.0 and new_value <= 0.0:
		light_depleted.emit()
	var stage: int = _compute_stage(stat, new_value)
	if stage != _stages[stat]:
		_stages[stat] = stage
		stage_changed.emit(stat, stage)


func add(stat: Stat, amount: float) -> void:
	set_value(stat, get_value(stat) + amount)


func consume_food(food: FoodData) -> void:
	add(Stat.HUNGER, food.hunger_restore)
	add(Stat.WARMTH, food.warmth_restore)
	add(Stat.CORRUPTION, food.corruption_gain)


## Multiplicador de velocidade do jogador (frio e fome deixam lento).
func get_speed_multiplier() -> float:
	var multiplier: float = 1.0
	var warmth: float = get_value(Stat.WARMTH)
	if warmth < slow_below_warmth:
		multiplier = lerpf(min_speed_multiplier, 1.0, warmth / slow_below_warmth)
	if get_value(Stat.HUNGER) <= 0.0:
		multiplier *= starving_speed_multiplier
	return multiplier


## Ao ar livre e longe de qualquer fonte de calor.
func is_cold_exposed() -> bool:
	return not is_sheltered and environment_heat <= 0.0


func kill(cause: DeathCause) -> void:
	if is_dead:
		return
	is_dead = true
	died.emit(cause)


func _compute_warmth_rate() -> float:
	var loss: float = shelter_warmth_loss
	if not is_sheltered:
		loss = outdoor_warmth_loss * lerpf(1.0, blizzard_cold_multiplier, WorldClock.blizzard_intensity)
	loss *= lerpf(1.0, night_cold_multiplier, WorldClock.get_night_factor())
	if get_value(Stat.HUNGER) <= 0.0:
		loss *= starving_cold_multiplier
	return environment_heat - loss


func _compute_hunger_rate() -> float:
	var loss: float = hunger_loss
	if is_exerting:
		loss *= exertion_hunger_multiplier
	if get_stage(Stat.WARMTH) >= 2:
		loss *= cold_hunger_multiplier
	return -loss


func _update_starvation(delta: float) -> void:
	if get_value(Stat.HUNGER) > 0.0:
		_starvation_time = 0.0
		return
	_starvation_time += delta
	if _starvation_time >= starvation_grace_seconds:
		kill(DeathCause.STARVATION)


func _compute_stage(stat: Stat, value: float) -> int:
	var stage: int = 0
	if stat == Stat.CORRUPTION:
		for threshold: float in corruption_stage_thresholds:
			if value >= threshold:
				stage += 1
		return stage
	for threshold: float in _get_descending_thresholds(stat):
		if value < threshold:
			stage += 1
	return stage


func _get_descending_thresholds(stat: Stat) -> PackedFloat32Array:
	match stat:
		Stat.WARMTH:
			return warmth_stage_thresholds
		Stat.HUNGER:
			return hunger_stage_thresholds
		Stat.LIGHT:
			return light_stage_thresholds
	return PackedFloat32Array()
