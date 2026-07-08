class_name TileVisualManager
extends Node3D

@export var grid_manager: GridManager
@export var visual_database: TileVisualDatabase

var visual_lookup: Dictionary = {}
var active_tile_visuals: Dictionary = {}
var active_tile_visual_layers: Dictionary = {}
var grass_mask_manager: GrassMaskManager

func _ready() -> void:
	add_to_group("tile_visual_manager")
	build_visual_lookup()
	refresh_all_tiles()
	grass_mask_manager = get_tree().get_first_node_in_group("grass_mask_manager")

	if not TimeManager.time_simulation_finished.is_connected(on_time_simulation_finished):
		TimeManager.time_simulation_finished.connect(on_time_simulation_finished)


func build_visual_lookup() -> void:
	visual_lookup.clear()

	if visual_database == null:
		return

	for definition in visual_database.definitions:
		if definition == null:
			continue

		visual_lookup[definition.id] = definition


func on_time_simulation_finished() -> void:
	refresh_all_tiles()


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

	for layer in get_ordered_visual_layers(tile):
		var visual_id: StringName = tile.visual_layers[layer]
		spawn_tile_visual(coord, visual_id, layer)

	refresh_grass_mask(coord)

func refresh_tile_layer(coord: Vector2i, layer: StringName) -> void:
	clear_tile_visual_layer(coord, layer)

	if grid_manager == null:
		return

	var tile := grid_manager.get_tile(coord)

	if tile == null:
		return

	var visual_id: StringName = tile.visual_layers.get(layer, &"")

	if visual_id != &"":
		spawn_tile_visual(coord, visual_id, layer)

	rebuild_active_tile_visuals(coord)

	refresh_attached_visual_layers(coord, layer)

	if layer == &"ground":
		refresh_grass_mask(coord)

func spawn_tile_visual(coord: Vector2i, visual_id: StringName, layer: StringName = &"") -> void:
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

	visual.global_transform = get_visual_spawn_transform(coord, definition, layer)

	if visual.has_method("setup"):
		visual.setup(coord, grid_manager)

	if not active_tile_visuals.has(coord):
		active_tile_visuals[coord] = []

	active_tile_visuals[coord].append(visual)

	if layer != &"":
		if not active_tile_visual_layers.has(coord):
			active_tile_visual_layers[coord] = {}

		active_tile_visual_layers[coord][layer] = visual


func get_ordered_visual_layers(tile: GameTileData) -> Array[StringName]:
	var result: Array[StringName] = []
	var preferred_layers: Array[StringName] = [&"ground", &"tree", &"object", &"crop", &"weed"]

	for layer in preferred_layers:
		if tile.visual_layers.has(layer):
			result.append(layer)

	for layer in tile.get_visual_layers().keys():
		var layer_name := StringName(layer)

		if not result.has(layer_name):
			result.append(layer_name)

	return result


func get_visual_spawn_position(
	coord: Vector2i,
	definition: TileVisualDefinition,
	layer: StringName
) -> Vector3:
	return get_visual_spawn_transform(coord, definition, layer).origin


func get_visual_spawn_transform(
	coord: Vector2i,
	definition: TileVisualDefinition,
	layer: StringName
) -> Transform3D:
	var attachment_transform: Variant = get_visual_attachment_transform(coord, definition)

	if attachment_transform is Transform3D:
		var typed_attachment_transform: Transform3D = attachment_transform
		typed_attachment_transform.origin += Vector3.UP * definition.y_offset
		return typed_attachment_transform

	if layer == &"crop":
		var surface_position: Variant = get_planting_surface_position(coord)

		if surface_position is Vector3:
			var typed_surface_position: Vector3 = surface_position
			return Transform3D(Basis(), typed_surface_position + Vector3.UP * definition.y_offset)

	return Transform3D(Basis(), grid_manager.tile_to_world(coord) + Vector3.UP * definition.y_offset)


func get_visual_attachment_transform(coord: Vector2i, definition: TileVisualDefinition) -> Variant:
	if definition == null:
		return null

	if definition.attach_to_layer == &"" or definition.attach_marker_name == &"":
		return null

	if not active_tile_visual_layers.has(coord):
		return null

	var layer_visuals: Dictionary = active_tile_visual_layers[coord]

	if not layer_visuals.has(definition.attach_to_layer):
		return null

	var parent_visual: Node = layer_visuals[definition.attach_to_layer]

	if not is_instance_valid(parent_visual):
		return null

	var marker: Node3D = find_attachment_marker(parent_visual, definition.attach_marker_name)

	if marker == null:
		return null

	return marker.global_transform


func find_attachment_marker(parent_visual: Node, marker_name: StringName) -> Node3D:
	var marker: Node3D = parent_visual.find_child(String(marker_name), true, false) as Node3D

	if marker != null:
		return marker

	var alternate_name: String = String(marker_name).replace("_", " ")
	return parent_visual.find_child(alternate_name, true, false) as Node3D


func refresh_attached_visual_layers(coord: Vector2i, refreshed_layer: StringName) -> void:
	if grid_manager == null:
		return

	var tile: GameTileData = grid_manager.get_tile(coord)

	if tile == null:
		return

	for layer in tile.get_visual_layers().keys():
		var layer_name: StringName = StringName(layer)

		if layer_name == refreshed_layer:
			continue

		var visual_id: StringName = tile.visual_layers[layer_name]
		var definition: TileVisualDefinition = get_visual_definition_with_fallback(visual_id)

		if definition == null:
			continue

		if definition.attach_to_layer != refreshed_layer:
			continue

		refresh_tile_layer(coord, layer_name)


func get_planting_surface_position(coord: Vector2i) -> Variant:
	var tile := grid_manager.get_tile(coord) if grid_manager != null else null

	if tile == null:
		return null

	var surface_layer := PlantingSurfaceResolver.get_surface_visual_layer(tile)

	if surface_layer == &"":
		return null

	if not active_tile_visual_layers.has(coord):
		return null

	var layer_visuals: Dictionary = active_tile_visual_layers[coord]

	if not layer_visuals.has(surface_layer):
		return null

	var surface_visual: Node = layer_visuals[surface_layer]

	if not is_instance_valid(surface_visual):
		return null

	var marker := surface_visual.find_child("planting_surface", true, false) as Node3D

	if marker == null:
		return null

	return marker.global_position

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
	if active_tile_visuals.has(coord):
		for visual in active_tile_visuals[coord]:
			if is_instance_valid(visual): 	
				visual.queue_free()
	elif active_tile_visual_layers.has(coord):
		for visual in active_tile_visual_layers[coord].values():
			if is_instance_valid(visual): 	
				visual.queue_free()


	active_tile_visuals.erase(coord)
	active_tile_visual_layers.erase(coord)

func clear_tile_visual_layer(coord: Vector2i, layer: StringName) -> void:
	if not active_tile_visual_layers.has(coord):
		return

	var layer_visuals: Dictionary = active_tile_visual_layers[coord]

	if not layer_visuals.has(layer):
		return

	var visual: Node = layer_visuals[layer]

	if active_tile_visuals.has(coord):
		active_tile_visuals[coord].erase(visual)

		if active_tile_visuals[coord].is_empty():
			active_tile_visuals.erase(coord)

	if is_instance_valid(visual):
		visual.queue_free()

	layer_visuals.erase(layer)

	if layer_visuals.is_empty():
		active_tile_visual_layers.erase(coord)

func rebuild_active_tile_visuals(coord: Vector2i) -> void:
	if not active_tile_visual_layers.has(coord):
		active_tile_visuals.erase(coord)
		return

	var layer_visuals: Dictionary = active_tile_visual_layers[coord]
	var ordered_visuals: Array = []
	var tile := grid_manager.get_tile(coord) if grid_manager != null else null

	if tile != null:
		for layer in tile.get_visual_layers().keys():
			if not layer_visuals.has(layer):
				continue

			var visual: Node = layer_visuals[layer]

			if is_instance_valid(visual):
				ordered_visuals.append(visual)

	for visual in layer_visuals.values():
		if is_instance_valid(visual) and not ordered_visuals.has(visual):
			ordered_visuals.append(visual)

	if ordered_visuals.is_empty():
		active_tile_visuals.erase(coord)
	else:
		active_tile_visuals[coord] = ordered_visuals

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
	active_tile_visual_layers.clear()

func refresh_grass_mask(coord: Vector2i) -> void:
	if grass_mask_manager == null:
		grass_mask_manager = get_tree().get_first_node_in_group("grass_mask_manager")

	if grass_mask_manager != null:
		grass_mask_manager.refresh_tile_mask(coord)
