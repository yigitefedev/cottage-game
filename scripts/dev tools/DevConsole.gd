class_name DevConsole
extends CanvasLayer

@export var item_database: ItemDatabase

@onready var output_text: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/OutputText
@onready var command_input: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/CommandInput
@onready var autocomplete_list: ItemList = 	$PanelContainer/MarginContainer/VBoxContainer/AutocompleteList

var player_inventory: PlayerInventory
var time_manager: Node
var wind_manager: Node
var sleep_manager: Node

var autocomplete_matches: Array[String] = []
var autocomplete_index: int = 0
var autocomplete_active := false
var autocomplete_kind := ""
var autocomplete_token_start: int = 0
var autocomplete_token_end: int = 0
var command_history: Array[String] = []
var history_index := -1
var history_draft := ""

const MAX_COMMAND_HISTORY := 50
const MAIN_ITEM_DATABASE_PATH := "res://resources/items/MainItemDatabase.tres"


func _ready() -> void:
	visible = false
	command_input.text_submitted.connect(_on_command_submitted)
	autocomplete_list.visible = false
	ensure_refs()
	log_info("Dev Console ready. Type 'help'.")
	command_input.gui_input.connect(_on_command_input_gui_input)
	command_input.text_changed.connect(_on_command_input_text_changed)

func show_autocomplete_popup(matches: Array[String], selected_index: int) -> void:
	if autocomplete_list == null:
		return

	autocomplete_list.clear()

	if matches.is_empty():
		autocomplete_active = false
		autocomplete_list.visible = false
		return

	autocomplete_active = true

	var max_visible: int = 8
	var start_index: int = selected_index - 3

	if start_index < 0:
		start_index = 0

	var max_start_index: int = matches.size() - max_visible

	if max_start_index < 0:
		max_start_index = 0

	if start_index > max_start_index:
		start_index = max_start_index

	var end_index: int = start_index + max_visible

	if end_index > matches.size():
		end_index = matches.size()

	for i: int in range(start_index, end_index):
		autocomplete_list.add_item(matches[i])

		if i == selected_index:
			autocomplete_list.select(autocomplete_list.item_count - 1)

	autocomplete_list.visible = true

func hide_autocomplete_popup() -> void:
	autocomplete_active = false
	autocomplete_matches.clear()
	autocomplete_index = 0
	autocomplete_kind = ""

	if autocomplete_list == null:
		return

	autocomplete_list.clear()
	autocomplete_list.visible = false
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_dev_console"):
		toggle_console()
		get_viewport().set_input_as_handled()
		
func _unhandled_input(_event: InputEvent) -> void:
	if visible:
		get_viewport().set_input_as_handled()

func toggle_console() -> void:
	visible = !visible

	DevManager.set_gameplay_input_locked(visible)

	if visible:
		ensure_refs()
		command_input.grab_focus()
	else:
		command_input.release_focus()


func close_console() -> void:
	visible = false
	command_input.release_focus()
	DevManager.set_gameplay_input_locked(false)


func ensure_refs() -> void:
	if player_inventory == null:
		player_inventory = get_tree().get_first_node_in_group("player_inventory")

	if time_manager == null:
		time_manager = get_tree().get_first_node_in_group("time_manager")

	if wind_manager == null:
		wind_manager = get_tree().get_first_node_in_group("wind_manager")

	if sleep_manager == null:
		sleep_manager = get_tree().get_first_node_in_group("sleep_manager")

	if item_database == null and ResourceLoader.exists(MAIN_ITEM_DATABASE_PATH):
		item_database = load(MAIN_ITEM_DATABASE_PATH) as ItemDatabase

	if item_database != null:
		item_database.build_lookup()

func _on_command_input_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey

		if not key_event.pressed or key_event.echo:
			return

		if key_event.keycode == KEY_TAB:
			if autocomplete_active:
				move_autocomplete_selection(1)
			else:
				refresh_autocomplete_popup()

			command_input.accept_event()
			return

		if key_event.keycode == KEY_UP:
			if autocomplete_active:
				move_autocomplete_selection(-1)
			else:
				navigate_history(-1)

			command_input.accept_event()
			return

		if key_event.keycode == KEY_DOWN:
			if autocomplete_active:
				move_autocomplete_selection(1)
			else:
				navigate_history(1)

			command_input.accept_event()
			return

		if autocomplete_active and (
			key_event.keycode == KEY_ENTER
			or key_event.keycode == KEY_KP_ENTER
			or key_event.keycode == KEY_RIGHT
		):
			accept_autocomplete()
			command_input.accept_event()
			return

		if autocomplete_active and key_event.keycode == KEY_ESCAPE:
			hide_autocomplete_popup()
			command_input.accept_event()
			return

func _on_command_input_text_changed(_new_text: String) -> void:
	if autocomplete_active:
		refresh_autocomplete_popup()



func reset_autocomplete() -> void:
	hide_autocomplete_popup()

func refresh_autocomplete_popup() -> void:
	ensure_refs()

	var text: String = command_input.text
	var caret: int = command_input.caret_column
	var before_caret: String = text.substr(0, caret)
	var ends_with_space: bool = before_caret.ends_with(" ")
	var parts: PackedStringArray = before_caret.split(" ", false)

	autocomplete_matches.clear()
	autocomplete_index = 0
	autocomplete_kind = ""
	autocomplete_token_start = caret
	autocomplete_token_end = caret

	if parts.is_empty():
		autocomplete_kind = "command"
		autocomplete_token_start = 0
		autocomplete_token_end = 0
		autocomplete_matches = get_command_matches("")
		show_autocomplete_popup(autocomplete_matches, autocomplete_index)
		return

	var command_name: String = parts[0].to_lower()

	if parts.size() == 1 and not ends_with_space:
		autocomplete_kind = "command"
		autocomplete_token_start = get_current_token_start()
		autocomplete_token_end = get_current_token_end()
		autocomplete_matches = get_command_matches(command_name)
		show_autocomplete_popup(autocomplete_matches, autocomplete_index)
		return

	if command_name == "add_item" or command_name == "give":
		if parts.size() == 1 and ends_with_space:
			autocomplete_kind = "item"
			autocomplete_token_start = caret
			autocomplete_token_end = caret
			autocomplete_matches = get_item_matches("")
			show_autocomplete_popup(autocomplete_matches, autocomplete_index)
			return

		if parts.size() == 2 and not ends_with_space:
			var prefix: String = parts[1]

			autocomplete_kind = "item"
			autocomplete_token_start = get_current_token_start()
			autocomplete_token_end = get_current_token_end()
			autocomplete_matches = get_item_matches(prefix)
			show_autocomplete_popup(autocomplete_matches, autocomplete_index)
			return

	hide_autocomplete_popup()

func move_autocomplete_selection(direction: int) -> void:
	if not autocomplete_active:
		return

	if autocomplete_matches.is_empty():
		hide_autocomplete_popup()
		return

	autocomplete_index += direction

	if autocomplete_index < 0:
		autocomplete_index = autocomplete_matches.size() - 1

	if autocomplete_index >= autocomplete_matches.size():
		autocomplete_index = 0

	show_autocomplete_popup(autocomplete_matches, autocomplete_index)


func get_command_matches(prefix: String) -> Array[String]:
	var commands: Array[String] = [
		"help",
		"clear",
		"add_item",
		"devmode",
		"set_time",
		"set_timescale",
		"pause_time",
		"sleep",
		"set_wind_strength",
		"set_wind_speed",
		"set_wind_scale",
	]

	var matches: Array[String] = []

	for command: String in commands:
		if command.begins_with(prefix):
			matches.append(command)

	matches.sort()
	return matches


func get_item_matches(prefix: String) -> Array[String]:
	var item_ids: Array[String] = get_all_item_ids()
	var matches: Array[String] = []

	for item_id: String in item_ids:
		if item_id.begins_with(prefix):
			matches.append(item_id)

	matches.sort()
	return matches


func cycle_autocomplete() -> void:
	if autocomplete_matches.is_empty():
		hide_autocomplete_popup()
		return

	autocomplete_index += 1

	if autocomplete_index >= autocomplete_matches.size():
		autocomplete_index = 0

	show_autocomplete_popup(autocomplete_matches, autocomplete_index)


func accept_autocomplete() -> void:
	if not autocomplete_active:
		return

	if autocomplete_matches.is_empty():
		hide_autocomplete_popup()
		return

	var selected: String = autocomplete_matches[autocomplete_index]

	var text: String = command_input.text
	var before: String = text.substr(0, autocomplete_token_start)
	var after: String = text.substr(autocomplete_token_end)

	command_input.text = before + selected + after
	command_input.caret_column = autocomplete_token_start + selected.length()

	hide_autocomplete_popup()


func get_current_token_start() -> int:
	var text: String = command_input.text
	var caret: int = command_input.caret_column
	var start: int = caret - 1

	while start >= 0 and text[start] != " ":
		start -= 1

	return start + 1


func get_current_token_end() -> int:
	var text: String = command_input.text
	var caret: int = command_input.caret_column
	var end: int = caret

	while end < text.length() and text[end] != " ":
		end += 1

	return end

func get_all_item_ids() -> Array[String]:
	var result: Array[String] = []

	if item_database == null:
		return result

	var items_variant: Variant = item_database.get("items")

	if items_variant is Array:
		for item in items_variant:
			if item is ItemDefinition:
				var definition := item as ItemDefinition

				if definition.id != &"":
					result.append(String(definition.id))

	result.sort()
	return result

func _on_command_submitted(command: String) -> void:
	command = command.strip_edges()

	if command == "":
		return

	log_command(command)
	command_input.clear()
	add_to_history(command)
	execute_command(command)
	reset_autocomplete()
func add_to_history(command: String) -> void:
	if command_history.is_empty() or command_history.back() != command:
		command_history.append(command)

	if command_history.size() > MAX_COMMAND_HISTORY:
		command_history.pop_front()

	history_index = -1
	history_draft = ""


func navigate_history(direction: int) -> void:
	if command_history.is_empty():
		return

	if history_index == -1:
		history_draft = command_input.text
		history_index = command_history.size()

	history_index += direction

	if history_index < 0:
		history_index = 0

	if history_index >= command_history.size():
		history_index = -1
		command_input.text = history_draft
		command_input.caret_column = command_input.text.length()
		return

	command_input.text = command_history[history_index]
	command_input.caret_column = command_input.text.length()
	
func execute_command(command: String) -> void:
	ensure_refs()

	var parts: PackedStringArray = command.split(" ", false)

	if parts.is_empty():
		return

	var command_name: String = parts[0].to_lower()

	match command_name:
		"help":
			command_help()

		"clear":
			command_clear()

		"add_item":
			command_add_item(parts)

		"devmode":
			command_devmode(parts)

		"set_time":
			command_set_time(parts)

		"set_timescale":
			command_set_timescale(parts)

		"pause_time":
			command_pause_time()

		"sleep":
			command_sleep()

		"set_wind_strength":
			command_wind_float("wind_strength", parts)

		"set_wind_speed":
			command_wind_float("wind_speed", parts)

		"set_wind_scale":
			command_wind_float("wind_scale", parts)

		_:
			log_error("Unknown command: %s" % command_name)


func command_help() -> void:
	log_info("[b]Commands[/b]")
	log_info("help")
	log_info("clear")
	log_info("devmode on/off/toggle")
	log_info("sleep")
	log_info("add_item <item_id> <amount>")
	log_info("set_time <hour> <minute> OR set_time <day> <hour> <minute>")
	log_info("set_timescale <value>")
	log_info("pause_time")
	log_info("set_wind_strength <value>")
	log_info("set_wind_speed <value>")
	log_info("set_wind_scale <value>")

func command_clear() -> void:
	output_text.clear()


func command_add_item(parts: PackedStringArray) -> void:
	if parts.size() < 2:
		log_error("Usage: add_item <item_id> <amount>")
		return

	if player_inventory == null:
		log_error("PlayerInventory not found.")
		return

	if item_database == null:
		log_error("ItemDatabase not found.")
		return

	var item_id := StringName(parts[1])
	var amount := 1

	if parts.size() >= 3:
		if not parts[2].is_valid_int():
			log_error("Amount must be an integer.")
			return

		amount = int(parts[2])

	if amount <= 0:
		log_error("Amount must be greater than 0.")
		return

	var definition: ItemDefinition = item_database.get_item(item_id)

	if definition == null:
		log_error("Item not found: %s" % item_id)
		return

	var item := ItemInstanceData.new()
	item.definition = definition
	item.amount = amount

	var remaining: ItemInstanceData = player_inventory.add_item(item)

	if remaining == null:
		log_success("Added %sx %s" % [amount, item_id])
	else:
		var added_amount := amount - remaining.amount
		log_warning("Inventory full. Added %s, remaining %s." % [added_amount, remaining.amount])


func command_devmode(parts: PackedStringArray) -> void:
	if parts.size() < 2:
		log_info("Dev mode: %s" % DevManager.dev_mode)
		return

	var value := parts[1].to_lower()

	match value:
		"on", "true", "1":
			DevManager.set_dev_mode(true)
			log_success("Dev mode ON")

		"off", "false", "0":
			DevManager.set_dev_mode(false)
			log_success("Dev mode OFF")

		"toggle":
			DevManager.toggle_dev_mode()
			log_success("Dev mode: %s" % DevManager.dev_mode)

		_:
			log_error("Usage: devmode on/off/toggle")


func command_set_time(parts: PackedStringArray) -> void:
	if time_manager == null:
		log_error("TimeManager not found.")
		return
	
	if not time_manager.has_method("set_time"):
		log_error("TimeManager has no set_time(day, hour, minute) method.")
		return
	if parts.size() == 1:
		log_info("Day %s, %02d:%02d" % [
			int(time_manager.get("current_day")),
			int(time_manager.get("current_hour")),
			int(time_manager.get("current_minute"))
		])
		return
	var day: int = 1
	var hour: int = 0
	var minute: int = 0

	# time 12 45
	if parts.size() == 3:
		if not parts[1].is_valid_int() or not parts[2].is_valid_int():
			log_error("Usage: time <hour> <minute> OR time <day> <hour> <minute>")
			return

		var current_day_value: Variant = time_manager.get("current_day")
		day = int(current_day_value)
		hour = int(parts[1])
		minute = int(parts[2])

	# time 4 12 45
	elif parts.size() == 4:
		if not parts[1].is_valid_int() or not parts[2].is_valid_int() or not parts[3].is_valid_int():
			log_error("Usage: time <hour> <minute> OR time <day> <hour> <minute>")
			return

		day = int(parts[1])
		hour = int(parts[2])
		minute = int(parts[3])

	else:
		log_error("Usage: time <hour> <minute> OR time <day> <hour> <minute>")
		return

	if day < 1:
		log_error("Day must be 1 or higher.")
		return

	if hour < 0 or hour > 23:
		log_error("Hour must be between 0 and 23.")
		return

	if minute < 0 or minute > 59:
		log_error("Minute must be between 0 and 59.")
		return

	time_manager.call("set_time", day, hour, minute)

	log_success("Time set to Day %s, %02d:%02d" % [day, hour, minute])

func command_set_timescale(parts: PackedStringArray) -> void:
	if time_manager == null:
		log_error("TimeManager not found.")
		return

	if parts.size() == 1:
		log_info("timescale = %s" % [time_manager.get("time_scale")])
		return

	if parts.size() != 2:
		log_error("Usage: timescale <value>")
		return

	if not parts[1].is_valid_float():
		log_error("Timescale must be a number.")
		return

	var value: float = float(parts[1])

	if not time_manager.has_method("set_time_scale"):
		log_error("TimeManager has no set_time_scale(value) method.")
		return

	time_manager.call("set_time_scale", value)
	log_success("timescale = %s" % [value])


func command_pause_time() -> void:
	if time_manager == null:
		log_error("TimeManager not found.")
		return

	if not time_manager.has_method("toggle_pause"):
		log_error("TimeManager has no toggle_pause() method.")
		return

	time_manager.call("toggle_pause")
	log_success("Time pause toggled.")


func command_sleep() -> void:
	if sleep_manager == null:
		log_error("SleepManager not found.")
		return

	if not sleep_manager.has_method("try_sleep"):
		log_error("SleepManager has no try_sleep() method.")
		return

	sleep_manager.call("try_sleep")
	log_success("Sleep triggered.")


func command_wind_float(property_name: String, parts: PackedStringArray) -> void:
	if wind_manager == null:
		log_error("WindManager not found.")
		return

	if parts.size() == 1:
		log_info("%s = %s" % [property_name, wind_manager.get(property_name)])
		return

	if parts.size() != 2:
		log_error("Usage: %s <value>" % property_name)
		return

	if not parts[1].is_valid_float():
		log_error("Value must be a number.")
		return

	var value: float = float(parts[1])
	wind_manager.set(property_name, value)

	if wind_manager.has_method("apply_wind"):
		wind_manager.call("apply_wind")

	log_success("%s = %s" % [property_name, value])


func log_command(message: String) -> void:
	append_line("[color=gray]> %s[/color]" % message)


func log_info(message: String) -> void:
	append_line("[color=white]%s[/color]" % message)


func log_success(message: String) -> void:
	append_line("[color=lime]%s[/color]" % message)


func log_warning(message: String) -> void:
	append_line("[color=yellow]%s[/color]" % message)


func log_error(message: String) -> void:
	append_line("[color=red]%s[/color]" % message)


func append_line(message: String) -> void:
	output_text.append_text(message + "\n")
	output_text.scroll_to_line(output_text.get_line_count())
