class_name HarvestTreeInteractionAction
extends InteractionAction

const TREE_LAYER := &"tree"
const tree_database: TreeDatabase = preload("res://resources/trees/MainTreeDatabase.tres")
const item_database: ItemDatabase = preload("res://resources/items/MainItemDatabase.tres")
const TreeTileResolverScript := preload("res://scripts/grid/TreeTileResolver.gd")


func _init() -> void:
	tree_database.build_lookup()
	item_database.build_lookup()


func can_interact(context: InteractionContext) -> bool:
	if context == null:
		return false

	if context.target_tile == null:
		return false

	if context.grid_manager == null:
		return false

	if context.world_item_spawner == null:
		return false

	if not TreeTileResolverScript.has_tree(context.target_tile):
		return false

	var tree_definition: TreeDefinition = get_tree_definition(context.target_tile)

	if tree_definition == null:
		return false

	if not is_tree_ready(context.target_tile, tree_definition):
		return false

	var harvest_item: ItemDefinition = get_harvest_item(tree_definition)

	if harvest_item == null:
		return false

	return harvest_item.has_tag(&"fruit") or harvest_item.has_tag(&"tree_fruit") or harvest_item.has_tag(&"tree_product")


func interact(context: InteractionContext) -> void:
	if not can_interact(context):
		return

	var tile: GameTileData = context.target_tile
	var tree_definition: TreeDefinition = get_tree_definition(tile)
	var harvest_item: ItemDefinition = get_harvest_item(tree_definition)

	if harvest_item == null:
		return

	if context.world_item_spawner == null:
		return

	var drop_position: Vector3 = context.grid_manager.tile_to_world(context.target_tile_coord) + Vector3.UP * 0.4
	var amount_min: int = mini(tree_definition.harvest_amount_min, tree_definition.harvest_amount_max)
	var amount_max: int = maxi(tree_definition.harvest_amount_min, tree_definition.harvest_amount_max)
	var amount: int = randi_range(amount_min, amount_max)

	for i: int in range(amount):
		var item: ItemInstanceData = ItemInstanceData.new()
		item.definition = harvest_item
		item.amount = 1

		context.world_item_spawner.spawn_item(item, drop_position)

	regrow_tree(context, tile, tree_definition)


func get_tree_definition(tile: GameTileData) -> TreeDefinition:
	var tree_id: StringName = TreeTileResolverScript.get_tree_id(tile)

	if tree_id == &"":
		return null

	return tree_database.get_tree(tree_id) as TreeDefinition


func get_harvest_item(tree_definition: TreeDefinition) -> ItemDefinition:
	if tree_definition == null:
		return null

	var harvest_item_id: StringName = tree_definition.harvest_item_id

	if harvest_item_id == &"":
		var tree_id: String = String(tree_definition.id)
		harvest_item_id = StringName("harvest_item_%s" % tree_id.trim_prefix("tree_"))

	return item_database.get_item(harvest_item_id)


func is_tree_ready(tile: GameTileData, tree_definition: TreeDefinition) -> bool:
	var current_stage: int = TreeTileResolverScript.get_stage_index(tile)

	return tree_definition.is_stage_harvestable(current_stage)


func regrow_tree(context: InteractionContext, tile: GameTileData, tree_definition: TreeDefinition) -> void:
	if not tree_definition.regrow_after_harvest:
		TreeTileResolverScript.clear_tree(tile)

		if context.tile_visual_manager != null:
			context.tile_visual_manager.refresh_tile_layer(context.target_tile_coord, TREE_LAYER)

		return

	var stage_count: int = tree_definition.get_stage_count()

	if stage_count <= 0:
		return

	var regrow_stage: int = clampi(tree_definition.regrow_stage_index, 0, stage_count - 1)

	TreeTileResolverScript.set_growth_state(tile, regrow_stage, 0, 0)

	var visual_id: StringName = StringName(tree_definition.get_stage_visual(regrow_stage))

	if visual_id != &"":
		tile.set_visual(TREE_LAYER, visual_id)

	if context.tile_visual_manager != null:
		context.tile_visual_manager.refresh_tile_layer(context.target_tile_coord, TREE_LAYER)
