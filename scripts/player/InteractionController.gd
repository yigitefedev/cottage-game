class_name InteractionController
extends Node

@export var interaction_actions: Array[InteractionAction] = []

var player: CharacterBody3D

var grid_manager: GridManager
var tile_visual_manager: TileVisualManager
var tile_targeter: PlayerTileTargeter
var world_item_spawner: WorldItemSpawner


func _ready() -> void:
	await get_tree().process_frame

	player = get_parent() as CharacterBody3D

	grid_manager = get_tree().get_first_node_in_group("grid_manager")
	tile_visual_manager = get_tree().get_first_node_in_group("tile_visual_manager")
	tile_targeter = get_tree().get_first_node_in_group("player_tile_targeter")
	world_item_spawner = get_tree().get_first_node_in_group("world_item_spawner")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		try_interact()


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

	if tile_targeter != null:
		context.target_tile_coord = tile_targeter.get_target_tile()
		context.target_tile = tile_targeter.get_target_tile_data()

	return context
