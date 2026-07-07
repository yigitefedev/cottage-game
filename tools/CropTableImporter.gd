@tool
extends EditorScript

const JSON_PATH := "res://data/import/crop_table.json"
const ICON_DIR := "res://art/icons/"
const CROP_DB_PATH := "res://resources/crops/MainCropDatabase.tres"
const ITEM_DB_PATH := "res://resources/items/MainItemDatabase.tres"

const CROP_OUTPUT_DIR := "res://resources/crops/generated/"
const ITEM_OUTPUT_DIR := "res://resources/items/generated/"

const PLANT_SEED_ACTION_PATH := "res://resources/actions/PlantSeedAction.tres"


func _run() -> void:
	ensure_dirs()

	var crop_database: CropDatabase = load(CROP_DB_PATH)
	var item_database: ItemDatabase = load(ITEM_DB_PATH)
	var plant_seed_action: ItemAction = load(PLANT_SEED_ACTION_PATH)

	if crop_database == null:
		push_error("Crop database not found.")
		return

	if item_database == null:
		push_error("Item database not found.")
		return

	var json_text := FileAccess.get_file_as_string(JSON_PATH)
	var parsed = JSON.parse_string(json_text)

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid crop json.")
		return

	var sheet: Dictionary = parsed.get("Sayfa1", {})

	for crop_name in sheet.keys():
		var row: Dictionary = sheet[crop_name]
		import_crop(row, str(crop_name), crop_database, item_database, plant_seed_action)

	save_database(crop_database, CROP_DB_PATH)
	save_database(item_database, ITEM_DB_PATH)

	print("Crop import finished. Imported: ", sheet.size())


func import_crop(
	row: Dictionary,
	fallback_display_name: String,
	crop_database: CropDatabase,
	item_database: ItemDatabase,
	plant_seed_action: ItemAction
) -> void:
	var base_id := String(row.get("id", "")).strip_edges()

	if base_id == "":
		push_warning("Skipped crop with empty id: " + fallback_display_name)
		return

	var display_name := String(row.get("display_name", fallback_display_name)).strip_edges()

	var crop_id := &"crop_%s" % base_id
	var harvest_item_id := &"harvest_item_%s" % base_id
	var crop_type := String(row.get("type", "crop"))

	var seed_suffix := "seed"

	if crop_type == "tree_fruit" or crop_type == "tree_tapping":
		seed_suffix = "sapling"

	var seed_item_id := StringName("%s_item_%s" % [seed_suffix, base_id])
	var seed_display_name := "%s %s" % [
		display_name,
		seed_suffix.substr(0, 1).to_upper() + seed_suffix.substr(1)
	]

	var crop := get_or_create_crop_definition(crop_database, crop_id, base_id)
	var harvest_item := get_or_create_item_definition(item_database, harvest_item_id, base_id + "_harvest")
	var seed_item := get_or_create_item_definition(item_database, seed_item_id, base_id + "_" + seed_suffix)

	update_crop_definition(crop, row, crop_id, display_name, harvest_item_id, base_id)
	update_harvest_item_definition(harvest_item, row, harvest_item_id, display_name)
	update_seed_item_definition(seed_item, row, seed_item_id, seed_display_name, crop_id, plant_seed_action)

	add_crop_to_database(crop_database, crop)
	add_item_to_database(item_database, harvest_item)
	add_item_to_database(item_database, seed_item)

	ResourceSaver.save(crop, crop.resource_path)
	ResourceSaver.save(harvest_item, harvest_item.resource_path)
	ResourceSaver.save(seed_item, seed_item.resource_path)
	crop = load(crop.resource_path)
	harvest_item = load(harvest_item.resource_path)
	seed_item = load(seed_item.resource_path)


func update_crop_definition(
	crop: CropDefinition,
	row: Dictionary,
	crop_id: StringName,
	display_name: String,
	harvest_item_id: StringName,
	base_id: String
) -> void:
	var growth_days := int(row.get("growth_days", 4))
	var stage_durations := parse_stage_durations(row.get("stage_durations", null), growth_days)

	crop.id = crop_id
	crop.display_name = display_name
	crop.stage_duration_days = stage_durations
	crop.stage_visual_ids = make_stage_visual_ids(base_id, stage_durations.size())
	crop.harvest_stage_index = stage_durations.size() - 1
	crop.harvest_item_id = harvest_item_id
	crop.harvest_amount_min = int(row.get("yield_min", 1))
	crop.harvest_amount_max = int(row.get("yield_max", 1))
	crop.regrow_after_harvest = bool(row.get("regrow_after_harvest", false))
	crop.regrow_stage_index = int(row.get("regrow_stage_index", 1))

	if "grow_seasons" in crop:
		crop.grow_seasons = parse_seasons(String(row.get("season", "")))

	if "allowed_planting_surfaces" in crop:
		crop.allowed_planting_surfaces = get_allowed_planting_surfaces(String(row.get("type", "crop")))

	if "harvest_type" in crop:
		crop.harvest_type = StringName(row.get("type", "crop"))

	if "required_structure" in crop:
		crop.required_structure = get_required_structure(String(row.get("type", "crop")))


func update_harvest_item_definition(
	item: ItemDefinition,
	row: Dictionary,
	item_id: StringName,
	display_name: String
) -> void:
	item.id = item_id
	item.display_name = display_name
	item.max_stack = int(row.get("max_stack", 20))
	item.tags = get_harvest_tags(String(row.get("type", "crop")))

	item.properties["buy_price"] = int(row.get("harvest_buy_price", 0))
	item.properties["sell_price"] = int(row.get("harvest_sell_price", 0))
	apply_icon_by_convention(item, item_id)

func update_seed_item_definition(
	item: ItemDefinition,
	row: Dictionary,
	item_id: StringName,
	display_name: String,
	crop_id: StringName,
	plant_seed_action: ItemAction
) -> void:
	var crop_type := String(row.get("type", "crop"))

	item.id = item_id
	item.display_name = display_name
	item.max_stack = int(row.get("seed_max_stack", 30))
	item.tags = get_seed_tags(crop_type)
	item.primary_action = plant_seed_action

	item.properties["crop_id"] = crop_id
	item.properties["buy_price"] = int(row.get("seed_buy_price", 0))
	item.properties["sell_price"] = int(row.get("seed_sell_price", 0))
	apply_icon_by_convention(item, item_id)

func parse_stage_durations(value, growth_days: int) -> Array[int]:
	if value != null and str(value).strip_edges() != "":
		var result: Array[int] = []

		for part in str(value).split(","):
			result.append(int(part.strip_edges()))

		return result

	var stage_count := 4
	var result: Array[int] = []
	var grow_stage_count := stage_count - 1

	var base := growth_days / grow_stage_count
	var remainder := growth_days % grow_stage_count

	for i in range(grow_stage_count):
		var duration := base

		if i < remainder:
			duration += 1

		result.append(duration)

	result.append(0)
	return result


func make_stage_visual_ids(base_id: String, count: int) -> Array[StringName]:
	var ids: Array[StringName] = []

	for i in range(count):
		ids.append(StringName("%s_stage_%s" % [base_id, i]))

	return ids


func parse_seasons(value: String) -> Array[StringName]:
	var text := value.to_lower().strip_edges()

	if text == "3 seasons":
		return [&"spring", &"summer", &"fall"]

	if text == "4 seasons":
		return [&"spring", &"summer", &"fall", &"winter"]

	var seasons: Array[StringName] = []

	for part in text.split(","):
		var season := part.strip_edges()

		if season == "autumn":
			season = "fall"

		if season != "":
			seasons.append(StringName(season))

	return seasons


func get_required_structure(crop_type: String) -> StringName:
	match crop_type:
		"crop":
			return &"soil"
		"crop_trellis":
			return &"trellis"
		"garden_bed":
			return &"garden_bed"
		"tree_fruit", "tree_tapping":
			return &"tree"
		_:
			return &"soil"


func get_allowed_planting_surfaces(crop_type: String) -> Array[StringName]:
	match crop_type:
		"garden_bed":
			return [&"garden_bed"]
		_:
			return [&"field"]


func get_seed_tags(crop_type: String) -> Array[StringName]:
	match crop_type:
		"tree_fruit", "tree_tapping":
			return [&"sapling"]
		_:
			return [&"seed"]


func get_harvest_tags(crop_type: String) -> Array[StringName]:
	match crop_type:
		"tree_fruit":
			return [&"fruit"]
		"tree_tapping":
			return [&"tree_product"]
		"garden_bed":
			return [&"herb"]
		"crop_trellis":
			return [&"crop", &"trellis_crop"]
		_:
			return [&"crop"]


func get_or_create_crop_definition(database: CropDatabase, crop_id: StringName, base_id: String) -> CropDefinition:
	var path := CROP_OUTPUT_DIR + "%s.tres" % crop_id

	for crop in database.crops:
		if crop != null and crop.id == crop_id:
			if crop.resource_path == "":
				crop.resource_path = path
			return crop

	var crop := CropDefinition.new()
	crop.resource_path = path
	return crop


func get_or_create_item_definition(database: ItemDatabase, item_id: StringName, suffix_id: String) -> ItemDefinition:
	var path := ITEM_OUTPUT_DIR + "%s.tres" % item_id

	for item in database.items:
		if item != null and item.id == item_id:
			if item.resource_path == "":
				item.resource_path = path
			return item

	var item := ItemDefinition.new()
	item.resource_path = path
	return item


func add_crop_to_database(database: CropDatabase, crop: CropDefinition) -> void:
	for existing in database.crops:
		if existing != null and existing.id == crop.id:
			return

	database.crops.append(crop)


func add_item_to_database(database: ItemDatabase, item: ItemDefinition) -> void:
	for existing in database.items:
		if existing != null and existing.id == item.id:
			return

	database.items.append(item)


func save_database(database: Resource, path: String) -> void:
	ResourceSaver.save(database, path)


func ensure_dirs() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CROP_OUTPUT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ITEM_OUTPUT_DIR))


func to_pascal_case(value: String) -> String:
	var result := ""

	for part in value.split("_"):
		if part == "":
			continue

		result += part.substr(0, 1).to_upper() + part.substr(1).to_lower()

	return result
func apply_icon_by_convention(item: ItemDefinition, item_id: StringName) -> void:
	var icon: Texture2D = find_icon_for_item(item_id)

	if icon == null:
		return

	item.icon = icon


func find_icon_for_item(item_id: StringName) -> Texture2D:
	var id_text := String(item_id)

	var specific_icon: Texture2D = load_icon_by_name("icon_%s" % id_text)

	if specific_icon != null:
		return specific_icon

	var fallback_icon: Texture2D = find_fallback_icon_for_item(id_text)

	if fallback_icon != null:
		return fallback_icon

	return null
func find_fallback_icon_for_item(item_id: String) -> Texture2D:
	if item_id.begins_with("seed_item_"):
		return load_icon_by_name("icon_seed_item_null")

	if item_id.begins_with("sapling_item_"):
		return load_icon_by_name("icon_seed_item_null")

	if item_id.begins_with("harvest_item_"):
		return load_icon_by_name("icon_harvest_item_null")

	return null
func load_icon_by_name(icon_name: String) -> Texture2D:
	var possible_paths: Array[String] = [
		ICON_DIR + icon_name + ".png",
		ICON_DIR + icon_name + ".webp",
		ICON_DIR + icon_name + ".svg",
		ICON_DIR + icon_name + ".tres",
		ICON_DIR + icon_name + ".res"
	]

	for path: String in possible_paths:
		if not ResourceLoader.exists(path):
			continue

		var resource: Resource = load(path)

		if resource is Texture2D:
			return resource as Texture2D

	return null
