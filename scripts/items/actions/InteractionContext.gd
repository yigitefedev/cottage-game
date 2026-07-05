class_name InteractionContext
extends RefCounted

var player: CharacterBody3D
var grid_manager: GridManager
var tile_visual_manager: TileVisualManager
var tile_targeter: PlayerTileTargeter
var world_item_spawner: WorldItemSpawner

var player_inventory: PlayerInventory
var selected_item: ItemInstanceData
var selected_inventory_index: int = -1

var workstation_manager: WorkstationManager

var target_tile_coord: Vector2i
var target_tile: GameTileData
