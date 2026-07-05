class_name WorkstationItemStack
extends Resource

@export var item_id: StringName = &""
@export var amount: int = 1


func is_valid_data() -> bool:
	if item_id == &"":
		return false

	if amount <= 0:
		return false

	return true
