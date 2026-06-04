class_name TilledSoil
extends Node3D

@export var dry_color := Color(0.56, 0.38, 0.24, 1.0)
@export var watered_color := Color(0.32, 0.22, 0.16, 1.0)
@export var color_transition_time := 1.0

@onready var all_round: Node3D = $"4"
@onready var no_round: Node3D = $"0"
@onready var one_round: Node3D = $"1"
@onready var two_round: Node3D = $"2"

var coord: Vector2i
var grid_manager: GridManager
var active_shape: Node3D
var material_instance: StandardMaterial3D


func setup(_coord: Vector2i, _grid_manager: GridManager) -> void:
	coord = _coord
	grid_manager = _grid_manager

	update_shape()

	var tile := grid_manager.get_tile(coord)

	if tile != null and tile.has_flag(&"watered"):
		if tile.has_flag(&"just_watered"):
			tile.set_flag(&"just_watered", false)
			set_material_color(dry_color)
			update_material(false)
		else:
			update_material(true)
	else:
		update_material(true)

func set_material_color(color: Color) -> void:
	if active_shape == null:
		return

	var mesh_instance := find_mesh_instance(active_shape)
	if mesh_instance == null:
		return

	if material_instance == null:
		var base_mat := mesh_instance.get_active_material(0)
		if base_mat != null:
			material_instance = base_mat.duplicate() as StandardMaterial3D
		else:
			material_instance = StandardMaterial3D.new()

		mesh_instance.set_surface_override_material(0, material_instance)

	material_instance.albedo_color = color
	
func update_shape() -> void:
	var up := has_soil(coord + Vector2i.UP)
	var right := has_soil(coord + Vector2i.RIGHT)
	var down := has_soil(coord + Vector2i.DOWN)
	var left := has_soil(coord + Vector2i.LEFT)

	var rounded_corners := []

	if not up and not left:
		rounded_corners.append("top_left")
	if not up and not right:
		rounded_corners.append("top_right")
	if not down and not right:
		rounded_corners.append("bottom_right")
	if not down and not left:
		rounded_corners.append("bottom_left")

	set_all_visible(false)

	match rounded_corners.size():
		0:
			active_shape = no_round
			no_round.rotation.y = 0.0
		1:
			active_shape = one_round
			one_round.rotation.y = get_rotation_for_one_corner(rounded_corners[0])
		2:
			active_shape = two_round
			two_round.rotation.y = get_rotation_for_two_corners(rounded_corners)
		_:
			active_shape = all_round
			all_round.rotation.y = 0.0

	active_shape.visible = true


func update_material(instant: bool = false) -> void:
	var tile := grid_manager.get_tile(coord)
	if tile == null or active_shape == null:
		return

	var mesh_instance := find_mesh_instance(active_shape)
	if mesh_instance == null:
		return

	if material_instance == null:
		var base_mat := mesh_instance.get_active_material(0)
		if base_mat != null:
			material_instance = base_mat.duplicate() as StandardMaterial3D
		else:
			material_instance = StandardMaterial3D.new()

		mesh_instance.set_surface_override_material(0, material_instance)

	var target_color := watered_color if tile.has_flag(&"watered") else dry_color

	if instant:
		material_instance.albedo_color = target_color
		return

	var duration := color_transition_time

	if tile.has_flag(&"slow_water_tween"):
		duration *= 4.0
		tile.set_flag(&"slow_water_tween", false)

	var tween := create_tween()
	tween.tween_property(material_instance, "albedo_color", target_color, duration)


func find_mesh_instance(root: Node) -> MeshInstance3D:
	if root is MeshInstance3D:
		return root

	for child in root.get_children():
		var found := find_mesh_instance(child)
		if found != null:
			return found

	return null


func has_soil(tile_coord: Vector2i) -> bool:
	var tile := grid_manager.get_tile(tile_coord)
	return tile != null and tile.has_flag(&"tilled")


func set_all_visible(value: bool) -> void:
	all_round.visible = value
	no_round.visible = value
	one_round.visible = value
	two_round.visible = value


func get_rotation_for_one_corner(corner: String) -> float:
	match corner:
		"top_left":
			return 0.0
		"top_right":
			return -PI * 0.5
		"bottom_right":
			return PI
		"bottom_left":
			return PI * 0.5

	return 0.0


func get_rotation_for_two_corners(corners: Array) -> float:
	if corners.has("top_left") and corners.has("top_right"):
		return 0.0
	if corners.has("top_right") and corners.has("bottom_right"):
		return -PI * 0.5
	if corners.has("bottom_left") and corners.has("bottom_right"):
		return PI
	if corners.has("top_left") and corners.has("bottom_left"):
		return PI * 0.5

	return 0.0
