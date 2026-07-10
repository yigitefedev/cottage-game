class_name SkyManager
extends Node

enum WeatherType {
	SUNNY,
	CLOUDY,
	RAIN,
	FOGGY,
	STORM,
	WINDY,
}

const DEFAULT_ORBIT_SCENE_PATH: NodePath = ^"World/LevelRoot/Orbit"
const DEFAULT_SUN_ORBIT_SCENE_PATH: NodePath = ^"World/LevelRoot/SunOrbit"
const DEFAULT_MOON_ORBIT_SCENE_PATH: NodePath = ^"World/LevelRoot/MoonOrbit"
const DEFAULT_WORLD_ENVIRONMENT_SCENE_PATH: NodePath = ^"World/LevelRoot/WorldEnvironment"
const DEFAULT_CLOUD_SHADOW_PLANE_PATH: NodePath = ^"World/EffectsRoot/CloudShadowPlane"
const DEFAULT_RAIN_ROOT_SCENE_PATH: NodePath = ^"World/EffectsRoot/Rain"
const DEFAULT_RAIN_PARTICLES_SCENE_PATH: NodePath = ^"World/EffectsRoot/Rain/Rain"
const DEFAULT_LIGHTNING_SCENE_PATH: NodePath = ^"World/EffectsRoot/Lightning"
const DEFAULT_PLAYER_SCENE_PATH: NodePath = ^"World/EntityRoot/Player"
const DEFAULT_SUN_SCENE_PATH: NodePath = ^"World/LevelRoot/SunOrbit/Sun"
const DEFAULT_MOON_SCENE_PATH: NodePath = ^"World/LevelRoot/MoonOrbit/Moon"
const SUNNY_PROFILE: Resource = preload("res://resources/weather/profiles/weather_sunny.tres")
const CLOUDY_PROFILE: Resource = preload("res://resources/weather/profiles/weather_cloudy.tres")
const RAIN_PROFILE: Resource = preload("res://resources/weather/profiles/weather_rain.tres")
const FOGGY_PROFILE: Resource = preload("res://resources/weather/profiles/weather_foggy.tres")
const STORM_PROFILE: Resource = preload("res://resources/weather/profiles/weather_storm.tres")
const WINDY_PROFILE: Resource = preload("res://resources/weather/profiles/weather_windy.tres")

@export_group("Orbits")
@export var sun_orbit_path: NodePath = ^"../../World/LevelRoot/SunOrbit"
@export var moon_orbit_path: NodePath = ^"../../World/LevelRoot/MoonOrbit"
@export var world_environment_path: NodePath = ^"../../World/LevelRoot/WorldEnvironment"
@export var cloud_shadow_plane_path: NodePath = ^"../../World/EffectsRoot/CloudShadowPlane"
@export var rain_root_path: NodePath = ^"../../World/EffectsRoot/Rain"
@export var rain_particles_path: NodePath = ^"../../World/EffectsRoot/Rain/Rain"
@export var player_path: NodePath = ^"../../World/EntityRoot/Player"
@export var sun_path: NodePath = ^"../../World/LevelRoot/SunOrbit/Sun"
@export var moon_path: NodePath = ^"../../World/LevelRoot/MoonOrbit/Moon"
@export var fixed_y_rotation_degrees: float = 20.0
@export var moon_fixed_y_rotation_degrees: float = 20.0
@export var day_start_x_rotation_degrees: float = -90.0
@export var full_day_x_rotation_degrees: float = 360.0
@export var moon_x_rotation_offset_degrees: float = -35.0
@export var orbit_time_curve: Curve
@export var cloud_shadow_enabled: bool = true
@export var disable_sky_shader_clouds: bool = true
@export_range(0.0, 10.0, 0.01) var rain_wind_velocity_multiplier: float = 2.0

@export_group("Lightning")
@export var lightning_path: NodePath = ^"../../World/EffectsRoot/Lightning"
@export var lightning_color: Color = Color(0.78, 0.86, 1.0, 1.0)
@export_range(0.0, 40.0, 0.01) var lightning_flash_energy: float = 14.0
@export_range(0.0, 1.0, 0.01) var lightning_energy_randomness: float = 0.22
@export_range(0.0, 100.0, 0.1) var lightning_height: float = 48.0
@export_range(0.0, 100.0, 0.1) var lightning_spawn_radius: float = 36.0
@export_range(0.0, 40.0, 0.1) var lightning_target_radius: float = 8.0

@export_group("Day Night Lighting")
@export var sun_light_curve: Curve
@export var moon_light_curve: Curve
@export var ambient_light_curve: Curve
@export var ambient_light_gradient: Gradient
@export var force_environment_ambient_color_source: bool = true

@export_group("Weather")
@export var active_weather: WeatherType = WeatherType.SUNNY
@export var sunny_profile: Resource = SUNNY_PROFILE
@export var cloudy_profile: Resource = CLOUDY_PROFILE
@export var rain_profile: Resource = RAIN_PROFILE
@export var foggy_profile: Resource = FOGGY_PROFILE
@export var storm_profile: Resource = STORM_PROFILE
@export var windy_profile: Resource = WINDY_PROFILE

var _sun_orbit: Node3D
var _moon_orbit: Node3D
var _world_environment: WorldEnvironment
var _environment: Environment
var _sky_material: ShaderMaterial
var _cloud_shadow_plane: MeshInstance3D
var _cloud_shadow_material: ShaderMaterial
var _rain_root: Node3D
var _rain_particles: GPUParticles3D
var _rain_process_material: ParticleProcessMaterial
var _lightning_light: DirectionalLight3D
var _player: Node3D
var _sun_light: DirectionalLight3D
var _moon_light: DirectionalLight3D
var _wind_manager: WindManager
var _base_sun_energy: float = 1.0
var _base_moon_energy: float = 1.0
var _base_sun_shadow_opacity: float = 1.0
var _base_moon_shadow_opacity: float = 1.0
var _base_ambient_light_energy: float = 1.0
var _base_tonemap_exposure: float = 1.0
var _base_volumetric_fog_density: float = 0.0
var _base_rain_amount: int = 1
var _base_wind_strength: float = 0.4
var _base_wind_speed: float = 0.075
var _sun_base_captured: bool = false
var _moon_base_captured: bool = false
var _environment_base_captured: bool = false
var _rain_base_captured: bool = false
var _wind_base_captured: bool = false
var _lightning_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _lightning_timer: float = 0.0
var _lightning_elapsed: float = 1.0
var _lightning_active: bool = false
var _last_lightning_frequency: float = -1.0
var _last_lightning_weather: int = -1
var _lightning_pattern: Array[Dictionary] = []


func _ready() -> void:
	add_to_group("sky_manager")
	_lightning_rng.randomize()
	_ensure_default_lighting_resources()
	_resolve_orbits()
	_resolve_sky_material()
	_resolve_cloud_shadow_material()
	_resolve_rain_nodes()
	_resolve_lightning()
	_resolve_lights()
	_resolve_wind_manager()
	_capture_base_values()
	_apply_orbit_rotation()
	_apply_weather_profile()
	_update_rain_position()


func _process(delta: float) -> void:
	_apply_orbit_rotation()
	_apply_weather_profile()
	_update_rain_position()
	_update_lightning(delta)


func _resolve_orbits() -> void:
	_sun_orbit = get_node_or_null(sun_orbit_path) as Node3D
	_moon_orbit = get_node_or_null(moon_orbit_path) as Node3D

	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return

	if _sun_orbit == null:
		_sun_orbit = current_scene.get_node_or_null(DEFAULT_SUN_ORBIT_SCENE_PATH) as Node3D

	if _moon_orbit == null:
		_moon_orbit = current_scene.get_node_or_null(DEFAULT_MOON_ORBIT_SCENE_PATH) as Node3D

	if _sun_orbit == null or _moon_orbit == null:
		var legacy_orbit: Node3D = current_scene.get_node_or_null(DEFAULT_ORBIT_SCENE_PATH) as Node3D

		if _sun_orbit == null:
			_sun_orbit = legacy_orbit

		if _moon_orbit == null:
			_moon_orbit = legacy_orbit


func _resolve_sky_material() -> void:
	_world_environment = get_node_or_null(world_environment_path) as WorldEnvironment
	if _world_environment == null:
		var current_scene: Node = get_tree().current_scene
		if current_scene != null:
			_world_environment = current_scene.get_node_or_null(DEFAULT_WORLD_ENVIRONMENT_SCENE_PATH) as WorldEnvironment

	if _world_environment == null:
		return

	var environment: Environment = _world_environment.environment
	if environment == null:
		return

	_environment = environment

	var sky: Sky = environment.sky
	if sky == null:
		return

	_sky_material = sky.sky_material as ShaderMaterial


func _resolve_cloud_shadow_material() -> void:
	_cloud_shadow_plane = get_node_or_null(cloud_shadow_plane_path) as MeshInstance3D
	if _cloud_shadow_plane == null:
		var current_scene: Node = get_tree().current_scene
		if current_scene != null:
			_cloud_shadow_plane = current_scene.get_node_or_null(DEFAULT_CLOUD_SHADOW_PLANE_PATH) as MeshInstance3D

	if _cloud_shadow_plane == null:
		return

	_cloud_shadow_material = _cloud_shadow_plane.get_active_material(0) as ShaderMaterial


func _resolve_rain_nodes() -> void:
	_rain_root = get_node_or_null(rain_root_path) as Node3D
	_rain_particles = get_node_or_null(rain_particles_path) as GPUParticles3D
	_resolve_player()

	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return

	if _rain_root == null:
		_rain_root = current_scene.get_node_or_null(DEFAULT_RAIN_ROOT_SCENE_PATH) as Node3D

	if _rain_particles == null:
		_rain_particles = current_scene.get_node_or_null(DEFAULT_RAIN_PARTICLES_SCENE_PATH) as GPUParticles3D

	if _rain_particles != null:
		_rain_process_material = _rain_particles.process_material as ParticleProcessMaterial


func _resolve_player() -> void:
	var grouped_player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if grouped_player != null:
		_player = grouped_player
		return

	if _player != null and is_instance_valid(_player) and _player.is_in_group("player"):
		return

	_player = get_node_or_null(player_path) as Node3D
	if _player != null:
		return

	var current_scene: Node = get_tree().current_scene
	if current_scene != null:
		_player = current_scene.get_node_or_null(DEFAULT_PLAYER_SCENE_PATH) as Node3D


func _resolve_lightning() -> void:
	_lightning_light = get_node_or_null(lightning_path) as DirectionalLight3D
	if _lightning_light == null:
		var current_scene: Node = get_tree().current_scene
		if current_scene != null:
			_lightning_light = current_scene.get_node_or_null(DEFAULT_LIGHTNING_SCENE_PATH) as DirectionalLight3D

	if _lightning_light == null:
		return

	_lightning_light.light_energy = 0.0
	_lightning_light.light_color = lightning_color


func _resolve_lights() -> void:
	_sun_light = get_node_or_null(sun_path) as DirectionalLight3D
	_moon_light = get_node_or_null(moon_path) as DirectionalLight3D

	if _sun_light != null and _moon_light != null:
		return

	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return

	if _sun_light == null:
		_sun_light = current_scene.get_node_or_null(DEFAULT_SUN_SCENE_PATH) as DirectionalLight3D
		if _sun_light == null:
			_sun_light = current_scene.get_node_or_null(^"World/LevelRoot/Orbit/Sun") as DirectionalLight3D

	if _moon_light == null:
		_moon_light = current_scene.get_node_or_null(DEFAULT_MOON_SCENE_PATH) as DirectionalLight3D
		if _moon_light == null:
			_moon_light = current_scene.get_node_or_null(^"World/LevelRoot/Orbit/Moon") as DirectionalLight3D


func _resolve_wind_manager() -> void:
	_wind_manager = get_tree().get_first_node_in_group("wind_manager") as WindManager


func _capture_base_values() -> void:
	if _sun_light == null or _moon_light == null:
		_resolve_lights()

	if _world_environment == null or _environment == null:
		_resolve_sky_material()

	if _wind_manager == null:
		_resolve_wind_manager()

	if _rain_particles == null:
		_resolve_rain_nodes()

	if _sun_light != null and not _sun_base_captured:
		_base_sun_energy = _sun_light.light_energy
		_base_sun_shadow_opacity = _sun_light.shadow_opacity
		_sun_base_captured = true

	if _moon_light != null and not _moon_base_captured:
		_base_moon_energy = _moon_light.light_energy
		_base_moon_shadow_opacity = _moon_light.shadow_opacity
		_moon_base_captured = true

	if _environment != null and not _environment_base_captured:
		_base_ambient_light_energy = _environment.ambient_light_energy
		_base_tonemap_exposure = _environment.tonemap_exposure
		_base_volumetric_fog_density = _environment.volumetric_fog_density
		_environment_base_captured = true

	if _rain_particles != null and not _rain_base_captured:
		_base_rain_amount = maxi(_rain_particles.amount, 1)
		_rain_base_captured = true

	if _wind_manager != null and not _wind_base_captured:
		_base_wind_strength = _wind_manager.wind_strength
		_base_wind_speed = _wind_manager.wind_speed
		_wind_base_captured = true


func _apply_orbit_rotation() -> void:
	if _sun_orbit == null or _moon_orbit == null:
		_resolve_orbits()

	if _sun_orbit == null and _moon_orbit == null:
		return

	var day_progress: float = _get_day_progress()
	var orbit_progress: float = _sample_curve(orbit_time_curve, day_progress, day_progress)

	if _sun_orbit != null:
		var sun_orbit_rotation: Vector3 = _sun_orbit.rotation_degrees
		sun_orbit_rotation.x = day_start_x_rotation_degrees + orbit_progress * full_day_x_rotation_degrees
		sun_orbit_rotation.y = fixed_y_rotation_degrees
		_sun_orbit.rotation_degrees = sun_orbit_rotation

	if _moon_orbit != null:
		var moon_orbit_rotation: Vector3 = _moon_orbit.rotation_degrees
		moon_orbit_rotation.x = day_start_x_rotation_degrees + orbit_progress * full_day_x_rotation_degrees + moon_x_rotation_offset_degrees
		moon_orbit_rotation.y = moon_fixed_y_rotation_degrees
		_moon_orbit.rotation_degrees = moon_orbit_rotation


func _apply_weather_profile() -> void:
	var profile: Resource = _get_active_weather_profile()
	if profile == null:
		profile = SUNNY_PROFILE

	_capture_base_values()
	_apply_sky_settings(profile)
	_apply_lighting_settings(profile)
	_apply_environment_settings(profile)
	_apply_wind_settings(profile)
	_apply_cloud_shadow_plane_state(profile)
	_apply_rain_settings(profile)


func _apply_sky_settings(profile: Resource) -> void:
	if _sky_material == null:
		_resolve_sky_material()

	if _sky_material == null:
		return

	_sky_material.set_shader_parameter(&"weather_desaturation", _profile_float(profile, &"weather_desaturation", 0.0))
	_sky_material.set_shader_parameter(&"weather_tint", _profile_color(profile, &"weather_tint", Color.WHITE))
	_sky_material.set_shader_parameter(&"clouds_enabled", not disable_sky_shader_clouds and _profile_bool(profile, &"has_clouds", false))
	_sky_material.set_shader_parameter(&"coverage", _profile_float(profile, &"cloud_noise_threshold", 0.6))


func _apply_lighting_settings(profile: Resource) -> void:
	if _sun_light == null or _moon_light == null:
		_resolve_lights()

	var day_progress: float = _get_day_progress()
	var sun_curve_value: float = _sample_curve(sun_light_curve, day_progress, 1.0)
	var moon_curve_value: float = _sample_curve(moon_light_curve, day_progress, 0.0)

	if _sun_light != null and _sun_base_captured:
		_sun_light.light_energy = _base_sun_energy * sun_curve_value * _profile_float(profile, &"sun_energy_multiplier", 1.0)
		_sun_light.shadow_opacity = _base_sun_shadow_opacity * _profile_float(profile, &"shadow_opacity_multiplier", 1.0)

	if _moon_light != null and _moon_base_captured:
		_moon_light.light_energy = _base_moon_energy * moon_curve_value * _profile_float(profile, &"moon_energy_multiplier", 1.0)
		_moon_light.shadow_opacity = _base_moon_shadow_opacity * _profile_float(profile, &"shadow_opacity_multiplier", 1.0)


func _apply_environment_settings(profile: Resource) -> void:
	if _world_environment == null or _environment == null:
		_resolve_sky_material()

	if _environment == null or not _environment_base_captured:
		return

	var day_progress: float = _get_day_progress()
	var ambient_curve_value: float = _sample_curve(ambient_light_curve, day_progress, 1.0)
	var ambient_color: Color = _sample_gradient(ambient_light_gradient, day_progress, _environment.ambient_light_color)
	var weather_tint: Color = _profile_color(profile, &"weather_tint", Color.WHITE)
	ambient_color.r *= weather_tint.r
	ambient_color.g *= weather_tint.g
	ambient_color.b *= weather_tint.b

	if force_environment_ambient_color_source:
		_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR

	_environment.ambient_light_color = ambient_color
	_environment.ambient_light_energy = _base_ambient_light_energy * ambient_curve_value * _profile_float(profile, &"ambient_energy_multiplier", 1.0)
	_environment.tonemap_exposure = _base_tonemap_exposure * _profile_float(profile, &"tonemap_exposure_multiplier", 1.0)
	_environment.volumetric_fog_density = _base_volumetric_fog_density * _profile_float(profile, &"fog_density_multiplier", 1.0)
	_environment.fog_height = _profile_float(profile, &"fog_height", 1.0)
	_environment.set(&"fog_height_density", _profile_float(profile, &"fog_height_density", 1.0))


func _apply_wind_settings(profile: Resource) -> void:
	if _wind_manager == null:
		_resolve_wind_manager()

	if _wind_manager == null or not _wind_base_captured:
		return

	_wind_manager.wind_strength = _base_wind_strength * _profile_float(profile, &"wind_strength_multiplier", 1.0)
	_wind_manager.wind_speed = _base_wind_speed * _profile_float(profile, &"wind_speed_multiplier", 1.0)
	_wind_manager.apply_wind()


func _apply_rain_settings(profile: Resource) -> void:
	if _rain_particles == null:
		_resolve_rain_nodes()

	if _rain_particles == null:
		return

	var rain_strength: float = clampf(_profile_float(profile, &"rain_strength", 0.0), 0.0, 10.0)
	_rain_particles.amount = maxi(1, int(round(float(_base_rain_amount) * rain_strength)))
	_rain_particles.emitting = rain_strength > 0.0
	_rain_particles.visible = rain_strength > 0.0

	if _rain_process_material == null:
		_rain_process_material = _rain_particles.process_material as ParticleProcessMaterial

	if _rain_process_material == null:
		return

	var wind_direction: Vector3 = Vector3.ZERO
	if _wind_manager != null:
		wind_direction = _wind_manager.wind_direction

	wind_direction.y = 0.0
	if wind_direction.length_squared() < 0.001:
		wind_direction = Vector3.FORWARD
	else:
		wind_direction = wind_direction.normalized()

	var wind_velocity_multiplier: float = rain_wind_velocity_multiplier * _profile_float(profile, &"rain_wind_velocity_multiplier", 1.0)
	_rain_process_material.direction = Vector3(
		wind_direction.x * wind_velocity_multiplier,
		-1.0,
		wind_direction.z * wind_velocity_multiplier
	).normalized()


func _update_rain_position() -> void:
	_resolve_player()
	if _rain_root == null:
		_resolve_rain_nodes()

	if _rain_root == null or _player == null or not is_instance_valid(_player):
		return

	var rain_position: Vector3 = _rain_root.global_position
	var player_position: Vector3 = _player.global_position
	rain_position.x = player_position.x
	rain_position.z = player_position.z
	_rain_root.global_position = rain_position


func _apply_cloud_shadow_plane_state(profile: Resource) -> void:
	if _cloud_shadow_material == null:
		_resolve_cloud_shadow_material()

	var shadows_enabled: bool = cloud_shadow_enabled and _profile_bool(profile, &"has_clouds", false)

	if _cloud_shadow_plane != null:
		_cloud_shadow_plane.visible = shadows_enabled

	if _cloud_shadow_material == null:
		return

	_cloud_shadow_material.set_shader_parameter(&"shadow_enabled", shadows_enabled)
	_cloud_shadow_material.set_shader_parameter(&"noise_threshold", _profile_float(profile, &"cloud_noise_threshold", 0.6))


func _update_lightning(delta: float) -> void:
	if _lightning_light == null:
		_resolve_lightning()

	if _lightning_light == null:
		return

	var profile: Resource = _get_active_weather_profile()
	var frequency: float = _profile_float(profile, &"lightning_frequency", 0.0)
	var weather_index: int = int(active_weather)
	if weather_index != _last_lightning_weather or not is_equal_approx(frequency, _last_lightning_frequency):
		_last_lightning_weather = weather_index
		_last_lightning_frequency = frequency
		_lightning_active = false
		_lightning_timer = 0.0
		_lightning_light.light_energy = 0.0

	if frequency <= 0.0:
		_lightning_active = false
		_lightning_timer = 0.0
		_lightning_light.light_energy = 0.0
		return

	if _lightning_active:
		_lightning_elapsed += delta
		_apply_lightning_flash()
		return

	_lightning_timer -= delta
	if _lightning_timer <= 0.0:
		_start_lightning_flash(frequency)


func _start_lightning_flash(frequency: float) -> void:
	_randomize_lightning_transform()
	_randomize_lightning_pattern()
	_lightning_active = true
	_lightning_elapsed = 0.0
	_apply_lightning_flash()
	_lightning_timer = _get_next_lightning_delay(frequency)


func _apply_lightning_flash() -> void:
	var energy: float = 0.0
	var pattern_end_time: float = 0.0

	for flash: Dictionary in _lightning_pattern:
		var start_time: float = float(flash["start"])
		var duration: float = float(flash["duration"])
		var flash_energy: float = float(flash["energy"])
		pattern_end_time = maxf(pattern_end_time, start_time + duration)
		if _lightning_elapsed >= start_time and _lightning_elapsed <= start_time + duration:
			var flash_ratio: float = (_lightning_elapsed - start_time) / duration
			energy = maxf(energy, lerpf(flash_energy, 0.0, flash_ratio))

	if _lightning_elapsed > pattern_end_time:
		_lightning_active = false
		energy = 0.0

	_lightning_light.light_color = lightning_color
	_lightning_light.light_energy = energy


func _randomize_lightning_pattern() -> void:
	_lightning_pattern.clear()

	var roll: float = _lightning_rng.randf()
	var flash_count: int = 2
	if roll < 0.18:
		flash_count = 1
	elif roll > 0.82:
		flash_count = 3

	var main_start: float = 0.0
	var main_duration: float = _lightning_rng.randf_range(0.045, 0.075)
	_add_lightning_flash(main_start, main_duration, 1.0)

	if flash_count >= 2:
		var second_start: float = _lightning_rng.randf_range(0.10, 0.15)
		var second_duration: float = _lightning_rng.randf_range(0.055, 0.105)
		var second_energy: float = _lightning_rng.randf_range(0.32, 0.58)
		_add_lightning_flash(second_start, second_duration, second_energy)

	if flash_count >= 3:
		var final_start: float = _lightning_rng.randf_range(0.24, 0.33)
		var final_duration: float = _lightning_rng.randf_range(0.025, 0.09)
		var final_energy: float = _lightning_rng.randf_range(0.14, 0.32)
		_add_lightning_flash(final_start, final_duration, final_energy)


func _add_lightning_flash(start_time: float, duration: float, energy_multiplier: float) -> void:
	var energy_jitter: float = _lightning_rng.randf_range(1.0 - lightning_energy_randomness, 1.0 + lightning_energy_randomness)
	_lightning_pattern.append({
		"start": start_time,
		"duration": duration,
		"energy": lightning_flash_energy * energy_multiplier * energy_jitter,
	})


func _randomize_lightning_transform() -> void:
	_resolve_player()

	var center_position: Vector3 = Vector3.ZERO
	if _player != null and is_instance_valid(_player):
		center_position = _player.global_position

	var spawn_angle: float = _lightning_rng.randf_range(0.0, TAU)
	var spawn_distance: float = _lightning_rng.randf_range(0.0, lightning_spawn_radius)
	var spawn_position: Vector3 = center_position
	spawn_position.x += cos(spawn_angle) * spawn_distance
	spawn_position.y = lightning_height
	spawn_position.z += sin(spawn_angle) * spawn_distance
	_lightning_light.global_position = spawn_position

	var target_angle: float = _lightning_rng.randf_range(0.0, TAU)
	var target_distance: float = _lightning_rng.randf_range(0.0, lightning_target_radius)
	var target_position: Vector3 = center_position
	target_position.x += cos(target_angle) * target_distance
	target_position.y = 0.0
	target_position.z += sin(target_angle) * target_distance
	_lightning_light.look_at(target_position, Vector3.UP)


func _get_next_lightning_delay(frequency: float) -> float:
	var flashes_per_minute: float = maxf(frequency, 0.01)
	var base_delay: float = 60.0 / flashes_per_minute
	return base_delay * _lightning_rng.randf_range(0.45, 1.45)


func _get_active_weather_profile() -> Resource:
	return get_weather_profile(active_weather)


func set_active_weather(weather_type: int) -> void:
	active_weather = weather_type as WeatherType
	_apply_weather_profile()


func get_weather_profile(weather_type: int) -> Resource:
	match weather_type:
		WeatherType.CLOUDY:
			return cloudy_profile
		WeatherType.RAIN:
			return rain_profile
		WeatherType.FOGGY:
			return foggy_profile
		WeatherType.STORM:
			return storm_profile
		WeatherType.WINDY:
			return windy_profile
		_:
			return sunny_profile


func apply_weather_now() -> void:
	_apply_weather_profile()


func _ensure_default_lighting_resources() -> void:
	if orbit_time_curve == null:
		orbit_time_curve = _create_curve([
			Vector2(0.0, 0.0),
			Vector2(1.0, 1.0),
		])

	if sun_light_curve == null:
		sun_light_curve = _create_curve([
			Vector2(0.0, 0.05),
			Vector2(0.08, 0.5),
			Vector2(0.24, 1.0),
			Vector2(0.45, 0.85),
			Vector2(0.55, 0.2),
			Vector2(0.62, 0.0),
			Vector2(1.0, 0.0),
		])

	if moon_light_curve == null:
		moon_light_curve = _create_curve([
			Vector2(0.0, 0.0),
			Vector2(0.55, 0.0),
			Vector2(0.65, 0.25),
			Vector2(0.78, 1.0),
			Vector2(0.92, 0.75),
			Vector2(1.0, 0.1),
		])

	if ambient_light_curve == null:
		ambient_light_curve = _create_curve([
			Vector2(0.0, 0.45),
			Vector2(0.12, 0.85),
			Vector2(0.35, 1.0),
			Vector2(0.52, 0.72),
			Vector2(0.62, 0.45),
			Vector2(0.75, 0.24),
			Vector2(0.92, 0.22),
			Vector2(1.0, 0.35),
		])

	if ambient_light_gradient == null:
		ambient_light_gradient = Gradient.new()
		ambient_light_gradient.offsets = PackedFloat32Array([0.0, 0.14, 0.48, 0.58, 0.72, 1.0])
		ambient_light_gradient.colors = PackedColorArray([
			Color(1.0, 0.62, 0.48, 1.0),
			Color(1.0, 0.92, 0.78, 1.0),
			Color(1.0, 0.96, 0.86, 1.0),
			Color(1.0, 0.45, 0.32, 1.0),
			Color(0.36, 0.48, 0.72, 1.0),
			Color(0.46, 0.52, 0.70, 1.0),
		])


func _create_curve(points: Array[Vector2]) -> Curve:
	var curve: Curve = Curve.new()
	curve.min_domain = 0.0
	curve.max_domain = 1.0
	curve.min_value = 0.0
	curve.max_value = 1.0
	for point: Vector2 in points:
		curve.add_point(point)
	return curve


func _sample_curve(curve: Curve, offset: float, default_value: float) -> float:
	if curve == null:
		return default_value

	return clampf(curve.sample_baked(clampf(offset, 0.0, 1.0)), 0.0, 1.0)


func _sample_gradient(gradient: Gradient, offset: float, default_value: Color) -> Color:
	if gradient == null:
		return default_value

	return gradient.sample(clampf(offset, 0.0, 1.0))


func _profile_float(profile: Resource, property_name: StringName, default_value: float) -> float:
	if profile == null:
		return default_value

	var value: Variant = profile.get(property_name)
	if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
		return float(value)

	return default_value


func _profile_bool(profile: Resource, property_name: StringName, default_value: bool) -> bool:
	if profile == null:
		return default_value

	var value: Variant = profile.get(property_name)
	if typeof(value) == TYPE_BOOL:
		return bool(value)

	return default_value


func _profile_color(profile: Resource, property_name: StringName, default_value: Color) -> Color:
	if profile == null:
		return default_value

	var value: Variant = profile.get(property_name)
	if typeof(value) == TYPE_COLOR:
		var color_value: Color = value
		return color_value

	return default_value


func _get_day_progress() -> float:
	var clock_minutes: int = TimeManager.current_hour * 60 + TimeManager.current_minute
	var day_start_minutes: int = TimeManager.day_start_hour * 60
	var minutes_since_day_start: int = clock_minutes - day_start_minutes
	if minutes_since_day_start < 0:
		minutes_since_day_start += TimeManager.MINUTES_PER_DAY

	var smooth_minutes: float = float(minutes_since_day_start)
	smooth_minutes += float(TimeManager.minutes_per_tick) * TimeManager.get_tick_progress_ratio()

	return wrapf(smooth_minutes / float(TimeManager.MINUTES_PER_DAY), 0.0, 1.0)
