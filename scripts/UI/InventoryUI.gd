extends Control

@export var slot_scene: PackedScene

@onready var hotbar_grid: GridContainer = $HotbarPanel/MarginContainer/HotbarGrid
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var inventory_grid: GridContainer = $InventoryPanel/MarginContainer/InventoryGrid
@onready var hotbar_panel: PanelContainer = $HotbarPanel
@onready var selected_item_name_label: Label = $SelectedItemNameLabel

var player_inventory: PlayerInventory
var hotbar_slots: Array[InventorySlotUI] = []
var inventory_slots: Array[InventorySlotUI] = []


func _ready() -> void:
	player_inventory = get_tree().get_first_node_in_group("player_inventory")
	add_to_group("inventory_ui")

	if player_inventory == null:
		push_warning("InventoryUI: PlayerInventory bulunamadı.")
		return

	player_inventory.inventory_changed.connect(refresh_all)
	player_inventory.selected_slot_changed.connect(refresh_all)

	build_ui()
	inventory_panel.visible = false
	hotbar_panel.visible = true
	selected_item_name_label.visible = false
	refresh_all()


func _input(event: InputEvent) -> void:
	var radial_menu := get_tree().get_first_node_in_group("tool_radial_menu")

	if radial_menu != null and radial_menu.is_open:
		return

	if event.is_action_pressed("open_inventory"):
		var is_open := not inventory_panel.visible

		inventory_panel.visible = is_open
		hotbar_panel.visible = not is_open

		refresh_all()


func build_ui() -> void:
	for child in hotbar_grid.get_children():
		child.queue_free()

	for child in inventory_grid.get_children():
		child.queue_free()

	hotbar_slots.clear()
	inventory_slots.clear()

	build_hotbar_slots()
	build_inventory_slots()


func build_hotbar_slots() -> void:
	for hotbar_index in range(player_inventory.HOTBAR_SIZE):
		var inventory_index := player_inventory.get_inventory_index_for_hotbar_index(hotbar_index)

		var slot := slot_scene.instantiate() as InventorySlotUI
		hotbar_grid.add_child(slot)

		slot.setup(player_inventory, inventory_index, true, hotbar_index)
		slot.hotbar_index = hotbar_index
		slot.is_hotbar_slot = true

		hotbar_slots.append(slot)


func build_inventory_slots() -> void:
	for inventory_index in range(player_inventory.inventory.get_slot_count()):
		var slot := slot_scene.instantiate() as InventorySlotUI
		inventory_grid.add_child(slot)

		slot.setup(player_inventory, inventory_index, false, -1)
		slot.is_hotbar_slot = false

		inventory_slots.append(slot)


func refresh_all(_index := -1) -> void:
	for i in range(hotbar_slots.size()):
		var inventory_index := player_inventory.get_inventory_index_for_hotbar_index(i)
		hotbar_slots[i].setup(player_inventory, inventory_index, true, i)
		hotbar_slots[i].refresh()

	for slot in inventory_slots:
		slot.refresh()
	
	update_selected_item_name()


func is_inventory_open() -> bool:
	return inventory_panel.visible

func update_selected_item_name() -> void:
	if selected_item_name_label == null or player_inventory == null:
		return

	if inventory_panel.visible:
		selected_item_name_label.visible = false
		return

	var item := player_inventory.get_selected_item()

	if item == null or item.definition == null:
		selected_item_name_label.visible = false
		selected_item_name_label.text = ""
		return

	selected_item_name_label.visible = true
	selected_item_name_label.text = item.definition.display_name
