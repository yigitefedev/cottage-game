class_name GameEdgeData
extends Resource

var coord: Vector2i
var orientation: StringName

var object_id: StringName = &""

var usable: bool = true

var flags: Dictionary = {}
var custom_data: Dictionary = {}
var visual_layers: Dictionary = {}

func _init(
	_coord: Vector2i = Vector2i.ZERO,
	_orientation: StringName = &"horizontal"
) -> void:

	coord = _coord
	orientation = _orientation


func has_object() -> bool:
	return object_id != &""


func set_flag(flag_name: StringName, value: bool = true) -> void:
	flags[flag_name] = value


func has_flag(flag_name: StringName) -> bool:
	return flags.get(flag_name, false)

func set_visual(layer: StringName, visual_id: StringName) -> void:
	if visual_id == &"":
		visual_layers.erase(layer)
	else:
		visual_layers[layer] = visual_id


func remove_visual(layer: StringName) -> void:
	visual_layers.erase(layer)


func get_visual_layers() -> Dictionary:
	return visual_layers
