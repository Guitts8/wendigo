class_name Journal
extends CanvasLayer
## Diário/inventário (Tab): único lugar com medidores. Mostra calor, fome e luz
## em barras com o estado em palavras, a lista de itens e as ações de cada um.
## A corrupção não aparece aqui de propósito: ela se mostra no corpo.

const WARMTH_STATES: PackedStringArray = ["Aquecido", "Com frio", "Congelando", "Hipotermia"]
const HUNGER_STATES: PackedStringArray = ["Alimentado", "Com fome", "Faminto", "Morrendo de fome"]
const LIGHT_STATES: PackedStringArray = ["Boa", "Pela metade", "Acabando", "Vazia"]
const PHASE_NAMES: PackedStringArray = ["amanhecer", "dia", "entardecer", "noite"]

@export var player: Player
## Pausar o jogo com o diário aberto. Desligado: o mundo continua (mais tensão).
@export var pause_game: bool = false

var is_open: bool = false

var _objective: String = ""

@onready var _root: Control = $Root
@onready var _time_label: Label = %TimeLabel
@onready var _objective_label: Label = %ObjectiveLabel
@onready var _weight_label: Label = %WeightLabel
@onready var _item_rows: VBoxContainer = %ItemRows
@onready var _warmth_bar: ProgressBar = %WarmthBar
@onready var _hunger_bar: ProgressBar = %HungerBar
@onready var _light_bar: ProgressBar = %LightBar
@onready var _warmth_state: Label = %WarmthState
@onready var _hunger_state: Label = %HungerState
@onready var _light_state: Label = %LightState


func _ready() -> void:
	_root.visible = false
	SurvivalStats.died.connect(_on_died)
	Events.objective_changed.connect(_on_objective_changed)
	# O diário é filho do jogador: o _ready dele roda antes do pai preencher os @onready.
	if not player.is_node_ready():
		await player.ready
	player.inventory.changed.connect(_on_inventory_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"journal"):
		if is_open:
			close()
		elif player.input_enabled:
			open()
		get_viewport().set_input_as_handled()
	elif is_open and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if is_open:
		_refresh_stats()


func open() -> void:
	is_open = true
	_root.visible = true
	player.input_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if pause_game:
		get_tree().paused = true
	_refresh_stats()
	_rebuild_items()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_root.visible = false
	if pause_game:
		get_tree().paused = false
	if not SurvivalStats.is_dead:
		player.input_enabled = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _refresh_stats() -> void:
	_objective_label.visible = not _objective.is_empty()
	_objective_label.text = "Anotação: %s" % _objective
	_time_label.text = "Dia %d, %s" % [WorldClock.day, PHASE_NAMES[WorldClock.phase]]
	_set_meter(_warmth_bar, _warmth_state, SurvivalStats.Stat.WARMTH, WARMTH_STATES)
	_set_meter(_hunger_bar, _hunger_state, SurvivalStats.Stat.HUNGER, HUNGER_STATES)
	_set_meter(_light_bar, _light_state, SurvivalStats.Stat.LIGHT, LIGHT_STATES)
	_weight_label.text = "Carga: %.1f / %.0f kg" % [player.inventory.get_total_weight(), player.inventory.max_weight]


func _set_meter(bar: ProgressBar, state_label: Label, stat: int, states: PackedStringArray) -> void:
	bar.value = SurvivalStats.get_value(stat)
	state_label.text = states[clampi(SurvivalStats.get_stage(stat), 0, states.size() - 1)]


func _rebuild_items() -> void:
	for child: Node in _item_rows.get_children():
		child.queue_free()
	var ids: Array[StringName] = player.inventory.get_item_ids()
	if ids.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "A mochila está vazia."
		_item_rows.add_child(empty_label)
		return
	for item_id: StringName in ids:
		_item_rows.add_child(_make_item_row(item_id))


func _make_item_row(item_id: StringName) -> HBoxContainer:
	var item: ItemData = Items.get_item(item_id)
	var amount: int = player.inventory.get_amount(item_id)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)

	var name_label: Label = Label.new()
	name_label.text = "%s ×%d" % [item.display_name, amount]
	name_label.tooltip_text = item.description
	name_label.mouse_filter = Control.MOUSE_FILTER_PASS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var weight_label: Label = Label.new()
	weight_label.text = "%.1f kg" % (item.weight * amount)
	weight_label.custom_minimum_size.x = 64.0
	row.add_child(weight_label)

	for action: StringName in player.item_user.get_available_actions(item_id):
		var button: Button = Button.new()
		button.text = ItemUser.ACTION_LABELS[action]
		# Sem foco: o Tab precisa chegar ao _unhandled_input para fechar o diário.
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_action_pressed.bind(item_id, action))
		row.add_child(button)
	return row


func _on_action_pressed(item_id: StringName, action: StringName) -> void:
	player.item_user.perform(item_id, action)
	_refresh_stats()


func _on_inventory_changed(_item_id: StringName, _amount: int) -> void:
	if is_open:
		_rebuild_items()


func _on_objective_changed(text: String) -> void:
	_objective = text


func _on_died(_cause: int) -> void:
	close()
