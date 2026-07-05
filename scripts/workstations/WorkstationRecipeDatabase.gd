class_name WorkstationRecipeDatabase
extends Resource

@export var recipes: Array[WorkstationRecipe] = []

var recipe_lookup: Dictionary = {}
var recipes_by_type: Dictionary = {}


func build_lookup() -> void:
	recipe_lookup.clear()
	recipes_by_type.clear()

	for recipe: WorkstationRecipe in recipes:
		if recipe == null:
			continue

		if not recipe.has_valid_data():
			continue

		recipe_lookup[recipe.id] = recipe

		if not recipes_by_type.has(recipe.workstation_type):
			recipes_by_type[recipe.workstation_type] = []

		recipes_by_type[recipe.workstation_type].append(recipe)


func get_recipe(recipe_id: StringName) -> WorkstationRecipe:
	if recipe_lookup.is_empty():
		build_lookup()

	return recipe_lookup.get(recipe_id, null)


func get_recipes_for_type(workstation_type: StringName) -> Array[WorkstationRecipe]:
	if recipes_by_type.is_empty():
		build_lookup()

	var result: Array[WorkstationRecipe] = []

	if not recipes_by_type.has(workstation_type):
		return result

	var raw_recipes: Array = recipes_by_type[workstation_type]

	for recipe in raw_recipes:
		if recipe is WorkstationRecipe:
			result.append(recipe as WorkstationRecipe)

	return result


func find_start_recipe(workstation_type: StringName, item_id: StringName) -> WorkstationRecipe:
	var type_recipes: Array[WorkstationRecipe] = get_recipes_for_type(workstation_type)

	for recipe: WorkstationRecipe in type_recipes:
		if recipe.can_start_with(item_id):
			return recipe

	return null
