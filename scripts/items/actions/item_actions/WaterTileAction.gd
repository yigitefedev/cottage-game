class_name WaterTileAction
extends ItemAction

func can_use(context: ItemUseContext) -> bool:
	if context == null:
		return false

	if context.target_tile == null:
		return false

	if context.selected_item == null:
		return false

	if not context.target_tile.has_flag(&"tilled"):
		return false

	if context.target_tile.has_flag(&"watered"):
		return false

	var water_amount: int = context.selected_item.state.get("water", 0)

	if water_amount <= 0:
		return false

	return true


func use(context: ItemUseContext) -> void:
	context.target_tile.set_flag(&"watered", true)
	context.target_tile.set_flag(&"just_watered", true)
	context.selected_item.state["water"] -= 1
	context.tile_visual_manager.refresh_tile_layer(context.target_tile_coord, &"ground")
