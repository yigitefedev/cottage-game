class_name DevWorldTools
extends Node

@export var tool_enabled := false

var wind_manager: WindManager
var grass: Node3D
var DEFAULT_WIND_STRENGTH := 0.4
var DEFAULT_WIND_SPEED := 0.075
var DEFAULT_WIND_SCALE := 0.025
var DEFAULT_WIND_DIRECTION_X := 1.0
var DEFAULT_WIND_DIRECTION_Z := 1.0

func _ready() -> void:
	add_to_group("dev_world_tools")

	await get_tree().process_frame

	wind_manager = get_tree().get_first_node_in_group("wind_manager")
	grass = get_node_or_null("/root/Main/World/MultiMeshGrass")
	DEFAULT_WIND_SCALE = wind_manager.wind_scale
	DEFAULT_WIND_SPEED = wind_manager.wind_speed
	DEFAULT_WIND_STRENGTH = wind_manager.wind_strength
	DEFAULT_WIND_DIRECTION_X = wind_manager.wind_direction.x
	DEFAULT_WIND_DIRECTION_Z = wind_manager.wind_direction.z
	reset_wind_direction_x()
	reset_wind_direction_z()
	reset_wind_scale()
	reset_wind_speed()
	reset_wind_strength()

func ensure_refs() -> void:
	if wind_manager == null:
		wind_manager = get_tree().get_first_node_in_group("wind_manager")

	if grass == null:
		grass = get_node_or_null("/root/Main/World/MultiMeshGrass")


func set_enabled(enabled: bool) -> void:
	tool_enabled = enabled


func set_grass_visible(enabled: bool) -> void:
	if not tool_enabled:
		return

	ensure_refs()

	if grass != null:
		grass.visible = enabled


func set_wind_strength(value: float) -> void:
	if not tool_enabled:
		return

	ensure_refs()

	if wind_manager != null:
		wind_manager.wind_strength = value


func set_wind_speed(value: float) -> void:
	if not tool_enabled:
		return

	ensure_refs()

	if wind_manager != null:
		wind_manager.wind_speed = value


func set_wind_scale(value: float) -> void:
	if not tool_enabled:
		return

	ensure_refs()

	if wind_manager != null:
		wind_manager.wind_scale = value


func set_wind_direction_x(value: float) -> void:
	if not tool_enabled:
		return

	ensure_refs()

	if wind_manager != null:
		wind_manager.wind_direction.x = value


func set_wind_direction_z(value: float) -> void:
	if not tool_enabled:
		return

	ensure_refs()

	if wind_manager != null:
		wind_manager.wind_direction.z = value
func reset_wind_strength() -> float:
	set_wind_strength(DEFAULT_WIND_STRENGTH)
	return DEFAULT_WIND_STRENGTH


func reset_wind_speed() -> float:
	set_wind_speed(DEFAULT_WIND_SPEED)
	return DEFAULT_WIND_SPEED


func reset_wind_scale() -> float:
	set_wind_scale(DEFAULT_WIND_SCALE)
	return DEFAULT_WIND_SCALE


func reset_wind_direction_x() -> float:
	set_wind_direction_x(DEFAULT_WIND_DIRECTION_X)
	return DEFAULT_WIND_DIRECTION_X


func reset_wind_direction_z() -> float:
	set_wind_direction_z(DEFAULT_WIND_DIRECTION_Z)
	return DEFAULT_WIND_DIRECTION_Z
