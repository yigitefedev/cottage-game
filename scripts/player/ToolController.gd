class_name ToolController
extends Node

var player_inventory: PlayerInventory
var tile_targeter: PlayerTileTargeter
const crop_database: CropDatabase = preload("res://resources/crops/MainCropDatabase.tres")
var grid_manager: GridManager
var tile_visual_manager: TileVisualManager
var corner_targeter: PlayerCornerTargeter
var corner_visual_manager: CornerVisualManager
var edge_targeter: PlayerEdgeTargeter
var edge_visual_manager: EdgeVisualManager
var grid_object_manager: GridObjectManager
var player_stamina: PlayerStamina

func _ready() -> void:
	await get_tree().process_frame
	crop_database.build_lookup()
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

func _input(event: InputEvent) -> void:
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

	context.player = get_parent() as CharacterBody3D

	context.player_inventory = player_inventory
	context.tool_controller = self

	context.selected_slot_index = player_inventory.selected_index
	context.selected_item = item
	context.crop_database = crop_database

	context.grid_manager = grid_manager
	context.tile_visual_manager = tile_visual_manager
	context.tile_targeter = tile_targeter

	context.target_tile_coord = tile_targeter.get_target_tile()
	context.target_tile = tile_targeter.get_target_tile_data()
	context.corner_targeter = corner_targeter
	context.corner_visual_manager = corner_visual_manager
	context.grid_object_manager = grid_object_manager
	context.player_stamina = player_stamina

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
