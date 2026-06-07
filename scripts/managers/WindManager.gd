class_name WindManager
extends Node

@export var wind_direction := Vector3(1.0, 0.0, 1.0)
@export var wind_noise: Texture2D
@export var wind_scale := 0.025
@export var wind_speed := 0.075
@export var wind_strength := 0.4

func _ready() -> void:
	add_to_group("wind_manager")
	apply_wind()

func _process(_delta: float) -> void:
	apply_wind()

func apply_wind() -> void:
	RenderingServer.global_shader_parameter_set("wind_direction", wind_direction.normalized())
	RenderingServer.global_shader_parameter_set("wind_noise", wind_noise)
	RenderingServer.global_shader_parameter_set("wind_scale", wind_scale)
	RenderingServer.global_shader_parameter_set("wind_speed", wind_speed)
	RenderingServer.global_shader_parameter_set("wind_strength", wind_strength)
