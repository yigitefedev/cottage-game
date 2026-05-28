class_name MalletAction
extends ItemAction


func can_use(context: ItemUseContext) -> bool:
	if context == null:
		return false

	if has_breakable_edge(context):
		return true

	if has_breakable_corner(context):
		return true

	if has_breakable_tile(context):
		return true

	return false


func use(context: ItemUseContext) -> void:
	if context.grid_object_manager == null:
		return

	var drop_position := get_drop_position(context)
	if has_breakable_edge(context):
		context.grid_object_manager.break_edge_object(
			context.target_edge_coord,
			context.target_edge_orientation,
			drop_position
		)
		return

	if has_breakable_corner(context):
		context.grid_object_manager.break_corner_object(
			context.target_corner_coord,
			drop_position
		)
		return

	if has_breakable_tile(context):
		context.grid_object_manager.break_tile_object(
			context.target_tile_coord,
			drop_position
		)


func has_breakable_edge(context: ItemUseContext) -> bool:
	var edge := context.target_edge

	return edge != null and edge.has_object()


func has_breakable_corner(context: ItemUseContext) -> bool:
	var corner := context.target_corner

	return corner != null and corner.has_object()


func has_breakable_tile(context: ItemUseContext) -> bool:
	var tile := context.target_tile

	if tile == null:
		return false

	return not tile.object_ids.is_empty()
func get_drop_position(context: ItemUseContext) -> Vector3:
	if context.grid_manager == null:
		return Vector3.ZERO

	if has_breakable_edge(context):
		return context.grid_manager.edge_to_world(
			context.target_edge_coord,
			context.target_edge_orientation
		) + Vector3.UP * 0.4

	if has_breakable_corner(context):
		return context.grid_manager.corner_to_world(
			context.target_corner_coord
		) + Vector3.UP * 0.4

	if has_breakable_tile(context):
		return context.grid_manager.tile_to_world(
			context.target_tile_coord
		) + Vector3.UP * 0.4

	return Vector3.ZERO
