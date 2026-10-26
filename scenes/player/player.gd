class_name Player
extends CharacterBody3D
## Jogador em primeira pessoa: andar, correr, agachar e olhar com o mouse.
## A interação fica no Interactor (filho da câmera), os itens no Inventory e
## o uso deles no ItemUser. A cada frame de física informa ao SurvivalStats
## o contexto do corpo (abrigo, fontes de calor, esforço).

@export_group("Movimento")
@export var walk_speed: float = 3.0
@export var sprint_speed: float = 5.5
@export var crouch_speed: float = 1.5
## Quão rápido a velocidade alcança o alvo (maior = mais responsivo).
@export var acceleration: float = 10.0
## Velocidade vertical do pulo. 0 desliga o pulo (decisão pendente).
## Para ligar, crie também a ação "jump" no mapa de entrada.
@export var jump_velocity: float = 0.0

@export_group("Câmera")
@export var mouse_sensitivity: float = 0.002
@export_range(0.0, 89.0) var max_pitch_degrees: float = 85.0

@export_group("Agachar")
@export var stand_height: float = 1.8
@export var crouch_height: float = 1.0
## Distância dos olhos até o topo da cápsula.
@export var eye_offset: float = 0.2
## Metros por segundo na transição de altura.
@export var crouch_transition_speed: float = 4.0

@export_group("Morte")
@export var death_fall_duration: float = 1.5

var is_crouching: bool = false
var is_sprinting: bool = false
## Desligado com o diário aberto ou depois da morte.
var input_enabled: bool = true

var _current_height: float = 0.0
var _warmth_zones: Array[WarmthZone] = []

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interactor: Interactor = $Head/Camera3D/Interactor
@onready var inventory: Inventory = $Inventory
@onready var item_user: ItemUser = $ItemUser
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
@onready var _capsule: CapsuleShape3D = _collision_shape.shape as CapsuleShape3D


func _ready() -> void:
	_current_height = stand_height
	_apply_height(_current_height)
	SurvivalStats.reset()
	SurvivalStats.died.connect(_on_died)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	var captured: bool = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and captured:
		var motion: InputEventMouseMotion = event
		rotate_y(-motion.relative.x * mouse_sensitivity)
		head.rotate_x(-motion.relative.y * mouse_sensitivity)
		var max_pitch: float = deg_to_rad(max_pitch_degrees)
		head.rotation.x = clampf(head.rotation.x, -max_pitch, max_pitch)
	elif event.is_action_pressed(&"ui_cancel") and captured:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.is_pressed() and not captured:
		# Clicar na janela recaptura o mouse.
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif input_enabled and _wants_jump():
		velocity.y = jump_velocity

	_update_crouch(delta)

	var input_dir: Vector2 = Vector2.ZERO
	if input_enabled:
		input_dir = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	# Só corre andando para a frente e em pé.
	is_sprinting = input_enabled and Input.is_action_pressed(&"sprint") and not is_crouching and input_dir.y < 0.0

	var target_velocity: Vector3 = direction * _get_target_speed() * SurvivalStats.get_speed_multiplier()
	var weight: float = clampf(acceleration * delta, 0.0, 1.0)
	velocity.x = lerpf(velocity.x, target_velocity.x, weight)
	velocity.z = lerpf(velocity.z, target_velocity.z, weight)

	move_and_slide()
	_update_survival_context()


func enter_warmth_zone(zone: WarmthZone) -> void:
	if not _warmth_zones.has(zone):
		_warmth_zones.append(zone)


func exit_warmth_zone(zone: WarmthZone) -> void:
	_warmth_zones.erase(zone)


## Fogueira acesa perto o bastante para cozinhar, ou null.
func get_nearby_lit_campfire() -> Campfire:
	for zone: WarmthZone in _warmth_zones:
		if zone.campfire and zone.campfire.is_lit:
			return zone.campfire
	return null


func _get_target_speed() -> float:
	if is_crouching:
		return crouch_speed
	if is_sprinting:
		return sprint_speed
	return walk_speed


func _wants_jump() -> bool:
	return jump_velocity > 0.0 and InputMap.has_action(&"jump") and Input.is_action_just_pressed(&"jump")


func _update_crouch(delta: float) -> void:
	if input_enabled and Input.is_action_pressed(&"crouch"):
		is_crouching = true
	elif is_crouching and _can_stand_up():
		is_crouching = false

	var target_height: float = crouch_height if is_crouching else stand_height
	if not is_equal_approx(_current_height, target_height):
		_current_height = move_toward(_current_height, target_height, crouch_transition_speed * delta)
		_apply_height(_current_height)


## Ajusta a cápsula mantendo os pés no chão e a cabeça no topo.
func _apply_height(height: float) -> void:
	_capsule.height = height
	_collision_shape.position.y = height * 0.5
	head.position.y = height - eye_offset


## Testa se a cápsula atual pode subir até a altura em pé sem bater em nada.
func _can_stand_up() -> bool:
	var rise: float = stand_height - _current_height
	return not test_move(global_transform, Vector3.UP * rise)


func _update_survival_context() -> void:
	var heat: float = 0.0
	var sheltered: bool = false
	for zone: WarmthZone in _warmth_zones:
		heat += zone.get_heat()
		sheltered = sheltered or zone.is_shelter
	SurvivalStats.environment_heat = heat
	SurvivalStats.is_sheltered = sheltered
	SurvivalStats.is_exerting = is_sprinting and Vector2(velocity.x, velocity.z).length() > 0.5


func _on_died(_cause: int) -> void:
	input_enabled = false
	# Placeholder de morte: a cabeça cai e tomba de lado.
	var tween: Tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(head, ^"position:y", 0.3, death_fall_duration)
	tween.tween_property(head, ^"rotation:z", deg_to_rad(70.0), death_fall_duration)
