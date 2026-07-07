class_name PlaceTileObjectAction
extends ItemAction


func can_use(context: ItemUseContext) -> bool:
	if context == null:
		return false

	if context.selected_item == null:
		return false

	if context.selected_item.amount <= 0:
		return false

	if not context.selected_item.has_tag(&"placeable_object"):
		return false

	if context.selected_item.has_tag(&"corner_object"):
		return false

	if context.selected_item.has_tag(&"edge_object"):
		return false

	if context.grid_manager == null:
		return false

	if context.tile_targeter == null:
		return false

	var tile: GameTileData = context.target_tile

	if tile == null:
		return false

	if not tile.usable:
		return false

	if tile.has_crop():
		return false

	if tile.has_flag(&"tilled"):
		return false

	if not tile.object_ids.is_empty():
		return false

	var object_id: StringName = StringName(context.selected_item.get_property("object_id", &""))

	if object_id == &"":
		return false

	return true


func use(context: ItemUseContext) -> void:
	if not can_use(context):
		return

	if context.grid_object_manager == null:
		return

	var object_id: StringName = StringName(context.selected_item.get_property("object_id", &""))
	var visual_layer: StringName = StringName(context.selected_item.get_property("visual_layer", &"object"))
	var visual_id: StringName = StringName(context.selected_item.get_property("visual_id", object_id))
	var object_properties: Dictionary = context.selected_item.definition.properties

	var placed: bool = context.grid_object_manager.place_tile_object(
		context.target_tile_coord,
		object_id,
		visual_layer,
		visual_id,
		object_properties
	)

	if not placed:
		return

	context.selected_item.amount -= 1

	if context.selected_item.amount <= 0:
		if context.player_inventory != null:
			context.player_inventory.inventory.set_slot(context.selected_slot_index, null)
