class_name WorkstationManager
extends Node

@export var definition_database: WorkstationDefinitionDatabase
@export var recipe_database: WorkstationRecipeDatabase
@export var grid_manager: GridManager
@export var time_manager: Node

const DEFINITION_DATABASE_PATH := "res://resources/workstations/MainWorkstationDefinitionDatabase.tres"
const RECIPE_DATABASE_PATH := "res://resources/workstations/MainWorkstationRecipeDatabase.tres"

const STATE_EMPTY: StringName = &"empty"
const STATE_COLLECTING_INPUTS: StringName = &"collecting_inputs"
const STATE_PROCESSING: StringName = &"processing"
const STATE_DONE: StringName = &"done"


func _ready() -> void:
	add_to_group("workstation_manager")

	ensure_refs()

	if time_manager != null and time_manager.has_signal("time_tick"):
		time_manager.time_tick.connect(_on_time_tick)
	if time_manager != null and time_manager.has_signal("time_skipped"):
		time_manager.time_skipped.connect(_on_time_skipped)

func _on_time_skipped(minutes: int) -> void:
	process_workstations_by_minutes(minutes)
func process_workstations_by_minutes(minutes_to_advance: int) -> void:
	ensure_refs()

	if grid_manager == null:
		return

	if grid_manager.grid_data == null:
		return

	if minutes_to_advance <= 0:
		return

	for coord in grid_manager.grid_data.tiles.keys():
		if coord is Vector2i:
			process_workstation_at(coord as Vector2i, minutes_to_advance)
func ensure_refs() -> void:
	if grid_manager == null:
		grid_manager = get_tree().get_first_node_in_group("grid_manager")

	if time_manager == null:
		time_manager = get_tree().get_first_node_in_group("time_manager")

	if definition_database == null and ResourceLoader.exists(DEFINITION_DATABASE_PATH):
		definition_database = load(DEFINITION_DATABASE_PATH) as WorkstationDefinitionDatabase

	if recipe_database == null and ResourceLoader.exists(RECIPE_DATABASE_PATH):
		recipe_database = load(RECIPE_DATABASE_PATH) as WorkstationRecipeDatabase

	if definition_database != null:
		definition_database.build_lookup()

	if recipe_database != null:
		recipe_database.build_lookup()

func get_current_tick_progress_ratio() -> float:
	if time_manager == null:
		return 0.0

	if not time_manager.has_method("get_tick_progress_ratio"):
		return 0.0

	return float(time_manager.call("get_tick_progress_ratio"))
func get_visual_progress_ratio(coord: Vector2i) -> float:
	var state: Dictionary = get_or_create_state(coord)

	if state.is_empty():
		return 0.0

	var current_state: StringName = StringName(state.get("state", STATE_EMPTY))

	if current_state == STATE_DONE:
		return 1.0

	if current_state != STATE_PROCESSING:
		return 0.0

	var duration_minutes: int = int(state.get("duration_minutes", 0))

	if duration_minutes <= 0:
		return 0.0

	var remaining_minutes: int = int(state.get("remaining_minutes", 0))
	var completed_minutes: int = duration_minutes - remaining_minutes

	var tick_alpha: float = get_current_tick_progress_ratio()
	var visual_extra_minutes: float = float(get_minutes_per_tick()) * tick_alpha

	if visual_extra_minutes > float(remaining_minutes):
		visual_extra_minutes = float(remaining_minutes)

	var visual_completed_minutes: float = float(completed_minutes) + visual_extra_minutes

	return clampf(visual_completed_minutes / float(duration_minutes), 0.0, 1.0)
	
func is_workstation_tile(coord: Vector2i) -> bool:
	var definition: WorkstationDefinition = get_definition_for_tile(coord)
	return definition != null


func get_definition_for_tile(coord: Vector2i) -> WorkstationDefinition:
	ensure_refs()

	if grid_manager == null:
		return null

	if definition_database == null:
		return null

	var tile: GameTileData = grid_manager.get_tile(coord)

	if tile == null:
		return null

	for object_id: StringName in tile.object_ids:
		var definition: WorkstationDefinition = definition_database.get_definition_for_object_id(object_id)

		if definition != null:
			return definition

	return null


func get_or_create_state(coord: Vector2i) -> Dictionary:
	ensure_refs()

	if grid_manager == null:
		return {}

	var tile: GameTileData = grid_manager.get_tile(coord)

	if tile == null:
		return {}

	var definition: WorkstationDefinition = get_definition_for_tile(coord)

	if definition == null:
		return {}

	var raw_state: Variant = tile.custom_data.get("workstation", null)

	if raw_state is Dictionary:
		var existing_state: Dictionary = raw_state

		if not existing_state.is_empty():
			return existing_state

	var state: Dictionary = create_empty_state(definition)
	tile.custom_data["workstation"] = state

	return state


func create_empty_state(definition: WorkstationDefinition) -> Dictionary:
	return {
		"workstation_id": definition.id,
		"workstation_type": definition.get_workstation_type(),
		"state": STATE_EMPTY,
		"recipe_id": &"",
		"input_slots": [],
		"output_slots": [],
		"remaining_minutes": 0,
		"duration_minutes": 0
	}


func clear_state(coord: Vector2i) -> void:
	if grid_manager == null:
		return

	var tile: GameTileData = grid_manager.get_tile(coord)

	if tile == null:
		return

	if tile.custom_data.has("workstation"):
		tile.custom_data.erase("workstation")

func can_cancel(coord: Vector2i) -> bool:
	var state: Dictionary = get_or_create_state(coord)

	if state.is_empty():
		return false

	var current_state: StringName = StringName(state.get("state", STATE_EMPTY))

	return current_state == STATE_COLLECTING_INPUTS or current_state == STATE_PROCESSING
	
func get_refund_slots(coord: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var state: Dictionary = get_or_create_state(coord)

	if state.is_empty():
		return result

	var raw_slots: Variant = state.get("input_slots", [])

	if not (raw_slots is Array):
		return result

	var slots: Array = raw_slots

	for raw_slot: Variant in slots:
		if not (raw_slot is Dictionary):
			continue

		var slot: Dictionary = raw_slot
		var item_id: StringName = StringName(slot.get("item_id", &""))
		var current_amount: int = int(slot.get("current_amount", 0))

		if item_id == &"":
			continue

		if current_amount <= 0:
			continue


		result.append({
			"item_id": item_id,
			"amount": current_amount
		})

	return result
	
func cancel_workstation(coord: Vector2i) -> Array[Dictionary]:
	if not can_cancel(coord):
		return []

	var refunds: Array[Dictionary] = get_refund_slots(coord)
	reset_to_empty(coord)

	return refunds
func try_insert_item(coord: Vector2i, item_id: StringName, available_amount: int) -> int:
	if available_amount <= 0:
		return 0

	var state: Dictionary = get_or_create_state(coord)

	if state.is_empty():
		return 0

	var current_state: StringName = StringName(state.get("state", STATE_EMPTY))

	match current_state:
		STATE_EMPTY:
			return try_start_recipe(coord, state, item_id, available_amount)

		STATE_COLLECTING_INPUTS:
			return try_add_input_to_active_recipe(coord, state, item_id, available_amount)

		STATE_PROCESSING:
			return 0

		STATE_DONE:
			return 0

	return 0


func try_start_recipe(coord: Vector2i, state: Dictionary, item_id: StringName, available_amount: int) -> int:
	if recipe_database == null:
		return 0

	var workstation_type: StringName = StringName(state.get("workstation_type", &""))
	var recipe: WorkstationRecipe = recipe_database.find_start_recipe(workstation_type, item_id)

	if recipe == null:
		return 0

	setup_state_from_recipe(state, recipe)

	var used_amount: int = add_item_to_input_slots(state, item_id, available_amount)

	if used_amount <= 0:
		return 0

	update_state_after_input_change(state)

	save_state(coord, state)

	return used_amount


func setup_state_from_recipe(state: Dictionary, recipe: WorkstationRecipe) -> void:
	state["state"] = STATE_COLLECTING_INPUTS
	state["recipe_id"] = recipe.id
	state["input_slots"] = build_input_slots(recipe)
	state["output_slots"] = build_output_slots(recipe)
	state["remaining_minutes"] = 0
	state["duration_minutes"] = recipe.duration_minutes


func build_input_slots(recipe: WorkstationRecipe) -> Array:
	var slots: Array = []

	for input: WorkstationItemStack in recipe.inputs:
		if input == null:
			continue

		slots.append({
			"item_id": input.item_id,
			"required_amount": input.amount,
			"current_amount": 0
		})

	return slots


func build_output_slots(recipe: WorkstationRecipe) -> Array:
	var slots: Array = []

	for output: WorkstationItemStack in recipe.outputs:
		if output == null:
			continue

		slots.append({
			"item_id": output.item_id,
			"amount": output.amount
		})

	return slots


func try_add_input_to_active_recipe(coord: Vector2i, state: Dictionary, item_id: StringName, available_amount: int) -> int:
	var used_amount: int = add_item_to_input_slots(state, item_id, available_amount)

	if used_amount <= 0:
		return 0

	update_state_after_input_change(state)
	save_state(coord, state)

	return used_amount


func add_item_to_input_slots(state: Dictionary, item_id: StringName, available_amount: int) -> int:
	var raw_slots: Variant = state.get("input_slots", [])

	if not (raw_slots is Array):
		return 0

	var slots: Array = raw_slots
	var remaining_to_insert: int = available_amount
	var used_amount: int = 0

	for i: int in range(slots.size()):
		var raw_slot: Variant = slots[i]

		if not (raw_slot is Dictionary):
			continue

		var slot: Dictionary = raw_slot
		var slot_item_id: StringName = StringName(slot.get("item_id", &""))

		if slot_item_id != item_id:
			continue

		var required_amount: int = int(slot.get("required_amount", 0))
		var current_amount: int = int(slot.get("current_amount", 0))
		var missing_amount: int = required_amount - current_amount

		if missing_amount <= 0:
			continue

		var amount_to_add: int = remaining_to_insert

		if amount_to_add > missing_amount:
			amount_to_add = missing_amount

		current_amount += amount_to_add
		remaining_to_insert -= amount_to_add
		used_amount += amount_to_add

		slot["current_amount"] = current_amount
		slots[i] = slot

		if remaining_to_insert <= 0:
			break

	state["input_slots"] = slots

	return used_amount


func update_state_after_input_change(state: Dictionary) -> void:
	if are_all_inputs_complete(state):
		state["state"] = STATE_PROCESSING
		state["remaining_minutes"] = int(state.get("duration_minutes", 0))


func are_all_inputs_complete(state: Dictionary) -> bool:
	var raw_slots: Variant = state.get("input_slots", [])

	if not (raw_slots is Array):
		return false

	var slots: Array = raw_slots

	if slots.is_empty():
		return false

	for raw_slot in slots:
		if not (raw_slot is Dictionary):
			return false

		var slot: Dictionary = raw_slot
		var required_amount: int = int(slot.get("required_amount", 0))
		var current_amount: int = int(slot.get("current_amount", 0))

		if current_amount < required_amount:
			return false

	return true


func save_state(coord: Vector2i, state: Dictionary) -> void:
	if grid_manager == null:
		return

	var tile: GameTileData = grid_manager.get_tile(coord)

	if tile == null:
		return

	tile.custom_data["workstation"] = state


func _on_time_tick(_day: int, _hour: int, _minute: int) -> void:
	process_workstations()


func process_workstations() -> void:
	ensure_refs()

	if grid_manager == null:
		return

	if grid_manager.grid_data == null:
		return

	var minutes_to_advance: int = get_minutes_per_tick()

	for coord in grid_manager.grid_data.tiles.keys():
		if coord is Vector2i:
			process_workstation_at(coord as Vector2i, minutes_to_advance)


func get_minutes_per_tick() -> int:
	if time_manager == null:
		return 1

	var raw_minutes: Variant = time_manager.get("minutes_per_tick")

	if raw_minutes == null:
		return 1

	var minutes: int = int(raw_minutes)

	if minutes <= 0:
		return 1

	return minutes


func process_workstation_at(coord: Vector2i, minutes_to_advance: int) -> void:
	var state: Dictionary = get_or_create_state(coord)

	if state.is_empty():
		return

	var current_state: StringName = StringName(state.get("state", STATE_EMPTY))

	if current_state != STATE_PROCESSING:
		return

	var remaining_minutes: int = int(state.get("remaining_minutes", 0))
	remaining_minutes -= minutes_to_advance

	if remaining_minutes <= 0:
		remaining_minutes = 0
		state["state"] = STATE_DONE

	state["remaining_minutes"] = remaining_minutes
	save_state(coord, state)


func get_progress_ratio(coord: Vector2i) -> float:
	var state: Dictionary = get_or_create_state(coord)

	if state.is_empty():
		return 0.0

	var duration_minutes: int = int(state.get("duration_minutes", 0))

	if duration_minutes <= 0:
		return 0.0

	var remaining_minutes: int = int(state.get("remaining_minutes", 0))
	var completed_minutes: int = duration_minutes - remaining_minutes

	return clampf(float(completed_minutes) / float(duration_minutes), 0.0, 1.0)


func is_done(coord: Vector2i) -> bool:
	var state: Dictionary = get_or_create_state(coord)

	if state.is_empty():
		return false

	return StringName(state.get("state", STATE_EMPTY)) == STATE_DONE


func get_output_slots(coord: Vector2i) -> Array:
	var state: Dictionary = get_or_create_state(coord)

	if state.is_empty():
		return []

	var raw_outputs: Variant = state.get("output_slots", [])

	if raw_outputs is Array:
		return raw_outputs

	return []

func can_insert_item(coord: Vector2i, item_id: StringName) -> bool:
	if item_id == &"":
		return false

	var state: Dictionary = get_or_create_state(coord)

	if state.is_empty():
		return false

	var current_state: StringName = StringName(state.get("state", STATE_EMPTY))

	match current_state:
		STATE_EMPTY:
			if recipe_database == null:
				return false

			var workstation_type: StringName = StringName(state.get("workstation_type", &""))
			var recipe: WorkstationRecipe = recipe_database.find_start_recipe(workstation_type, item_id)

			return recipe != null

		STATE_COLLECTING_INPUTS:
			return has_missing_input_for_item(state, item_id)

		STATE_PROCESSING:
			return false

		STATE_DONE:
			return false

	return false


func has_missing_input_for_item(state: Dictionary, item_id: StringName) -> bool:
	var raw_slots: Variant = state.get("input_slots", [])

	if not (raw_slots is Array):
		return false

	var slots: Array = raw_slots

	for raw_slot: Variant in slots:
		if not (raw_slot is Dictionary):
			continue

		var slot: Dictionary = raw_slot
		var slot_item_id: StringName = StringName(slot.get("item_id", &""))

		if slot_item_id != item_id:
			continue

		var required_amount: int = int(slot.get("required_amount", 0))
		var current_amount: int = int(slot.get("current_amount", 0))

		if current_amount < required_amount:
			return true

	return false
func reset_to_empty(coord: Vector2i) -> void:
	var definition: WorkstationDefinition = get_definition_for_tile(coord)

	if definition == null:
		clear_state(coord)
		return

	var state: Dictionary = create_empty_state(definition)
	save_state(coord, state)
