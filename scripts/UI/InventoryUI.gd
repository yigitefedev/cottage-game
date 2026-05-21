extends Control

@export var slot_scene: PackedScene

@onready var hotbar_grid: GridContainer = $HotbarPanel/MarginContainer/HotbarGrid
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var inventory_grid: GridContainer = $InventoryPanel/MarginContainer/InventoryGrid
@onready var hotbar_panel: PanelContainer = $HotbarPanel

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
	refresh_all()


func _input(event: InputEvent) -> void:
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

	for i in range(7):
		var slot := slot_scene.instantiate() as InventorySlotUI
		hotbar_grid.add_child(slot)
		slot.setup(player_inventory, i)
		hotbar_slots.append(slot)

	for i in range(player_inventory.inventory.get_slot_count()):
		var slot := slot_scene.instantiate() as InventorySlotUI
		inventory_grid.add_child(slot)
		slot.setup(player_inventory, i)
		inventory_slots.append(slot)


func refresh_all(_index := -1) -> void:
	for slot in hotbar_slots:
		slot.refresh()

	for slot in inventory_slots:
		slot.refresh()
		
func is_inventory_open() -> bool:
	return inventory_panel.visible
