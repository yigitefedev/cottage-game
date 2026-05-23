class_name PlayerInventory
extends Node
@export var inventory: ItemContainerData
@export var starting_items: Array[ItemInstanceData] = []
var world_item_spawner: WorldItemSpawner
var player: Node3D
var selected_index := 0


signal selected_slot_changed(index: int)
signal inventory_changed

func _ready() -> void:
	add_to_group("player_inventory")
	await get_tree().process_frame

	world_item_spawner = get_tree().get_first_node_in_group("world_item_spawner")
	player = get_tree().get_first_node_in_group("player") as Node3D

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
	if event.is_action_pressed("drop_selected_item"):
		drop_selected_item(Input.is_key_pressed(KEY_SHIFT))


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
	
func add_item(item: ItemInstanceData) -> ItemInstanceData:
	if inventory == null:
		return item

	var remaining := inventory.add_item(item)

	inventory_changed.emit()

	return remaining
func drop_selected_item(drop_all: bool = false) -> void:
	if inventory == null:
		return

	var item := inventory.get_slot(selected_index)

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
		inventory.set_slot(selected_index, null)

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
