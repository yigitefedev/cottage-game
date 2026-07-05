class_name PlaceholderCropVisual
extends Node3D

@export var label_path: NodePath
@export var capsule_mesh_path: NodePath
@export var stage_index := -1

@onready var label: Label3D = get_node_or_null(label_path)
@onready var capsule_mesh_instance: MeshInstance3D = get_node_or_null(capsule_mesh_path)

const BASE_STAGE_SIZES: Array[Vector2] = [
	Vector2(0.03, 0.10),
	Vector2(0.05, 0.2),
	Vector2(0.1, 0.45),
	Vector2(0.13, 0.7),
]

const RADIUS_OFFSET_MIN := 0
const RADIUS_OFFSET_MAX := 0.05

const HEIGHT_OFFSET_MIN := -0.5
const HEIGHT_OFFSET_MAX := 0.5


func setup(coord: Vector2i, grid_manager: GridManager) -> void:
	if grid_manager == null:
		return

	var tile: GameTileData = grid_manager.get_tile(coord)

	if tile == null:
		return

	var crop_id: StringName = tile.crop_id
	var crop_name: String = prettify_crop_id(crop_id)
	var crop_color: Color = get_color_from_text(String(crop_id))

	apply_label(crop_name)
	apply_capsule_size(crop_id)
	apply_capsule_color(crop_color)


func apply_label(crop_name: String) -> void:
	if label == null:
		return

	label.text = crop_name
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED


func apply_capsule_size(crop_id: StringName) -> void:
	if capsule_mesh_instance == null:
		return

	var capsule := capsule_mesh_instance.mesh as CapsuleMesh

	if capsule == null:
		return

	var local_stage_index: int = get_stage_index()

	if local_stage_index < 0 or local_stage_index >= BASE_STAGE_SIZES.size():
		local_stage_index = 0

	var base_size: Vector2 = BASE_STAGE_SIZES[local_stage_index]

	var radius_offset: float = get_number_from_text(
		String(crop_id) + "_radius",
		RADIUS_OFFSET_MIN,
		RADIUS_OFFSET_MAX
	)

	var height_offset: float = get_number_from_text(
		String(crop_id) + "_height",
		HEIGHT_OFFSET_MIN,
		HEIGHT_OFFSET_MAX
	)

	var final_radius: float = base_size.x + radius_offset
	var final_height: float = base_size.y + height_offset

	final_radius = max(final_radius, 0.02)

	# Capsule bozulmasın diye height minimum radius'un 2 katından biraz büyük olsun.
	final_height = max(final_height, final_radius * 2.0 + 0.01)

	var unique_capsule := capsule.duplicate() as CapsuleMesh
	unique_capsule.radius = final_radius
	unique_capsule.height = final_height

	capsule_mesh_instance.mesh = unique_capsule


func apply_capsule_color(crop_color: Color) -> void:
	if capsule_mesh_instance == null:
		return

	var material := StandardMaterial3D.new()
	material.albedo_color = crop_color
	capsule_mesh_instance.material_override = material


func get_stage_index() -> int:
	if stage_index >= 0:
		return stage_index

	var scene_name: String = name
	var marker := "_stage_"
	var marker_index: int = scene_name.find(marker)

	if marker_index == -1:
		return 0

	var stage_text: String = scene_name.substr(marker_index + marker.length())

	if not stage_text.is_valid_int():
		return 0

	return int(stage_text)


func prettify_crop_id(crop_id: StringName) -> String:
	var text: String = String(crop_id)

	if text.begins_with("crop_"):
		text = text.substr(5)

	var parts := text.split("_")
	var result := ""

	for part in parts:
		if part == "":
			continue

		if result != "":
			result += " "

		result += part.substr(0, 1).to_upper() + part.substr(1)

	return result


func get_color_from_text(text: String) -> Color:
	var hash_value: int = abs(text.hash())
	var hue: float = float(hash_value % 360) / 360.0

	return Color.from_hsv(hue, 0.45, 0.95)


func get_number_from_text(text: String, min_value: float, max_value: float) -> float:
	var hash_value: int = abs(text.hash())
	var normalized: float = float(hash_value % 10000) / 9999.0

	return lerpf(min_value, max_value, normalized)
