class_name WorkstationRoot
extends Node3D

@export var particles_path: NodePath = ^"Particles"
@export var auto_find_particles := true

var grid_coord: Vector2i
var has_grid_coord := false

var grid_manager: GridManager
var workstation_manager: WorkstationManager
var particles: GPUParticles3D


func _ready() -> void:
	ensure_refs()


func setup(coord: Vector2i, grid_manager_value: GridManager) -> void:
	grid_coord = coord
	has_grid_coord = true
	grid_manager = grid_manager_value

	ensure_refs()
	update_particles(true)


func _process(_delta: float) -> void:
	ensure_refs()
	update_particles(false)


func ensure_refs() -> void:
	if grid_manager == null:
		grid_manager = get_tree().get_first_node_in_group("grid_manager")

	if workstation_manager == null:
		workstation_manager = get_tree().get_first_node_in_group("workstation_manager")

	if particles == null and String(particles_path) != "":
		particles = get_node_or_null(particles_path) as GPUParticles3D

	if particles == null and auto_find_particles:
		var found: Node = find_child("Particles", true, false)

		if found is GPUParticles3D:
			particles = found as GPUParticles3D

	if not has_grid_coord and grid_manager != null:
		grid_coord = grid_manager.world_to_tile(global_position)
		has_grid_coord = true


func update_particles(force_update: bool) -> void:
	if particles == null:
		return

	if workstation_manager == null:
		return

	if not has_grid_coord:
		return

	var state: Dictionary = workstation_manager.get_or_create_state(grid_coord)

	if state.is_empty():
		if force_update or particles.emitting:
			particles.emitting = false
		return

	var workstation_state: StringName = StringName(state.get("state", WorkstationManager.STATE_EMPTY))
	var should_emit := workstation_state == WorkstationManager.STATE_PROCESSING

	if force_update or particles.emitting != should_emit:
		particles.emitting = should_emit
