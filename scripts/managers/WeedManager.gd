class_name WeedManager
extends Node

const WEED_KEY := "weed"
const MAX_WEED_LEVEL := 3

@export_range(0.0, 1.0, 0.01) var random_spawn_chance := 0.05
@export_range(0.0, 1.0, 0.01) var growth_chance := 0.35
@export_range(0.0, 1.0, 0.01) var spread_chance := 1.0

var grid_manager: GridManager
var tile_visual_manager: TileVisualManager


func _ready() -> void:
	add_to_group("weed_manager")
	ensure_refs()

	if not TimeManager.day_simulated.is_connected(on_day_simulated):
		TimeManager.day_simulated.connect(on_day_simulated)


func ensure_refs() -> void:
	if grid_manager == null:
		grid_manager = get_tree().get_first_node_in_group("grid_manager")

	if tile_visual_manager == null:
		tile_visual_manager = get_tree().get_first_node_in_group("tile_visual_manager")


func on_day_simulated(_day: int, fast_forward: bool) -> void:
	simulate_day(not fast_forward)


func simulate_day(refresh_visuals: bool = true) -> void:
	ensure_refs()

	if grid_manager == null:
		return

	var weed_coords := get_weed_coords()

	grow_existing_weeds(weed_coords, refresh_visuals)
	spread_existing_weeds(weed_coords, refresh_visuals)
	spawn_random_weeds(refresh_visuals)


func get_weed_coords() -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	if grid_manager == null:
		return result

	for coord in grid_manager.grid_data.tiles.keys():
		var tile: GameTileData = grid_manager.grid_data.tiles[coord]

		if tile == null:
			continue

		if has_weed(tile):
			result.append(coord)

	return result


func grow_existing_weeds(weed_coords: Array[Vector2i], refresh_visuals: bool = true) -> void:
	for coord: Vector2i in weed_coords:
		var tile := grid_manager.get_tile(coord)

		if tile == null:
			continue

		var current_level := get_weed_level(tile)

		if current_level >= MAX_WEED_LEVEL:
			continue

		if randf() > growth_chance:
			continue

		set_weed_level(tile, current_level + 1, refresh_visuals)


func spread_existing_weeds(weed_coords: Array[Vector2i], refresh_visuals: bool = true) -> void:
	for coord: Vector2i in weed_coords:
		if randf() > spread_chance:
			continue

		var spread_targets := get_spread_targets(coord)

		if spread_targets.is_empty():
			continue

		var target_coord: Vector2i = spread_targets.pick_random()
		var target_tile := grid_manager.get_tile(target_coord)

		if target_tile == null:
			continue

		spawn_weed(target_tile, 1, refresh_visuals)


func spawn_random_weeds(refresh_visuals: bool = true) -> void:
	for coord in grid_manager.grid_data.tiles.keys():
		var tile: GameTileData = grid_manager.grid_data.tiles[coord]

		if not can_spawn_weed_on_tile(tile):
			continue

		if randf() > random_spawn_chance:
			continue

		spawn_weed(tile, 1, refresh_visuals)


func get_spread_targets(coord: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var directions: Array[Vector2i] = [
		Vector2i.UP,
		Vector2i.RIGHT,
		Vector2i.DOWN,
		Vector2i.LEFT
	]

	for direction: Vector2i in directions:
		var target_coord := coord + direction
		var target_tile := grid_manager.get_tile(target_coord)

		if can_spawn_weed_on_tile(target_tile):
			result.append(target_coord)

	return result


func can_spawn_weed_on_tile(tile: GameTileData) -> bool:
	if tile == null:
		return false

	if not tile.usable:
		return false

	if not PlantingSurfaceResolver.has_surface(tile):
		return false

	if not PlantingSurfaceResolver.allows_weeds(tile):
		return false

	return not has_weed(tile)


func has_weed(tile: GameTileData) -> bool:
	if tile == null:
		return false

	return tile.custom_data.has(WEED_KEY)


func get_weed_level(tile: GameTileData) -> int:
	if not has_weed(tile):
		return 0

	var raw_data: Variant = tile.custom_data.get(WEED_KEY, {})

	if raw_data is Dictionary:
		var weed_data: Dictionary = raw_data
		return clampi(int(weed_data.get("level", 1)), 1, MAX_WEED_LEVEL)

	return 1


func set_weed_level(tile: GameTileData, level: int, refresh_visuals: bool = true) -> void:
	if tile == null:
		return

	var safe_level := clampi(level, 1, MAX_WEED_LEVEL)

	tile.custom_data[WEED_KEY] = {
		"level": safe_level
	}

	tile.set_visual(&"weed", get_visual_id_for_level(safe_level))
	if refresh_visuals:
		refresh_weed_visual(tile.coord)


func spawn_weed(tile: GameTileData, level: int = 1, refresh_visuals: bool = true) -> void:
	set_weed_level(tile, level, refresh_visuals)


func remove_weed(tile: GameTileData, refresh_visuals: bool = true) -> void:
	if tile == null:
		return

	tile.custom_data.erase(WEED_KEY)
	tile.remove_visual(&"weed")
	if refresh_visuals:
		refresh_weed_visual(tile.coord)


func get_visual_id_for_level(level: int) -> StringName:
	var safe_level := clampi(level, 1, MAX_WEED_LEVEL)
	return StringName("weed_level_%sa" % [safe_level])


func refresh_weed_visual(coord: Vector2i) -> void:
	if tile_visual_manager == null:
		tile_visual_manager = get_tree().get_first_node_in_group("tile_visual_manager")

	if tile_visual_manager == null:
		return

	tile_visual_manager.refresh_tile_layer(coord, &"weed")
