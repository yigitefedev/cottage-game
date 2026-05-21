class_name GameTileData
extends Resource

var coord: Vector2i
var ground_id: StringName = &"grass"

var usable: bool = true

var crop_id: StringName = &""
var crop_growth_day: int = 0
var crop_quality: int = 0
var crop_stage_index: int = 0
var crop_days_in_stage: int = 0
var crop_harvestable: bool = false

var object_ids: Array[StringName] = []

var flags: Dictionary = {}
var custom_data: Dictionary = {}
var visual_layers: Dictionary = {}

func _init(_coord: Vector2i = Vector2i.ZERO) -> void:
	coord = _coord


func is_used() -> bool:
	return has_crop() or object_ids.size() > 0 or has_flag(&"tilled")


func has_crop() -> bool:
	return crop_id != &""


func has_object(object_id: StringName) -> bool:
	return object_ids.has(object_id)


func set_flag(flag_name: StringName, value: bool = true) -> void:
	flags[flag_name] = value


func has_flag(flag_name: StringName) -> bool:
	return flags.get(flag_name, false)


func can_interact() -> bool:
	return usable

func set_visual(layer: StringName, visual_id: StringName) -> void:
	if visual_id == &"":
		visual_layers.erase(layer)
	else:
		visual_layers[layer] = visual_id


func remove_visual(layer: StringName) -> void:
	visual_layers.erase(layer)


func get_visual_layers() -> Dictionary:
	return visual_layers
