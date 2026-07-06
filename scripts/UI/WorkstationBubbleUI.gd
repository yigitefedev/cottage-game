class_name WorkstationBubbleUI
extends Control

@export var item_database: ItemDatabase

@export var bubble_world_offset: Vector3 = Vector3(0.0, 1.35, 0.0)

@export var slot_size: Vector2 = Vector2(38.0, 38.0)
@export var edge_padding: float = 7.0
@export var slot_separation: float = 6.0

@export var bubble_color: Color = Color(1.0, 1.0, 1.0, 0.92)
@export var slot_color: Color = Color(1.0, 1.0, 1.0, 0.0)
@export var slot_border_color: Color = Color(0.72, 0.62, 0.55, 0.0)
@export var progress_color: Color = Color(0.52, 0.92, 0.55, 0.65)

const ITEM_DATABASE_PATH := "res://resources/items/MainItemDatabase.tres"

var bubble_progress_fill: ColorRect
var bubble_panel: Panel
var slot_container: HBoxContainer

var camera: Camera3D
var grid_manager: GridManager
var tile_targeter: PlayerTileTargeter
var workstation_manager: WorkstationManager


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	ensure_refs()
	build_ui()

	if item_database != null:
		item_database.build_lookup()


func _process(_delta: float) -> void:
	ensure_refs()
	update_bubble()


func ensure_refs() -> void:
	if camera == null:
		camera = get_viewport().get_camera_3d()

	if grid_manager == null:
		grid_manager = get_tree().get_first_node_in_group("grid_manager")

	if tile_targeter == null:
		tile_targeter = get_tree().get_first_node_in_group("player_tile_targeter")

	if workstation_manager == null:
		workstation_manager = get_tree().get_first_node_in_group("workstation_manager")

	if item_database == null and ResourceLoader.exists(ITEM_DATABASE_PATH):
		item_database = load(ITEM_DATABASE_PATH) as ItemDatabase

	if item_database != null:
		item_database.build_lookup()


func build_ui() -> void:
	bubble_panel = Panel.new()
	bubble_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble_panel.visible = false
	bubble_panel.clip_children = Control.CLIP_CHILDREN_AND_DRAW
	add_child(bubble_panel)

	var bubble_style := StyleBoxFlat.new()
	bubble_style.bg_color = bubble_color
	bubble_style.corner_radius_top_left = 12
	bubble_style.corner_radius_top_right = 12
	bubble_style.corner_radius_bottom_left = 12
	bubble_style.corner_radius_bottom_right = 12
	bubble_panel.add_theme_stylebox_override("panel", bubble_style)

	bubble_progress_fill = ColorRect.new()
	bubble_progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble_progress_fill.color = progress_color
	bubble_progress_fill.visible = false
	bubble_panel.add_child(bubble_progress_fill)

	slot_container = HBoxContainer.new()
	slot_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	slot_container.add_theme_constant_override("separation", int(slot_separation))
	bubble_panel.add_child(slot_container)

func get_bubble_size_for_slot_count(slot_count: int) -> Vector2:
	var safe_slot_count: int = slot_count

	if safe_slot_count < 1:
		safe_slot_count = 1

	var width: float = edge_padding * 2.0
	width += float(safe_slot_count) * slot_size.x
	width += float(safe_slot_count - 1) * slot_separation

	var height: float = edge_padding * 2.0
	height += slot_size.y

	return Vector2(width, height)

func apply_bubble_layout(slot_count: int, current_bubble_size: Vector2) -> void:
	bubble_panel.custom_minimum_size = current_bubble_size
	bubble_panel.size = current_bubble_size

	var safe_slot_count: int = slot_count

	if safe_slot_count < 1:
		safe_slot_count = 1

	var slots_width: float = float(safe_slot_count) * slot_size.x
	slots_width += float(safe_slot_count - 1) * slot_separation

	var slots_size := Vector2(slots_width, slot_size.y)

	slot_container.position = Vector2(edge_padding, edge_padding)
	slot_container.custom_minimum_size = slots_size
	slot_container.size = slots_size
	slot_container.add_theme_constant_override("separation", int(slot_separation))

	if bubble_progress_fill != null:
		bubble_progress_fill.color = progress_color
	
func update_bubble() -> void:
	if camera == null or grid_manager == null or tile_targeter == null or workstation_manager == null:
		hide_bubble()
		return

	var coord: Vector2i = tile_targeter.get_target_tile()

	if not workstation_manager.is_workstation_tile(coord):
		hide_bubble()
		return

	var definition: WorkstationDefinition = workstation_manager.get_definition_for_tile(coord)

	if definition == null:
		hide_bubble()
		return

	if not definition.show_bubble_ui:
		hide_bubble()
		return

	var state: Dictionary = workstation_manager.get_or_create_state(coord)

	if state.is_empty():
		hide_bubble()
		return

	var display_slots: Array[Dictionary] = build_display_slots(coord, definition, state)
	if display_slots.is_empty():
		hide_bubble()
		return

	var current_bubble_size: Vector2 = get_bubble_size_for_slot_count(display_slots.size())
	apply_bubble_layout(display_slots.size(), current_bubble_size)

	sync_slot_count(display_slots.size())

	for i: int in range(display_slots.size()):
		var slot_node: PanelContainer = slot_container.get_child(i) as PanelContainer
		update_slot(slot_node, display_slots[i])
	update_bubble_progress(coord, state)
	update_screen_position(coord)

	bubble_panel.visible = true

func update_bubble_progress(coord: Vector2i, state: Dictionary) -> void:
	if bubble_progress_fill == null:
		return

	var workstation_state: StringName = StringName(state.get("state", WorkstationManager.STATE_EMPTY))

	var progress: float = 0.0

	if workstation_state == WorkstationManager.STATE_PROCESSING:
		progress = workstation_manager.get_visual_progress_ratio(coord)
	elif workstation_state == WorkstationManager.STATE_DONE:
		progress = 1.0

	progress = clampf(progress, 0.0, 1.0)

	bubble_progress_fill.visible = progress > 0.0
	bubble_progress_fill.color = progress_color

	var bubble_size: Vector2 = bubble_panel.size
	var fill_height: float = bubble_size.y * progress

	bubble_progress_fill.position = Vector2(0.0, bubble_size.y - fill_height)
	bubble_progress_fill.size = Vector2(bubble_size.x, fill_height)
	
func hide_bubble() -> void:
	if bubble_panel != null:
		bubble_panel.visible = false


func update_screen_position(coord: Vector2i) -> void:
	var world_position: Vector3 = grid_manager.tile_to_world(coord) + bubble_world_offset

	if camera.is_position_behind(world_position):
		hide_bubble()
		return

	var screen_position: Vector2 = camera.unproject_position(world_position)
	var panel_size: Vector2 = bubble_panel.size

	if panel_size == Vector2.ZERO:
		panel_size = bubble_panel.get_combined_minimum_size()

	bubble_panel.position = screen_position - panel_size * 0.5


func build_display_slots(
	coord: Vector2i,
	definition: WorkstationDefinition,
	state: Dictionary
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	var workstation_state: StringName = StringName(state.get("state", WorkstationManager.STATE_EMPTY))

	match workstation_state:
		WorkstationManager.STATE_EMPTY:
			return []

		WorkstationManager.STATE_COLLECTING_INPUTS:
			return build_input_display_slots(state, 0.0, false)

		WorkstationManager.STATE_PROCESSING:
			return build_input_display_slots(state, 0.0, false)

		WorkstationManager.STATE_DONE:
			return build_done_display_slots(state)

	return result


func build_empty_display_slots(definition: WorkstationDefinition) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	var slot_count: int = definition.max_input_slots

	if slot_count <= 0:
		slot_count = 1

	for i: int in range(slot_count):
		result.append({
			"item_id": &"",
			"label": "",
			"progress": 0.0,
			"show_progress": false
		})

	return result


func build_input_display_slots(
	state: Dictionary,
	progress: float,
	show_progress: bool
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	var raw_slots: Variant = state.get("input_slots", [])

	if not (raw_slots is Array):
		return result

	var input_slots: Array = raw_slots

	for raw_slot: Variant in input_slots:
		if not (raw_slot is Dictionary):
			continue

		var slot: Dictionary = raw_slot
		var item_id: StringName = StringName(slot.get("item_id", &""))
		var current_amount: int = int(slot.get("current_amount", 0))
		var required_amount: int = int(slot.get("required_amount", 0))

		var label_text := ""

		if required_amount > 1:
			label_text = "%s/%s" % [current_amount, required_amount]

		result.append({
			"item_id": item_id,
			"label": label_text,
			"progress": 0.0,
			"show_progress": false
		})

	return result


func build_done_display_slots(state: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	var output_slots: Array = []

	var raw_outputs: Variant = state.get("output_slots", [])

	if raw_outputs is Array:
		output_slots = raw_outputs

	for raw_output: Variant in output_slots:
		if not (raw_output is Dictionary):
			continue

		var output: Dictionary = raw_output
		var item_id: StringName = StringName(output.get("item_id", &""))
		var amount: int = int(output.get("amount", 0))

		if item_id == &"":
			continue

		if amount <= 0:
			continue

		var label_text := ""

		if amount > 1:
			label_text = "x%s" % amount

		result.append({
			"item_id": item_id,
			"label": label_text,
			"progress": 0.0,
			"show_progress": false
		})

	return result


func get_input_slot_count_from_state(state: Dictionary) -> int:
	var raw_slots: Variant = state.get("input_slots", [])

	if not (raw_slots is Array):
		return 0

	var input_slots: Array = raw_slots
	return input_slots.size()


func sync_slot_count(count: int) -> void:
	while slot_container.get_child_count() > count:
		var child: Node = slot_container.get_child(slot_container.get_child_count() - 1)
		slot_container.remove_child(child)
		child.queue_free()

	while slot_container.get_child_count() < count:
		slot_container.add_child(create_slot_control())


func create_slot_control() -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = slot_size
	slot.size = slot_size
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var slot_style := StyleBoxFlat.new()
	slot_style.bg_color = slot_color
	slot_style.border_color = slot_border_color
	slot_style.border_width_left = 1
	slot_style.border_width_right = 1
	slot_style.border_width_top = 1
	slot_style.border_width_bottom = 1
	slot_style.corner_radius_top_left = 8
	slot_style.corner_radius_top_right = 8
	slot_style.corner_radius_bottom_left = 8
	slot_style.corner_radius_bottom_right = 8
	slot.add_theme_stylebox_override("panel", slot_style)

	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.custom_minimum_size = slot_size
	content.size = slot_size
	content.offset_left = 0
	content.offset_right = 0
	content.offset_top = 0
	content.offset_bottom = 0
	slot.add_child(content)

	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 5
	icon.offset_right = -5
	icon.offset_top = 5
	icon.offset_bottom = -5
	content.add_child(icon)

	var amount_label := Label.new()
	amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	amount_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	amount_label.offset_left = 2
	amount_label.offset_right = -3
	amount_label.offset_top = 2
	amount_label.offset_bottom = -2
	amount_label.add_theme_font_size_override("font_size", 10)
	amount_label.add_theme_color_override("font_color", Color(0.12, 0.09, 0.07, 1.0))
	content.add_child(amount_label)

	slot.set_meta("icon", icon)
	slot.set_meta("amount_label", amount_label)

	return slot


func update_slot(slot: PanelContainer, data: Dictionary) -> void:
	slot.custom_minimum_size = slot_size
	slot.size = slot_size
	var icon: TextureRect = slot.get_meta("icon") as TextureRect
	var amount_label: Label = slot.get_meta("amount_label") as Label

	var item_id: StringName = StringName(data.get("item_id", &""))
	var label_text: String = String(data.get("label", ""))

	update_icon(icon, item_id)

	if amount_label != null:
		amount_label.text = label_text
		amount_label.visible = label_text != ""


func update_icon(icon: TextureRect, item_id: StringName) -> void:
	if icon == null:
		return

	if item_id == &"":
		icon.texture = null
		icon.visible = false
		return

	var texture: Texture2D = get_item_icon(item_id)

	icon.texture = texture
	icon.visible = texture != null


func get_item_icon(item_id: StringName) -> Texture2D:
	if item_database == null:
		return null

	var definition: ItemDefinition = item_database.get_item(item_id)

	if definition == null:
		return null

	return definition.icon
