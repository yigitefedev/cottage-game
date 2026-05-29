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

	if context.grid_object_manager == null:
		return

	var object_id: StringName = context.selected_item.get_property("object_id", &"")
	var visual_layer: StringName = context.selected_item.get_property("visual_layer", &"object")
	var visual_id: StringName = context.selected_item.get_property("visual_id", object_id)

	var placed: bool = context.grid_object_manager.place_edge_object(
		context.target_edge_coord,
		context.target_edge_orientation,
		object_id,
		visual_layer,
		visual_id
	)

	if not placed:
		return

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
