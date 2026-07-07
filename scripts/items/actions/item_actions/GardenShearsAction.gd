class_name GardenShearsAction
extends ItemAction

const WEED_KEY := "weed"
const PLANT_WASTE_ID := &"plant_waste"
const MAX_WEED_LEVEL := 3
const DROP_HEIGHT := 0.4


func can_use(context: ItemUseContext) -> bool:
	if context == null:
		return false

	if context.target_tile == null:
		return false

	if context.world_item_spawner == null:
		return false

	if context.item_database == null:
		return false

	if context.grid_manager == null:
		return false

	return context.target_tile.custom_data.has(WEED_KEY)


func use(context: ItemUseContext) -> void:
	if not can_use(context):
		return

	var weed_level := get_weed_level(context.target_tile)
	var drop_position := context.grid_manager.tile_to_world(context.target_tile_coord) + Vector3.UP * DROP_HEIGHT

	context.target_tile.custom_data.erase(WEED_KEY)
	context.target_tile.remove_visual(&"weed")

	if context.tile_visual_manager != null:
		context.tile_visual_manager.refresh_tile_layer(context.target_tile_coord, &"weed")

	spawn_plant_waste(context, drop_position, weed_level)


func get_weed_level(tile: GameTileData) -> int:
	var raw_data: Variant = tile.custom_data.get(WEED_KEY, {})

	if raw_data is Dictionary:
		var weed_data: Dictionary = raw_data
		return clampi(int(weed_data.get("level", 1)), 1, MAX_WEED_LEVEL)

	return 1


func spawn_plant_waste(context: ItemUseContext, drop_position: Vector3, amount: int) -> void:
	var plant_waste_definition := context.item_database.get_item(PLANT_WASTE_ID)

	if plant_waste_definition == null:
		push_warning("GardenShearsAction: plant_waste is missing from the item database.")
		return

	for _i in range(amount):
		var waste := ItemInstanceData.new()
		waste.definition = plant_waste_definition
		waste.amount = 1

		context.world_item_spawner.spawn_item(waste, drop_position)
