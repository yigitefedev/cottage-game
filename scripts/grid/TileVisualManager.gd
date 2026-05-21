class_name TileVisualManager
extends Node3D

@export var grid_manager: GridManager
@export var visual_database: TileVisualDatabase

var visual_lookup: Dictionary = {}
var active_tile_visuals: Dictionary = {}


func _ready() -> void:
	add_to_group("tile_visual_manager")
	build_visual_lookup()
	refresh_all_tiles()


func build_visual_lookup() -> void:
	visual_lookup.clear()

	if visual_database == null:
		return

	for definition in visual_database.definitions:
		if definition == null:
			continue

		visual_lookup[definition.id] = definition


func refresh_all_tiles() -> void:
	clear_all_tile_visuals()

	if grid_manager == null:
		return

	for coord in grid_manager.grid_data.tiles.keys():
		refresh_tile(coord)


func refresh_tile(coord: Vector2i) -> void:
	clear_tile_visuals(coord)

	if grid_manager == null:
		return

	var tile := grid_manager.get_tile(coord)

	if tile == null:
		return

	for layer in tile.get_visual_layers().keys():
		var visual_id: StringName = tile.visual_layers[layer]
		spawn_tile_visual(coord, visual_id)


func spawn_tile_visual(coord: Vector2i, visual_id: StringName) -> void:
	if not visual_lookup.has(visual_id):
		push_warning("No TileVisualDefinition found for id: %s" % visual_id)
		return

	var definition: TileVisualDefinition = visual_lookup[visual_id]

	if definition.scene == null:
		return

	var visual := definition.scene.instantiate() as Node3D
	add_child(visual)

	visual.global_position = grid_manager.tile_to_world(coord) + Vector3.UP * definition.y_offset

	if not active_tile_visuals.has(coord):
		active_tile_visuals[coord] = []

	active_tile_visuals[coord].append(visual)


func clear_tile_visuals(coord: Vector2i) -> void:
	if not active_tile_visuals.has(coord):
		return

	for visual in active_tile_visuals[coord]:
		if is_instance_valid(visual): 	
			visual.queue_free()

	active_tile_visuals.erase(coord)


func clear_all_tile_visuals() -> void:
	for coord in active_tile_visuals.keys():
		clear_tile_visuals(coord)

	active_tile_visuals.clear()
