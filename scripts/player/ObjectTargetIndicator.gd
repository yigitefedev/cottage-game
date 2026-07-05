class_name ObjectTargetIndicator
extends Node3D

@export var outline_material: Material
var grid_manager: GridManager
var object_target_resolver: ObjectTargetResolver
var targeting_system: TargetingSystem
var current_target: Node3D
var outlined_meshes: Array[MeshInstance3D] = []
var edge_visual_manager: EdgeVisualManager
var corner_visual_manager: CornerVisualManager

func _ready() -> void:
	await get_tree().process_frame
	object_target_resolver = get_tree().get_first_node_in_group("object_target_resolver")
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
	if object_target_resolver == null:
		object_target_resolver = get_tree().get_first_node_in_group("object_target_resolver")

	if object_target_resolver == null:
		return null

	return object_target_resolver.get_current_visual()



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
