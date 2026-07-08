@tool
extends EditorScript

const JSON_PATH := "res://data/import/crop_table.json"
const ICON_DIR := "res://art/icons/"

const CROP_DB_PATH := "res://resources/crops/MainCropDatabase.tres"
const TREE_DB_PATH := "res://resources/trees/MainTreeDatabase.tres"
const ITEM_DB_PATH := "res://resources/items/MainItemDatabase.tres"

const CROP_DEFINITION_DIR := "res://resources/crops/definitions/"
const SEED_DEFINITION_DIR := "res://resources/crops/seed_definitions/"
const TREE_DEFINITION_DIR := "res://resources/trees/definitions/"
const SAPLING_DEFINITION_DIR := "res://resources/trees/sapling_definitions/"
const HARVEST_ITEM_DIR := "res://resources/items/harvest_items/"

const OLD_CROP_GENERATED_DIR := "res://resources/crops/generated/"
const OLD_ITEM_GENERATED_DIR := "res://resources/items/generated/"

const PLANT_SEED_ACTION_PATH := "res://resources/actions/PlantSeedAction.tres"
const PLANT_SAPLING_ACTION_PATH := "res://resources/actions/PlantSaplingAction.tres"

const TreeDatabaseScript := preload("res://scripts/crops/TreeDatabase.gd")
const TreeDefinitionScript := preload("res://scripts/crops/TreeDefinition.gd")


func _run() -> void:
	ensure_dirs()

	var crop_database: CropDatabase = load(CROP_DB_PATH)
	var tree_database: Resource = load_or_create_tree_database()
	var item_database: ItemDatabase = load(ITEM_DB_PATH)
	var plant_seed_action: ItemAction = load(PLANT_SEED_ACTION_PATH)
	var plant_sapling_action: ItemAction = load(PLANT_SAPLING_ACTION_PATH)

	if crop_database == null:
		push_error("Crop database not found.")
		return

	if tree_database == null:
		push_error("Tree database not found.")
		return

	if item_database == null:
		push_error("Item database not found.")
		return

	if plant_seed_action == null:
		push_error("Plant seed action not found.")
		return

	if plant_sapling_action == null:
		push_error("Plant sapling action not found.")
		return

	var json_text := FileAccess.get_file_as_string(JSON_PATH)
	var parsed = JSON.parse_string(json_text)

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid crop json.")
		return

	var sheet: Dictionary = parsed.get("Sayfa1", {})

	clear_imported_entries(crop_database, tree_database, item_database)

	var crop_count := 0
	var tree_count := 0

	for crop_name in sheet.keys():
		var row: Dictionary = sheet[crop_name]
		var crop_type := String(row.get("type", "crop"))

		if is_tree_type(crop_type):
			import_tree(row, str(crop_name), tree_database, item_database, plant_sapling_action)
			tree_count += 1
		else:
			import_crop(row, str(crop_name), crop_database, item_database, plant_seed_action)
			crop_count += 1

	save_database(crop_database, CROP_DB_PATH)
	save_database(tree_database, TREE_DB_PATH)
	save_database(item_database, ITEM_DB_PATH)

	print("Crop import finished. Crops: ", crop_count, ", Trees: ", tree_count)


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
	var crop_id := StringName("crop_%s" % base_id)
	var harvest_item_id := StringName("harvest_item_%s" % base_id)
	var seed_item_id := StringName("seed_item_%s" % base_id)
	var seed_display_name := "%s Seed" % display_name

	var crop := get_or_create_crop_definition(crop_id)
	var harvest_item := get_or_create_item_definition(harvest_item_id, get_harvest_item_path(harvest_item_id))
	var seed_item := get_or_create_item_definition(seed_item_id, get_seed_item_path(seed_item_id))

	update_crop_definition(crop, row, crop_id, display_name, harvest_item_id, base_id)
	update_harvest_item_definition(harvest_item, row, harvest_item_id, display_name)
	update_seed_item_definition(seed_item, row, seed_item_id, seed_display_name, crop_id, plant_seed_action)

	add_crop_to_database(crop_database, crop)
	add_item_to_database(item_database, harvest_item)
	add_item_to_database(item_database, seed_item)

	save_resource(crop)
	save_resource(harvest_item)
	save_resource(seed_item)


func import_tree(
	row: Dictionary,
	fallback_display_name: String,
	tree_database: Resource,
	item_database: ItemDatabase,
	plant_sapling_action: ItemAction
) -> void:
	var base_id := String(row.get("id", "")).strip_edges()

	if base_id == "":
		push_warning("Skipped tree with empty id: " + fallback_display_name)
		return

	var display_name := String(row.get("display_name", fallback_display_name)).strip_edges()
	var tree_id := StringName("tree_%s" % base_id)
	var harvest_item_id := StringName("harvest_item_%s" % base_id)
	var sapling_item_id := StringName("sapling_%s" % base_id)
	var sapling_display_name := "%s Sapling" % display_name

	var tree_definition: TreeDefinition = get_or_create_tree_definition(tree_id)
	var harvest_item: ItemDefinition = get_or_create_item_definition(harvest_item_id, get_harvest_item_path(harvest_item_id))
	var sapling_item: ItemDefinition = get_or_create_item_definition(sapling_item_id, get_sapling_item_path(sapling_item_id))

	update_tree_definition(tree_definition, row, tree_id, display_name, harvest_item_id)
	update_harvest_item_definition(harvest_item, row, harvest_item_id, display_name)
	update_sapling_item_definition(sapling_item, row, sapling_item_id, sapling_display_name, tree_id, plant_sapling_action)

	add_tree_to_database(tree_database, tree_definition)
	add_item_to_database(item_database, harvest_item)
	add_item_to_database(item_database, sapling_item)

	save_resource(tree_definition)
	save_resource(harvest_item)
	save_resource(sapling_item)


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
	crop.stage_visual_ids = make_crop_stage_visual_ids(base_id, stage_durations.size())
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


func update_tree_definition(
	tree_definition: TreeDefinition,
	row: Dictionary,
	tree_id: StringName,
	display_name: String,
	harvest_item_id: StringName
) -> void:
	var growth_days: int = int(row.get("growth_days", 4))
	var stage_durations: Array[int] = parse_stage_durations(row.get("stage_durations", null), growth_days)

	tree_definition.id = tree_id
	tree_definition.display_name = display_name
	tree_definition.stage_duration_days = stage_durations
	tree_definition.stage_visual_ids = make_tree_stage_visual_ids(stage_durations.size())
	tree_definition.harvest_stage_index = stage_durations.size() - 1
	tree_definition.harvest_item_id = harvest_item_id
	tree_definition.harvest_amount_min = int(row.get("yield_min", 1))
	tree_definition.harvest_amount_max = int(row.get("yield_max", 1))
	tree_definition.regrow_after_harvest = bool(row.get("regrow_after_harvest", true))
	tree_definition.regrow_stage_index = int(row.get("regrow_stage_index", maxi(stage_durations.size() - 2, 0)))
	tree_definition.grow_seasons = parse_seasons(String(row.get("season", "")))
	tree_definition.tree_type = get_tree_definition_type(String(row.get("type", "tree_fruit")))


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
	item.primary_action = null
	item.secondary_action = null
	item.properties = {
		"buy_price": int(row.get("harvest_buy_price", 0)),
		"sell_price": int(row.get("harvest_sell_price", 0))
	}
	apply_icon_by_convention(item, item_id)


func update_seed_item_definition(
	item: ItemDefinition,
	row: Dictionary,
	item_id: StringName,
	display_name: String,
	crop_id: StringName,
	plant_seed_action: ItemAction
) -> void:
	item.id = item_id
	item.display_name = display_name
	item.max_stack = int(row.get("seed_max_stack", 30))
	item.tags = [&"seed"]
	item.primary_action = plant_seed_action
	item.secondary_action = null
	item.properties = {
		"crop_id": crop_id,
		"buy_price": int(row.get("seed_buy_price", 0)),
		"sell_price": int(row.get("seed_sell_price", 0))
	}
	apply_icon_by_convention(item, item_id)


func update_sapling_item_definition(
	item: ItemDefinition,
	row: Dictionary,
	item_id: StringName,
	display_name: String,
	tree_id: StringName,
	plant_sapling_action: ItemAction
) -> void:
	item.id = item_id
	item.display_name = display_name
	item.max_stack = int(row.get("seed_max_stack", 30))
	item.tags = [&"sapling"]
	item.primary_action = plant_sapling_action
	item.secondary_action = null
	item.properties = {
		"tree_id": tree_id,
		"buy_price": int(row.get("seed_buy_price", 0)),
		"sell_price": int(row.get("seed_sell_price", 0))
	}
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


func get_tree_stage_count(row: Dictionary) -> int:
	var growth_days := int(row.get("growth_days", 4))
	var stage_durations := parse_stage_durations(row.get("stage_durations", null), growth_days)

	return maxi(stage_durations.size(), 1)


func make_crop_stage_visual_ids(base_id: String, count: int) -> Array[StringName]:
	var ids: Array[StringName] = []

	for i in range(count):
		ids.append(StringName("%s_stage_%s" % [base_id, i]))

	return ids


func make_tree_stage_visual_ids(count: int) -> Array[StringName]:
	var ids: Array[StringName] = []

	for i in range(count):
		ids.append(StringName("tree_stage_%s" % i))

	return ids


func make_one_day_stage_durations(count: int) -> Array[int]:
	var durations: Array[int] = []

	for i in range(count):
		durations.append(1)

	return durations


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
		_:
			return &"soil"


func get_allowed_planting_surfaces(crop_type: String) -> Array[StringName]:
	match crop_type:
		"garden_bed":
			return [&"garden_bed"]
		_:
			return [&"field"]


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


func is_tree_type(crop_type: String) -> bool:
	return crop_type == "tree_fruit" or crop_type == "tree_tapping"


func get_tree_definition_type(crop_type: String) -> StringName:
	match crop_type:
		"tree_tapping":
			return &"tapping"
		_:
			return &"fruit"


func get_or_create_crop_definition(crop_id: StringName) -> CropDefinition:
	var path := get_crop_definition_path(crop_id)

	if ResourceLoader.exists(path):
		var loaded_crop: CropDefinition = load(path)

		if loaded_crop != null:
			loaded_crop.resource_path = path
			return loaded_crop

	var crop := CropDefinition.new()
	crop.resource_path = path
	return crop


func get_or_create_tree_definition(tree_id: StringName) -> TreeDefinition:
	var path: String = get_tree_definition_path(tree_id)

	if ResourceLoader.exists(path):
		var loaded_tree: TreeDefinition = load(path)

		if loaded_tree != null:
			loaded_tree.resource_path = path
			return loaded_tree

	var tree_definition: TreeDefinition = TreeDefinitionScript.new()
	tree_definition.resource_path = path
	return tree_definition


func get_or_create_item_definition(item_id: StringName, path: String) -> ItemDefinition:
	if ResourceLoader.exists(path):
		var loaded_item: ItemDefinition = load(path)

		if loaded_item != null:
			loaded_item.resource_path = path
			return loaded_item

	var item := ItemDefinition.new()
	item.resource_path = path
	return item


func add_crop_to_database(database: CropDatabase, crop: CropDefinition) -> void:
	var crops: Array[CropDefinition] = []
	crops.assign(database.crops)

	for existing in crops:
		if existing != null and existing.id == crop.id:
			return

	crops.append(crop)
	database.crops = crops


func add_tree_to_database(database: Resource, tree_definition: Resource) -> void:
	var tree_id := StringName(tree_definition.get("id"))
	var trees: Array = []
	var current_trees = database.get("trees")

	if current_trees is Array:
		trees.assign(current_trees)

	for existing in trees:
		if existing != null and StringName(existing.get("id")) == tree_id:
			return

	trees.append(tree_definition)
	database.set("trees", trees)


func add_item_to_database(database: ItemDatabase, item: ItemDefinition) -> void:
	var items: Array[ItemDefinition] = []
	items.assign(database.items)

	for existing in items:
		if existing != null and existing.id == item.id:
			return

	items.append(item)
	database.items = items


func clear_imported_entries(
	crop_database: CropDatabase,
	tree_database: Resource,
	item_database: ItemDatabase
) -> void:
	var kept_crops: Array[CropDefinition] = []

	for crop in crop_database.crops:
		if crop == null:
			continue

		if is_imported_crop(crop):
			continue

		kept_crops.append(crop)

	crop_database.crops = kept_crops

	var kept_trees: Array[Resource] = []
	var trees: Array = []
	var current_trees = tree_database.get("trees")
	if current_trees is Array:
		trees.assign(current_trees)

	for tree_definition in trees:
		if tree_definition == null:
			continue

		if is_imported_tree(tree_definition):
			continue

		kept_trees.append(tree_definition)

	tree_database.set("trees", kept_trees)

	var kept_items: Array[ItemDefinition] = []

	for item in item_database.items:
		if item == null:
			continue

		if is_imported_item(item):
			continue

		kept_items.append(item)

	item_database.items = kept_items


func is_imported_crop(crop: CropDefinition) -> bool:
	var path := normalize_resource_path(crop.resource_path)

	return path.begins_with(CROP_DEFINITION_DIR) or path.begins_with(OLD_CROP_GENERATED_DIR)


func is_imported_tree(tree_definition: Resource) -> bool:
	var path := normalize_resource_path(tree_definition.resource_path)
	var id_text := String(tree_definition.get("id"))

	return path.begins_with(TREE_DEFINITION_DIR) or id_text.begins_with("tree_")


func is_imported_item(item: ItemDefinition) -> bool:
	var path := normalize_resource_path(item.resource_path)
	var id_text := String(item.id)

	if path.begins_with(OLD_ITEM_GENERATED_DIR):
		return true

	if path.begins_with(SEED_DEFINITION_DIR):
		return true

	if path.begins_with(SAPLING_DEFINITION_DIR):
		return true

	if path.begins_with(HARVEST_ITEM_DIR):
		return true

	return (
		id_text.begins_with("seed_item_")
		or id_text.begins_with("sapling_item_")
		or id_text.begins_with("sapling_")
		or id_text.begins_with("harvest_item_")
	)


func load_or_create_tree_database() -> Resource:
	if ResourceLoader.exists(TREE_DB_PATH):
		var tree_database: Resource = load(TREE_DB_PATH)

		if tree_database != null:
			tree_database.resource_path = TREE_DB_PATH
			return tree_database

	var created_database: Resource = TreeDatabaseScript.new()
	created_database.resource_path = TREE_DB_PATH
	created_database.set("trees", [])
	return created_database


func get_crop_definition_path(crop_id: StringName) -> String:
	return CROP_DEFINITION_DIR + "%s.tres" % crop_id


func get_tree_definition_path(tree_id: StringName) -> String:
	return TREE_DEFINITION_DIR + "%s.tres" % tree_id


func get_seed_item_path(item_id: StringName) -> String:
	return SEED_DEFINITION_DIR + "%s.tres" % item_id


func get_sapling_item_path(item_id: StringName) -> String:
	return SAPLING_DEFINITION_DIR + "%s.tres" % item_id


func get_harvest_item_path(item_id: StringName) -> String:
	return HARVEST_ITEM_DIR + "%s.tres" % item_id


func normalize_resource_path(path: String) -> String:
	return path.replace("\\", "/")


func save_resource(resource: Resource) -> void:
	var error := ResourceSaver.save(resource, resource.resource_path)

	if error != OK:
		push_error("Resource save failed: %s (%s)" % [resource.resource_path, error])


func save_database(database: Resource, path: String) -> void:
	var error := ResourceSaver.save(database, path)

	if error != OK:
		push_error("Database save failed: %s (%s)" % [path, error])


func ensure_dirs() -> void:
	var dirs: Array[String] = [
		CROP_DEFINITION_DIR,
		SEED_DEFINITION_DIR,
		TREE_DEFINITION_DIR,
		SAPLING_DEFINITION_DIR,
		HARVEST_ITEM_DIR
	]

	for dir_path in dirs:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))


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

	if item_id.begins_with("sapling_") or item_id.begins_with("sapling_item_"):
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
