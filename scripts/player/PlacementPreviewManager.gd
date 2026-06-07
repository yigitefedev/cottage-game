class_name PlacementPreviewManager
extends Node3D

var targeting_system: TargetingSystem
var grid_manager: GridManager
var tile_visual_manager: TileVisualManager

var current_preview: Node3D
var current_visual_id: StringName = &""
@onready var tool_controller: ToolController = $"../ToolController"
var preview_is_valid := true

func _ready() -> void:
	await get_tree().process_frame

	targeting_system = get_tree().get_first_node_in_group("targeting_system")
	grid_manager = get_tree().get_first_node_in_group("grid_manager")
	tile_visual_manager = get_tree().get_first_node_in_group("tile_visual_manager")
	if tool_controller == null:
		tool_controller = get_tree().get_first_node_in_group("tool_controller")
func _process(_delta: float) -> void:
	if targeting_system == null:
		targeting_system = get_tree().get_first_node_in_group("targeting_system")

	if grid_manager == null:
		grid_manager = get_tree().get_first_node_in_group("grid_manager")

	if tile_visual_manager == null:
		tile_visual_manager = get_tree().get_first_node_in_group("tile_visual_manager")
	
	if tool_controller == null:
		tool_controller = get_tree().get_first_node_in_group("tool_controller")
	update_preview()


func update_preview() -> void:
	if targeting_system == null or grid_manager == null or tile_visual_manager == null:
		hide_preview()
		return

	if targeting_system.visual_mode != TargetingSystem.TargetVisualMode.GHOST:
		hide_preview()
		return

	var item := targeting_system.selected_item
	if item == null:
		hide_preview()
		return

	var visual_id: StringName = item.get_property(&"visual_id", &"")

	if visual_id == &"":
		hide_preview()
		return

	ensure_preview(visual_id)
	preview_is_valid = get_preview_valid(item)
	apply_preview_material(current_preview, preview_is_valid)
	update_preview_transform()

func get_preview_valid(item: ItemInstanceData) -> bool:
	if item == null or item.definition == null:
		return false

	var action := item.definition.primary_action

	if action == null:
		return true

	if tool_controller == null:
		return true

	var context := tool_controller.build_context(item)

	context.selected_item = item

	var result := action.can_use(context)

	return result
	
func ensure_preview(visual_id: StringName) -> void:
	if current_preview != null and current_visual_id == visual_id:
		current_preview.visible = true
		return

	clear_preview()

	if not tile_visual_manager.visual_lookup.has(visual_id):
		push_warning("PlacementPreviewManager: visual_id bulunamadı: %s" % visual_id)
		return

	var definition: TileVisualDefinition = tile_visual_manager.visual_lookup[visual_id]

	if definition == null or definition.scene == null:
		return

	current_preview = definition.scene.instantiate() as Node3D
	add_child(current_preview)

	current_visual_id = visual_id
	current_preview.visible = true

	disable_preview_collision(current_preview)
	apply_preview_material(current_preview, true)


func update_preview_transform() -> void:
	if current_preview == null:
		return

	match targeting_system.target_shape:
		TargetingSystem.TargetShape.CORNER:
			current_preview.global_position = grid_manager.corner_to_world(targeting_system.target_corner_coord)
			current_preview.global_rotation = Vector3.ZERO

		TargetingSystem.TargetShape.EDGE:
			current_preview.global_position = grid_manager.edge_to_world(
				targeting_system.target_edge_coord,
				targeting_system.target_edge_orientation
			)

			current_preview.global_rotation = Vector3.ZERO

			if targeting_system.target_edge_orientation == &"vertical":
				current_preview.global_rotation.y = PI * 0.5

		_:
			current_preview.global_position = grid_manager.tile_to_world(targeting_system.target_tile_coord)
			current_preview.global_rotation = Vector3.ZERO


func hide_preview() -> void:
	if current_preview != null:
		current_preview.visible = false


func clear_preview() -> void:
	if current_preview != null:
		current_preview.queue_free()

	current_preview = null
	current_visual_id = &""


func disable_preview_collision(root: Node) -> void:
	if root is CollisionShape3D:
		root.disabled = true

	if root is CollisionObject3D:
		root.collision_layer = 0
		root.collision_mask = 0

	for child in root.get_children():
		disable_preview_collision(child)


func apply_preview_material(root: Node, is_valid: bool) -> void:
	if root == null:
		return

	var color := Color(1.0, 1.0, 1.0, 0.45)

	if not is_valid:
		color = Color(1.0, 0.35, 0.45, 0.45)

	if root is MeshInstance3D:
		var mesh_instance := root as MeshInstance3D

		if mesh_instance.mesh != null:
			var ghost_mat := StandardMaterial3D.new()
			ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ghost_mat.albedo_color = color
			ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

			for i in range(mesh_instance.mesh.get_surface_count()):
				mesh_instance.set_surface_override_material(i, ghost_mat)

	for child in root.get_children():
		apply_preview_material(child, is_valid)
