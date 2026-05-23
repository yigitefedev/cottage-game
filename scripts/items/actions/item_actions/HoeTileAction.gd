class_name HoeTileAction
extends ItemAction

func can_use(context: ItemUseContext) -> bool:
	if context.target_tile == null:
		return false

	if not context.target_tile.usable:
		return false

	return true


func use(context: ItemUseContext) -> void:
	var tile := context.target_tile
	var coord := context.target_tile_coord

	var ground: StringName = tile.visual_layers.get(&"ground", &"")

	if ground == &"tilled_soil" or ground == &"tilled_soil_watered":
		remove_soil(tile)
	else:
		add_soil(tile)

	context.tile_visual_manager.refresh_tile(coord)


func add_soil(tile: GameTileData) -> void:
	tile.set_flag(&"tilled", true)
	tile.set_flag(&"watered", false)

	tile.set_visual(&"ground", &"tilled_soil")


func remove_soil(tile: GameTileData) -> void:
	tile.set_flag(&"tilled", false)
	tile.set_flag(&"watered", false)

	tile.remove_visual(&"ground")

	if tile.crop_id != &"":
		remove_crop(tile)


func remove_crop(tile: GameTileData) -> void:
	tile.crop_id = &""
	tile.crop_growth_day = 0
	tile.crop_stage_index = 0
	tile.crop_days_in_stage = 0
	tile.crop_harvestable = false
	tile.crop_quality = 0

	tile.remove_visual(&"crop")	
