class_name CropDatabase
extends Resource

@export var crops: Array[CropDefinition] = []

var crop_lookup: Dictionary = {}

func build_lookup() -> void:
	crop_lookup.clear()

	for crop in crops:
		if crop == null:
			continue

		crop_lookup[crop.id] = crop


func get_crop(crop_id: StringName) -> CropDefinition:
	return crop_lookup.get(crop_id, null)
