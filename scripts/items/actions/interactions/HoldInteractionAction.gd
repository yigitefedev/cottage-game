class_name HoldInteractionAction
extends InteractionAction

@export var hold_duration_seconds: float = 0.75


func can_start_hold(_context: InteractionContext) -> bool:
	return false


func complete_hold(_context: InteractionContext) -> void:
	pass
