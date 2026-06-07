class_name ObjectTargetIndicator
extends Node3D

@export var outline_material: Material
var grid_manager: GridManager
var targeting_system: TargetingSystem
var current_target: Node3D
var outlined_meshes: Array[MeshInstance3D] = []
var edge_visual_manager: EdgeVisualManager
var corner_visual_manager: CornerVisualManager

func _ready() -> void:
	await get_tree().process_frame
	targeting_system = get_tree().get_first_node_in_group("targeting_system")
	if edge_visual_manager == null:
		edge_visual_manager = get_tree().get_first_node_in_group("edge_visual_manager")
	grid_manager = get_tree().get_first_node_in_group("grid_manager")
	if corner_visual_manager == null:
		corner_visual_manager = get_tree().get_first_node_in_group("corner_visual_manager")
		
func _process(_delta: float) -> void:
	if targeting_system == null:
		targeting_system = get_tree().get_first_node_in_group("targeting_system")

	update_target()


func update_target() -> void:
	if targeting_system == null:

		clear_outline()
		return



	if targeting_system.visual_mode != TargetingSystem.TargetVisualMode.OBJECT:
		clear_outline()
		return

	var target := get_object_target()


	if target != current_target:
		clear_outline()
		current_target = target
		apply_outline(current_target)


func get_object_target() -> Node3D:
	var edge_target := get_edge_object_target()
	if edge_target != null:
		return edge_target

	var corner_target := get_corner_object_target()
	if corner_target != null:
		return corner_target

	var tile_target := get_tile_object_target()
	if tile_target != null:
		return tile_target

	return null
func get_corner_object_target() -> Node3D:
	if targeting_system == null or corner_visual_manager == null or grid_manager == null:
		return null

	var coord := targeting_system.target_corner_coord
	var corner := grid_manager.get_corner(coord)

	if corner == null or not corner.has_object():
		return null

	if not corner_visual_manager.active_corner_visuals.has(coord):
		return null

	for visual in corner_visual_manager.active_corner_visuals[coord]:
		if visual is Node3D:
			return visual

	return null
	
func get_edge_object_target() -> Node3D:
	if targeting_system == null or edge_visual_manager == null or grid_manager == null:
		return null

	var edge := grid_manager.get_edge(
		targeting_system.target_edge_coord,
		targeting_system.target_edge_orientation
	)

	if edge == null or not edge.has_object():
		return null

	var key := edge_visual_manager.make_edge_key(
		targeting_system.target_edge_coord,
		targeting_system.target_edge_orientation
	)
	if not edge_visual_manager.active_edge_visuals.has(key):
		return null

	for visual in edge_visual_manager.active_edge_visuals[key]:
		if visual is Node3D:
			return visual

	return null


func get_tile_object_target() -> Node3D:
	var tile := targeting_system.target_tile

	if tile == null:
		return null

	if tile.object_ids.is_empty():
		return null

	var tile_visual_manager := get_tree().get_first_node_in_group("tile_visual_manager") as TileVisualManager

	if tile_visual_manager == null:
		return null

	if not tile_visual_manager.active_tile_visuals.has(targeting_system.target_tile_coord):
		return null

	for visual in tile_visual_manager.active_tile_visuals[targeting_system.target_tile_coord]:
		if visual is Node3D:
			return visual

	return null



func apply_outline(target: Node3D) -> void:
	if target == null or outline_material == null:
		return

	outlined_meshes.clear()
	collect_meshes(target)

	for mesh_instance in outlined_meshes:
		mesh_instance.material_overlay = outline_material


func clear_outline() -> void:
	for mesh_instance in outlined_meshes:
		if is_instance_valid(mesh_instance):
			mesh_instance.material_overlay = null

	outlined_meshes.clear()
	current_target = null


func collect_meshes(root: Node) -> void:
	if root is MeshInstance3D:
		outlined_meshes.append(root)

	for child in root.get_children():
		collect_meshes(child)
