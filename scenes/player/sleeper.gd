class_name Sleeper
extends Node
## Dormir: tela preta e o tempo acelerado até a hora de acordar. Tudo continua
## valendo durante o sono (o fogo queima, o frio e a fome caem), então dá para
## acordar com frio ou nem acordar.

signal woke_up(hours: float)

@export var player: Player
@export_range(0.0, 24.0) var wake_hour: float = 7.0
## Multiplicador de Engine.time_scale enquanto dorme (8 h de jogo ≈ 6 s).
@export var sleep_time_scale: float = 80.0
@export var fade_duration: float = 1.5

var is_sleeping: bool = false


func _ready() -> void:
	SurvivalStats.died.connect(_on_died)


func sleep(bed: Bed) -> void:
	if is_sleeping:
		return
	is_sleeping = true
	player.input_enabled = false
	await ScreenFade.fade_out(fade_duration)

	var start_time: float = _absolute_hours()
	var wake_time: float = _next_wake_time()
	Engine.time_scale = sleep_time_scale
	SurvivalStats.is_sleeping = true
	while _absolute_hours() < wake_time and not SurvivalStats.is_dead:
		await get_tree().process_frame
	Engine.time_scale = 1.0
	SurvivalStats.is_sleeping = false
	if SurvivalStats.is_dead:
		return

	var hours: float = _absolute_hours() - start_time
	Events.slept.emit(bed.bed_id, bed.global_position, hours)
	await ScreenFade.fade_in(fade_duration)
	is_sleeping = false
	player.input_enabled = true
	woke_up.emit(hours)


func _absolute_hours() -> float:
	return WorldClock.day * WorldClock.HOURS_PER_DAY + WorldClock.hour


func _next_wake_time() -> float:
	var today_wake: float = WorldClock.day * WorldClock.HOURS_PER_DAY + wake_hour
	if WorldClock.hour < wake_hour:
		return today_wake
	return today_wake + WorldClock.HOURS_PER_DAY


func _on_died(_cause: int) -> void:
	Engine.time_scale = 1.0
	SurvivalStats.is_sleeping = false
