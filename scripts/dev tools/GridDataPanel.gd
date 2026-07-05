class_name GridDataPanel
extends PanelContainer

@export var show_data := false

@onready var grid_data_text: RichTextLabel = $MarginContainer/VBoxContainer/GridDataText

var dev_grid_debugger: DevGridDebugger


func _ready() -> void:
	add_to_group("grid_data_panel")
	visible = false
	dev_grid_debugger = get_tree().get_first_node_in_group("dev_grid_debugger")
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	if not show_data:
		visible = false
		return

	if dev_grid_debugger == null:
		dev_grid_debugger = get_tree().get_first_node_in_group("dev_grid_debugger")

	visible = true
	update_text()


func set_show_data(value: bool) -> void:
	show_data = value
	visible = value


func update_text() -> void:
	if grid_data_text == null:
		return

	if dev_grid_debugger == null:
		grid_data_text.text = "DevGridDebugger not found."
		return

	if not dev_grid_debugger.has_hovered_tile():
		grid_data_text.text = "No tile hovered."
		return

	var coord: Vector2i = dev_grid_debugger.get_hovered_coord()
	var tile: GameTileData = dev_grid_debugger.get_hovered_tile()

	var corner_coord: Vector2i = dev_grid_debugger.get_hovered_corner_coord()
	var corner: GameCornerData = dev_grid_debugger.get_hovered_corner()

	var edge_coord: Vector2i = dev_grid_debugger.get_hovered_edge_coord()
	var edge_orientation: StringName = dev_grid_debugger.get_hovered_edge_orientation()
	var edge: GameEdgeData = dev_grid_debugger.get_hovered_edge()

	grid_data_text.text = format_grid_data(coord, tile, corner_coord, corner, edge_coord, edge_orientation, edge)

func format_workstation_data(raw_state: Variant) -> String:
	var text: String = "\n[b][WORKSTATION][/b]\n"

	if not (raw_state is Dictionary):
		text += "Invalid workstation data\n\n"
		return text

	var state: Dictionary = raw_state

	var workstation_state: StringName = StringName(state.get("state", &""))
	var workstation_type: StringName = StringName(state.get("workstation_type", &""))
	var recipe_id: StringName = StringName(state.get("recipe_id", &""))

	var remaining_minutes: int = int(state.get("remaining_minutes", 0))
	var duration_minutes: int = int(state.get("duration_minutes", 0))

	text += "Type: %s\n" % [workstation_type]
	text += "State: %s\n" % [workstation_state]
	text += "Recipe: %s\n" % [recipe_id]
	text += "Remaining: %s min\n" % [remaining_minutes]
	text += "Duration: %s min\n" % [duration_minutes]

	if duration_minutes > 0:
		var completed_minutes: int = duration_minutes - remaining_minutes
		var progress: float = clampf(float(completed_minutes) / float(duration_minutes), 0.0, 1.0)
		text += "Progress: %s%%\n" % [roundi(progress * 100.0)]
	else:
		text += "Progress: 0%%\n"

	text += "\n[b]Inputs[/b]\n"
	text += format_workstation_slots(state.get("input_slots", []), true)

	text += "\n[b]Outputs[/b]\n"
	text += format_workstation_slots(state.get("output_slots", []), false)

	text += "\n"
	return text
func format_workstation_slots(raw_slots: Variant, show_required: bool) -> String:
	var text: String = ""

	if not (raw_slots is Array):
		return "Invalid slots\n"

	var slots: Array = raw_slots

	if slots.is_empty():
		return "None\n"

	for raw_slot: Variant in slots:
		if not (raw_slot is Dictionary):
			continue

		var slot: Dictionary = raw_slot
		var item_id: StringName = StringName(slot.get("item_id", &""))

		if show_required:
			var current_amount: int = int(slot.get("current_amount", 0))
			var required_amount: int = int(slot.get("required_amount", 0))
			text += "- %s: %s/%s\n" % [item_id, current_amount, required_amount]
		else:
			var amount: int = int(slot.get("amount", 0))
			text += "- %s x%s\n" % [item_id, amount]

	if text == "":
		text = "None\n"

	return text

func format_empty_tile_data(coord: Vector2i) -> String:
	return """[b]Tile[/b]: %s
[b]Status[/b]: No data
""" % [coord]


func format_grid_data(
	tile_coord: Vector2i,
	tile: GameTileData,
	corner_coord: Vector2i,
	corner: GameCornerData,
	edge_coord: Vector2i,
	edge_orientation: StringName,
	edge: GameEdgeData
) -> String:
	var text := ""

	text += "[b]GRID DATA[/b]\n\n"
	text += "[b]Tile[/b]: %s\n" % [tile_coord]
	text += "[b]Corner[/b]: %s\n" % [corner_coord]
	text += "[b]Edge[/b]: %s / %s\n\n" % [edge_coord, edge_orientation]

	text += "[b][TILE][/b]\n"
	if tile == null:
		text += "Exists: false\n\n"
	else:
		text += "Exists: true\n"
		text += "Usable: %s\n" % [tile.usable]
		text += "Used: %s\n" % [tile.is_used()]
		text += "Ground: %s\n" % [tile.ground_id]
		text += "Crop: %s\n" % [tile.crop_id]
		text += "Growth: day %s, stage %s, days in stage %s\n" % [
			tile.crop_growth_day,
			tile.crop_stage_index,
			tile.crop_days_in_stage
		]
		text += "Harvestable: %s\n" % [tile.crop_harvestable]
		text += "Quality: %s\n" % [tile.crop_quality]
		text += "Objects: %s\n" % [tile.object_ids]
		text += "Flags: %s\n" % [tile.flags]
		text += "Visuals: %s\n\n" % [tile.visual_layers]
		text += "Custom Data Keys: %s\n" % [tile.custom_data.keys()]

		if tile.custom_data.has("workstation"):
			text += format_workstation_data(tile.custom_data["workstation"])
		else:
			text += "[b][WORKSTATION][/b]\nNone\n\n"

	text += "[b][CORNER][/b]\n"
	if corner == null:
		text += "Exists: false\n\n"
	else:
		text += "Exists: true\n"
		text += "Object: %s\n" % [corner.object_id]
		text += "Visuals: %s\n\n" % [corner.visual_layers]

	text += "[b][EDGE][/b]\n"
	if edge == null:
		text += "Exists: false\n"
	else:
		text += "Exists: true\n"
		text += "Orientation: %s\n" % [edge.orientation]
		text += "Object: %s\n" % [edge.object_id]
		text += "Visuals: %s\n" % [edge.visual_layers]

	return text
