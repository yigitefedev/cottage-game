class_name PlaceEdgeObjectAction
extends ItemAction


func can_use(context: ItemUseContext) -> bool:
	if context == null:
		return false

	if context.selected_item == null:
		return false

	if context.selected_item.amount <= 0:
		return false

	if not context.selected_item.has_tag(&"edge_object"):
		return false

	if context.grid_manager == null:
		return false

	if context.edge_targeter == null:
		return false

	var edge := context.target_edge

	if edge != null and edge.has_object():
		return false

	if not is_edge_usable(context):
		return false

	return true


func use(context: ItemUseContext) -> void:
	if not can_use(context):
		return

	var object_id: StringName = context.selected_item.get_property("object_id", &"")
	var visual_layer: StringName = context.selected_item.get_property("visual_layer", &"object")
	var visual_id: StringName = context.selected_item.get_property("visual_id", object_id)

	if object_id == &"" or visual_id == &"":
		return

	var coord := context.target_edge_coord
	var orientation := context.target_edge_orientation

	var edge := context.grid_manager.get_or_create_edge(coord, orientation)

	edge.object_id = object_id
	edge.set_visual(visual_layer, visual_id)

	if context.edge_visual_manager != null:
		context.edge_visual_manager.refresh_edge(coord, orientation)

	context.selected_item.amount -= 1

	if context.selected_item.amount <= 0:
		context.player_inventory.inventory.set_slot(context.selected_slot_index, null)


func is_edge_usable(context: ItemUseContext) -> bool:
	var edge_coord := context.target_edge_coord
	var orientation := context.target_edge_orientation

	var adjacent_tiles: Array[Vector2i] = []

	if orientation == &"horizontal":
		adjacent_tiles = [
			edge_coord + Vector2i(0, -1),
			edge_coord
		]

	elif orientation == &"vertical":
		adjacent_tiles = [
			edge_coord + Vector2i(-1, 0),
			edge_coord
		]

	for tile_coord in adjacent_tiles:
		var tile := context.grid_manager.get_tile(tile_coord)

		if tile != null and tile.usable:
			return true

	return false
