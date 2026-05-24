class_name PlaceCornerObjectAction
extends ItemAction

func can_use(context: ItemUseContext) -> bool:
	if context == null:
		return false

	if context.selected_item == null:
		return false

	if context.selected_item.amount <= 0:
		return false

	if not context.selected_item.has_tag(&"corner_object"):
		return false

	if context.grid_manager == null:
		return false

	if context.corner_targeter == null:
		return false

	var corner := context.target_corner

	if corner != null and corner.has_object():
		return false
	
	if not is_corner_usable(context, context.target_corner_coord):
		return false

	return true


func use(context: ItemUseContext) -> void:
	var object_id: StringName = context.selected_item.get_property("object_id", &"")
	var visual_layer: StringName = context.selected_item.get_property("visual_layer", &"object")
	var visual_id: StringName = context.selected_item.get_property("visual_id", object_id)

	if object_id == &"":
		return

	var coord := context.target_corner_coord
	var corner := context.grid_manager.get_or_create_corner(coord)

	corner.object_id = object_id
	corner.set_visual(visual_layer, visual_id)

	if context.corner_visual_manager != null:
		context.corner_visual_manager.refresh_corner(coord)

	context.selected_item.amount -= 1

	if context.selected_item.amount <= 0:
		context.player_inventory.inventory.set_slot(context.selected_slot_index, null)
	
func is_corner_usable(context: ItemUseContext, corner_coord: Vector2i) -> bool:
	var affected_tiles := [
		corner_coord + Vector2i(-1, -1),
		corner_coord + Vector2i(0, -1),
		corner_coord + Vector2i(-1, 0),
		corner_coord + Vector2i(0, 0),
	]

	for tile_coord in affected_tiles:
		var tile := context.grid_manager.get_tile(tile_coord)

		if tile != null and tile.usable:
			return true

	return false
