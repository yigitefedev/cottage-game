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
