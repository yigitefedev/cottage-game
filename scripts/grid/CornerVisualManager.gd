class_name CornerVisualManager
extends Node3D

@export var grid_manager: GridManager
@export var visual_database: TileVisualDatabase

var visual_lookup: Dictionary = {}
var active_corner_visuals: Dictionary = {}


func _ready() -> void:
	add_to_group("corner_visual_manager")
	build_visual_lookup()
	refresh_all_corners()


func build_visual_lookup() -> void:
	visual_lookup.clear()

	if visual_database == null:
		return

	for definition in visual_database.definitions:
		if definition == null:
			continue

		visual_lookup[definition.id] = definition


func refresh_all_corners() -> void:
	clear_all_corner_visuals()

	if grid_manager == null:
		return

	for coord in grid_manager.grid_data.corners.keys():
		refresh_corner(coord)


func refresh_corner(coord: Vector2i) -> void:
	clear_corner_visuals(coord)

	if grid_manager == null:
		return

	var corner := grid_manager.get_corner(coord)

	if corner == null:
		return

	for layer in corner.get_visual_layers().keys():
		var visual_id: StringName = corner.visual_layers[layer]
		spawn_corner_visual(coord, visual_id)


func spawn_corner_visual(coord: Vector2i, visual_id: StringName) -> void:
	if not visual_lookup.has(visual_id):
		push_warning("No TileVisualDefinition found for corner visual id: %s" % visual_id)
		return

	var definition: TileVisualDefinition = visual_lookup[visual_id]

	if definition.scene == null:
		return

	var visual := definition.scene.instantiate() as Node3D
	add_child(visual)

	visual.global_position = grid_manager.corner_to_world(coord) + Vector3.UP * definition.y_offset

	if visual.has_method("setup"):
		visual.setup(coord)

	if not active_corner_visuals.has(coord):
		active_corner_visuals[coord] = []

	active_corner_visuals[coord].append(visual)


func clear_corner_visuals(coord: Vector2i) -> void:
	if not active_corner_visuals.has(coord):
		return

	for visual in active_corner_visuals[coord]:
		if is_instance_valid(visual):
			visual.queue_free()

	active_corner_visuals.erase(coord)


func clear_all_corner_visuals() -> void:
	for coord in active_corner_visuals.keys():
		clear_corner_visuals(coord)

	active_corner_visuals.clear()
