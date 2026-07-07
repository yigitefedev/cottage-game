class_name Sprinkler
extends Node3D

var corner_coord: Vector2i = Vector2i.ZERO
var has_setup := false

var grid_manager: GridManager
var tile_visual_manager: TileVisualManager

@onready var head: MeshInstance3D = $head

@export var spin_duration := 12
@export var spin_rotations := 24

func setup(coord: Vector2i) -> void:
	corner_coord = coord
	has_setup = true
	ensure_refs()
	connect_day_started()


func _ready() -> void:
	ensure_refs()


func _exit_tree() -> void:
	if TimeManager.day_started.is_connected(on_day_started):
		TimeManager.day_started.disconnect(on_day_started)

	if TimeManager.day_simulated.is_connected(on_day_simulated):
		TimeManager.day_simulated.disconnect(on_day_simulated)


func ensure_refs() -> void:
	grid_manager = get_tree().get_first_node_in_group("grid_manager")
	tile_visual_manager = get_tree().get_first_node_in_group("tile_visual_manager")


func connect_day_started() -> void:
	if not has_setup:
		return

	if not TimeManager.day_started.is_connected(on_day_started):
		TimeManager.day_started.connect(on_day_started)

	if not TimeManager.day_simulated.is_connected(on_day_simulated):
		TimeManager.day_simulated.connect(on_day_simulated)


func on_day_started(_day: int) -> void:
	if not has_setup:
		return

	await get_tree().create_timer(2.0).timeout

	if not is_inside_tree() or not has_setup:
		return

	play_spin_animation()

	water_nearby_tiles()


func on_day_simulated(_day: int, fast_forward: bool) -> void:
	if not fast_forward:
		return

	water_nearby_tiles(false)


func water_nearby_tiles(refresh_visuals: bool = true) -> void:
	if not has_setup:
		return

	if grid_manager == null:
		ensure_refs()

	if grid_manager == null:
		return

	var affected_tiles := [
		corner_coord + Vector2i(-1, -1),
		corner_coord + Vector2i(0, -1),
		corner_coord + Vector2i(-1, 0),
		corner_coord + Vector2i(0, 0),
	]

	for tile_coord in affected_tiles:
		var tile := grid_manager.get_tile(tile_coord)


		if tile == null:
			continue


		if not tile.usable:
			continue

		if not PlantingSurfaceResolver.is_waterable(tile):
			continue

		tile.set_flag(&"watered", true)
		tile.set_flag(&"just_watered", refresh_visuals)
		tile.set_flag(&"slow_water_tween", refresh_visuals)

		var surface_layer := PlantingSurfaceResolver.get_surface_visual_layer(tile)

		if refresh_visuals and tile_visual_manager != null and surface_layer != &"":
			tile_visual_manager.refresh_tile_layer(tile_coord, surface_layer)
			
func play_spin_animation() -> void:
	if head == null:
		return

	var tween := create_tween()

	tween.tween_property(
		head,
		"rotation:y",
		head.rotation.y + TAU * spin_rotations,
		spin_duration
	)
