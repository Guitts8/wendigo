class_name Snowfall
extends GPUParticles3D
## Neve que acompanha o alvo (o jogador). Fica mais densa e ganha vento na nevasca.
## Partículas em coordenadas globais: a neve não "anda junto" com o jogador.

@export var target: Node3D
@export var height_above_target: float = 8.0
## Fração das partículas com céu limpo.
@export_range(0.0, 1.0) var clear_amount_ratio: float = 0.15
@export var base_gravity: Vector3 = Vector3(0.0, -1.5, 0.0)
## Vento somado à gravidade na nevasca total.
@export var blizzard_wind: Vector3 = Vector3(5.0, 0.0, 2.0)

var _material: ParticleProcessMaterial


func _ready() -> void:
	_material = process_material as ParticleProcessMaterial


func _process(_delta: float) -> void:
	if target:
		global_position = target.global_position + Vector3.UP * height_above_target
	var blizzard: float = WorldClock.blizzard_intensity
	amount_ratio = lerpf(clear_amount_ratio, 1.0, blizzard)
	_material.gravity = base_gravity + blizzard_wind * blizzard
