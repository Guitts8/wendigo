class_name Companion
extends Interactable
## O colega do tutorial. Fica de cama com a perna ferida; o roteiro piora a
## condição dele (ferido → febre → delirando → morto). Conversar (E) repete o
## lembrete da etapa atual ou uma fala da condição. Comida e curativo são dados
## pelo diário, perto dele (ItemUser).

enum Condition { INJURED, FEVER, DELIRIOUS, DEAD }

signal condition_changed(condition: Condition)

## Prefixo das falas genéricas: "talk_<condição>_1", "talk_<condição>_2"...
@export var talk_prefix: String = "talk"
@export var healthy_skin: Color = Color(0.85, 0.7, 0.6)
@export var fever_skin: Color = Color(0.9, 0.55, 0.5)
@export var dead_skin: Color = Color(0.62, 0.64, 0.66)
@export var breaths_per_minute: float = 14.0

var condition: Condition = Condition.INJURED
var times_fed: int = 0
var times_treated: int = 0
var treated_today: bool = false
## Fala que o roteiro quer repetir quando o jogador conversa; vazia usa as genéricas.
var reminder_key: StringName = &""

var _talk_index: int = 0
var _time: float = 0.0
var _skin_material: StandardMaterial3D

@onready var _torso: MeshInstance3D = $Torso
@onready var _head: MeshInstance3D = $Head
@onready var _torso_base_scale: Vector3 = _torso.scale
@onready var _head_base_position: Vector3 = _head.position


func _ready() -> void:
	add_to_group(&"companion")
	# Material próprio para mudar a cor da pele sem afetar outras instâncias.
	_skin_material = (_head.mesh.surface_get_material(0) as StandardMaterial3D).duplicate()
	_head.material_override = _skin_material
	_apply_condition_visuals()


func _process(delta: float) -> void:
	if condition == Condition.DEAD:
		return
	_time += delta
	# Respiração: o peito sobe e desce; com febre fica rápida e o corpo treme.
	var rate: float = breaths_per_minute / 60.0 * (1.6 if condition != Condition.INJURED else 1.0)
	var breath: float = sin(_time * TAU * rate) * 0.04
	_torso.scale = _torso_base_scale * Vector3(1.0, 1.0 + breath, 1.0)
	if condition != Condition.INJURED:
		var shiver: float = sin(_time * 47.0) * 0.004
		_head.position = _head_base_position + Vector3(shiver, 0.0, 0.0)


func get_prompt(_player: Player) -> String:
	if condition == Condition.DEAD:
		return ""
	return prompt_text


func can_interact(_player: Player) -> bool:
	return condition != Condition.DEAD and not Dialogue.is_playing()


func interact(_player: Player) -> void:
	if not can_interact(_player):
		return
	if not reminder_key.is_empty() and Dialogue.play(reminder_key):
		return
	var key: StringName = _next_generic_talk_key()
	if not key.is_empty():
		Dialogue.play(key)


func is_alive() -> bool:
	return condition != Condition.DEAD


func can_be_treated() -> bool:
	return is_alive() and not treated_today


func treat() -> void:
	times_treated += 1
	treated_today = true
	Events.companion_cared.emit(&"treat")


func feed(_food: FoodData) -> void:
	times_fed += 1
	Events.companion_cared.emit(&"food")


func set_condition(value: Condition) -> void:
	if value == condition:
		return
	condition = value
	_apply_condition_visuals()
	condition_changed.emit(condition)


## Chamado pelo roteiro a cada manhã.
func start_new_day() -> void:
	treated_today = false


func _apply_condition_visuals() -> void:
	if _skin_material == null:
		return
	match condition:
		Condition.INJURED:
			_skin_material.albedo_color = healthy_skin
		Condition.FEVER, Condition.DELIRIOUS:
			_skin_material.albedo_color = fever_skin
		Condition.DEAD:
			_skin_material.albedo_color = dead_skin
			_torso.scale = _torso_base_scale
			_head.position = _head_base_position


func _next_generic_talk_key() -> StringName:
	var condition_name: String = Condition.keys()[condition].to_lower()
	var count: int = 0
	while Dialogue.has_sequence(StringName("%s_%s_%d" % [talk_prefix, condition_name, count + 1])):
		count += 1
	if count == 0:
		return &""
	_talk_index = (_talk_index % count) + 1
	return StringName("%s_%s_%d" % [talk_prefix, condition_name, _talk_index])
