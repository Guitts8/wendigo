class_name DebugOverlay
extends CanvasLayer
## Painel de testes (só em builds de debug). F3 mostra os números.
## Atalhos: F4 nevasca, F6 avança 1 hora, F7 tira calor, F8 tira fome.

const DRAIN_AMOUNT: float = 20.0

@onready var _label: Label = $Label


func _ready() -> void:
	visible = false
	if not OS.is_debug_build():
		queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_overlay"):
		visible = not visible
	elif event.is_action_pressed(&"debug_blizzard"):
		WorldClock.set_blizzard(not WorldClock.is_blizzard)
	elif event.is_action_pressed(&"debug_skip_hour"):
		WorldClock.advance_hours(1.0)
	elif event.is_action_pressed(&"debug_drain_warmth"):
		SurvivalStats.add(SurvivalStats.Stat.WARMTH, -DRAIN_AMOUNT)
	elif event.is_action_pressed(&"debug_drain_hunger"):
		SurvivalStats.add(SurvivalStats.Stat.HUNGER, -DRAIN_AMOUNT)
	else:
		return
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not visible:
		return
	var lines: PackedStringArray = [
		"Dia %d  %s  fase %s" % [WorldClock.day, WorldClock.get_time_text(), WorldClock.DayPhase.keys()[WorldClock.phase]],
		"Noite %.2f  Nevasca %s (%.2f)" % [WorldClock.get_night_factor(), "sim" if WorldClock.is_blizzard else "não", WorldClock.blizzard_intensity],
		_stat_line("Calor", SurvivalStats.Stat.WARMTH),
		_stat_line("Fome", SurvivalStats.Stat.HUNGER),
		_stat_line("Luz", SurvivalStats.Stat.LIGHT),
		_stat_line("Corrupção", SurvivalStats.Stat.CORRUPTION),
		"Abrigo %s  Calor ambiente %+.2f/s  Esforço %s  Lanterna %s" % [
			"sim" if SurvivalStats.is_sheltered else "não",
			SurvivalStats.environment_heat,
			"sim" if SurvivalStats.is_exerting else "não",
			"ligada" if SurvivalStats.lantern_on else "desligada",
		],
		"Velocidade x%.2f" % SurvivalStats.get_speed_multiplier(),
		"[F4] nevasca  [F6] +1 h  [F7] -%d calor  [F8] -%d fome" % [int(DRAIN_AMOUNT), int(DRAIN_AMOUNT)],
	]
	_label.text = "\n".join(lines)


func _stat_line(label: String, stat: int) -> String:
	return "%s %5.1f  (%+.3f/s)  estágio %d" % [label, SurvivalStats.get_value(stat), SurvivalStats.get_rate(stat), SurvivalStats.get_stage(stat)]
