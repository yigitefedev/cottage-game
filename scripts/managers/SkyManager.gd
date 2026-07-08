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
const DEFAULT_WORLD_ENVIRONMENT_SCENE_PATH: NodePath = ^"World/LevelRoot/WorldEnvironment"
const DEFAULT_CLOUD_SHADOW_PLANE_PATH: NodePath = ^"World/LevelRoot/CloudShadowPlane"
const DEFAULT_SUN_SCENE_PATH: NodePath = ^"World/LevelRoot/Orbit/Sun"
const DEFAULT_MOON_SCENE_PATH: NodePath = ^"World/LevelRoot/Orbit/Moon"
const SUNNY_PROFILE: Resource = preload("res://resources/weather/profiles/weather_sunny.tres")
const CLOUDY_PROFILE: Resource = preload("res://resources/weather/profiles/weather_cloudy.tres")
const RAIN_PROFILE: Resource = preload("res://resources/weather/profiles/weather_rain.tres")
const FOGGY_PROFILE: Resource = preload("res://resources/weather/profiles/weather_foggy.tres")
const STORM_PROFILE: Resource = preload("res://resources/weather/profiles/weather_storm.tres")
const WINDY_PROFILE: Resource = preload("res://resources/weather/profiles/weather_windy.tres")

@export var orbit_path: NodePath = ^"../../World/LevelRoot/Orbit"
@export var world_environment_path: NodePath = ^"../../World/LevelRoot/WorldEnvironment"
@export var cloud_shadow_plane_path: NodePath = ^"../../World/LevelRoot/CloudShadowPlane"
@export var sun_path: NodePath = ^"../../World/LevelRoot/Orbit/Sun"
@export var moon_path: NodePath = ^"../../World/LevelRoot/Orbit/Moon"
@export var fixed_y_rotation_degrees: float = 20.0
@export var day_start_x_rotation_degrees: float = -90.0
@export var full_day_x_rotation_degrees: float = 360.0
@export var cloud_shadow_enabled: bool = true
@export var disable_sky_shader_clouds: bool = true

@export_group("Weather")
@export var active_weather: WeatherType = WeatherType.SUNNY
@export var sunny_profile: Resource = SUNNY_PROFILE
@export var cloudy_profile: Resource = CLOUDY_PROFILE
@export var rain_profile: Resource = RAIN_PROFILE
@export var foggy_profile: Resource = FOGGY_PROFILE
@export var storm_profile: Resource = STORM_PROFILE
@export var windy_profile: Resource = WINDY_PROFILE

var _orbit: Node3D
var _world_environment: WorldEnvironment
var _environment: Environment
var _sky_material: ShaderMaterial
var _cloud_shadow_plane: MeshInstance3D
var _cloud_shadow_material: ShaderMaterial
var _sun_light: DirectionalLight3D
var _moon_light: DirectionalLight3D
var _wind_manager: WindManager
var _base_sun_energy: float = 1.0
var _base_moon_energy: float = 1.0
var _base_sun_shadow_opacity: float = 1.0
var _base_moon_shadow_opacity: float = 1.0
var _base_tonemap_exposure: float = 1.0
var _base_volumetric_fog_density: float = 0.0
var _base_wind_strength: float = 0.4
var _base_wind_speed: float = 0.075
var _sun_base_captured: bool = false
var _moon_base_captured: bool = false
var _environment_base_captured: bool = false
var _wind_base_captured: bool = false


func _ready() -> void:
	add_to_group("sky_manager")
	_resolve_orbit()
	_resolve_sky_material()
	_resolve_cloud_shadow_material()
	_resolve_lights()
	_resolve_wind_manager()
	_capture_base_values()
	_apply_orbit_rotation()
	_apply_weather_profile()


func _process(_delta: float) -> void:
	_apply_orbit_rotation()
	_apply_weather_profile()


func _resolve_orbit() -> void:
	_orbit = get_node_or_null(orbit_path) as Node3D
	if _orbit != null:
		return

	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return

	_orbit = current_scene.get_node_or_null(DEFAULT_ORBIT_SCENE_PATH) as Node3D


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

	if _moon_light == null:
		_moon_light = current_scene.get_node_or_null(DEFAULT_MOON_SCENE_PATH) as DirectionalLight3D


func _resolve_wind_manager() -> void:
	_wind_manager = get_tree().get_first_node_in_group("wind_manager") as WindManager


func _capture_base_values() -> void:
	if _sun_light == null or _moon_light == null:
		_resolve_lights()

	if _world_environment == null or _environment == null:
		_resolve_sky_material()

	if _wind_manager == null:
		_resolve_wind_manager()

	if _sun_light != null and not _sun_base_captured:
		_base_sun_energy = _sun_light.light_energy
		_base_sun_shadow_opacity = _sun_light.shadow_opacity
		_sun_base_captured = true

	if _moon_light != null and not _moon_base_captured:
		_base_moon_energy = _moon_light.light_energy
		_base_moon_shadow_opacity = _moon_light.shadow_opacity
		_moon_base_captured = true

	if _environment != null and not _environment_base_captured:
		_base_tonemap_exposure = _environment.tonemap_exposure
		_base_volumetric_fog_density = _environment.volumetric_fog_density
		_environment_base_captured = true

	if _wind_manager != null and not _wind_base_captured:
		_base_wind_strength = _wind_manager.wind_strength
		_base_wind_speed = _wind_manager.wind_speed
		_wind_base_captured = true


func _apply_orbit_rotation() -> void:
	if _orbit == null:
		_resolve_orbit()

	if _orbit == null:
		return

	var day_progress: float = _get_day_progress()
	var orbit_rotation: Vector3 = _orbit.rotation_degrees
	orbit_rotation.x = day_start_x_rotation_degrees + day_progress * full_day_x_rotation_degrees
	orbit_rotation.y = fixed_y_rotation_degrees
	_orbit.rotation_degrees = orbit_rotation


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


func _apply_sky_settings(profile: Resource) -> void:
	if _sky_material == null:
		_resolve_sky_material()

	if _sky_material == null:
		return

	_sky_material.set_shader_parameter(&"weather_darkness", _profile_float(profile, &"weather_darkness", 0.0))
	_sky_material.set_shader_parameter(&"weather_desaturation", _profile_float(profile, &"weather_desaturation", 0.0))
	_sky_material.set_shader_parameter(&"weather_tint", _profile_color(profile, &"weather_tint", Color.WHITE))
	_sky_material.set_shader_parameter(&"star_visibility", _profile_float(profile, &"star_visibility_multiplier", 1.0))
	_sky_material.set_shader_parameter(&"horizon_haze", _profile_float(profile, &"horizon_haze", 0.0))
	_sky_material.set_shader_parameter(&"clouds_enabled", not disable_sky_shader_clouds and _profile_bool(profile, &"has_clouds", false))
	_sky_material.set_shader_parameter(&"coverage", _profile_float(profile, &"cloud_noise_threshold", 0.6))


func _apply_lighting_settings(profile: Resource) -> void:
	if _sun_light == null or _moon_light == null:
		_resolve_lights()

	if _sun_light != null and _sun_base_captured:
		_sun_light.light_energy = _base_sun_energy * _profile_float(profile, &"sun_energy_multiplier", 1.0)
		_sun_light.shadow_opacity = _base_sun_shadow_opacity * _profile_float(profile, &"shadow_opacity_multiplier", 1.0)

	if _moon_light != null and _moon_base_captured:
		_moon_light.light_energy = _base_moon_energy * _profile_float(profile, &"moon_energy_multiplier", 1.0)
		_moon_light.shadow_opacity = _base_moon_shadow_opacity * _profile_float(profile, &"shadow_opacity_multiplier", 1.0)


func _apply_environment_settings(profile: Resource) -> void:
	if _world_environment == null or _environment == null:
		_resolve_sky_material()

	if _environment == null or not _environment_base_captured:
		return

	_environment.tonemap_exposure = _base_tonemap_exposure * _profile_float(profile, &"tonemap_exposure_multiplier", 1.0)
	_environment.volumetric_fog_density = _base_volumetric_fog_density * _profile_float(profile, &"volumetric_fog_density_multiplier", 1.0)


func _apply_wind_settings(profile: Resource) -> void:
	if _wind_manager == null:
		_resolve_wind_manager()

	if _wind_manager == null or not _wind_base_captured:
		return

	_wind_manager.wind_strength = _base_wind_strength * _profile_float(profile, &"wind_strength_multiplier", 1.0)
	_wind_manager.wind_speed = _base_wind_speed * _profile_float(profile, &"wind_speed_multiplier", 1.0)
	_wind_manager.apply_wind()


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


func _get_active_weather_profile() -> Resource:
	match active_weather:
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
