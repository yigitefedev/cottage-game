class_name HarvestCropInteractionAction
extends InteractionAction

const crop_database: CropDatabase = preload("res://resources/crops/MainCropDatabase.tres")
const item_database: ItemDatabase = preload("res://resources/items/MainItemDatabase.tres")


func can_interact(context: InteractionContext) -> bool:
	if context.target_tile == null:
		return false

	if context.target_tile.crop_id == &"":
		return false

	if not context.target_tile.crop_harvestable:
		return false

	var crop := crop_database.get_crop(context.target_tile.crop_id)

	if crop == null:
		return false

	if crop.harvest_item_id == &"":
		return false

	return true


func interact(context: InteractionContext) -> void:
	harvest_tile(context, context.target_tile_coord, context.target_tile)


func harvest_tile(context: InteractionContext, coord: Vector2i, tile: GameTileData) -> void:
	if tile == null:
		return

	var crop := crop_database.get_crop(tile.crop_id)

	if crop == null:
		return

	var harvest_item := item_database.get_item(crop.harvest_item_id)
	
	if context.world_item_spawner == null:
		return

	if harvest_item == null:
		return

	var amount := randi_range(crop.harvest_amount_min, crop.harvest_amount_max)
	var drop_position := context.grid_manager.tile_to_world(coord) + Vector3.UP * 0.4


	if context.world_item_spawner == null:
		return
	for i in range(amount):

		var item := ItemInstanceData.new()
		item.definition = harvest_item
		item.amount = 1

		context.world_item_spawner.spawn_item(item, drop_position)

	clear_crop(context, coord, tile)


func clear_crop(context: InteractionContext, coord: Vector2i, tile: GameTileData) -> void:
	var crop := crop_database.get_crop(tile.crop_id)

	if crop != null and crop.regrow_after_harvest:
		var reset_stage: int = clampi(
			crop.regrow_stage_index,
			0,
			crop.stage_visual_ids.size() - 1
		)

		tile.crop_growth_day = 0
		tile.crop_stage_index = reset_stage
		tile.crop_days_in_stage = 0
		tile.crop_harvestable = false
		tile.crop_quality = 0

		var visual_id: StringName = crop.stage_visual_ids[reset_stage]

		if visual_id != &"":
			tile.set_visual(&"crop", visual_id)
		else:
			tile.remove_visual(&"crop")

	else:
		tile.crop_id = &""
		tile.crop_growth_day = 0
		tile.crop_stage_index = 0
		tile.crop_days_in_stage = 0
		tile.crop_harvestable = false
		tile.crop_quality = 0

		tile.remove_visual(&"crop")

	context.tile_visual_manager.refresh_tile(coord)
	
func _init() -> void:
	crop_database.build_lookup()
	item_database.build_lookup()
