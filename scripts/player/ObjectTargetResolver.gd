class_name ObjectTargetResolver
extends Node

var targeting_system: TargetingSystem
var grid_manager: GridManager
var tile_visual_manager: TileVisualManager
var edge_visual_manager: EdgeVisualManager
var corner_visual_manager: CornerVisualManager
var player_inventory: PlayerInventory

var candidates: Array[ObjectTargetCandidate] = []
var selected_index := 0

var last_tile_coord := Vector2i(999999, 999999)
var last_signature := ""


func _ready() -> void:
	add_to_group("object_target_resolver")

	await get_tree().process_frame
	ensure_refs()


func _process(_delta: float) -> void:
	update_candidates()


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("cycle_edge_direction"):
		return

	if not is_object_targeting_active():
		return

	cycle_target()
	get_viewport().set_input_as_handled()


func ensure_refs() -> void:
	if targeting_system == null:
		targeting_system = get_tree().get_first_node_in_group("targeting_system")

	if grid_manager == null:
		grid_manager = get_tree().get_first_node_in_group("grid_manager")

	if tile_visual_manager == null:
		tile_visual_manager = get_tree().get_first_node_in_group("tile_visual_manager")

	if edge_visual_manager == null:
		edge_visual_manager = get_tree().get_first_node_in_group("edge_visual_manager")

	if corner_visual_manager == null:
		corner_visual_manager = get_tree().get_first_node_in_group("corner_visual_manager")

	if player_inventory == null:
		player_inventory = get_tree().get_first_node_in_group("player_inventory")


func is_object_targeting_active() -> bool:
	ensure_refs()

	if player_inventory == null:
		return false

	var item: ItemInstanceData = player_inventory.get_selected_item()

	if item == null:
		return false

	if item.definition == null:
		return false

	return item.has_tag(&"target_object")


func update_candidates() -> void:
	ensure_refs()

	if not is_object_targeting_active():
		candidates.clear()
		selected_index = 0
		last_signature = ""
		return

	if targeting_system == null or grid_manager == null:
		candidates.clear()
		selected_index = 0
		return

	var tile_coord: Vector2i = targeting_system.target_tile_coord
	var new_candidates: Array[ObjectTargetCandidate] = build_candidates_for_tile(tile_coord)
	var new_signature: String = make_signature(new_candidates)

	if tile_coord != last_tile_coord or new_signature != last_signature:
		selected_index = 0
		last_tile_coord = tile_coord
		last_signature = new_signature

	candidates = new_candidates

	if candidates.is_empty():
		selected_index = 0
	else:
		selected_index = clampi(selected_index, 0, candidates.size() - 1)


func build_candidates_for_tile(tile_coord: Vector2i) -> Array[ObjectTargetCandidate]:
	var result: Array[ObjectTargetCandidate] = []

	add_tile_candidates(result, tile_coord)
	add_edge_candidates(result, tile_coord)
	add_corner_candidates(result, tile_coord)

	return result


func add_tile_candidates(result: Array[ObjectTargetCandidate], tile_coord: Vector2i) -> void:
	var tile: GameTileData = grid_manager.get_tile(tile_coord)

	if tile == null:
		return

	if tile.object_ids.is_empty():
		return

	var visuals: Array = []

	if tile_visual_manager != null:
		visuals = tile_visual_manager.active_tile_visuals.get(tile_coord, [])

	for i: int in range(tile.object_ids.size()):
		var object_id: StringName = tile.object_ids[i]
		var visual: Node3D = null

		if i < visuals.size() and visuals[i] is Node3D:
			visual = visuals[i] as Node3D

		result.append(ObjectTargetCandidate.create_tile(tile_coord, object_id, visual))


func add_edge_candidates(result: Array[ObjectTargetCandidate], tile_coord: Vector2i) -> void:
	var directions: Array[Vector2i] = [
		Vector2i.UP,
		Vector2i.RIGHT,
		Vector2i.DOWN,
		Vector2i.LEFT
	]

	for direction: Vector2i in directions:
		var edge_data: Dictionary = grid_manager.get_edge_from_tile_direction(tile_coord, direction)

		var edge_coord: Vector2i = edge_data.get("coord", Vector2i.ZERO)
		var orientation := StringName(edge_data.get("orientation", &"horizontal"))

		var edge: GameEdgeData = grid_manager.get_edge(edge_coord, orientation)

		if edge == null:
			continue

		if not edge.has_object():
			continue

		var visual: Node3D = get_edge_visual(edge_coord, orientation)
		result.append(ObjectTargetCandidate.create_edge(edge_coord, orientation, edge.object_id, visual))


func add_corner_candidates(result: Array[ObjectTargetCandidate], tile_coord: Vector2i) -> void:
	var corner_coords: Array[Vector2i] = [
		tile_coord,
		tile_coord + Vector2i.RIGHT,
		tile_coord + Vector2i.DOWN,
		tile_coord + Vector2i.RIGHT + Vector2i.DOWN
	]

	for corner_coord: Vector2i in corner_coords:
		var corner: GameCornerData = grid_manager.get_corner(corner_coord)

		if corner == null:
			continue

		if not corner.has_object():
			continue

		var visual: Node3D = get_corner_visual(corner_coord)
		result.append(ObjectTargetCandidate.create_corner(corner_coord, corner.object_id, visual))


func get_edge_visual(coord: Vector2i, orientation: StringName) -> Node3D:
	if edge_visual_manager == null:
		return null

	var key: String = edge_visual_manager.make_edge_key(coord, orientation)

	if not edge_visual_manager.active_edge_visuals.has(key):
		return null

	for visual in edge_visual_manager.active_edge_visuals[key]:
		if visual is Node3D:
			return visual as Node3D

	return null


func get_corner_visual(coord: Vector2i) -> Node3D:
	if corner_visual_manager == null:
		return null

	if not corner_visual_manager.active_corner_visuals.has(coord):
		return null

	for visual in corner_visual_manager.active_corner_visuals[coord]:
		if visual is Node3D:
			return visual as Node3D

	return null


func make_signature(list: Array[ObjectTargetCandidate]) -> String:
	var parts: Array[String] = []

	for candidate: ObjectTargetCandidate in list:
		parts.append(candidate.get_signature())

	return "|".join(parts)


func cycle_target() -> void:
	update_candidates()

	if candidates.is_empty():
		selected_index = 0
		return

	selected_index += 1

	if selected_index >= candidates.size():
		selected_index = 0


func has_current_target() -> bool:
	update_candidates()
	return not candidates.is_empty()


func get_current_candidate() -> ObjectTargetCandidate:
	update_candidates()

	if candidates.is_empty():
		return null

	return candidates[selected_index]


func get_current_visual() -> Node3D:
	var candidate: ObjectTargetCandidate = get_current_candidate()

	if candidate == null:
		return null

	if candidate.visual == null:
		return null

	if not is_instance_valid(candidate.visual):
		return null

	return candidate.visual


func get_current_world_position() -> Vector3:
	var candidate: ObjectTargetCandidate = get_current_candidate()

	if candidate == null or grid_manager == null:
		return Vector3.ZERO

	match candidate.kind:
		ObjectTargetCandidate.Kind.EDGE:
			return grid_manager.edge_to_world(candidate.coord, candidate.orientation)

		ObjectTargetCandidate.Kind.CORNER:
			return grid_manager.corner_to_world(candidate.coord)

		_:
			return grid_manager.tile_to_world(candidate.coord)


func break_current_target(grid_object_manager: GridObjectManager) -> bool:
	if grid_object_manager == null:
		return false

	var candidate: ObjectTargetCandidate = get_current_candidate()

	if candidate == null:
		return false

	var drop_position: Vector3 = get_current_world_position() + Vector3.UP * 0.4
	var did_break := false

	match candidate.kind:
		ObjectTargetCandidate.Kind.EDGE:
			did_break = grid_object_manager.break_edge_object(
				candidate.coord,
				candidate.orientation,
				drop_position
			)

		ObjectTargetCandidate.Kind.CORNER:
			did_break = grid_object_manager.break_corner_object(
				candidate.coord,
				drop_position
			)

		ObjectTargetCandidate.Kind.TILE:
			did_break = grid_object_manager.break_tile_object(
				candidate.coord,
				drop_position,
				candidate.object_id
			)

	if did_break:
		selected_index = 0
		last_signature = ""
		update_candidates()

	return did_break
