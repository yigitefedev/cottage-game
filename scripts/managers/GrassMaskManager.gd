class_name GrassMaskManager
extends Node

@export var mask_size_px := Vector2i(512, 512)
@export var world_origin := Vector2(-25.0, -25.0)
@export var world_size := Vector2(50.0, 50.0)

var grid_manager: GridManager
var mask_image: Image
var mask_texture: ImageTexture


func _ready() -> void:
	add_to_group("grass_mask_manager")

	await get_tree().process_frame

	grid_manager = get_tree().get_first_node_in_group("grid_manager")

	create_mask()
	refresh_all_from_grid()


func create_mask() -> void:
	mask_image = Image.create(mask_size_px.x, mask_size_px.y, false, Image.FORMAT_RF)
	mask_image.fill(Color.WHITE)

	mask_texture = ImageTexture.create_from_image(mask_image)

	RenderingServer.global_shader_parameter_set("grass_mask_texture", mask_texture)
	RenderingServer.global_shader_parameter_set("grass_mask_origin", world_origin)
	RenderingServer.global_shader_parameter_set("grass_mask_size", world_size)


func refresh_all_from_grid() -> void:
	if grid_manager == null:
		return

	mask_image.fill(Color.WHITE)

	for coord in grid_manager.grid_data.tiles.keys():
		refresh_tile_mask(coord, false)

	apply_mask()


func refresh_tile_mask(coord: Vector2i, apply_immediately: bool = true) -> void:
	if grid_manager == null or mask_image == null:
		return

	var tile := grid_manager.get_tile(coord)
	var should_hide_grass := tile != null and tile.is_used()

	var color := Color.BLACK if should_hide_grass else Color.WHITE

	paint_tile(coord, color)

	if apply_immediately:
		apply_mask()


func paint_tile(coord: Vector2i, color: Color) -> void:
	var center := grid_manager.tile_to_world(coord)
	var size := Vector2(grid_manager.tile_size, grid_manager.tile_size)

	var min_world := Vector2(
		center.x - size.x * 0.5,
		center.z - size.y * 0.5
	)

	var max_world := Vector2(
		center.x + size.x * 0.5,
		center.z + size.y * 0.5
	)

	var min_px := world_vec2_to_mask_pixel(min_world)
	var max_px := world_vec2_to_mask_pixel(max_world)

	var x0: int = min(min_px.x, max_px.x)
	var x1: int = max(min_px.x, max_px.x)
	var y0: int = min(min_px.y, max_px.y)
	var y1: int = max(min_px.y, max_px.y)

	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if x < 0 or y < 0 or x >= mask_size_px.x or y >= mask_size_px.y:
				continue

			mask_image.set_pixel(x, y, color)


func apply_mask() -> void:
	if mask_texture != null:
		mask_texture.update(mask_image)


func world_vec2_to_mask_pixel(world_xz: Vector2) -> Vector2i:
	var uv := (world_xz - world_origin) / world_size

	return Vector2i(
		clampi(int(uv.x * mask_size_px.x), 0, mask_size_px.x - 1),
		clampi(int(uv.y * mask_size_px.y), 0, mask_size_px.y - 1)
	)
func clear_tile_grass(coord: Vector2i) -> void:
	paint_tile(coord, Color.BLACK)
	apply_mask()
func clear_arc(world_center: Vector3, forward: Vector3, radius: float, angle_degrees: float) -> int:
	if mask_image == null:
		return 0

	var removed_pixels := 0

	var center_xz := Vector2(world_center.x, world_center.z)

	var forward_xz := Vector2(forward.x, forward.z)
	if forward_xz.length() <= 0.001:
		forward_xz = Vector2(0, -1)
	else:
		forward_xz = forward_xz.normalized()

	var center_px := world_vec2_to_mask_pixel(center_xz)
	var radius_px := int(radius / world_size.x * mask_size_px.x)
	var half_angle := deg_to_rad(angle_degrees * 0.5)

	for y in range(center_px.y - radius_px, center_px.y + radius_px + 1):
		for x in range(center_px.x - radius_px, center_px.x + radius_px + 1):
			if x < 0 or y < 0 or x >= mask_size_px.x or y >= mask_size_px.y:
				continue

			var pixel_world := mask_pixel_to_world_vec2(Vector2i(x, y))
			var dir := pixel_world - center_xz
			var dist := dir.length()

			if dist <= 0.001 or dist > radius:
				continue

			dir = dir.normalized()

			var dot_value: float = clamp(forward_xz.dot(dir), -1.0, 1.0)
			var angle := acos(dot_value)

			if angle <= half_angle:
				if mask_image.get_pixel(x, y).r > 0.5:
					mask_image.set_pixel(x, y, Color.BLACK)
					removed_pixels += 1

	if removed_pixels > 0:
		apply_mask()

	return removed_pixels
	
func mask_pixel_to_world_vec2(pixel: Vector2i) -> Vector2:
	var uv := Vector2(
		float(pixel.x) / float(mask_size_px.x),
		float(pixel.y) / float(mask_size_px.y)
	)

	return world_origin + uv * world_size
