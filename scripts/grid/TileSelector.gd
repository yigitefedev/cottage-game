extends Node3D
enum SelectionMode {
	TILE,
	CORNER,
	EDGE
}

@onready var corner_target_highlight: MeshInstance3D = $CornerTargetHighlight
@onready var edge_target_highlight: MeshInstance3D = $EdgeTargetHighlight

var player_edge_targeter: PlayerEdgeTargeter
var player_corner_targeter: PlayerCornerTargeter
var player_inventory: PlayerInventory
var selection_mode: SelectionMode = SelectionMode.TILE

@onready var hover_highlight: MeshInstance3D = $HoverHighlight
@onready var target_highlight: MeshInstance3D = $TargetHighlight

@onready var usable_tile_borders: MeshInstance3D = $UsableTileBorders
@onready var unusable_tile_borders: MeshInstance3D = $UnusableTileBorders

var usable_border_material := StandardMaterial3D.new()
var unusable_border_material := StandardMaterial3D.new()
var player_tile_targeter: PlayerTileTargeter

@export var grid_manager: GridManager
@export var debug_label: Label

var camera: Camera3D

var hovered_coord: Vector2i
var has_hover := false

func _ready() -> void:
	camera = get_viewport().get_camera_3d()

	usable_border_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	usable_border_material.albedo_color = Color(0.4, 1.0, 0.4, 0.45)
	usable_border_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	unusable_border_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	unusable_border_material.albedo_color = Color(1.0, 0.3, 0.25, 0.55)
	unusable_border_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	player_tile_targeter = get_tree().get_first_node_in_group("player_tile_targeter")
	player_corner_targeter = get_tree().get_first_node_in_group("player_corner_targeter")
	player_inventory = get_tree().get_first_node_in_group("player_inventory")
	player_edge_targeter = get_tree().get_first_node_in_group("player_edge_targeter")
	if corner_target_highlight != null:
		corner_target_highlight.visible = false

	if edge_target_highlight != null:
		edge_target_highlight.visible = false

	if target_highlight != null:
		target_highlight.visible = false
func _physics_process(_delta: float) -> void:
	update_hovered_tile()
	handle_debug_input()
	update_selection_mode()
	update_debug_text()
	update_hover_visual()
	update_tile_borders()
	update_target_visuals()


func update_hovered_tile() -> void:
	if camera == null or grid_manager == null:
		has_hover = false
		return

	var mouse_pos := get_viewport().get_mouse_position()

	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_direction := camera.project_ray_normal(mouse_pos)
	var ray_end := ray_origin + ray_direction * 1000.0

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result := get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		has_hover = false
		return

	var hit_position: Vector3 = result.position
	hovered_coord = grid_manager.world_to_tile(hit_position)
	has_hover = true
func update_hover_visual() -> void:
	if hover_highlight == null:
		return

	if not DevManager.dev_mode or not has_hover:
		hover_highlight.visible = false
		return

	hover_highlight.visible = true
	hover_highlight.global_position = grid_manager.tile_to_world(hovered_coord) + Vector3.UP * 0.03
func update_tile_borders() -> void:
	if usable_tile_borders == null or unusable_tile_borders == null or grid_manager == null:
		return

	if not DevManager.dev_mode:
		usable_tile_borders.visible = false
		unusable_tile_borders.visible = false
		return

	usable_tile_borders.visible = true
	unusable_tile_borders.visible = true

	var usable_mesh := ImmediateMesh.new()
	var unusable_mesh := ImmediateMesh.new()

	usable_mesh.surface_begin(Mesh.PRIMITIVE_LINES, usable_border_material)
	unusable_mesh.surface_begin(Mesh.PRIMITIVE_LINES, unusable_border_material)

	for coord in grid_manager.grid_data.tiles.keys():
		var tile = grid_manager.get_tile(coord)

		if tile == null:
			continue

		if tile.usable:
			add_tile_border_to_mesh(usable_mesh, coord)
		else:
			add_tile_border_to_mesh(unusable_mesh, coord)

	usable_mesh.surface_end()
	unusable_mesh.surface_end()

	usable_tile_borders.mesh = usable_mesh
	unusable_tile_borders.mesh = unusable_mesh
func add_tile_border_to_mesh(mesh: ImmediateMesh, coord: Vector2i) -> void:
	var y := 0.04
	var s := grid_manager.tile_size
	var base := grid_manager.tile_to_world(coord)
	var half := s * 0.5

	var a := Vector3(base.x - half, y, base.z - half)
	var b := Vector3(base.x + half, y, base.z - half)
	var c := Vector3(base.x + half, y, base.z + half)
	var d := Vector3(base.x - half, y, base.z + half)

	mesh.surface_add_vertex(a)
	mesh.surface_add_vertex(b)

	mesh.surface_add_vertex(b)
	mesh.surface_add_vertex(c)

	mesh.surface_add_vertex(c)
	mesh.surface_add_vertex(d)

	mesh.surface_add_vertex(d)
	mesh.surface_add_vertex(a)
	
func handle_debug_input() -> void:
	if not has_hover:
		return

	if not DevManager.dev_mode:
		return

	if Input.is_action_just_pressed("debug_create_tile"):
		var tile := grid_manager.get_tile(hovered_coord)

		if tile == null:
			grid_manager.create_tile(hovered_coord, true)
		else:
			tile.usable = !tile.usable

	if Input.is_action_just_pressed("debug_remove_tile"):
		grid_manager.grid_data.remove_tile(hovered_coord)
	
	if Input.is_action_just_pressed("debug_save_grid"):
		grid_manager.save_grid_definition()
func update_selection_mode() -> void:
	selection_mode = SelectionMode.TILE

	if player_inventory == null:
		player_inventory = get_tree().get_first_node_in_group("player_inventory")

	if player_inventory == null:
		return

	var selected_item := player_inventory.get_selected_item()
	if selected_item == null:
		return

	if selected_item.has_tag(&"corner_object"):
		selection_mode = SelectionMode.CORNER
		return

	if selected_item.has_tag(&"edge_object"):
		selection_mode = SelectionMode.EDGE
		return
func update_target_visuals() -> void:
	if target_highlight != null:
		target_highlight.visible = false

	if corner_target_highlight != null:
		corner_target_highlight.visible = false
	
	if edge_target_highlight != null:
		edge_target_highlight.visible = false

	match selection_mode:
		SelectionMode.TILE:
			update_tile_target_visual()

		SelectionMode.CORNER:
			update_corner_target_visual()

		SelectionMode.EDGE:
			update_edge_target_visual()
func update_tile_target_visual() -> void:
	if target_highlight == null:
		return

	if player_tile_targeter == null:
		player_tile_targeter = get_tree().get_first_node_in_group("player_tile_targeter")

	if player_tile_targeter == null or grid_manager == null:
		target_highlight.visible = false
		return

	var target_coord := player_tile_targeter.get_target_tile()
	var tile := grid_manager.get_tile(target_coord)

	if tile == null:
		target_highlight.visible = false
		return

	target_highlight.visible = true
	target_highlight.global_position = grid_manager.tile_to_world(target_coord) + Vector3.UP * 0.055
	
func update_corner_target_visual() -> void:
	if corner_target_highlight == null:
		return

	if player_corner_targeter == null:
		player_corner_targeter = get_tree().get_first_node_in_group("player_corner_targeter")

	if player_corner_targeter == null or grid_manager == null:
		corner_target_highlight.visible = false
		return

	var target_corner := player_corner_targeter.get_target_corner()

	corner_target_highlight.visible = true
	corner_target_highlight.global_position = grid_manager.corner_to_world(target_corner) + Vector3.UP * 0.075

func update_edge_target_visual() -> void:
	if edge_target_highlight == null:
		return

	if player_edge_targeter == null:
		player_edge_targeter = get_tree().get_first_node_in_group("player_edge_targeter")

	if player_edge_targeter == null or grid_manager == null:
		edge_target_highlight.visible = false
		return

	var edge_coord := player_edge_targeter.get_target_edge_coord()
	var orientation := player_edge_targeter.get_target_edge_orientation()

	edge_target_highlight.visible = true

	edge_target_highlight.global_position = (
		grid_manager.edge_to_world(edge_coord, orientation)
		+ Vector3.UP * 0.08
	)

	if orientation == &"vertical":
		edge_target_highlight.global_rotation.y = PI * 0.5
	else:
		edge_target_highlight.global_rotation.y = 0.0
		
func update_debug_text() -> void:
	if debug_label == null:
		return

	if not has_hover:
		debug_label.text = "No tile hovered"
		return

	var tile := grid_manager.get_tile(hovered_coord)

	if tile == null:
		debug_label.text = "--Tile Debug Menu--\nTile: %s\nStatus: no data\nLeft click: create tile" % [hovered_coord]
		return

	debug_label.text = """--Tile Debug Menu--
Tile: %s
Usable: %s
Used: %s
Ground: %s
Crop: %s
Growth Day: %s
Crop Stage: %s
Days In Stage: %s
Harvestable: %s
Quality: %s
Objects: %s
Flags: %s
Visual Layers: %s

Left click: toggle usable
Right click: remove tile
""" % [
		hovered_coord,
		tile.usable,
		tile.is_used(),
		tile.ground_id,
		tile.crop_id,
		tile.crop_growth_day,
		tile.crop_stage_index,
		tile.crop_days_in_stage,
		tile.crop_harvestable,
		tile.crop_quality,
		tile.object_ids,
		tile.flags,
		tile.visual_layers
	]
