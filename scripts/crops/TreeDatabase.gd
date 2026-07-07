class_name TreeDatabase
extends Resource

@export var trees: Array[Resource] = []

var tree_lookup: Dictionary = {}


func build_lookup() -> void:
	tree_lookup.clear()

	for tree_definition in trees:
		if tree_definition == null:
			continue

		var tree_id := StringName(tree_definition.get("id"))

		if tree_id == &"":
			continue

		tree_lookup[tree_id] = tree_definition


func get_tree(tree_id: StringName) -> Resource:
	return tree_lookup.get(tree_id, null)
