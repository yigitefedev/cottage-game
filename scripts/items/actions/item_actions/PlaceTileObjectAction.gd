class_name PlaceTileObjectAction
extends ItemAction

const tree_database: TreeDatabase = preload("res://resources/trees/MainTreeDatabase.tres")
const TreeTileResolverScript := preload("res://scripts/grid/TreeTileResolver.gd")


func _init() -> void:
	tree_database.build_lookup()


func can_use(context: ItemUseContext) -> bool:
	if context == null:
		return false

	if context.selected_item == null:
		return false

	if context.selected_item.amount <= 0:
		return false

	if not context.selected_item.has_tag(&"placeable_object"):
		return false

	if context.selected_item.has_tag(&"corner_object"):
		return false

	if context.selected_item.has_tag(&"edge_object"):
		return false

	if context.grid_manager == null:
		return false

	if context.tile_targeter == null:
		return false

	var tile: GameTileData = context.target_tile

	if tile == null:
		return false

	if not tile.usable:
		return false

	var requires_tree: bool = bool(context.selected_item.get_property("requires_tree", false))

	if tile.has_crop():
		return false

	if requires_tree and not TreeTileResolverScript.has_tree(tile):
		return false

	if not requires_tree and TreeTileResolverScript.has_tree(tile):
		return false

	if requires_tree and not can_place_on_tree(tile, context.selected_item):
		return false

	if tile.has_flag(&"tilled"):
		return false

	if not tile.object_ids.is_empty():
		return false

	var object_id: StringName = StringName(context.selected_item.get_property("object_id", &""))

	if object_id == &"":
		return false

	return true


func can_place_on_tree(tile: GameTileData, item: ItemInstanceData) -> bool:
	if tile == null or item == null:
		return false

	var tree_stage_index: int = TreeTileResolverScript.get_stage_index(tile)
	var min_tree_stage: int = int(item.get_property("min_tree_stage", 0))
	var max_tree_stage: int = int(item.get_property("max_tree_stage", 999999))

	if tree_stage_index < min_tree_stage:
		return false

	if tree_stage_index > max_tree_stage:
		return false

	var required_tree_type: StringName = StringName(item.get_property("required_tree_type", &""))

	if required_tree_type == &"":
		return true

	var tree_id: StringName = TreeTileResolverScript.get_tree_id(tile)
	var tree_definition: TreeDefinition = tree_database.get_tree(tree_id) as TreeDefinition

	if tree_definition == null:
		return false

	return tree_definition.tree_type == required_tree_type


func use(context: ItemUseContext) -> void:
	if not can_use(context):
		return

	if context.grid_object_manager == null:
		return

	var object_id: StringName = StringName(context.selected_item.get_property("object_id", &""))
	var visual_layer: StringName = StringName(context.selected_item.get_property("visual_layer", &"object"))
	var visual_id: StringName = StringName(context.selected_item.get_property("visual_id", object_id))
	var object_properties: Dictionary = context.selected_item.definition.properties

	var placed: bool = context.grid_object_manager.place_tile_object(
		context.target_tile_coord,
		object_id,
		visual_layer,
		visual_id,
		object_properties
	)

	if not placed:
		return

	context.selected_item.amount -= 1

	if context.selected_item.amount <= 0:
		if context.player_inventory != null:
			context.player_inventory.inventory.set_slot(context.selected_slot_index, null)
