class_name ToolController
extends Node

var player_inventory: PlayerInventory
var tile_targeter: PlayerTileTargeter
const crop_database: CropDatabase = preload("res://resources/crops/MainCropDatabase.tres")
const tree_database = preload("res://resources/trees/MainTreeDatabase.tres")
@export var item_database: ItemDatabase
var grid_manager: GridManager
var tile_visual_manager: TileVisualManager
var corner_targeter: PlayerCornerTargeter
var corner_visual_manager: CornerVisualManager
var edge_targeter: PlayerEdgeTargeter
var edge_visual_manager: EdgeVisualManager
var grid_object_manager: GridObjectManager
var player_stamina: PlayerStamina
var grass_mask_manager: GrassMaskManager
var world_item_spawner: WorldItemSpawner
var player: CharacterBody3D
var object_target_resolver: ObjectTargetResolver

func _ready() -> void:
	await get_tree().process_frame
	crop_database.build_lookup()
	tree_database.build_lookup()
	player_inventory = get_tree().get_first_node_in_group("player_inventory")
	tile_targeter = get_tree().get_first_node_in_group("player_tile_targeter")
	corner_targeter = get_tree().get_first_node_in_group("player_corner_targeter")
	corner_visual_manager = get_tree().get_first_node_in_group("corner_visual_manager")
	grid_object_manager = get_tree().get_first_node_in_group("grid_object_manager")
	grid_manager = get_tree().get_first_node_in_group("grid_manager")
	tile_visual_manager = get_tree().get_first_node_in_group("tile_visual_manager")
	edge_targeter = get_tree().get_first_node_in_group("player_edge_targeter")
	edge_visual_manager = get_tree().get_first_node_in_group("edge_visual_manager")
	player_stamina = get_tree().get_first_node_in_group("player_stamina")
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	world_item_spawner = get_tree().get_first_node_in_group("world_item_spawner")
	grass_mask_manager = get_tree().get_first_node_in_group("grass_mask_manager")
	object_target_resolver = get_tree().get_first_node_in_group("object_target_resolver")
	
	if item_database != null:
		item_database.build_lookup()
func _input(event: InputEvent) -> void:
	if DevManager.is_gameplay_input_locked():
		return
	if event.is_action_pressed("use_item"):
		use_selected_item()
	


func use_selected_item() -> void:
	if player_inventory == null:
		return

	var item := player_inventory.get_selected_item()

	if item == null:
		return

	if item.definition == null:
		return

	var action := item.definition.primary_action

	if action == null:
		return

	var context := build_context(item)
	if not action.can_use(context):
		return

	if player_stamina != null:
		if not player_stamina.can_spend(action.stamina_cost):
			return

		action.use(context)
		player_stamina.spend(action.stamina_cost)
	else:
		action.use(context)
	player_inventory.inventory_changed.emit()



func build_context(item: ItemInstanceData) -> ItemUseContext:
	var context := ItemUseContext.new()
	add_to_group("tool_controller")
	context.player = player

	context.player_inventory = player_inventory
	context.tool_controller = self
	if object_target_resolver == null:
		object_target_resolver = get_tree().get_first_node_in_group("object_target_resolver")

	context.object_target_resolver = object_target_resolver
	context.selected_slot_index = player_inventory.get_inventory_index_for_hotbar_index(player_inventory.selected_index)
	context.selected_item = item
	context.crop_database = crop_database
	context.tree_database = tree_database

	context.grid_manager = grid_manager
	context.tile_visual_manager = tile_visual_manager
	context.tile_targeter = tile_targeter

	context.target_tile_coord = tile_targeter.get_target_tile()
	context.target_tile = tile_targeter.get_target_tile_data()
	context.corner_targeter = corner_targeter
	context.corner_visual_manager = corner_visual_manager
	context.grid_object_manager = grid_object_manager
	context.player_stamina = player_stamina
	context.grass_mask_manager = grass_mask_manager
	context.world_item_spawner = world_item_spawner
	context.item_database = item_database

	if corner_targeter != null:
		context.target_corner_coord = corner_targeter.get_target_corner()
		context.target_corner = grid_manager.get_corner(context.target_corner_coord)
	
	context.edge_targeter = edge_targeter
	context.edge_visual_manager = edge_visual_manager

	if edge_targeter != null:
		context.target_edge_coord = edge_targeter.get_target_edge_coord()
		context.target_edge_orientation = edge_targeter.get_target_edge_orientation()
		context.target_edge = edge_targeter.get_target_edge_data()
	
	return context
