class_name AxeAction
extends ItemAction

const TREE_TAPPER_OBJECT_ID := &"tree_tapper"
const TreeTileResolverScript := preload("res://scripts/grid/TreeTileResolver.gd")


func can_use(context: ItemUseContext) -> bool:
	if context == null:
		return false

	if context.target_tile == null:
		return false

	if context.grid_manager == null:
		return false

	return TreeTileResolverScript.has_tree(context.target_tile)


func use(context: ItemUseContext) -> void:
	if not can_use(context):
		return

	var tile: GameTileData = context.target_tile
	var drop_position: Vector3 = context.grid_manager.tile_to_world(context.target_tile_coord) + Vector3.UP * 0.4

	if tile.has_object(TREE_TAPPER_OBJECT_ID) and context.grid_object_manager != null:
		context.grid_object_manager.break_tile_object(
			context.target_tile_coord,
			drop_position,
			TREE_TAPPER_OBJECT_ID
		)

	TreeTileResolverScript.clear_tree(tile)

	if context.tile_visual_manager != null:
		context.tile_visual_manager.refresh_tile(context.target_tile_coord)
