class_name PlayerCornerTargeter
extends Node

var player: CharacterBody3D
var grid_manager: GridManager

var current_tile: Vector2i
var facing_direction: Vector2i = Vector2i.DOWN
var target_corner: Vector2i

func _ready() -> void:
	add_to_group("player_corner_targeter")
	await get_tree().process_frame

	player = get_parent() as CharacterBody3D
	grid_manager = get_tree().get_first_node_in_group("grid_manager")

func _physics_process(_delta: float) -> void:
	if player == null or grid_manager == null:
		return

	current_tile = grid_manager.world_to_tile(player.global_position)
	facing_direction = get_facing_direction()
	target_corner = get_corner_in_front()

func get_facing_direction() -> Vector2i:
	var forward := player.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	if abs(forward.x) > abs(forward.z):
		return Vector2i.RIGHT if forward.x > 0 else Vector2i.LEFT
	else:
		return Vector2i.DOWN if forward.z > 0 else Vector2i.UP

func get_corner_in_front() -> Vector2i:
	var base := current_tile

	match facing_direction:
		Vector2i.RIGHT:
			return base + Vector2i(1, 1)
		Vector2i.LEFT:
			return base + Vector2i(0, 1)
		Vector2i.DOWN:
			return base + Vector2i(1, 1)
		Vector2i.UP:
			return base + Vector2i(1, 0)

	return base

func get_target_corner() -> Vector2i:
	return target_corner

func get_target_corner_data() -> GameCornerData:
	if grid_manager == null:
		return null
	return grid_manager.get_corner(target_corner)
