class_name WorkstationDefinitionDatabase
extends Resource

@export var definitions: Array[WorkstationDefinition] = []

var definitions_by_id: Dictionary = {}
var definitions_by_object_id: Dictionary = {}


func build_lookup() -> void:
	definitions_by_id.clear()
	definitions_by_object_id.clear()

	for definition: WorkstationDefinition in definitions:
		if definition == null:
			continue

		if definition.id == &"":
			continue

		definitions_by_id[definition.id] = definition
		definitions_by_object_id[definition.get_object_id()] = definition


func get_definition(id: StringName) -> WorkstationDefinition:
	if definitions_by_id.is_empty():
		build_lookup()

	return definitions_by_id.get(id, null)


func get_definition_for_object_id(object_id: StringName) -> WorkstationDefinition:
	if definitions_by_object_id.is_empty():
		build_lookup()

	return definitions_by_object_id.get(object_id, null)
