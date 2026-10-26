class_name TutorialDirector
extends Node
## Roteiro do tutorial (Ato 1). Etapa 3a: dia 1 completo e o começo do dia 2.
##
## Cada etapa define a anotação do diário e o lembrete que o colega repete ao
## conversar, toca uma fala de instrução ao começar e avança ouvindo o Events.
## Se o jogador já cumpriu uma etapa antes da hora, ela é pulada em silêncio.

enum Step { INTRO, GATHER_WOOD, LIGHT_FIRE, EAT, TREAT, SLEEP, DAY_TWO }

const OBJECTIVES: Dictionary = {
	Step.GATHER_WOOD: "Pegar lenha lá fora (%d/%d)",
	Step.LIGHT_FIRE: "Acender a lareira",
	Step.EAT: "Comer alguma coisa (Tab)",
	Step.TREAT: "Fazer curativo na perna do colega (Tab, perto dele)",
	Step.SLEEP: "Pôr lenha na lareira e dormir",
	Step.DAY_TWO: "Fim da etapa 3a",
}
## Fala tocada ao entrar na etapa.
const INSTRUCTIONS: Dictionary = {
	Step.LIGHT_FIRE: &"instr_fire",
	Step.EAT: &"instr_eat",
	Step.TREAT: &"instr_treat",
	Step.SLEEP: &"instr_sleep",
	Step.DAY_TWO: &"day2_morning",
}
## Fala que o colega repete quando o jogador conversa com ele.
const REMINDERS: Dictionary = {
	Step.GATHER_WOOD: &"remind_wood",
	Step.LIGHT_FIRE: &"remind_fire",
	Step.EAT: &"remind_eat",
	Step.TREAT: &"remind_treat",
	Step.SLEEP: &"remind_sleep",
}

@export var player: Player
@export var companion: Companion
@export var hearth: Campfire
@export var player_bed: Bed

@export_group("Início")
@export_range(0.0, 24.0) var start_hour: float = 14.0
@export_range(0.0, 1.0) var blizzard_strength: float = 0.6
@export_range(0.0, 100.0) var start_warmth: float = 70.0
@export_range(0.0, 100.0) var start_hunger: float = 55.0
@export_range(0.0, 100.0) var start_light: float = 60.0
@export var intro_fade_seconds: float = 3.0

@export_group("Etapas")
@export var wood_needed: int = 3
@export var bed_locked_text: String = "Ainda tem coisa pra fazer"
## Gatilhos do mapa (TriggerZone) → fala tocada.
@export var trigger_lines: Dictionary[StringName, StringName] = {
	&"trail_blocked": &"trail_blocked",
	&"lake": &"lake_seen",
}

var step: Step = Step.INTRO

var _wood_collected: int = 0
var _has_eaten: bool = false


func _ready() -> void:
	Events.item_picked_up.connect(_on_item_picked_up)
	Events.campfire_lit.connect(_on_campfire_lit)
	Events.food_eaten.connect(_on_food_eaten)
	Events.companion_cared.connect(_on_companion_cared)
	Events.slept.connect(_on_slept)
	Events.trigger_entered.connect(_on_trigger_entered)
	Dialogue.sequence_finished.connect(_on_sequence_finished)
	_start.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed(&"debug_skip_step"):
		_debug_skip_step()
		get_viewport().set_input_as_handled()


func _start() -> void:
	WorldClock.set_hour(start_hour)
	WorldClock.blizzards_enabled = false
	WorldClock.set_blizzard(true, 10000.0, blizzard_strength)
	WorldClock.blizzard_intensity = blizzard_strength
	SurvivalStats.set_value(SurvivalStats.Stat.WARMTH, start_warmth)
	SurvivalStats.set_value(SurvivalStats.Stat.HUNGER, start_hunger)
	SurvivalStats.set_value(SurvivalStats.Stat.LIGHT, start_light)
	player_bed.lock_text = bed_locked_text
	ScreenFade.set_black(true)
	Dialogue.play(&"intro", true)
	await ScreenFade.fade_in(intro_fade_seconds)


func _go_to(new_step: Step) -> void:
	step = new_step
	companion.reminder_key = REMINDERS.get(step, &"")
	_emit_objective()
	if _is_step_done(step):
		_go_to((step + 1) as Step)
		return
	if INSTRUCTIONS.has(step):
		Dialogue.play(INSTRUCTIONS[step])
	match step:
		Step.SLEEP:
			player_bed.lock_text = ""
			player_bed.sleep_unlocked = true
		Step.DAY_TWO:
			player_bed.sleep_unlocked = false
			companion.start_new_day()
			companion.set_condition(Companion.Condition.FEVER)


func _complete(done_step: Step) -> void:
	if step == done_step:
		_go_to((step + 1) as Step)


## Etapas que podem ter sido cumpridas antes de o roteiro pedir.
func _is_step_done(check_step: Step) -> bool:
	match check_step:
		Step.GATHER_WOOD:
			return _wood_collected >= wood_needed or hearth.is_lit
		Step.LIGHT_FIRE:
			return hearth.is_lit
		Step.EAT:
			return _has_eaten
		Step.TREAT:
			return companion.times_treated > 0
	return false


func _emit_objective() -> void:
	var text: String = OBJECTIVES.get(step, "")
	if step == Step.GATHER_WOOD:
		text = text % [mini(_wood_collected, wood_needed), wood_needed]
	Events.objective_changed.emit(text)


func _on_sequence_finished(key: StringName) -> void:
	if key == &"intro" and step == Step.INTRO:
		_go_to(Step.GATHER_WOOD)


func _on_item_picked_up(item_id: StringName, amount: int, _world_position: Vector3) -> void:
	if item_id != hearth.fuel_item_id:
		return
	_wood_collected += amount
	if step != Step.GATHER_WOOD:
		return
	if _wood_collected >= wood_needed:
		_complete(Step.GATHER_WOOD)
	else:
		if _wood_collected == amount:
			Dialogue.play(&"wood_first")
		_emit_objective()


func _on_campfire_lit(campfire: Campfire) -> void:
	if campfire != hearth:
		return
	if step == Step.GATHER_WOOD:
		_complete(Step.GATHER_WOOD)
	_complete(Step.LIGHT_FIRE)


func _on_food_eaten(_item_id: StringName, _world_position: Vector3) -> void:
	_has_eaten = true
	_complete(Step.EAT)


func _on_companion_cared(kind: StringName) -> void:
	if kind == &"treat":
		_complete(Step.TREAT)


func _on_slept(bed_id: StringName, _world_position: Vector3, _hours: float) -> void:
	if bed_id == player_bed.bed_id:
		_complete(Step.SLEEP)


func _on_trigger_entered(trigger_id: StringName) -> void:
	if trigger_lines.has(trigger_id):
		Dialogue.play(trigger_lines[trigger_id])


## F9 em builds de debug: cumpre a etapa atual na marra.
func _debug_skip_step() -> void:
	match step:
		Step.INTRO:
			Dialogue.stop()
			_go_to(Step.GATHER_WOOD)
		Step.GATHER_WOOD:
			player.inventory.add(hearth.fuel_item_id, wood_needed)
			_wood_collected = wood_needed
			_complete(Step.GATHER_WOOD)
		Step.LIGHT_FIRE:
			player.inventory.add(hearth.fuel_item_id)
			hearth.interact(player)
		Step.EAT:
			_on_food_eaten(&"", Vector3.ZERO)
		Step.TREAT:
			companion.treat()
		Step.SLEEP:
			player.sleeper.sleep(player_bed)
