class_name InteractionAction
extends Resource

@export var action_id: StringName

func can_interact(_context: InteractionContext) -> bool:
	return false


func interact(_context: InteractionContext) -> void:
	pass
