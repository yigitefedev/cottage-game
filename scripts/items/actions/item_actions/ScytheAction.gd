class_name ScytheAction
extends ItemAction

@export var cut_radius := 1.4
@export var cut_angle_degrees := 110.0
@export var plant_waste_amount := 1
@export var minimum_pixels_for_waste := 20

func can_use(context: ItemUseContext) -> bool:
	if context == null:
		return false

	if context.grass_mask_manager == null:
		return false

	if context.player == null:
		return false

	if context.world_item_spawner == null:
		return false

	if context.item_database == null:
		return false

	return true


func use(context: ItemUseContext) -> void:
	if not can_use(context):
		return

	var forward := get_player_forward(context.player)
	var center := context.player.global_position + forward * 0.7

	var removed_pixels: int = context.grass_mask_manager.clear_arc(
		center,
		forward,
		cut_radius,
		cut_angle_degrees
	)

	if removed_pixels >= minimum_pixels_for_waste:
		spawn_plant_waste(context, center + Vector3.UP * 0.4)


func spawn_plant_waste(context: ItemUseContext, drop_position: Vector3) -> void:
	var plant_waste_definition := context.item_database.get_item(&"plant_waste")

	if plant_waste_definition == null:
		push_warning("ScytheAction: plant_waste item database içinde yok.")
		return

	for i in range(plant_waste_amount):
		var waste := ItemInstanceData.new()
		waste.definition = plant_waste_definition
		waste.amount = 1

		context.world_item_spawner.spawn_item(waste, drop_position)


func get_player_forward(player: Node3D) -> Vector3:
	var forward := player.global_transform.basis.z
	forward.y = 0.0

	if forward.length() <= 0.001:
		return Vector3.FORWARD

	return forward.normalized()
