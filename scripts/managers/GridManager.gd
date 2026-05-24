class_name GridManager
extends Node3D

@export var tile_size := 1.0

func _ready() -> void:
	add_to_group("grid_manager")
	load_grid_definition()

var grid_data := GameGridData.new()
@export var grid_definition: GameGridDefinition

func world_to_tile(world_position: Vector3) -> Vector2i:
	var local_position := to_local(world_position)

	return Vector2i(
		floori(local_position.x / tile_size),
		floori(local_position.z / tile_size)
	)


func tile_to_world(coord: Vector2i) -> Vector3:
	return global_position + Vector3(
		(coord.x + 0.5) * tile_size,
		0.0,
		(coord.y + 0.5) * tile_size
	)


func create_tile(coord: Vector2i, usable: bool = true) -> GameTileData:
	return grid_data.create_tile(coord, usable)


func get_tile(coord: Vector2i) -> GameTileData:
	return grid_data.get_tile(coord)


func get_or_create_tile(coord: Vector2i, usable: bool = true) -> GameTileData:
	return grid_data.get_or_create_tile(coord, usable)


func has_tile(coord: Vector2i) -> bool:
	return grid_data.has_tile(coord)

func load_grid_definition() -> void:
	if grid_definition == null:
		return

	grid_data.tiles.clear()

	for entry in grid_definition.tile_entries:
		var coord: Vector2i = entry.get("coord", Vector2i.ZERO)
		var usable: bool = entry.get("usable", true)
		var ground_id: StringName = entry.get("ground_id", &"grass")

		var tile := grid_data.create_tile(coord, usable)
		tile.ground_id = ground_id
func save_grid_definition(path: String = "res://resources/grid/GameGridDefinition.tres") -> void:
	var definition := GameGridDefinition.new()

	for coord in grid_data.tiles.keys():
		var tile: GameTileData = grid_data.tiles[coord]

		definition.tile_entries.append({
			"coord": coord,
			"usable": tile.usable,
			"ground_id": tile.ground_id
		})

	var error := ResourceSaver.save(definition, path)

	if error != OK:
		push_error("Grid definition save failed: %s" % error)
	else:
		print("Grid definition saved: ", path)

func world_to_corner(world_position: Vector3) -> Vector2i:
	var local_position := to_local(world_position)
	return Vector2i(
		roundi(local_position.x / tile_size),
		roundi(local_position.z / tile_size)
	)


func corner_to_world(coord: Vector2i) -> Vector3:
	return global_position + Vector3(
		coord.x * tile_size,
		0.0,
		coord.y * tile_size
	)


func get_corner(coord: Vector2i) -> GameCornerData:
	return grid_data.get_corner(coord)


func get_or_create_corner(coord: Vector2i) -> GameCornerData:
	return grid_data.get_or_create_corner(coord)
