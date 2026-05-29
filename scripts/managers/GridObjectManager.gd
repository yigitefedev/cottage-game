class_name GridObjectManager
extends Node

@export var item_database: ItemDatabase
var grid_manager: GridManager
var tile_visual_manager: TileVisualManager
var corner_visual_manager: CornerVisualManager
var edge_visual_manager: EdgeVisualManager
var world_item_spawner: WorldItemSpawner


func _ready() -> void:
	add_to_group("grid_object_manager")

	await get_tree().process_frame

	grid_manager = get_tree().get_first_node_in_group("grid_manager")
	tile_visual_manager = get_tree().get_first_node_in_group("tile_visual_manager")
	corner_visual_manager = get_tree().get_first_node_in_group("corner_visual_manager")
	edge_visual_manager = get_tree().get_first_node_in_group("edge_visual_manager")
	world_item_spawner = get_tree().get_first_node_in_group("world_item_spawner")


func break_corner_object(coord: Vector2i, drop_position: Vector3 = Vector3.ZERO) -> bool:
	if grid_manager == null:
		return false

	var corner := grid_manager.get_corner(coord)

	if corner == null or not corner.has_object():
		return false

	var object_id := corner.object_id

	spawn_object_drop(object_id, drop_position)

	corner.object_id = &""
	corner.remove_visual(&"object")

	if corner_visual_manager != null:
		corner_visual_manager.refresh_corner(coord)

	return true


func break_edge_object(coord: Vector2i, orientation: StringName, drop_position: Vector3 = Vector3.ZERO) -> bool:
	if grid_manager == null:
		return false

	var edge := grid_manager.get_edge(coord, orientation)

	if edge == null or not edge.has_object():
		return false

	var object_id := edge.object_id

	spawn_object_drop(object_id, drop_position)

	edge.object_id = &""
	edge.remove_visual(&"object")

	if edge_visual_manager != null:
		edge_visual_manager.refresh_edge(coord, orientation)

	return true


func break_tile_object(coord: Vector2i, drop_position: Vector3 = Vector3.ZERO) -> bool:
	if grid_manager == null:
		return false

	var tile := grid_manager.get_tile(coord)

	if tile == null:
		return false

	if tile.object_ids.is_empty():
		return false

	var object_id: StringName = tile.object_ids[0]

	spawn_object_drop(object_id, drop_position)

	tile.object_ids.erase(object_id)
	tile.remove_visual(&"object")

	if tile_visual_manager != null:
		tile_visual_manager.refresh_tile(coord)

	return true


func spawn_object_drop(object_id: StringName, drop_position: Vector3) -> void:
	if object_id == &"":
		return

	if world_item_spawner == null:
		return

	var item_definition := find_item_definition_for_object(object_id)

	if item_definition == null:
		return

	var item := ItemInstanceData.new()
	item.definition = item_definition
	item.amount = 1
	item.state = {}

	var dropped := world_item_spawner.spawn_item(item, drop_position, 0.0)

	if dropped != null:
		var random_dir := Vector3(
			randf_range(-1.0, 1.0),
			0.0,
			randf_range(-1.0, 1.0)
		).normalized()

		dropped.velocity = random_dir * randf_range(1.5, 2.5) + Vector3.UP * randf_range(1.0, 1.8)


func find_item_definition_for_object(object_id: StringName) -> ItemDefinition:
	if item_database == null:
		push_warning("GridObjectManager: item_database atanmadı.")
		return null

	for definition in item_database.items:
		if definition == null:
			continue

		if definition.id == object_id:
			return definition

		var definition_object_id: StringName = definition.get_property("object_id", &"")

		if definition_object_id == object_id:
			return definition

	return null
func place_corner_object(coord: Vector2i, object_id: StringName, visual_layer: StringName, visual_id: StringName) -> bool:
	if grid_manager == null:
		return false

	if object_id == &"" or visual_id == &"":
		return false

	var corner := grid_manager.get_corner(coord)

	if corner != null and corner.has_object():
		return false

	corner = grid_manager.get_or_create_corner(coord)
	corner.object_id = object_id
	corner.set_visual(visual_layer, visual_id)

	if corner_visual_manager != null:
		corner_visual_manager.refresh_corner(coord)

	return true


func place_edge_object(coord: Vector2i, orientation: StringName, object_id: StringName, visual_layer: StringName, visual_id: StringName) -> bool:
	if grid_manager == null:
		return false

	if object_id == &"" or visual_id == &"":
		return false

	var edge := grid_manager.get_edge(coord, orientation)

	if edge != null and edge.has_object():
		return false

	edge = grid_manager.get_or_create_edge(coord, orientation)
	edge.object_id = object_id
	edge.set_visual(visual_layer, visual_id)

	if edge_visual_manager != null:
		edge_visual_manager.refresh_edge(coord, orientation)

	return true
