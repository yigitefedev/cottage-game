class_name ItemInstanceData
extends Resource

@export var definition: ItemDefinition

@export var amount: int = 1

@export var state: Dictionary = {}


func is_stackable_with(other: ItemInstanceData) -> bool:
	if other == null:
		return false

	if definition != other.definition:
		return false

	return state == other.state


func has_tag(tag: StringName) -> bool:
	if definition == null:
		return false

	return definition.has_tag(tag)


func get_property(property_name: StringName, default_value = null):
	if definition == null:
		return default_value

	return definition.get_property(property_name, default_value)


func get_state(state_name: String, default_value = null):
	return state.get(state_name, default_value)


func set_state(state_name: String, value) -> void:
	state[state_name] = value
