class_name EdgeVisualManager
extends Node3D

@export var grid_manager: GridManager
@export var visual_database: TileVisualDatabase

var visual_lookup: Dictionary = {}
var active_edge_visuals: Dictionary = {}


func _ready() -> void:
	add_to_group("edge_visual_manager")

	build_visual_lookup()
	refresh_all_edges()


func build_visual_lookup() -> void:
	visual_lookup.clear()

	if visual_database == null:
		return

	for definition in visual_database.definitions:
		if definition == null:
			continue

		visual_lookup[definition.id] = definition


func refresh_all_edges() -> void:
	clear_all_edge_visuals()

	if grid_manager == null:
		return

	for key in grid_manager.grid_data.edges.keys():
		var edge: GameEdgeData = grid_manager.grid_data.edges[key]

		if edge == null:
			continue

		refresh_edge(edge.coord, edge.orientation)


func refresh_edge(coord: Vector2i, orientation: StringName) -> void:
	clear_edge_visuals(coord, orientation)

	if grid_manager == null:
		return

	var edge := grid_manager.get_edge(coord, orientation)

	if edge == null:
		return

	for layer in edge.get_visual_layers().keys():
		var visual_id: StringName = edge.visual_layers[layer]
		spawn_edge_visual(coord, orientation, visual_id)


func spawn_edge_visual(coord: Vector2i, orientation: StringName, visual_id: StringName) -> void:
	if not visual_lookup.has(visual_id):
		push_warning("No TileVisualDefinition found for edge visual id: %s" % visual_id)
		return

	var definition: TileVisualDefinition = visual_lookup[visual_id]

	if definition.scene == null:
		return

	var visual := definition.scene.instantiate() as Node3D
	add_child(visual)

	visual.global_position = grid_manager.edge_to_world(coord, orientation) + Vector3.UP * definition.y_offset

	if orientation == &"vertical":
		visual.rotation.y = PI * 0.5

	if visual.has_method("setup"):
		visual.setup(coord, orientation)

	var key := make_edge_key(coord, orientation)

	if not active_edge_visuals.has(key):
		active_edge_visuals[key] = []

	active_edge_visuals[key].append(visual)


func clear_edge_visuals(coord: Vector2i, orientation: StringName) -> void:
	var key := make_edge_key(coord, orientation)

	if not active_edge_visuals.has(key):
		return

	for visual in active_edge_visuals[key]:
		if is_instance_valid(visual):
			visual.queue_free()

	active_edge_visuals.erase(key)


func clear_all_edge_visuals() -> void:
	for key in active_edge_visuals.keys():
		for visual in active_edge_visuals[key]:
			if is_instance_valid(visual):
				visual.queue_free()

	active_edge_visuals.clear()


func make_edge_key(coord: Vector2i, orientation: StringName) -> String:
	return "%s_%s_%s" % [coord.x, coord.y, orientation]
