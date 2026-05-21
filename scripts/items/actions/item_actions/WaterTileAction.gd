class_name WaterTileAction
extends ItemAction

func can_use(context: ItemUseContext) -> bool:
	if context.target_tile == null:
		return false

	var current_ground = context.target_tile.visual_layers.get(&"ground", &"")

	if current_ground != &"tilled_soil":
		return false

	if not context.selected_item.state.has("water"):
		return false

	return context.selected_item.state["water"] > 0


func use(context: ItemUseContext) -> void:
	context.target_tile.set_flag(&"watered", true)

	context.target_tile.set_visual(&"ground", &"tilled_soil_watered")

	context.selected_item.state["water"] -= 1

	context.tile_visual_manager.refresh_tile(context.target_tile_coord)
