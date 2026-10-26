class_name Player
extends CharacterBody3D
## Jogador em primeira pessoa: andar, correr, agachar e olhar com o mouse.
## A interação fica no Interactor (filho da câmera) e os itens no Inventory.

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

var is_crouching: bool = false
var is_sprinting: bool = false

var _current_height: float = 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interactor: Interactor = $Head/Camera3D/Interactor
@onready var inventory: Inventory = $Inventory
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
@onready var _capsule: CapsuleShape3D = _collision_shape.shape as CapsuleShape3D


func _ready() -> void:
	_current_height = stand_height
	_apply_height(_current_height)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
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
	elif _wants_jump():
		velocity.y = jump_velocity

	_update_crouch(delta)

	var input_dir: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	# Só corre andando para a frente e em pé.
	is_sprinting = Input.is_action_pressed(&"sprint") and not is_crouching and input_dir.y < 0.0

	var target_velocity: Vector3 = direction * _get_target_speed()
	var weight: float = clampf(acceleration * delta, 0.0, 1.0)
	velocity.x = lerpf(velocity.x, target_velocity.x, weight)
	velocity.z = lerpf(velocity.z, target_velocity.z, weight)

	move_and_slide()


func _get_target_speed() -> float:
	if is_crouching:
		return crouch_speed
	if is_sprinting:
		return sprint_speed
	return walk_speed


func _wants_jump() -> bool:
	return jump_velocity > 0.0 and InputMap.has_action(&"jump") and Input.is_action_just_pressed(&"jump")


func _update_crouch(delta: float) -> void:
	if Input.is_action_pressed(&"crouch"):
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
