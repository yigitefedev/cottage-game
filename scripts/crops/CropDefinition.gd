class_name CropDefinition
extends Resource

@export var id: StringName
@export var display_name: String

@export var stage_visual_ids: Array[StringName] = []
@export var stage_duration_days: Array[int] = []

@export var harvest_stage_index: int = -1
@export var harvest_item_id: StringName


func get_stage_count() -> int:
	return stage_visual_ids.size()


func get_stage_visual(stage_index: int) -> StringName:
	if stage_index < 0 or stage_index >= stage_visual_ids.size():
		return &""

	return stage_visual_ids[stage_index]


func get_stage_duration(stage_index: int) -> int:
	if stage_index < 0 or stage_index >= stage_duration_days.size():
		return 0

	return stage_duration_days[stage_index]


func is_stage_harvestable(stage_index: int) -> bool:
	return stage_index == harvest_stage_index
