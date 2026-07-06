class_name WorkstationCancelHoldAction
extends HoldInteractionAction

const ITEM_DATABASE: ItemDatabase = preload("res://resources/items/MainItemDatabase.tres")


func _init() -> void:
	hold_duration_seconds = 0.75
	ITEM_DATABASE.build_lookup()


func can_start_hold(context: InteractionContext) -> bool:
	if context == null:
		return false

	if context.workstation_manager == null:
		return false

	if context.target_tile == null:
		return false

	if not context.workstation_manager.is_workstation_tile(context.target_tile_coord):
		return false

	return context.workstation_manager.can_cancel(context.target_tile_coord)


func complete_hold(context: InteractionContext) -> void:
	if context == null:
		return

	if context.workstation_manager == null:
		return

	if context.world_item_spawner == null:
		return

	if context.grid_manager == null:
		return

	var refunds: Array[Dictionary] = context.workstation_manager.cancel_workstation(context.target_tile_coord)

	if refunds.is_empty():
		return

	var drop_position: Vector3 = context.grid_manager.tile_to_world(context.target_tile_coord) + Vector3.UP * 0.45

	for refund: Dictionary in refunds:
		var item_id: StringName = StringName(refund.get("item_id", &""))
		var amount: int = int(refund.get("amount", 0))

		if item_id == &"" or amount <= 0:
			continue

		var item_definition: ItemDefinition = ITEM_DATABASE.get_item(item_id)

		if item_definition == null:
			continue

		context.world_item_spawner.spawn_item_stack(item_definition, amount, drop_position)
