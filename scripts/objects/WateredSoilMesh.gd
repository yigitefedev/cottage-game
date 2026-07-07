class_name WateredSoilMesh
extends MeshInstance3D

@export var color_transition_time := 3.0

var coord: Vector2i
var grid_manager: GridManager
var material_instance: ShaderMaterial


func _ready() -> void:
	call_deferred("refresh_from_tile")


func refresh_from_tile() -> void:
	grid_manager = get_tree().get_first_node_in_group("grid_manager")

	if grid_manager == null:
		return

	coord = grid_manager.world_to_tile(global_position)

	var tile := grid_manager.get_tile(coord)

	if tile == null:
		return

	if tile.has_flag(&"watered"):
		if tile.has_flag(&"just_watered"):
			tile.set_flag(&"just_watered", false)
			set_material_wetness(0.0)
			update_material(false)
		else:
			update_material(true)
	else:
		update_material(true)


func ensure_material_instance() -> bool:
	if material_instance == null:
		var base_mat := get_active_material(0)

		if base_mat != null and base_mat is ShaderMaterial:
			material_instance = base_mat.duplicate() as ShaderMaterial
		else:
			return false

		set_surface_override_material(0, material_instance)

	return true


func set_material_wetness(value: float) -> void:
	if not ensure_material_instance():
		return

	material_instance.set_shader_parameter("wetness", value)


func update_material(instant: bool = false) -> void:
	if grid_manager == null:
		return

	var tile := grid_manager.get_tile(coord)

	if tile == null:
		return

	if not ensure_material_instance():
		return

	var target_wetness := 1.0 if tile.has_flag(&"watered") else 0.0

	if instant:
		material_instance.set_shader_parameter("wetness", target_wetness)
		return

	var duration := color_transition_time

	if tile.has_flag(&"slow_water_tween"):
		duration *= 4.0
		tile.set_flag(&"slow_water_tween", false)

	var start_wetness := float(material_instance.get_shader_parameter("wetness"))
	var tween := create_tween()

	tween.tween_method(
		func(value: float) -> void:
			material_instance.set_shader_parameter("wetness", value),
		start_wetness,
		target_wetness,
		duration
	)
