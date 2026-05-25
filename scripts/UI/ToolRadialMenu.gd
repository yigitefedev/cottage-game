class_name ToolRadialMenu
extends Control

@export var slot_scene: PackedScene
@export var radius := 120.0
@export var selected_scale := 1.25
@export var normal_scale := 1.0

@onready var slot_container: Control = $SlotContainer

var player_inventory: PlayerInventory
var slots: Array[InventorySlotUI] = []

var is_open := false
var selected_radial_index := -1
var quick_slot_to_replace := 0


func _ready() -> void:
	add_to_group("tool_radial_menu")
	player_inventory = get_tree().get_first_node_in_group("player_inventory")
	visible = false

	if slot_scene == null:
		push_error("ToolRadialMenu: slot_scene atanmadı.")
		return

	build_slots()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("tool_radial"):
		open_menu()

	if event.is_action_released("tool_radial"):
		confirm_selection()
		close_menu()


func _process(_delta: float) -> void:
	if not is_open:
		return

	update_selection_from_mouse()
	update_slot_visuals()


func build_slots() -> void:
	for child in slot_container.get_children():
		child.queue_free()

	slots.clear()

	for i in range(7):
		var slot := slot_scene.instantiate() as InventorySlotUI
		slot_container.add_child(slot)

		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var inventory_index := PlayerInventory.TOOL_ROW_START + i
		slot.setup(player_inventory, inventory_index, false, -1)

		var angle := -PI / 2.0 + TAU * float(i) / 7.0
		var pos := Vector2(cos(angle), sin(angle)) * radius

		slot.position = pos - slot.size * 0.5

		slots.append(slot)


func open_menu() -> void:
	var inventory_ui := get_tree().get_first_node_in_group("inventory_ui")

	if inventory_ui != null and inventory_ui.is_inventory_open():
		return
	if player_inventory == null:
		player_inventory = get_tree().get_first_node_in_group("player_inventory")

	if player_inventory == null:
		return

	quick_slot_to_replace = get_quick_slot_to_replace()

	is_open = true
	visible = true

	refresh_slots()
	update_selection_from_mouse()
	update_slot_visuals()


func close_menu() -> void:
	is_open = false
	visible = false
	selected_radial_index = -1
	for slot in slots:
		slot.hide_tooltip()


func confirm_selection() -> void:
	if player_inventory == null:
		return

	if selected_radial_index < 0:
		return

	var tool_row_index := PlayerInventory.TOOL_ROW_START + selected_radial_index
	var item := player_inventory.inventory.get_slot(tool_row_index)

	if item == null:
		return

	if not item.has_tag(&"tool"):
		return

	player_inventory.equip_tool_to_quick_slot(tool_row_index, quick_slot_to_replace)


func get_quick_slot_to_replace() -> int:
	if player_inventory == null:
		return 0

	if player_inventory.selected_index == 1:
		return 1

	return 0


func update_selection_from_mouse() -> void:
	var center := global_position + size * 0.5
	var mouse_pos := get_global_mouse_position()
	var dir := mouse_pos - center

	if dir.length() < 25.0:
		selected_radial_index = -1
		return

	var angle := atan2(dir.y, dir.x)
	angle += PI / 2.0

	if angle < 0:
		angle += TAU

	selected_radial_index = roundi(angle / TAU * 7.0) % 7


func update_slot_visuals() -> void:
	for i in range(slots.size()):
		var slot := slots[i]

		if i == selected_radial_index:
			slot.scale = Vector2.ONE * selected_scale
			slot.show_tooltip()
		else:
			slot.scale = Vector2.ONE * normal_scale
			slot.hide_tooltip()


func refresh_slots() -> void:
	for slot in slots:
		slot.refresh()
