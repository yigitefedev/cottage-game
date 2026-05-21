class_name HoeTileAction
extends ItemAction

func can_use(context: ItemUseContext) -> bool:
	if context.target_tile == null:
		return false

	if not context.target_tile.usable:
		return false

	var current_ground = context.target_tile.visual_layers.get(&"ground", &"")

	if current_ground == &"tilled_soil":
		return false

	if current_ground == &"tilled_soil_watered":
		return false

	return true


func use(context: ItemUseContext) -> void:
	context.target_tile.set_flag(&"tilled", true)

	context.target_tile.set_visual(&"ground", &"tilled_soil")

	context.tile_visual_manager.refresh_tile(context.target_tile_coord)
