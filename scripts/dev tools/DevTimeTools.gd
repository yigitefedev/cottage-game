class_name DevTimeTools
extends Node

@export var tool_enabled := false

var time_manager: TimeManager
var sleep_manager: SleepManager


func _ready() -> void:
	add_to_group("dev_time_tools")

	await get_tree().process_frame

	time_manager = get_tree().get_first_node_in_group("time_manager")
	sleep_manager = get_tree().get_first_node_in_group("sleep_manager")


func ensure_refs() -> void:
	if time_manager == null:
		time_manager = get_tree().get_first_node_in_group("time_manager")

	if sleep_manager == null:
		sleep_manager = get_tree().get_first_node_in_group("sleep_manager")


func set_enabled(enabled: bool) -> void:
	tool_enabled = enabled


func toggle_pause() -> void:
	if not tool_enabled:
		return

	ensure_refs()

	if time_manager != null:
		time_manager.toggle_pause()


func set_time_scale(value: float) -> void:
	if not tool_enabled:
		return

	ensure_refs()

	if time_manager != null:
		time_manager.set_time_scale(value)


func sleep() -> void:
	if not tool_enabled:
		return

	ensure_refs()

	if sleep_manager != null:
		sleep_manager.try_sleep()


func skip_minutes(minutes: int) -> void:
	if not tool_enabled:
		return

	ensure_refs()

	if time_manager != null:
		time_manager.skip_minutes(minutes)


func next_day() -> void:
	if not tool_enabled:
		return

	ensure_refs()

	if time_manager != null:
		time_manager.sleep_until_next_day(time_manager.day_start_hour)
