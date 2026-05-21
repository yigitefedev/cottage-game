class_name PlantSeedAction
extends ItemAction

func can_use(context: ItemUseContext) -> bool:
	if context.target_tile == null:
		return false

	if not context.target_tile.usable:
		return false

	if not context.selected_item.has_tag(&"seed"):
		return false

	if context.selected_item.amount <= 0:
		return false

	if context.target_tile.crop_id != &"":
		return false

	var ground: StringName = context.target_tile.visual_layers.get(&"ground", &"")

	if ground != &"tilled_soil" and ground != &"tilled_soil_watered":
		return false

	var crop_id: String = context.selected_item.get_property("crop_id", "")

	if crop_id == "":
		return false

	if context.crop_database == null:
		return false

	var crop := context.crop_database.get_crop(StringName(crop_id))

	if crop == null:
		return false

	if crop.get_stage_count() <= 0:
		return false

	if crop.get_stage_visual(0) == &"":
		return false

	return true


func use(context: ItemUseContext) -> void:
	var crop_id: String = context.selected_item.get_property("crop_id", "")
	var crop := context.crop_database.get_crop(StringName(crop_id))

	context.target_tile.crop_id = StringName(crop_id)
	context.target_tile.crop_stage_index = 0
	context.target_tile.crop_days_in_stage = 0
	context.target_tile.crop_harvestable = crop.is_stage_harvestable(0)

	context.target_tile.set_visual(&"crop", crop.get_stage_visual(0))

	context.selected_item.amount -= 1

	if context.selected_item.amount <= 0:
		context.player_inventory.inventory.set_slot(context.selected_slot_index, null)

	context.tile_visual_manager.refresh_tile(context.target_tile_coord)
