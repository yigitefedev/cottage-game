class_name PlantSaplingAction
extends ItemAction

const TREE_LAYER := &"tree"
const TreeTileResolverScript := preload("res://scripts/grid/TreeTileResolver.gd")


func can_use(context: ItemUseContext) -> bool:
	if context == null:
		return false

	if context.target_tile == null:
		return false

	if context.selected_item == null:
		return false

	if not context.selected_item.has_tag(&"sapling"):
		return false

	if context.selected_item.amount <= 0:
		return false

	if context.grid_manager == null:
		return false

	if context.tile_visual_manager == null:
		return false

	if context.tree_database == null:
		return false

	if not can_plant_on_tile(context.target_tile):
		return false

	if has_tree_in_spacing_area(context.grid_manager, context.target_tile_coord):
		return false

	var tree_id := get_sapling_tree_id(context.selected_item)

	if tree_id == &"":
		return false

	var tree_definition: Variant = context.tree_database.get_tree(tree_id)

	if tree_definition == null:
		return false

	if int(tree_definition.get_stage_count()) <= 0:
		return false

	if StringName(tree_definition.get_stage_visual(0)) == &"":
		return false

	return true


func use(context: ItemUseContext) -> void:
	if not can_use(context):
		return

	var tree_id := get_sapling_tree_id(context.selected_item)
	var tree_definition: Variant = context.tree_database.get_tree(tree_id)

	TreeTileResolverScript.set_tree(context.target_tile, tree_id)
	context.target_tile.set_visual(TREE_LAYER, StringName(tree_definition.get_stage_visual(0)))

	context.selected_item.amount -= 1

	if context.selected_item.amount <= 0:
		context.player_inventory.inventory.set_slot(context.selected_slot_index, null)

	context.tile_visual_manager.refresh_tile_layer(context.target_tile_coord, TREE_LAYER)


func can_plant_on_tile(tile: GameTileData) -> bool:
	if tile == null:
		return false

	if not tile.usable:
		return false

	if tile.has_crop():
		return false

	if not tile.object_ids.is_empty():
		return false

	if PlantingSurfaceResolver.has_surface(tile):
		return false

	if TreeTileResolverScript.has_tree(tile):
		return false

	return true


func has_tree_in_spacing_area(grid_manager: GridManager, center_coord: Vector2i) -> bool:
	for x in range(-1, 2):
		for y in range(-1, 2):
			var tile := grid_manager.get_tile(center_coord + Vector2i(x, y))

			if TreeTileResolverScript.has_tree(tile):
				return true

	return false


func get_sapling_tree_id(item: ItemInstanceData) -> StringName:
	if item == null:
		return &""

	var raw_tree_id: Variant = item.get_property("tree_id", &"")

	if raw_tree_id != null and StringName(raw_tree_id) != &"":
		return StringName(raw_tree_id)

	var raw_crop_id: Variant = item.get_property("crop_id", &"")
	var crop_id := String(raw_crop_id)

	if crop_id.begins_with("crop_"):
		return StringName("tree_%s" % crop_id.trim_prefix("crop_"))

	if item.definition != null:
		var item_id := String(item.definition.id)

		if item_id.begins_with("sapling_"):
			return StringName("tree_%s" % item_id.trim_prefix("sapling_"))

	return &""
