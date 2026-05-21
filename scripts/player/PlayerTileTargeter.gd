class_name PlayerTileTargeter
extends Node

var player: CharacterBody3D
var grid_manager: GridManager

var current_tile: Vector2i
var facing_tile: Vector2i
var facing_direction: Vector2i = Vector2i.DOWN

func _ready() -> void:
	add_to_group("player_tile_targeter")
	await get_tree().process_frame
	player = get_parent() as CharacterBody3D
	grid_manager = get_tree().get_first_node_in_group("grid_manager")


func _physics_process(_delta: float) -> void:
	if player == null or grid_manager == null:
		return

	current_tile = grid_manager.world_to_tile(player.global_position)
	facing_direction = get_facing_direction()
	facing_tile = current_tile + facing_direction


func get_facing_direction() -> Vector2i:
	var forward := player.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	if abs(forward.x) > abs(forward.z):
		if forward.x > 0:
			return Vector2i.RIGHT
		else:
			return Vector2i.LEFT
	else:
		if forward.z > 0:
			return Vector2i.DOWN
		else:
			return Vector2i.UP


func get_target_tile() -> Vector2i:
	return facing_tile


func get_target_tile_data() -> GameTileData:
	if grid_manager == null:
		return null

	return grid_manager.get_tile(facing_tile)
