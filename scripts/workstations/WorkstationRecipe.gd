class_name WorkstationRecipe
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""

@export var workstation_type: StringName = &""

@export var inputs: Array[WorkstationItemStack] = []
@export var outputs: Array[WorkstationItemStack] = []

@export var duration_minutes: int = 60


func can_start_with(item_id: StringName) -> bool:
	var starter: WorkstationItemStack = get_starter_input()

	if starter == null:
		return false

	return starter.item_id == item_id


func accepts_input(item_id: StringName) -> bool:
	for input: WorkstationItemStack in inputs:
		if input == null:
			continue

		if input.item_id == item_id:
			return true

	return false


func get_input_index(item_id: StringName) -> int:
	for i: int in range(inputs.size()):
		var input: WorkstationItemStack = inputs[i]

		if input == null:
			continue

		if input.item_id == item_id:
			return i

	return -1


func get_starter_input() -> WorkstationItemStack:
	if inputs.is_empty():
		return null

	return inputs[0]


func has_valid_data() -> bool:
	if id == &"":
		return false

	if workstation_type == &"":
		return false

	if duration_minutes <= 0:
		return false

	if inputs.is_empty():
		return false

	if outputs.is_empty():
		return false

	for input: WorkstationItemStack in inputs:
		if input == null:
			return false

		if not input.is_valid_data():
			return false

	for output: WorkstationItemStack in outputs:
		if output == null:
			return false

		if not output.is_valid_data():
			return false

	return true
