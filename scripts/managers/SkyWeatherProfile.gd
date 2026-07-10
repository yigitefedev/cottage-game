class_name SkyWeatherProfile
extends Resource

@export var display_name: String = "Sunny"

@export_group("Sky")
@export_range(0.0, 1.0, 0.01) var weather_desaturation: float = 0.0
@export var weather_tint: Color = Color.WHITE

@export_group("Lighting Multipliers")
@export_range(0.0, 3.0, 0.01) var sun_energy_multiplier: float = 1.0
@export_range(0.0, 3.0, 0.01) var moon_energy_multiplier: float = 1.0
@export_range(0.0, 3.0, 0.01) var ambient_energy_multiplier: float = 1.0
@export_range(0.0, 3.0, 0.01) var shadow_opacity_multiplier: float = 1.0
@export_range(0.0, 3.0, 0.01) var tonemap_exposure_multiplier: float = 1.0
@export_range(0.0, 5.0, 0.01) var fog_density_multiplier: float = 1.0
@export_range(0.0, 3.0, 0.01) var fog_height: float = 1.0
@export_range(0.0, 3.0, 0.01) var fog_height_density: float = 1.0

@export_group("Wind Multipliers")
@export_range(0.0, 5.0, 0.01) var wind_strength_multiplier: float = 1.0
@export_range(0.0, 5.0, 0.01) var wind_speed_multiplier: float = 1.0

@export_group("Clouds")
@export var has_clouds: bool = false
@export_range(0.0, 1.0, 0.01) var cloud_noise_threshold: float = 0.6

@export_group("Future Effects")
@export_range(0.0, 10.0, 0.01) var rain_strength: float = 0.0
@export_range(0.0, 10.0, 0.01) var rain_wind_velocity_multiplier: float = 1.0
@export_range(0.0, 10.0, 0.01) var lightning_frequency: float = 0.0
