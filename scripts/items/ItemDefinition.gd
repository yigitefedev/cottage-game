class_name ItemDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D

@export var max_stack: int = 99
@export var tags: Array[StringName] = []

@export var primary_action: ItemAction
@export var secondary_action: ItemAction

@export var properties: Dictionary = {}


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)


func get_property(property_name: String, default_value = null):
	return properties.get(property_name, default_value)
