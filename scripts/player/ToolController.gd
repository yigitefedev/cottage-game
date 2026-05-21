class_name ToolController
extends Node

var player_inventory: PlayerInventory
var tile_targeter: PlayerTileTargeter
const crop_database: CropDatabase = preload("res://resources/crops/MainCropDatabase.tres")
var grid_manager: GridManager
var tile_visual_manager: TileVisualManager

func _ready() -> void:
	await get_tree().process_frame
	crop_database.build_lookup()
	player_inventory = get_tree().get_first_node_in_group("player_inventory")
	tile_targeter = get_tree().get_first_node_in_group("player_tile_targeter")


	grid_manager = get_tree().get_first_node_in_group("grid_manager")
	tile_visual_manager = get_tree().get_first_node_in_group("tile_visual_manager")
	
	print("ToolController ready")
	print("inventory: ", player_inventory)
	print("targeter: ", tile_targeter)
	print("grid: ", grid_manager)
	print("visual manager: ", tile_visual_manager)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("use_item"):
		print("F pressed")
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

	return context
