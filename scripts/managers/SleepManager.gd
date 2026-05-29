class_name SleepManager
extends Node

@export var sleep_fade_duration := 0.8

var time_manager: TimeManager
var player_stamina: PlayerStamina
@export var fade_rect: ColorRect

var is_sleeping := false


func _ready() -> void:
	add_to_group("sleep_manager")

	await get_tree().process_frame

	time_manager = get_tree().get_first_node_in_group("time_manager")
	player_stamina = get_tree().get_first_node_in_group("player_stamina")
	
	print("[SleepManager] ready")
	print("[SleepManager] time_manager: ", time_manager)
	print("[SleepManager] player_stamina: ", player_stamina)
	print("[SleepManager] fade_rect: ", fade_rect)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_sleep"):
		print("[SleepManager] debug_sleep pressed")
		try_sleep()


func try_sleep() -> void:
	print("[SleepManager] try_sleep")

	if is_sleeping:
		print("[SleepManager] already sleeping")
		return

	sleep()


func sleep() -> void:
	print("[SleepManager] sleep start")
	if time_manager == null:
		print("[SleepManager] no time manager")
		return

	is_sleeping = true

	var wake_hour := time_manager.get_sleep_wake_hour()

	await fade_to_black()

	time_manager.sleep_until_next_day(wake_hour)

	if player_stamina != null:
		player_stamina.refill()

	await fade_from_black()

	is_sleeping = false


func fade_to_black() -> void:
	if fade_rect == null:
		return

	var tween := create_tween()

	fade_rect.visible = true
	fade_rect.modulate.a = 0.0

	tween.tween_property(
		fade_rect,
		"modulate:a",
		1.0,
		sleep_fade_duration
	)

	await tween.finished


func fade_from_black() -> void:
	if fade_rect == null:
		return

	var tween := create_tween()

	tween.tween_property(
		fade_rect,
		"modulate:a",
		0.0,
		sleep_fade_duration
	)

	await tween.finished

	fade_rect.visible = false
