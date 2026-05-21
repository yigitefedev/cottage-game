class_name ItemDatabase
extends Resource

@export var items: Array[ItemDefinition] = []

var item_lookup: Dictionary = {}


func build_lookup() -> void:
	item_lookup.clear()

	for item in items:
		if item == null:
			continue

		item_lookup[item.id] = item


func get_item(item_id: StringName) -> ItemDefinition:
	return item_lookup.get(item_id, null)
