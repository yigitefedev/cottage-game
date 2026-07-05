class_name TileVisualManager
extends Node3D

@export var grid_manager: GridManager
@export var visual_database: TileVisualDatabase

var visual_lookup: Dictionary = {}
var active_tile_visuals: Dictionary = {}
var grass_mask_manager: GrassMaskManager

func _ready() -> void:
	add_to_group("tile_visual_manager")
	build_visual_lookup()
	refresh_all_tiles()
	grass_mask_manager = get_tree().get_first_node_in_group("grass_mask_manager")


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
	if grass_mask_manager == null:
		grass_mask_manager = get_tree().get_first_node_in_group("grass_mask_manager")

	if grass_mask_manager != null:
		grass_mask_manager.refresh_tile_mask(coord)

func spawn_tile_visual(coord: Vector2i, visual_id: StringName) -> void:
	var definition: TileVisualDefinition = get_visual_definition_with_fallback(visual_id)

	if definition == null:
		push_warning("No TileVisualDefinition found for id: %s" % visual_id)
		return

	if definition.scene == null:
		return

	var visual := definition.scene.instantiate() as Node3D

	if visual == null:
		return

	add_child(visual)

	visual.global_position = grid_manager.tile_to_world(coord) + Vector3.UP * definition.y_offset

	if visual.has_method("setup"):
		visual.setup(coord, grid_manager)

	if not active_tile_visuals.has(coord):
		active_tile_visuals[coord] = []

	active_tile_visuals[coord].append(visual)
func get_visual_definition_with_fallback(visual_id: StringName) -> TileVisualDefinition:
	if visual_lookup.has(visual_id):
		var definition: TileVisualDefinition = visual_lookup[visual_id]

		if definition != null and definition.scene != null:
			return definition

	var fallback_id: StringName = get_nullcrop_fallback_id(visual_id)

	if fallback_id == &"":
		return null

	if not visual_lookup.has(fallback_id):
		return null

	var fallback_definition: TileVisualDefinition = visual_lookup[fallback_id]

	if fallback_definition == null:
		return null

	if fallback_definition.scene == null:
		return null

	return fallback_definition


func get_nullcrop_fallback_id(visual_id: StringName) -> StringName:
	var text: String = String(visual_id)
	var marker := "_stage_"
	var marker_index: int = text.find(marker)

	if marker_index == -1:
		return &""

	var stage_text: String = text.substr(marker_index + marker.length())

	if stage_text == "":
		return &""

	return StringName("nullcrop_stage_%s" % stage_text)

func clear_tile_visuals(coord: Vector2i) -> void:
	if not active_tile_visuals.has(coord):
		return

	for visual in active_tile_visuals[coord]:
		if is_instance_valid(visual): 	
			visual.queue_free()

	active_tile_visuals.erase(coord)

func refresh_tile_and_neighbors(coord: Vector2i) -> void:
	refresh_tile(coord)
	refresh_tile(coord + Vector2i.UP)
	refresh_tile(coord + Vector2i.RIGHT)
	refresh_tile(coord + Vector2i.DOWN)
	refresh_tile(coord + Vector2i.LEFT)
	
func clear_all_tile_visuals() -> void:
	for coord in active_tile_visuals.keys():
		clear_tile_visuals(coord)

	active_tile_visuals.clear()
