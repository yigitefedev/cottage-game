class_name InventorySlotUI
extends PanelContainer

@onready var amount_label: Label = $AmountLabel
@onready var icon: TextureRect = $Icon
@onready var panel_stylebox: StyleBoxFlat = get_theme_stylebox("panel").duplicate()

var is_hovered := false
var slot_index: int = -1
var player_inventory: PlayerInventory

func _ready() -> void:
	add_theme_stylebox_override("panel", panel_stylebox)
	mouse_entered.connect(func(): 
		is_hovered = true
		refresh()
	)

	mouse_exited.connect(func():
		is_hovered = false
		refresh()
	)
	update_highlight()
func setup(_player_inventory: PlayerInventory, _slot_index: int) -> void:
	player_inventory = _player_inventory
	slot_index = _slot_index
	refresh()

func update_highlight() -> void:
	var selected := false
	var inventory_is_open := false

	if player_inventory != null:
		selected = slot_index == player_inventory.selected_index

	var inventory_ui := get_tree().get_first_node_in_group("inventory_ui")

	if inventory_ui != null:
		inventory_is_open = inventory_ui.is_inventory_open()

	if selected and not inventory_is_open:
		panel_stylebox.bg_color = Color(0.75, 0.75, 0.75, 1.0)
	elif is_hovered:
		panel_stylebox.bg_color = Color(0.75, 0.75, 0.75, 1.0)
	else:
		panel_stylebox.bg_color = Color(0.2, 0.2, 0.2, 1.0)
	
func refresh() -> void:
	if icon == null:
		return

	if player_inventory == null or player_inventory.inventory == null:
		update_highlight()
		return

	var item := player_inventory.inventory.get_slot(slot_index)

	if item == null or item.definition == null:
		icon.texture = null
		amount_label.text = ""
	else:
		icon.texture = item.definition.icon

		if item.amount > 1:
			amount_label.text = str(item.amount)

		elif item.state.has("water"):
			amount_label.text = str(item.state["water"])

		else:
			amount_label.text = ""

	update_highlight()


func _get_drag_data(mouse_pos: Vector2) -> Variant:
	if player_inventory == null:
		return null

	var item := player_inventory.inventory.get_slot(slot_index)

	if item == null:
		return null

	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(64, 64)
	preview.size = Vector2(64, 64)

	var preview_icon := TextureRect.new()
	preview_icon.texture = item.definition.icon
	preview_icon.custom_minimum_size = Vector2(64, 64)
	preview_icon.size = Vector2(64, 64)
	preview_icon.position = -mouse_pos
	preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	preview.add_child(preview_icon)
	set_drag_preview(preview)

	icon.visible = false

	return {
		"slot_index": slot_index
	}


func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("slot_index")


func _drop_data(_position: Vector2, data: Variant) -> void:
	var from_index: int = data["slot_index"]

	if player_inventory != null:
		player_inventory.swap_slots(from_index, slot_index)
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		icon.visible = true
