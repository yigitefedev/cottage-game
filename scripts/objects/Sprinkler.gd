class_name Sprinkler
extends Node3D

var corner_coord: Vector2i = Vector2i.ZERO
var has_setup := false

var grid_manager: GridManager
var tile_visual_manager: TileVisualManager


func setup(coord: Vector2i) -> void:
	corner_coord = coord
	has_setup = true


func _ready() -> void:

	grid_manager = get_tree().get_first_node_in_group("grid_manager")
	tile_visual_manager = get_tree().get_first_node_in_group("tile_visual_manager")

	if not TimeManager.day_started.is_connected(on_day_started):
		TimeManager.day_started.connect(on_day_started)

func on_day_started(_day: int) -> void:

	water_nearby_tiles()


func water_nearby_tiles() -> void:
	if grid_manager == null:
		return

	var affected_tiles := [
		corner_coord + Vector2i(-1, -1),
		corner_coord + Vector2i(0, -1),
		corner_coord + Vector2i(-1, 0),
		corner_coord + Vector2i(0, 0),
	]

	for tile_coord in affected_tiles:
		var tile := grid_manager.get_tile(tile_coord)


		if tile == null:
			continue


		if not tile.usable:
			continue

		if not tile.has_flag(&"tilled"):
			continue

		tile.set_flag(&"watered", true)
		tile.set_visual(&"ground", &"tilled_soil_watered")


		if tile_visual_manager != null:
			tile_visual_manager.refresh_tile(tile_coord)
