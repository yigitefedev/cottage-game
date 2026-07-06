class_name InteractionController
extends Node

@export var interaction_actions: Array[InteractionAction] = []

var active_hold_action: HoldInteractionAction
var active_hold_context: InteractionContext
var active_hold_time := 0.0
var active_hold_completed := false

var player: CharacterBody3D

var grid_manager: GridManager
var tile_visual_manager: TileVisualManager
var tile_targeter: PlayerTileTargeter
var world_item_spawner: WorldItemSpawner
@export var item_database: ItemDatabase

var player_inventory: PlayerInventory
var workstation_manager: WorkstationManager

func _ready() -> void:
	await get_tree().process_frame

	player = get_parent() as CharacterBody3D
	player_inventory = get_tree().get_first_node_in_group("player_inventory")
	workstation_manager = get_tree().get_first_node_in_group("workstation_manager")
	grid_manager = get_tree().get_first_node_in_group("grid_manager")
	tile_visual_manager = get_tree().get_first_node_in_group("tile_visual_manager")
	tile_targeter = get_tree().get_first_node_in_group("player_tile_targeter")
	world_item_spawner = get_tree().get_first_node_in_group("world_item_spawner")

func _process(delta: float) -> void:
	update_hold_interaction(delta)

func update_hold_interaction(delta: float) -> void:
	if active_hold_action == null:
		return

	if active_hold_completed:
		return

	if not Input.is_action_pressed("interact"):
		return

	active_hold_time += delta

	if active_hold_time >= active_hold_action.hold_duration_seconds:
		active_hold_completed = true
		active_hold_action.complete_hold(active_hold_context)
		clear_active_hold()
	
func _input(event: InputEvent) -> void:
	if DevManager.is_gameplay_input_locked():
		return
	if event.is_action_pressed("interact"):
		start_interaction_input()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_released("interact"):
		release_interaction_input()
		get_viewport().set_input_as_handled()
		return

func start_interaction_input() -> void:
	var context: InteractionContext = build_context()
	var hold_action: HoldInteractionAction = find_hold_action(context)

	if hold_action != null:
		active_hold_action = hold_action
		active_hold_context = context
		active_hold_time = 0.0
		active_hold_completed = false
		return

	run_normal_interaction(context)


func release_interaction_input() -> void:
	if active_hold_action == null:
		return

	if not active_hold_completed:
		var context: InteractionContext = build_context()
		run_normal_interaction(context)

	clear_active_hold()


func clear_active_hold() -> void:
	active_hold_action = null
	active_hold_context = null
	active_hold_time = 0.0
	active_hold_completed = false


func find_hold_action(context: InteractionContext) -> HoldInteractionAction:
	for action: InteractionAction in interaction_actions:
		if action == null:
			continue

		if not (action is HoldInteractionAction):
			continue

		var hold_action := action as HoldInteractionAction

		if hold_action.can_start_hold(context):
			return hold_action

	return null


func run_normal_interaction(context: InteractionContext) -> void:
	for action: InteractionAction in interaction_actions:
		if action == null:
			continue

		if action is HoldInteractionAction:
			continue

		if action.can_interact(context):
			action.interact(context)
			return
			
func try_interact() -> void:
	var context := build_context()

	for action in interaction_actions:
		if action == null:
			continue

		if action.can_interact(context):
			action.interact(context)
			return


func build_context() -> InteractionContext:
	var context := InteractionContext.new()

	context.player = player

	context.grid_manager = grid_manager
	context.tile_visual_manager = tile_visual_manager
	context.tile_targeter = tile_targeter
	context.world_item_spawner = world_item_spawner
	context.player_inventory = player_inventory
	context.workstation_manager = workstation_manager

	if player_inventory != null:
		context.selected_item = player_inventory.get_selected_item()
		context.selected_inventory_index = player_inventory.get_inventory_index_for_hotbar_index(player_inventory.selected_index)
	if tile_targeter != null:
		context.target_tile_coord = tile_targeter.get_target_tile()
		context.target_tile = tile_targeter.get_target_tile_data()

	return context
