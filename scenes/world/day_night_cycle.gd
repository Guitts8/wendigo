class_name DayNightCycle
extends Node
## Aplica o WorldClock no nível: posição e força do sol e da lua, cores do céu,
## luz ambiente e neblina (mais densa e clara na nevasca).

@export var sun: DirectionalLight3D
@export var moon: DirectionalLight3D
@export var world_environment: WorldEnvironment
## Reinicia o relógio ao carregar o nível.
@export var reset_clock_on_ready: bool = true
@export var sun_yaw_degrees: float = -30.0

@export_group("Luz")
@export var sun_energy: float = 0.9
@export var moon_energy: float = 0.06
@export var day_ambient_energy: float = 1.0
@export var night_ambient_energy: float = 0.03
@export var night_sky_energy: float = 0.05
@export_range(0.0, 1.0) var blizzard_sun_dimming: float = 0.6

@export_group("Cores")
@export var day_sky_top: Color = Color(0.42, 0.49, 0.58)
@export var day_horizon: Color = Color(0.74, 0.77, 0.81)
@export var dusk_horizon: Color = Color(0.7, 0.55, 0.5)
@export var night_sky_top: Color = Color(0.02, 0.03, 0.06)
@export var night_horizon: Color = Color(0.05, 0.06, 0.09)
@export var day_ground: Color = Color(0.28, 0.3, 0.33)
@export var night_ground: Color = Color(0.02, 0.02, 0.03)
@export var day_fog: Color = Color(0.72, 0.76, 0.82)
@export var blizzard_fog: Color = Color(0.82, 0.84, 0.87)
@export var night_fog: Color = Color(0.03, 0.04, 0.06)

@export_group("Neblina")
@export var clear_fog_density: float = 0.015
@export var blizzard_fog_density: float = 0.09

var _environment: Environment
var _sky_material: ProceduralSkyMaterial


func _ready() -> void:
	_environment = world_environment.environment
	if _environment.sky:
		_sky_material = _environment.sky.sky_material as ProceduralSkyMaterial
	if reset_clock_on_ready:
		WorldClock.reset()
	_apply()


func _process(_delta: float) -> void:
	_apply()


func _apply() -> void:
	var elevation: float = WorldClock.get_sun_elevation()
	var night: float = WorldClock.get_night_factor()
	var blizzard: float = WorldClock.blizzard_intensity
	# Perto do horizonte o céu puxa para o tom de entardecer.
	var dusk: float = (1.0 - clampf(absf(elevation) / 0.3, 0.0, 1.0)) * (1.0 - blizzard)

	# 6 h = nascente (ângulo 0), 12 h = topo, 18 h = poente.
	var angle: float = (WorldClock.hour - 6.0) / WorldClock.HOURS_PER_DAY * TAU
	var yaw: float = deg_to_rad(sun_yaw_degrees)
	sun.rotation = Vector3(-angle, yaw, 0.0)
	sun.light_energy = sun_energy * clampf(elevation * 4.0, 0.0, 1.0) * (1.0 - blizzard_sun_dimming * blizzard)
	sun.visible = sun.light_energy > 0.001
	if moon:
		moon.rotation = Vector3(PI - angle, yaw, 0.0)
		moon.light_energy = moon_energy * night * (1.0 - blizzard)
		moon.visible = moon.light_energy > 0.001

	if _sky_material:
		var horizon: Color = day_horizon.lerp(dusk_horizon, dusk).lerp(night_horizon, night)
		_sky_material.sky_top_color = day_sky_top.lerp(night_sky_top, night)
		_sky_material.sky_horizon_color = horizon
		_sky_material.ground_horizon_color = horizon
		_sky_material.ground_bottom_color = day_ground.lerp(night_ground, night)

	_environment.ambient_light_energy = lerpf(day_ambient_energy, night_ambient_energy, night)
	_environment.background_energy_multiplier = lerpf(1.0, night_sky_energy, night)
	_environment.fog_light_color = day_fog.lerp(blizzard_fog, blizzard).lerp(night_fog, night)
	_environment.fog_density = lerpf(clear_fog_density, blizzard_fog_density, blizzard)
