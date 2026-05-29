class_name PlayerInventory
extends Node

const INVENTORY_WIDTH := 7
const NORMAL_SLOT_COUNT := 14
const TOOL_ROW_START := 14
const TOOL_ROW_END := 20
const HOTBAR_SIZE := 9

@export var inventory: ItemContainerData
@export var starting_items: Array[ItemInstanceData] = []

var world_item_spawner: WorldItemSpawner
var player: Node3D
var active_inventory_row := 0
var selected_index := 0
var equipped_tool_indices: Array[int] = [14, 15]

signal selected_slot_changed(index: int)
signal inventory_changed


func _ready() -> void:
	add_to_group("player_inventory")

	await get_tree().process_frame

	world_item_spawner = get_tree().get_first_node_in_group("world_item_spawner")
	player = get_tree().get_first_node_in_group("player") as Node3D

	if inventory != null:
		inventory.width = INVENTORY_WIDTH
		inventory.height = 3
		inventory.setup_slots()

		for item in starting_items:
			if item == null:
				continue

			if item_is_tool(item):
				var placed := false

				for slot_index in range(TOOL_ROW_START, TOOL_ROW_END + 1):
					if inventory.get_slot(slot_index) == null:
						inventory.set_slot(slot_index, item)
						placed = true
						break

				if placed:
					continue

			inventory.add_item(item)

	inventory_changed.emit()
	selected_slot_changed.emit(selected_index)


func _input(event: InputEvent) -> void:
	for i in HOTBAR_SIZE:
		if event.is_action_pressed("hotbar_%s" % [i + 1]):
			select_slot(i)

	if event.is_action_pressed("drop_selected_item"):
		drop_selected_item(Input.is_key_pressed(KEY_SHIFT))
	
	if event.is_action_pressed("cycle_hotbar_row"):
		cycle_active_inventory_row()


func select_slot(index: int) -> void:
	if inventory == null:
		return

	if index < 0 or index >= HOTBAR_SIZE:
		return

	selected_index = index
	selected_slot_changed.emit(selected_index)


func get_selected_item() -> ItemInstanceData:
	if inventory == null:
		return null

	var inventory_index := get_inventory_index_for_hotbar_index(selected_index)
	return inventory.get_slot(inventory_index)


func get_inventory_index_for_hotbar_index(hotbar_index: int) -> int:
	if hotbar_index == 0:
		return equipped_tool_indices[0]

	if hotbar_index == 1:
		return equipped_tool_indices[1]

	var column := hotbar_index - 2
	return active_inventory_row * INVENTORY_WIDTH + column


func is_tool_slot(index: int) -> bool:
	return index >= TOOL_ROW_START and index <= TOOL_ROW_END


func is_normal_slot(index: int) -> bool:
	return index >= 0 and index < NORMAL_SLOT_COUNT


func item_is_tool(item: ItemInstanceData) -> bool:
	return item != null and item.has_tag(&"tool")


func can_place_item_in_slot(item: ItemInstanceData, index: int) -> bool:
	if item == null:
		return true

	if is_tool_slot(index):
		return item_is_tool(item)

	if is_normal_slot(index):
		return true

	return false


func can_swap_slots(a: int, b: int) -> bool:
	if inventory == null:
		return false

	if not inventory.is_valid_slot(a) or not inventory.is_valid_slot(b):
		return false

	var item_a := inventory.get_slot(a)
	var item_b := inventory.get_slot(b)

	return can_place_item_in_slot(item_a, b) and can_place_item_in_slot(item_b, a)


func swap_slots(a: int, b: int) -> void:
	if inventory == null:
		return

	if not can_swap_slots(a, b):
		return

	var temp := inventory.get_slot(a)
	inventory.set_slot(a, inventory.get_slot(b))
	inventory.set_slot(b, temp)

	inventory_changed.emit()
	selected_slot_changed.emit(selected_index)


func add_item(item: ItemInstanceData) -> ItemInstanceData:
	if inventory == null:
		return item

	var remaining := inventory.add_item(item)

	inventory_changed.emit()

	return remaining


func drop_selected_item(drop_all: bool = false) -> void:
	if inventory == null:
		return

	var inventory_index := get_inventory_index_for_hotbar_index(selected_index)
	var item := inventory.get_slot(inventory_index)

	if item == null or item.definition == null:
		return

	if world_item_spawner == null or player == null:
		return

	var drop_amount := item.amount if drop_all else 1

	var dropped_item := ItemInstanceData.new()
	dropped_item.definition = item.definition
	dropped_item.amount = drop_amount
	dropped_item.state = item.state.duplicate(true)

	item.amount -= drop_amount

	if item.amount <= 0:
		inventory.set_slot(inventory_index, null)

	var forward := get_player_forward()
	var spawn_position := player.global_position + Vector3.UP * 0.6

	var dropped := world_item_spawner.spawn_item(
		dropped_item,
		spawn_position,
		0.0
	)

	if dropped != null:
		dropped.velocity = forward * randf_range(3.5, 5.0) + Vector3.UP * randf_range(1.0, 2.0)

	inventory_changed.emit()


func get_player_forward() -> Vector3:
	if player == null:
		return Vector3.FORWARD

	var forward := player.global_transform.basis.z
	forward.y = 0

	if forward.length() <= 0.01:
		return Vector3.FORWARD

	return forward.normalized()

func equip_tool_to_quick_slot(tool_row_index: int, quick_slot: int) -> void:
	if quick_slot < 0 or quick_slot >= equipped_tool_indices.size():
		return

	if not is_tool_slot(tool_row_index):
		return

	var item := inventory.get_slot(tool_row_index)

	if item == null:
		return

	if not item_is_tool(item):
		return

	var previous_tool_index := equipped_tool_indices[quick_slot]

	for i in range(equipped_tool_indices.size()):
		if i == quick_slot:
			continue

		if equipped_tool_indices[i] == tool_row_index:
			equipped_tool_indices[i] = previous_tool_index

	equipped_tool_indices[quick_slot] = tool_row_index

	inventory_changed.emit()
	selected_slot_changed.emit(selected_index)

	if not item_is_tool(item):
		return

	equipped_tool_indices[quick_slot] = tool_row_index

	inventory_changed.emit()
	selected_slot_changed.emit(selected_index)


func get_equipped_tool_index(quick_slot: int) -> int:
	if quick_slot < 0 or quick_slot >= equipped_tool_indices.size():
		return -1

	return equipped_tool_indices[quick_slot]

func get_tool_row_indices() -> Array[int]:
	var indices: Array[int] = []

	for i in range(TOOL_ROW_START, TOOL_ROW_END + 1):
		indices.append(i)

	return indices
	
func cycle_active_inventory_row() -> void:
	active_inventory_row += 1

	if active_inventory_row >= 2:
		active_inventory_row = 0

	inventory_changed.emit()
	selected_slot_changed.emit(selected_index)
