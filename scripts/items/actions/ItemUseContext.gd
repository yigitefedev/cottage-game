class_name ItemUseContext
extends RefCounted

var item_database: ItemDatabase
var player: CharacterBody3D
var player_inventory: PlayerInventory
var tool_controller: ToolController
var player_stamina: PlayerStamina
var world_item_spawner: WorldItemSpawner
var selected_slot_index: int
var selected_item: ItemInstanceData
var grid_object_manager: GridObjectManager
var object_target_resolver: ObjectTargetResolver

var crop_database: CropDatabase
var grid_manager: GridManager
var tile_visual_manager: TileVisualManager
var corner_visual_manager: CornerVisualManager

var tile_targeter: PlayerTileTargeter
var target_tile_coord: Vector2i	
var target_tile: GameTileData
var grass_mask_manager: GrassMaskManager

var corner_targeter: PlayerCornerTargeter
var target_corner_coord: Vector2i
var target_corner: GameCornerData

var edge_visual_manager: EdgeVisualManager
var edge_targeter: PlayerEdgeTargeter

var target_edge_coord: Vector2i
var target_edge_orientation: StringName
var target_edge: GameEdgeData
