class_name DevGridDebugger
extends Node3D

@export var tool_enabled := false
@export var grid_manager: GridManager

@onready var hover_highlight: MeshInstance3D = $HoverHighlight
@onready var usable_tile_borders: MeshInstance3D = $UsableTileBorders
@onready var unusable_tile_borders: MeshInstance3D = $UnusableTileBorders

var camera: Camera3D

var hovered_coord: Vector2i
var has_hover := false
var hovered_corner_coord: Vector2i
var hovered_edge_coord: Vector2i
var hovered_edge_orientation: StringName = &"horizontal"
var usable_border_material := StandardMaterial3D.new()
var unusable_border_material := StandardMaterial3D.new()


func _ready() -> void:
	add_to_group("dev_grid_debugger")

	camera = get_viewport().get_camera_3d()

	setup_materials()
	hide_all()


func _physics_process(_delta: float) -> void:
	if not tool_enabled:
		has_hover = false
		hide_all()
		return

	if grid_manager == null:
		grid_manager = get_tree().get_first_node_in_group("grid_manager")

	update_hovered_tile()
	handle_debug_input()
	update_hover_visual()
	update_tile_borders()

func save_grid() -> void:
	if grid_manager == null:
		grid_manager = get_tree().get_first_node_in_group("grid_manager")

	if grid_manager == null:
		return

	grid_manager.save_grid_definition()
func load_grid() -> void:
	if grid_manager == null:
		grid_manager = get_tree().get_first_node_in_group("grid_manager")

	if grid_manager == null:
		return

	grid_manager.load_grid_definition()

	update_tile_borders()
	
func setup_materials() -> void:
	usable_border_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	usable_border_material.albedo_color = Color(0.4, 1.0, 0.4, 0.45)
	usable_border_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	unusable_border_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	unusable_border_material.albedo_color = Color(1.0, 0.3, 0.25, 0.55)
	unusable_border_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


func hide_all() -> void:
	if hover_highlight != null:
		hover_highlight.visible = false

	if usable_tile_borders != null:
		usable_tile_borders.visible = false

	if unusable_tile_borders != null:
		unusable_tile_borders.visible = false


func update_hovered_tile() -> void:
	if camera == null:
		camera = get_viewport().get_camera_3d()

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
	hovered_corner_coord = grid_manager.world_to_corner(hit_position)

	var local_pos: Vector3 = grid_manager.to_local(hit_position)
	var tile_local_x: float = local_pos.x - floorf(local_pos.x / grid_manager.tile_size) * grid_manager.tile_size
	var tile_local_z: float = local_pos.z - floorf(local_pos.z / grid_manager.tile_size) * grid_manager.tile_size

	var dist_left: float = tile_local_x
	var dist_right: float = grid_manager.tile_size - tile_local_x
	var dist_top: float = tile_local_z
	var dist_bottom: float = grid_manager.tile_size - tile_local_z

	var min_dist: float = min(min(dist_left, dist_right), min(dist_top, dist_bottom))

	if min_dist == dist_left:
		hovered_edge_coord = hovered_coord
		hovered_edge_orientation = &"vertical"
	elif min_dist == dist_right:
		hovered_edge_coord = hovered_coord + Vector2i.RIGHT
		hovered_edge_orientation = &"vertical"
	elif min_dist == dist_top:
		hovered_edge_coord = hovered_coord
		hovered_edge_orientation = &"horizontal"
	else:
		hovered_edge_coord = hovered_coord + Vector2i.DOWN
		hovered_edge_orientation = &"horizontal"
	has_hover = true

func get_hovered_corner_coord() -> Vector2i:
	return hovered_corner_coord


func get_hovered_corner() -> GameCornerData:
	if grid_manager == null or not has_hover:
		return null

	return grid_manager.get_corner(hovered_corner_coord)


func get_hovered_edge_coord() -> Vector2i:
	return hovered_edge_coord


func get_hovered_edge_orientation() -> StringName:
	return hovered_edge_orientation


func get_hovered_edge() -> GameEdgeData:
	if grid_manager == null or not has_hover:
		return null

	return grid_manager.get_edge(hovered_edge_coord, hovered_edge_orientation)
	
func handle_debug_input() -> void:
	if not has_hover or grid_manager == null:
		return

	if Input.is_action_just_pressed("debug_create_tile"):
		toggle_hovered_tile()

	if Input.is_action_just_pressed("debug_remove_tile"):
		remove_hovered_tile()


func toggle_hovered_tile() -> void:
	var tile := grid_manager.get_tile(hovered_coord)

	if tile == null:
		grid_manager.create_tile(hovered_coord, true)
	else:
		tile.usable = !tile.usable


func remove_hovered_tile() -> void:
	grid_manager.grid_data.remove_tile(hovered_coord)

func has_hovered_tile() -> bool:
	return has_hover


func get_hovered_coord() -> Vector2i:
	return hovered_coord


func get_hovered_tile() -> GameTileData:
	if grid_manager == null or not has_hover:
		return null

	return grid_manager.get_tile(hovered_coord)
	
func update_hover_visual() -> void:
	if hover_highlight == null or grid_manager == null:
		return

	if not has_hover:
		hover_highlight.visible = false
		return

	hover_highlight.visible = true
	hover_highlight.global_position = grid_manager.tile_to_world(hovered_coord) + Vector3.UP * 0.03
	hover_highlight.global_rotation = Vector3.ZERO


func update_tile_borders() -> void:
	if usable_tile_borders == null or unusable_tile_borders == null or grid_manager == null:
		return

	usable_tile_borders.visible = true
	unusable_tile_borders.visible = true

	var usable_mesh := ImmediateMesh.new()
	var unusable_mesh := ImmediateMesh.new()

	usable_mesh.surface_begin(Mesh.PRIMITIVE_LINES, usable_border_material)
	unusable_mesh.surface_begin(Mesh.PRIMITIVE_LINES, unusable_border_material)

	for coord in grid_manager.grid_data.tiles.keys():
		var tile := grid_manager.get_tile(coord)

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
