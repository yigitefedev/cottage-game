class_name MalletAction
extends ItemAction


func can_use(context: ItemUseContext) -> bool:
	if context == null:
		return false

	if context.object_target_resolver == null:
		return false

	return context.object_target_resolver.has_current_target()


func use(context: ItemUseContext) -> void:
	if context == null:
		return

	if context.object_target_resolver == null:
		return

	if context.grid_object_manager == null:
		return

	context.object_target_resolver.break_current_target(context.grid_object_manager)
