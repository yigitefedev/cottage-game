class_name ToolTargetIndicator
extends Node3D

@export var targeting_system: TargetingSystem

@onready var tile_indicator: MeshInstance3D = $TileIndicator

var grid_manager: GridManager


func _ready() -> void:
	tile_indicator.visible = false

	await get_tree().process_frame

	grid_manager = get_tree().get_first_node_in_group("grid_manager")

	if targeting_system == null:
		targeting_system = get_tree().get_first_node_in_group("targeting_system")

func _process(_delta: float) -> void:
	if targeting_system == null or grid_manager == null:
		tile_indicator.visible = false
		return

	if targeting_system.visual_mode != TargetingSystem.TargetVisualMode.SOFT_TILE:
		tile_indicator.visible = false
		return

	tile_indicator.visible = true
	tile_indicator.global_position = grid_manager.tile_to_world(targeting_system.target_tile_coord) + Vector3.UP * 0.24
	tile_indicator.global_rotation = Vector3.ZERO
