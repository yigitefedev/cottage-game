class_name ItemAction
extends Resource

@export var action_id: StringName
@export var stamina_cost := 1

func can_use(_context) -> bool:
	return false

func use(_context) -> void:
	pass
