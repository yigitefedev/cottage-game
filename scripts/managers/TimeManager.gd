extends Node

signal time_tick(day: int, hour: int, minute: int)
signal hour_passed(day: int, hour: int)
signal day_started(day: int)
signal day_changed(day: int)
signal time_skipped(minutes: int)
signal forced_sleep_requested

@export var seconds_per_game_minute := 1.0
@export var minutes_per_tick := 10
@export var day_start_hour := 6

var is_paused := false
var time_scale := 1.0

var current_day := 1
var current_hour := 6
var current_minute := 0

var _second_accumulator := 0.0
var _last_hour := 6
var _last_day := 1
var forced_sleep_triggered_today := false

func _ready() -> void:
	add_to_group("time_manager")

func _process(delta: float) -> void:
	if is_paused:
		return

	_second_accumulator += delta * time_scale

	var seconds_per_tick := seconds_per_game_minute * minutes_per_tick

	while _second_accumulator >= seconds_per_tick:
		_second_accumulator -= seconds_per_tick
		advance_time(minutes_per_tick)

func advance_time(minutes: int) -> void:
	current_minute += minutes

	while current_minute >= 60:
		current_minute -= 60
		current_hour += 1

	while current_hour >= 24:
		current_hour -= 24

	time_tick.emit(current_day, current_hour, current_minute)

	if current_hour != _last_hour:
		_last_hour = current_hour
		hour_passed.emit(current_day, current_hour)

	if current_day != _last_day:
		_last_day = current_day

	if current_hour == 2 and current_minute == 0 and not forced_sleep_triggered_today:
		forced_sleep_triggered_today = true
		forced_sleep_requested.emit()
		return

	if current_hour == day_start_hour and current_minute == 0:
		current_day += 1

		day_changed.emit(current_day)
		day_started.emit(current_day)


func get_time_string() -> String:
	return "%02d:%02d" % [current_hour, current_minute]


func get_day_string() -> String:
	return "Day %d" % current_day


func set_time(day: int, hour: int, minute: int) -> void:
	current_day = day
	current_hour = hour
	current_minute = minute

	_last_day = current_day
	_last_hour = current_hour

	time_tick.emit(current_day, current_hour, current_minute)


func skip_minutes(minutes: int) -> void:
	advance_time(minutes)

func pause_time() -> void:
	is_paused = true


func resume_time() -> void:
	is_paused = false


func toggle_pause() -> void:
	is_paused = !is_paused


func set_time_scale(value: float) -> void:
	time_scale = max(value, 0.0)
func sleep_until_next_day(wake_hour: int, wake_minute: int = 0) -> void:
	var skipped_minutes := get_minutes_until_next_day_time(wake_hour, wake_minute)

	current_day += 1
	current_hour = wake_hour
	current_minute = wake_minute

	_last_day = current_day
	_last_hour = current_hour
	_second_accumulator = 0.0
	forced_sleep_triggered_today = false

	time_skipped.emit(skipped_minutes)
	day_changed.emit(current_day)
	day_started.emit(current_day)
	time_tick.emit(current_day, current_hour, current_minute)


func get_minutes_until_next_day_time(wake_hour: int, wake_minute: int = 0) -> int:
	var current_total := current_hour * 60 + current_minute
	var target_total := wake_hour * 60 + wake_minute

	return (24 * 60 - current_total) + target_total


func get_sleep_wake_hour() -> int:
	if current_hour >= 0 and current_hour < 2:
		return 8

	return 6
func get_forced_sleep_wake_hour() -> int:
	return 10
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle_time_pause"):
		toggle_pause()

	if event.is_action_pressed("debug_time_speed_1"):
		set_time_scale(1.0)

	if event.is_action_pressed("debug_time_speed_5"):
		set_time_scale(10.0)

	if event.is_action_pressed("debug_time_speed_20"):
		set_time_scale(200.0)
