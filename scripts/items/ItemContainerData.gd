class_name ItemContainerData
extends Resource

@export var width: int = 7
@export var height: int = 1

@export var slots: Array[ItemInstanceData] = []


func get_slot_count() -> int:
	return width * height


func setup_slots() -> void:
	var target_size := get_slot_count()

	while slots.size() < target_size:
		slots.append(null)

	while slots.size() > target_size:
		slots.pop_back()


func get_slot(index: int) -> ItemInstanceData:
	if index < 0 or index >= slots.size():
		return null

	return slots[index]


func set_slot(index: int, item: ItemInstanceData) -> void:
	if index < 0 or index >= slots.size():
		return

	slots[index] = item


func is_valid_slot(index: int) -> bool:
	return index >= 0 and index < slots.size()
	
func add_item(item: ItemInstanceData) -> ItemInstanceData:
	if item == null or item.definition == null:
		return item

	var remaining := item.amount

	# stacking
	for slot_item in slots:
		if slot_item == null:
			continue

		if not slot_item.is_stackable_with(item):
			continue

		var space := slot_item.definition.max_stack - slot_item.amount

		if space <= 0:
			continue

		var added = min(space, remaining)
		slot_item.amount += added
		remaining -= added

		if remaining <= 0:
			return null

	# to empty slot
	for i in range(slots.size()):
		if slots[i] != null:
			continue

		var new_stack := ItemInstanceData.new()
		new_stack.definition = item.definition
		new_stack.amount = min(item.definition.max_stack, remaining)
		new_stack.state = item.state.duplicate(true)

		slots[i] = new_stack
		remaining -= new_stack.amount

		if remaining <= 0:
			return null

	item.amount = remaining
	return item
