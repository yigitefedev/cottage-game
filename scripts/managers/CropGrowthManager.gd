class_name CropGrowthManager
extends Node

const crop_database: CropDatabase = preload("res://resources/crops/MainCropDatabase.tres")

var grid_manager: GridManager
var tile_visual_manager: TileVisualManager


func _ready() -> void:
	grid_manager = get_tree().get_first_node_in_group("grid_manager")
	tile_visual_manager = get_tree().get_first_node_in_group("tile_visual_manager")

	crop_database.build_lookup()

	TimeManager.day_started.connect(on_day_started)


func on_day_started(_day: int) -> void:
	if grid_manager == null:
		return

	for coord in grid_manager.grid_data.tiles.keys():
		var tile: GameTileData = grid_manager.grid_data.tiles[coord]

		if tile == null:
			continue

		process_crop_growth(coord, tile)

		reset_watered_state(coord, tile)


func process_crop_growth(coord: Vector2i, tile: GameTileData) -> void:
	if tile.crop_id == &"":
		return

	var crop := crop_database.get_crop(tile.crop_id)

	if crop == null:
		return

	if tile.crop_harvestable:
		return

	if not tile.has_flag(&"watered"):
		return

	tile.crop_days_in_stage += 1
	tile.crop_growth_day += 1

	var stage_duration := crop.get_stage_duration(tile.crop_stage_index)

	if stage_duration <= 0:
		return

	if tile.crop_days_in_stage < stage_duration:
		return

	tile.crop_days_in_stage = 0
	tile.crop_stage_index += 1

	if tile.crop_stage_index >= crop.get_stage_count():
		tile.crop_stage_index = crop.get_stage_count() - 1

	var new_visual := crop.get_stage_visual(tile.crop_stage_index)

	tile.set_visual(&"crop", new_visual)

	tile.crop_harvestable = crop.is_stage_harvestable(tile.crop_stage_index)

	tile_visual_manager.refresh_tile(coord)


func reset_watered_state(coord: Vector2i, tile: GameTileData) -> void:
	var ground: StringName = tile.visual_layers.get(&"ground", &"")

	if ground != &"tilled_soil_watered":
		return

	tile.set_visual(&"ground", &"tilled_soil")

	tile.set_flag(&"watered", false)

	tile_visual_manager.refresh_tile(coord)
