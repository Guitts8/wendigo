extends Node
## Relógio do mundo: hora do dia, fases do dia e nevascas.
##
## Só guarda o estado. O DayNightCycle de cada nível aplica isso no sol,
## no céu e na neblina. Os ajustes ficam em world_clock.tscn.

enum DayPhase { DAWN, DAY, DUSK, NIGHT }

signal phase_changed(phase: DayPhase)
signal new_day(day: int)
signal blizzard_changed(active: bool)

const HOURS_PER_DAY: float = 24.0

## Duração de um dia inteiro em segundos reais (1440 = 24 min, 1 h de jogo = 1 min).
@export var day_length_seconds: float = 1440.0
@export_range(0.0, 24.0) var start_hour: float = 8.0

@export_group("Fases (hora de início)")
@export_range(0.0, 24.0) var dawn_hour: float = 5.0
@export_range(0.0, 24.0) var day_hour: float = 7.0
@export_range(0.0, 24.0) var dusk_hour: float = 17.0
@export_range(0.0, 24.0) var night_hour: float = 19.0

@export_group("Nevasca")
@export var blizzards_enabled: bool = true
## Chance de começar uma nevasca a cada hora de jogo.
@export_range(0.0, 1.0) var blizzard_chance_per_hour: float = 0.08
@export var blizzard_min_hours: float = 1.0
@export var blizzard_max_hours: float = 3.0
## Segundos reais para a nevasca chegar à força total (ou sumir).
@export var blizzard_ramp_seconds: float = 20.0

var hour: float = 0.0
var day: int = 1
var phase: DayPhase = DayPhase.NIGHT
var running: bool = false
var is_blizzard: bool = false
## 0 = céu limpo, 1 = nevasca total. Sobe e desce aos poucos.
var blizzard_intensity: float = 0.0

var _blizzard_hours_left: float = 0.0


func _process(delta: float) -> void:
	if not running:
		return
	advance_hours(delta * HOURS_PER_DAY / day_length_seconds)
	var target: float = 1.0 if is_blizzard else 0.0
	blizzard_intensity = move_toward(blizzard_intensity, target, delta / maxf(blizzard_ramp_seconds, 0.01))


func reset() -> void:
	hour = start_hour
	day = 1
	phase = _compute_phase(hour)
	is_blizzard = false
	blizzard_intensity = 0.0
	_blizzard_hours_left = 0.0
	running = true


func advance_hours(hours: float) -> void:
	var previous_whole_hour: int = floori(hour)
	hour += hours
	while hour >= HOURS_PER_DAY:
		hour -= HOURS_PER_DAY
		day += 1
		new_day.emit(day)
	_update_blizzard(hours, floori(hour) != previous_whole_hour)
	var new_phase: DayPhase = _compute_phase(hour)
	if new_phase != phase:
		phase = new_phase
		phase_changed.emit(phase)


## Liga ou desliga a nevasca. Duração negativa = sorteada entre o mínimo e o máximo.
func set_blizzard(active: bool, duration_hours: float = -1.0) -> void:
	if active == is_blizzard:
		return
	is_blizzard = active
	if active:
		_blizzard_hours_left = duration_hours if duration_hours > 0.0 else randf_range(blizzard_min_hours, blizzard_max_hours)
	else:
		_blizzard_hours_left = 0.0
	blizzard_changed.emit(active)


## Altura do sol de -1 (meia-noite) a 1 (meio-dia); 0 às 6 h e às 18 h.
func get_sun_elevation() -> float:
	return sin((hour - 6.0) / HOURS_PER_DAY * TAU)


## 0 = dia claro, 1 = noite fechada, com transição suave no amanhecer e no entardecer.
func get_night_factor() -> float:
	return 1.0 - smoothstep(-0.15, 0.15, get_sun_elevation())


func get_time_text() -> String:
	return "%02d:%02d" % [floori(hour), floori(fmod(hour, 1.0) * 60.0)]


func _update_blizzard(hours: float, crossed_hour: bool) -> void:
	if is_blizzard:
		_blizzard_hours_left -= hours
		if _blizzard_hours_left <= 0.0:
			set_blizzard(false)
	elif crossed_hour and blizzards_enabled and randf() < blizzard_chance_per_hour:
		set_blizzard(true)


func _compute_phase(at_hour: float) -> DayPhase:
	if at_hour >= night_hour or at_hour < dawn_hour:
		return DayPhase.NIGHT
	if at_hour < day_hour:
		return DayPhase.DAWN
	if at_hour < dusk_hour:
		return DayPhase.DAY
	return DayPhase.DUSK
