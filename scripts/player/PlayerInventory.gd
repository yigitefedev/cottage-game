class_name PlayerInventory
extends Node
@export var inventory: ItemContainerData
@export var starting_items: Array[ItemInstanceData] = []

var selected_index := 0

signal selected_slot_changed(index: int)
signal inventory_changed

func _ready() -> void:
	add_to_group("player_inventory")

	if inventory != null:
		inventory.width = 7
		inventory.height = 3
		inventory.setup_slots()

		for i in starting_items.size():
			if i < inventory.slots.size():
				inventory.set_slot(i, starting_items[i])

		inventory_changed.emit()
		selected_slot_changed.emit(selected_index)


func _input(event: InputEvent) -> void:
	for i in 7:
		if event.is_action_pressed("hotbar_%s" % [i + 1]):
			select_slot(i)


func select_slot(index: int) -> void:
	if inventory == null:
		return

	if index < 0 or index >= 7:
		return

	selected_index = index
	selected_slot_changed.emit(selected_index)


func get_selected_item() -> ItemInstanceData:
	if inventory == null:
		return null

	return inventory.get_slot(selected_index)


func swap_slots(a: int, b: int) -> void:
	if inventory == null:
		return

	if not inventory.is_valid_slot(a) or not inventory.is_valid_slot(b):
		return

	var temp := inventory.get_slot(a)
	inventory.set_slot(a, inventory.get_slot(b))
	inventory.set_slot(b, temp)

	inventory_changed.emit()
	selected_slot_changed.emit(selected_index)
