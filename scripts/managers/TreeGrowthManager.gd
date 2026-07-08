class_name TreeGrowthManager
extends Node

const TREE_LAYER := &"tree"
const TREE_TAPPER_OBJECT_ID := &"tree_tapper"
const tree_database: TreeDatabase = preload("res://resources/trees/MainTreeDatabase.tres")
const TreeTileResolverScript := preload("res://scripts/grid/TreeTileResolver.gd")

var grid_manager: GridManager
var tile_visual_manager: TileVisualManager


func _ready() -> void:
	add_to_group("tree_growth_manager")

	grid_manager = get_tree().get_first_node_in_group("grid_manager")
	tile_visual_manager = get_tree().get_first_node_in_group("tile_visual_manager")

	tree_database.build_lookup()

	if not TimeManager.day_simulated.is_connected(on_day_simulated):
		TimeManager.day_simulated.connect(on_day_simulated)


func on_day_simulated(_day: int, fast_forward: bool) -> void:
	simulate_day(not fast_forward)


func simulate_day(refresh_visuals: bool = true) -> void:
	if grid_manager == null:
		return

	for coord in grid_manager.grid_data.tiles.keys():
		var tile: GameTileData = grid_manager.grid_data.tiles[coord]

		if tile == null:
			continue

		process_tree_growth(coord, tile, refresh_visuals)


func process_tree_growth(coord: Vector2i, tile: GameTileData, refresh_visuals: bool = true) -> void:
	if not TreeTileResolverScript.has_tree(tile):
		return

	var tree_id: StringName = TreeTileResolverScript.get_tree_id(tile)
	var tree_definition: TreeDefinition = tree_database.get_tree(tree_id) as TreeDefinition

	if tree_definition == null:
		return

	var stage_count: int = tree_definition.get_stage_count()

	if stage_count <= 0:
		return

	var current_stage: int = clampi(TreeTileResolverScript.get_stage_index(tile), 0, stage_count - 1)

	if tree_definition.is_stage_harvestable(current_stage):
		TreeTileResolverScript.set_growth_state(
			tile,
			current_stage,
			TreeTileResolverScript.get_growth_day(tile),
			0
		)
		return

	if tree_definition.is_tapping_tree() and current_stage == 2 and not tile.has_object(TREE_TAPPER_OBJECT_ID):
		TreeTileResolverScript.set_growth_state(
			tile,
			current_stage,
			TreeTileResolverScript.get_growth_day(tile),
			0
		)
		return

	var growth_day: int = TreeTileResolverScript.get_growth_day(tile) + 1
	var days_in_stage: int = TreeTileResolverScript.get_days_in_stage(tile) + 1
	var stage_duration: int = tree_definition.get_stage_duration(current_stage)
	var next_stage: int = current_stage

	if days_in_stage >= stage_duration:
		next_stage = mini(current_stage + 1, stage_count - 1)
		days_in_stage = 0

	TreeTileResolverScript.set_growth_state(tile, next_stage, growth_day, days_in_stage)

	if next_stage == current_stage:
		return

	var new_visual: StringName = StringName(tree_definition.get_stage_visual(next_stage))

	if new_visual != &"":
		tile.set_visual(TREE_LAYER, new_visual)

	if refresh_visuals and tile_visual_manager != null:
		tile_visual_manager.refresh_tile_layer(coord, TREE_LAYER)
