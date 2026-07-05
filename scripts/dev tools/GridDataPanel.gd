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
