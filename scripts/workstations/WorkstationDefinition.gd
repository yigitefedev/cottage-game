class_name WorkstationDefinition
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""

@export var workstation_type: StringName = &""

@export_range(1, 8) var max_input_slots: int = 1
@export_range(1, 8) var max_output_slots: int = 1

@export var object_id: StringName = &""
@export var visual_id: StringName = &""

@export var show_bubble_ui := true


func get_object_id() -> StringName:
	if object_id != &"":
		return object_id

	return id


func get_visual_id() -> StringName:
	if visual_id != &"":
		return visual_id

	return get_object_id()


func get_workstation_type() -> StringName:
	if workstation_type != &"":
		return workstation_type

	return id
