class_name PlayerEdgeTargeter
extends Node

var player_tile_targeter: PlayerTileTargeter
var grid_manager: GridManager

var selected_direction: Vector2i = Vector2i.UP
var target_tile_coord: Vector2i
var target_edge_coord: Vector2i
var target_edge_orientation: StringName = &"horizontal"


func _ready() -> void:
	add_to_group("player_edge_targeter")

	await get_tree().process_frame

	player_tile_targeter = get_tree().get_first_node_in_group("player_tile_targeter")
	grid_manager = get_tree().get_first_node_in_group("grid_manager")

	update_target_edge()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cycle_edge_direction"):
		cycle_direction()


func _physics_process(_delta: float) -> void:
	update_target_edge()


func cycle_direction() -> void:
	if selected_direction == Vector2i.UP:
		selected_direction = Vector2i.RIGHT
	elif selected_direction == Vector2i.RIGHT:
		selected_direction = Vector2i.DOWN
	elif selected_direction == Vector2i.DOWN:
		selected_direction = Vector2i.LEFT
	else:
		selected_direction = Vector2i.UP

	update_target_edge()


func update_target_edge() -> void:
	if player_tile_targeter == null:
		player_tile_targeter = get_tree().get_first_node_in_group("player_tile_targeter")

	if grid_manager == null:
		grid_manager = get_tree().get_first_node_in_group("grid_manager")

	if player_tile_targeter == null or grid_manager == null:
		return

	target_tile_coord = player_tile_targeter.get_target_tile()

	var edge_data := grid_manager.get_edge_from_tile_direction(target_tile_coord, selected_direction)

	target_edge_coord = edge_data["coord"]
	target_edge_orientation = edge_data["orientation"]


func get_target_edge_coord() -> Vector2i:
	return target_edge_coord


func get_target_edge_orientation() -> StringName:
	return target_edge_orientation


func get_target_edge_direction() -> Vector2i:
	return selected_direction


func get_target_edge_data() -> GameEdgeData:
	if grid_manager == null:
		return null

	return grid_manager.get_edge(target_edge_coord, target_edge_orientation)
