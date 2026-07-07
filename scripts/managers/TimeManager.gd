extends Node

signal time_tick(day: int, hour: int, minute: int)
signal time_advanced(minutes: int)
signal hour_passed(day: int, hour: int)
signal day_started(day: int)
signal day_simulated(day: int, fast_forward: bool)
signal day_changed(day: int)
signal time_skipped(minutes: int)
signal time_simulation_finished
signal forced_sleep_requested

const MINUTES_PER_DAY := 24 * 60

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

func get_tick_progress_ratio() -> float:
	var seconds_per_tick: float = seconds_per_game_minute * float(minutes_per_tick)

	if seconds_per_tick <= 0.0:
		return 0.0

	return clampf(_second_accumulator / seconds_per_tick, 0.0, 1.0)

func advance_time(minutes: int) -> void:
	if minutes <= 0:
		return

	current_minute += minutes

	while current_minute >= 60:
		current_minute -= 60
		current_hour += 1

	while current_hour >= 24:
		current_hour -= 24

	time_advanced.emit(minutes)

	if current_hour == 2 and current_minute == 0 and not forced_sleep_triggered_today:
		forced_sleep_triggered_today = true
		time_tick.emit(current_day, current_hour, current_minute)
		forced_sleep_requested.emit()
		return

	if current_hour == day_start_hour and current_minute == 0:
		current_day += 1
		emit_day_transition(false)

	time_tick.emit(current_day, current_hour, current_minute)

	if current_hour != _last_hour:
		_last_hour = current_hour
		hour_passed.emit(current_day, current_hour)

	if current_day != _last_day:
		_last_day = current_day


func get_time_string() -> String:
	return "%02d:%02d" % [current_hour, current_minute]


func get_day_string() -> String:
	return "Day %d" % current_day


func set_time(day: int, hour: int, minute: int) -> void:
	var current_absolute_minutes := get_current_absolute_minutes()
	var target_absolute_minutes := get_absolute_minutes(day, hour, minute)

	if target_absolute_minutes > current_absolute_minutes:
		simulate_forward_to_absolute(target_absolute_minutes)
	else:
		set_clock_direct(day, hour, minute)

	_last_day = current_day
	_last_hour = current_hour
	_second_accumulator = 0.0

	time_tick.emit(current_day, current_hour, current_minute)


func skip_minutes(minutes: int) -> void:
	if minutes <= 0:
		return

	var target_absolute_minutes := get_current_absolute_minutes() + minutes
	simulate_forward_to_absolute(target_absolute_minutes)

	_last_day = current_day
	_last_hour = current_hour
	_second_accumulator = 0.0

	time_tick.emit(current_day, current_hour, current_minute)

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

	time_skipped.emit(skipped_minutes)
	emit_day_transition(false)
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


func simulate_forward_to_absolute(target_absolute_minutes: int) -> void:
	var cursor_absolute_minutes := get_current_absolute_minutes()
	var next_day_start_minutes := get_next_day_start_after(cursor_absolute_minutes)
	var simulated_days := false

	while next_day_start_minutes <= target_absolute_minutes:
		var skipped_minutes := next_day_start_minutes - cursor_absolute_minutes

		set_clock_from_absolute(next_day_start_minutes)

		if skipped_minutes > 0:
			time_skipped.emit(skipped_minutes)

		emit_day_transition(true)
		simulated_days = true

		cursor_absolute_minutes = next_day_start_minutes
		next_day_start_minutes += MINUTES_PER_DAY

	var remaining_minutes := target_absolute_minutes - cursor_absolute_minutes

	set_clock_from_absolute(target_absolute_minutes)

	if remaining_minutes > 0:
		time_skipped.emit(remaining_minutes)

	if simulated_days:
		time_simulation_finished.emit()


func emit_day_transition(fast_forward: bool) -> void:
	forced_sleep_triggered_today = false

	day_changed.emit(current_day)
	day_simulated.emit(current_day, fast_forward)

	if not fast_forward:
		day_started.emit(current_day)


func get_current_absolute_minutes() -> int:
	return get_absolute_minutes(current_day, current_hour, current_minute)


func get_absolute_minutes(day: int, hour: int, minute: int) -> int:
	var safe_day: int = max(day, 1)
	var day_start_minutes: int = day_start_hour * 60
	var clock_minutes: int = hour * 60 + minute
	var minutes_into_day: int = clock_minutes - day_start_minutes

	if minutes_into_day < 0:
		minutes_into_day += MINUTES_PER_DAY

	return (safe_day - 1) * MINUTES_PER_DAY + minutes_into_day


func get_next_day_start_after(absolute_minutes: int) -> int:
	var day_index := floori(float(absolute_minutes) / float(MINUTES_PER_DAY))
	return (day_index + 1) * MINUTES_PER_DAY


func set_clock_from_absolute(absolute_minutes: int) -> void:
	var safe_minutes: int = max(absolute_minutes, 0)
	var day_index: int = floori(float(safe_minutes) / float(MINUTES_PER_DAY))
	var minutes_into_day: int = safe_minutes % MINUTES_PER_DAY
	var clock_minutes: int = (day_start_hour * 60 + minutes_into_day) % MINUTES_PER_DAY

	current_day = day_index + 1
	current_hour = floori(float(clock_minutes) / 60.0)
	current_minute = clock_minutes % 60


func set_clock_direct(day: int, hour: int, minute: int) -> void:
	current_day = day
	current_hour = hour
	current_minute = minute
