class_name PlantingSurfaceResolver
extends RefCounted

const DATA_KEY := "planting_surface"
const SURFACE_FIELD := &"field"
const SURFACE_GARDEN_BED := &"garden_bed"
const SURFACE_NONE := &""


static func get_surface_id(tile: GameTileData) -> StringName:
	if tile == null:
		return SURFACE_NONE

	var raw_data: Variant = tile.custom_data.get(DATA_KEY, null)

	if raw_data is Dictionary:
		var data: Dictionary = raw_data
		var surface_id := StringName(data.get("surface_id", SURFACE_NONE))

		if surface_id != SURFACE_NONE:
			return surface_id

	if tile.has_flag(&"tilled"):
		return SURFACE_FIELD

	return SURFACE_NONE


static func has_surface(tile: GameTileData) -> bool:
	return get_surface_id(tile) != SURFACE_NONE


static func is_waterable(tile: GameTileData) -> bool:
	if tile == null:
		return false

	var raw_data: Variant = tile.custom_data.get(DATA_KEY, null)

	if raw_data is Dictionary:
		var data: Dictionary = raw_data
		return bool(data.get("waterable", true))

	return tile.has_flag(&"tilled")


static func allows_weeds(tile: GameTileData) -> bool:
	if tile == null:
		return false

	var raw_data: Variant = tile.custom_data.get(DATA_KEY, null)

	if raw_data is Dictionary:
		var data: Dictionary = raw_data
		return bool(data.get("allows_weeds", false))

	return tile.has_flag(&"tilled")


static func can_plant_crop_on_tile(crop: CropDefinition, tile: GameTileData) -> bool:
	if crop == null:
		return false

	var surface_id := get_surface_id(tile)

	if surface_id == SURFACE_NONE:
		return false

	return crop.can_plant_on_surface(surface_id)


static func get_surface_visual_layer(tile: GameTileData) -> StringName:
	if tile == null:
		return &""

	if tile.custom_data.has(DATA_KEY):
		return &"object"

	if tile.has_flag(&"tilled"):
		return &"ground"

	return &""


static func set_object_surface(
	tile: GameTileData,
	object_id: StringName,
	surface_id: StringName,
	waterable: bool = true,
	surface_allows_weeds: bool = false
) -> void:
	if tile == null:
		return

	if surface_id == SURFACE_NONE:
		return

	tile.custom_data[DATA_KEY] = {
		"source_object_id": object_id,
		"surface_id": surface_id,
		"waterable": waterable,
		"allows_weeds": surface_allows_weeds
	}


static func clear_object_surface(tile: GameTileData, object_id: StringName = &"") -> void:
	if tile == null:
		return

	var raw_data: Variant = tile.custom_data.get(DATA_KEY, null)

	if not (raw_data is Dictionary):
		return

	if object_id != &"":
		var data: Dictionary = raw_data
		var source_object_id := StringName(data.get("source_object_id", &""))

		if source_object_id != object_id:
			return

	tile.custom_data.erase(DATA_KEY)


static func is_object_surface(tile: GameTileData, object_id: StringName) -> bool:
	if tile == null:
		return false

	var raw_data: Variant = tile.custom_data.get(DATA_KEY, null)

	if not (raw_data is Dictionary):
		return false

	var data: Dictionary = raw_data
	return StringName(data.get("source_object_id", &"")) == object_id
