class_name WorkstationInteractionAction
extends InteractionAction

const ITEM_DATABASE: ItemDatabase = preload("res://resources/items/MainItemDatabase.tres")


func _init() -> void:
	ITEM_DATABASE.build_lookup()


func can_interact(context: InteractionContext) -> bool:
	if context == null:
		return false

	if context.workstation_manager == null:
		return false

	if context.target_tile == null:
		return false

	if not context.workstation_manager.is_workstation_tile(context.target_tile_coord):
		return false

	if context.workstation_manager.is_done(context.target_tile_coord):
		return true

	var selected_item: ItemInstanceData = context.selected_item

	if selected_item == null:
		return false

	if selected_item.definition == null:
		return false

	if selected_item.amount <= 0:
		return false

	return context.workstation_manager.can_insert_item(
		context.target_tile_coord,
		selected_item.definition.id
	)


func interact(context: InteractionContext) -> void:
	if context == null:
		return

	if context.workstation_manager == null:
		return

	if context.target_tile == null:
		return

	if context.workstation_manager.is_done(context.target_tile_coord):
		drop_outputs(context)
		return

	insert_selected_item(context)


func insert_selected_item(context: InteractionContext) -> void:
	var selected_item: ItemInstanceData = context.selected_item

	if selected_item == null:
		return

	if selected_item.definition == null:
		return

	if selected_item.amount <= 0:
		return

	if context.player_inventory == null:
		return

	# Şimdilik her E basışında 1 adet koyuyoruz.
	# Strawberry jam gibi şeylerde 1/3, 2/3, 3/3 hissi böyle oluşacak.
	var amount_to_try: int = 1

	var used_amount: int = context.workstation_manager.try_insert_item(
		context.target_tile_coord,
		selected_item.definition.id,
		amount_to_try
	)

	if used_amount <= 0:
		return

	selected_item.amount -= used_amount

	if selected_item.amount <= 0:
		context.player_inventory.inventory.set_slot(context.selected_inventory_index, null)

	context.player_inventory.inventory_changed.emit()
	context.player_inventory.selected_slot_changed.emit(context.player_inventory.selected_index)


func drop_outputs(context: InteractionContext) -> void:
	if context.world_item_spawner == null:
		return

	if context.grid_manager == null:
		return

	var output_slots: Array = context.workstation_manager.get_output_slots(context.target_tile_coord)

	if output_slots.is_empty():
		context.workstation_manager.reset_to_empty(context.target_tile_coord)
		return

	var drop_position: Vector3 = context.grid_manager.tile_to_world(context.target_tile_coord) + Vector3.UP * 0.45

	for raw_output: Variant in output_slots:
		if not (raw_output is Dictionary):
			continue

		var output: Dictionary = raw_output
		var item_id: StringName = StringName(output.get("item_id", &""))
		var amount: int = int(output.get("amount", 0))

		if item_id == &"":
			continue

		if amount <= 0:
			continue

		var item_definition: ItemDefinition = ITEM_DATABASE.get_item(item_id)

		if item_definition == null:
			continue

		context.world_item_spawner.spawn_item_stack(item_definition, amount, drop_position)

	context.workstation_manager.reset_to_empty(context.target_tile_coord)
