class_name TargetingSystem
extends Node

enum TargetVisualMode {
	NONE,
	SOFT_TILE,
	GHOST,
	OBJECT
}

enum TargetShape {
	TILE,
	CORNER,
	EDGE
}

var player_inventory: PlayerInventory
var tile_targeter: PlayerTileTargeter
var corner_targeter: PlayerCornerTargeter
var edge_targeter: PlayerEdgeTargeter
var grid_manager: GridManager

var visual_mode: TargetVisualMode = TargetVisualMode.NONE
var target_shape: TargetShape = TargetShape.TILE

var selected_item: ItemInstanceData
var target_tile_coord: Vector2i
var target_corner_coord: Vector2i
var target_edge_coord: Vector2i
var target_edge_orientation: StringName = &"horizontal"
var target_tile: GameTileData
signal target_changed


func _ready() -> void:
	add_to_group("targeting_system")

	await get_tree().process_frame

	player_inventory = get_tree().get_first_node_in_group("player_inventory")
	tile_targeter = get_tree().get_first_node_in_group("player_tile_targeter")
	corner_targeter = get_tree().get_first_node_in_group("player_corner_targeter")
	edge_targeter = get_tree().get_first_node_in_group("player_edge_targeter")
	grid_manager = get_tree().get_first_node_in_group("grid_manager")

func _physics_process(_delta: float) -> void:
	update_targeting()


func update_targeting() -> void:
	if player_inventory == null:
		return

	selected_item = player_inventory.get_selected_item()

	update_target_data()
	update_visual_mode()


func update_target_data() -> void:
	if tile_targeter != null:
		target_tile_coord = tile_targeter.get_target_tile()

	if corner_targeter != null:
		target_corner_coord = corner_targeter.get_target_corner()

	if edge_targeter != null:
		target_edge_coord = edge_targeter.get_target_edge_coord()
		target_edge_orientation = edge_targeter.get_target_edge_orientation()
	if grid_manager != null:
		target_tile = grid_manager.get_tile(target_tile_coord)


func update_visual_mode() -> void:
	visual_mode = TargetVisualMode.NONE
	target_shape = TargetShape.TILE
	if selected_item == null:
		return

	if selected_item.definition == null:
		return
	if selected_item.has_tag(&"corner_object"):
		visual_mode = TargetVisualMode.GHOST
		target_shape = TargetShape.CORNER
		return

	if selected_item.has_tag(&"edge_object"):
		visual_mode = TargetVisualMode.GHOST
		target_shape = TargetShape.EDGE
		return

	if selected_item.has_tag(&"placeable_object"):
		visual_mode = TargetVisualMode.GHOST
		target_shape = TargetShape.TILE
		return

	if selected_item.has_tag(&"target_object"):
		visual_mode = TargetVisualMode.OBJECT
		target_shape = TargetShape.TILE
		return

	if selected_item.has_tag(&"target_tile"):
		visual_mode = TargetVisualMode.SOFT_TILE
		target_shape = TargetShape.TILE
		return


func get_target_world_position() -> Vector3:
	if grid_manager == null:
		return Vector3.ZERO

	match target_shape:
		TargetShape.CORNER:
			return grid_manager.corner_to_world(target_corner_coord)

		TargetShape.EDGE:
			return grid_manager.edge_to_world(target_edge_coord, target_edge_orientation)

		_:
			return grid_manager.tile_to_world(target_tile_coord)
