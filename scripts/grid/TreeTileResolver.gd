class_name TreeTileResolver
extends RefCounted

const DATA_KEY := "tree"


static func has_tree(tile: GameTileData) -> bool:
	if tile == null:
		return false

	return tile.custom_data.has(DATA_KEY)


static func get_tree_data(tile: GameTileData) -> Dictionary:
	if tile == null:
		return {}

	var raw_data: Variant = tile.custom_data.get(DATA_KEY, null)

	if raw_data is Dictionary:
		var tree_data: Dictionary = raw_data
		return tree_data

	return {}


static func get_tree_id(tile: GameTileData) -> StringName:
	var tree_data := get_tree_data(tile)

	return StringName(tree_data.get("tree_id", &""))


static func get_stage_index(tile: GameTileData) -> int:
	var tree_data := get_tree_data(tile)

	return int(tree_data.get("stage_index", 0))


static func get_growth_day(tile: GameTileData) -> int:
	var tree_data := get_tree_data(tile)

	return int(tree_data.get("growth_day", 0))


static func get_days_in_stage(tile: GameTileData) -> int:
	var tree_data := get_tree_data(tile)

	return int(tree_data.get("days_in_stage", 0))


static func set_tree(
	tile: GameTileData,
	tree_id: StringName,
	stage_index: int = 0,
	growth_day: int = 0,
	days_in_stage: int = 0
) -> void:
	if tile == null:
		return

	tile.custom_data[DATA_KEY] = {
		"tree_id": tree_id,
		"stage_index": stage_index,
		"growth_day": growth_day,
		"days_in_stage": days_in_stage
	}


static func set_growth_state(
	tile: GameTileData,
	stage_index: int,
	growth_day: int,
	days_in_stage: int
) -> void:
	var tree_data := get_tree_data(tile)

	if tree_data.is_empty():
		return

	tree_data["stage_index"] = stage_index
	tree_data["growth_day"] = growth_day
	tree_data["days_in_stage"] = days_in_stage
	tile.custom_data[DATA_KEY] = tree_data


static func clear_tree(tile: GameTileData) -> void:
	if tile == null:
		return

	tile.custom_data.erase(DATA_KEY)
	tile.remove_visual(&"tree")
