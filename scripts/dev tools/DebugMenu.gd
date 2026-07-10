class_name DebugMenu
extends Control

const WEATHER_NAMES: PackedStringArray = ["Sunny", "Cloudy", "Rain", "Foggy", "Storm", "Windy"]
const WEATHER_SLIDER_PROPERTIES: Array[Array] = [
	[&"weather_desaturation", "Desaturation", 0.0, 1.0, 0.01],
	[&"sun_energy_multiplier", "Sun Energy", 0.0, 3.0, 0.01],
	[&"moon_energy_multiplier", "Moon Energy", 0.0, 3.0, 0.01],
	[&"ambient_energy_multiplier", "Ambient Energy", 0.0, 3.0, 0.01],
	[&"shadow_opacity_multiplier", "Shadow Opacity", 0.0, 3.0, 0.01],
	[&"tonemap_exposure_multiplier", "Exposure", 0.0, 3.0, 0.01],
	[&"fog_density_multiplier", "Fog Density", 0.0, 5.0, 0.01],
	[&"fog_height", "Fog Height", 0.0, 3.0, 0.01],
	[&"fog_height_density", "Fog Height Density", 0.0, 3.0, 0.01],
	[&"wind_strength_multiplier", "Wind Strength", 0.0, 5.0, 0.01],
	[&"wind_speed_multiplier", "Wind Speed", 0.0, 5.0, 0.01],
	[&"cloud_noise_threshold", "Cloud Threshold", 0.0, 1.0, 0.01],
	[&"rain_strength", "Rain Strength", 0.0, 10.0, 0.01],
	[&"rain_wind_velocity_multiplier", "Rain Wind Velocity", 0.0, 10.0, 0.01],
	[&"lightning_frequency", "Lightning / Min", 0.0, 10.0, 0.01],
]
const WEATHER_BOOL_PROPERTIES: Array[Array] = [
	[&"has_clouds", "Has Clouds"],
]
const WEATHER_COLOR_PROPERTIES: Array[Array] = [
	[&"weather_tint", "Weather Tint"],
]

@onready var panel_container: PanelContainer = $PanelContainer
@onready var tab_container: TabContainer = $PanelContainer/VBoxContainer/TabContainer

#griddebugger
@onready var grid_debugger_checkbox: CheckBox = $PanelContainer/VBoxContainer/TabContainer/Grid/GridDebuggerCheckBox
@onready var grid_debugger_controls: VBoxContainer = $PanelContainer/VBoxContainer/TabContainer/Grid/VBoxContainer
@onready var save_grid_button: Button = $PanelContainer/VBoxContainer/TabContainer/Grid/VBoxContainer/HBoxContainer/SaveGridButton
@onready var load_grid_button: Button = $PanelContainer/VBoxContainer/TabContainer/Grid/VBoxContainer/HBoxContainer/LoadGridButton
@onready var show_grid_data_checkbox: CheckBox = $PanelContainer/VBoxContainer/TabContainer/Grid/VBoxContainer/ShowGridDataCheckBox


#playertools
@onready var player_tools_checkbox: CheckBox = $PanelContainer/VBoxContainer/TabContainer/Player/PlayerToolsCheckBox
@onready var player_tools_controls: VBoxContainer = $PanelContainer/VBoxContainer/TabContainer/Player/PlayerToolsControls
@onready var refill_stamina_button: Button = $PanelContainer/VBoxContainer/TabContainer/Player/PlayerToolsControls/RefillStaminaButton

#time
@onready var time_tools_checkbox: CheckBox = $PanelContainer/VBoxContainer/TabContainer/Time/TimeToolsCheckBox
@onready var time_tools_controls: VBoxContainer = $PanelContainer/VBoxContainer/TabContainer/Time/TimeToolsControls
@onready var pause_time_button: Button = $PanelContainer/VBoxContainer/TabContainer/Time/TimeToolsControls/HBoxContainer/PauseTimeButton
@onready var sleep_button: Button = $PanelContainer/VBoxContainer/TabContainer/Time/TimeToolsControls/SleepButton
@onready var time_scale_1_button: Button = $PanelContainer/VBoxContainer/TabContainer/Time/TimeToolsControls/HBoxContainer/TimeScale1Button
@onready var time_scale_10_button: Button = $PanelContainer/VBoxContainer/TabContainer/Time/TimeToolsControls/HBoxContainer/TimeScale10Button
@onready var time_scale_200_button: Button = $PanelContainer/VBoxContainer/TabContainer/Time/TimeToolsControls/HBoxContainer/TimeScale200Button

#world
@onready var world_tools_checkbox: CheckBox = $PanelContainer/VBoxContainer/TabContainer/World/WorldToolsCheckBox
@onready var world_tools_controls: VBoxContainer = $PanelContainer/VBoxContainer/TabContainer/World/VBoxContainer
@onready var grass_visible_checkbox: CheckBox = $PanelContainer/VBoxContainer/TabContainer/World/VBoxContainer/GrassVisibleCheckBox
@onready var wind_strength_slider: HSlider = $PanelContainer/VBoxContainer/TabContainer/World/VBoxContainer/HBoxContainer/WindStrengthSlider
@onready var wind_speed_slider: HSlider = $PanelContainer/VBoxContainer/TabContainer/World/VBoxContainer/HBoxContainer2/WindSpeedSlider
@onready var wind_scale_slider: HSlider = $PanelContainer/VBoxContainer/TabContainer/World/VBoxContainer/HBoxContainer3/WindScaleSlider
@onready var wind_direction_x_slider: HSlider = $PanelContainer/VBoxContainer/TabContainer/World/VBoxContainer/HBoxContainer4/WindDirectionXSlider
@onready var wind_direction_z_slider: HSlider = $PanelContainer/VBoxContainer/TabContainer/World/VBoxContainer/HBoxContainer5/WindDirectionZSlider
@onready var default_wind_strength_button: Button = $PanelContainer/VBoxContainer/TabContainer/World/VBoxContainer/HBoxContainer/DefaultValuesButton
@onready var default_wind_speed_button: Button = $PanelContainer/VBoxContainer/TabContainer/World/VBoxContainer/HBoxContainer2/DefaultValuesButton
@onready var default_wind_scale_button: Button = $PanelContainer/VBoxContainer/TabContainer/World/VBoxContainer/HBoxContainer3/DefaultValuesButton
@onready var default_wind_direction_x_button: Button = $PanelContainer/VBoxContainer/TabContainer/World/VBoxContainer/HBoxContainer4/DefaultValuesButton
@onready var default_wind_direction_z_button: Button = $PanelContainer/VBoxContainer/TabContainer/World/VBoxContainer/HBoxContainer5/DefaultValuesButton

var dev_world_tools: DevWorldTools
var dev_time_tools: DevTimeTools
var dev_player_tools: DevPlayerTools
var dev_grid_debugger: DevGridDebugger
var grid_data_panel
var sky_manager: SkyManager
var weather_option_button: OptionButton
var weather_save_button: Button
var weather_status_label: Label
var weather_controls_container: VBoxContainer
var weather_controls: Dictionary = {}
var weather_saved_defaults: Dictionary = {}

func _ready() -> void:
	dev_grid_debugger = get_tree().get_first_node_in_group("dev_grid_debugger")
	grid_data_panel = get_tree().get_first_node_in_group("grid_data_panel")
	show_grid_data_checkbox.toggled.connect(_on_show_grid_data_toggled)
	if dev_grid_debugger != null:
		grid_debugger_checkbox.set_pressed_no_signal(dev_grid_debugger.tool_enabled)

	grid_debugger_checkbox.toggled.connect(_on_grid_debugger_toggled)
	save_grid_button.pressed.connect(_on_save_grid_pressed)
	load_grid_button.pressed.connect(_on_load_grid_pressed)
	_update_grid_debugger_controls()
	
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_container.mouse_filter = Control.MOUSE_FILTER_STOP
	
	dev_player_tools = get_tree().get_first_node_in_group("dev_player_tools")

	if dev_player_tools != null:
		player_tools_checkbox.set_pressed_no_signal(dev_player_tools.tool_enabled)

	_update_player_tools_controls()

	player_tools_checkbox.toggled.connect(_on_player_tools_toggled)
	refill_stamina_button.pressed.connect(_on_refill_stamina_pressed)
	
	dev_time_tools = get_tree().get_first_node_in_group("dev_time_tools")

	if dev_time_tools != null:
		time_tools_checkbox.set_pressed_no_signal(dev_time_tools.tool_enabled)

	_update_time_tools_controls()

	time_tools_checkbox.toggled.connect(_on_time_tools_toggled)
	pause_time_button.pressed.connect(_on_pause_time_pressed)
	sleep_button.pressed.connect(_on_sleep_pressed)
	time_scale_1_button.pressed.connect(_on_time_scale_1_pressed)
	time_scale_10_button.pressed.connect(_on_time_scale_10_pressed)
	time_scale_200_button.pressed.connect(_on_time_scale_200_pressed)

	dev_world_tools = get_tree().get_first_node_in_group("dev_world_tools")

	if dev_world_tools != null:
		world_tools_checkbox.set_pressed_no_signal(dev_world_tools.tool_enabled)
		dev_world_tools.ensure_refs()

		if dev_world_tools.grass != null:
			grass_visible_checkbox.set_pressed_no_signal(dev_world_tools.grass.visible)

		if dev_world_tools.wind_manager != null:
			wind_strength_slider.set_value_no_signal(dev_world_tools.wind_manager.wind_strength)
			wind_speed_slider.set_value_no_signal(dev_world_tools.wind_manager.wind_speed)
			wind_scale_slider.set_value_no_signal(dev_world_tools.wind_manager.wind_scale)
			wind_direction_x_slider.set_value_no_signal(dev_world_tools.wind_manager.wind_direction.x)
			wind_direction_z_slider.set_value_no_signal(dev_world_tools.wind_manager.wind_direction.z)

	_update_world_tools_controls()

	world_tools_checkbox.toggled.connect(_on_world_tools_toggled)
	grass_visible_checkbox.toggled.connect(_on_grass_visible_toggled)

	wind_strength_slider.value_changed.connect(_on_wind_strength_changed)
	wind_speed_slider.value_changed.connect(_on_wind_speed_changed)
	wind_scale_slider.value_changed.connect(_on_wind_scale_changed)
	wind_direction_x_slider.value_changed.connect(_on_wind_direction_x_changed)
	wind_direction_z_slider.value_changed.connect(_on_wind_direction_z_changed)
	default_wind_strength_button.pressed.connect(_on_default_wind_strength_pressed)
	default_wind_speed_button.pressed.connect(_on_default_wind_speed_pressed)
	default_wind_scale_button.pressed.connect(_on_default_wind_scale_pressed)
	default_wind_direction_x_button.pressed.connect(_on_default_wind_direction_x_pressed)
	default_wind_direction_z_button.pressed.connect(_on_default_wind_direction_z_pressed)
	_setup_weather_tab()
	

func _setup_weather_tab() -> void:
	sky_manager = get_tree().get_first_node_in_group("sky_manager") as SkyManager

	var weather_tab: VBoxContainer = VBoxContainer.new()
	weather_tab.name = "Weather"
	weather_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.add_child(weather_tab)

	var selector_row: HBoxContainer = HBoxContainer.new()
	weather_tab.add_child(selector_row)

	var selector_label: Label = Label.new()
	selector_label.text = "Weather"
	selector_label.custom_minimum_size = Vector2(72.0, 0.0)
	selector_row.add_child(selector_label)

	weather_option_button = OptionButton.new()
	weather_option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for weather_index: int in range(WEATHER_NAMES.size()):
		weather_option_button.add_item(WEATHER_NAMES[weather_index], weather_index)
	selector_row.add_child(weather_option_button)

	weather_save_button = Button.new()
	weather_save_button.text = "Save"
	selector_row.add_child(weather_save_button)

	var separator: HSeparator = HSeparator.new()
	weather_tab.add_child(separator)

	var scroll_container: ScrollContainer = ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(0.0, 360.0)
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	weather_tab.add_child(scroll_container)

	weather_controls_container = VBoxContainer.new()
	weather_controls_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(weather_controls_container)

	_build_weather_controls()

	weather_status_label = Label.new()
	weather_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	weather_tab.add_child(weather_status_label)

	weather_option_button.item_selected.connect(_on_weather_selected)
	weather_save_button.pressed.connect(_on_weather_save_pressed)
	_cache_weather_defaults()
	_refresh_weather_selection()


func _build_weather_controls() -> void:
	for property_data: Array in WEATHER_COLOR_PROPERTIES:
		var property_name: StringName = property_data[0]
		var label_text: String = property_data[1]
		_add_weather_color_row(property_name, label_text)

	for property_data: Array in WEATHER_BOOL_PROPERTIES:
		var property_name: StringName = property_data[0]
		var label_text: String = property_data[1]
		_add_weather_bool_row(property_name, label_text)

	for property_data: Array in WEATHER_SLIDER_PROPERTIES:
		var property_name: StringName = property_data[0]
		var label_text: String = property_data[1]
		var min_value: float = float(property_data[2])
		var max_value: float = float(property_data[3])
		var step: float = float(property_data[4])
		_add_weather_slider_row(property_name, label_text, min_value, max_value, step)


func _add_weather_slider_row(property_name: StringName, label_text: String, min_value: float, max_value: float, step: float) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	weather_controls_container.add_child(row)

	var default_button: Button = _create_weather_default_button()
	default_button.pressed.connect(_on_weather_default_pressed.bind(property_name))
	row.add_child(default_button)

	var property_label: Label = _create_weather_property_label(label_text)
	row.add_child(property_label)

	var slider: HSlider = HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_weather_float_changed.bind(property_name))
	row.add_child(slider)

	var value_label: Label = Label.new()
	value_label.custom_minimum_size = Vector2(48.0, 0.0)
	row.add_child(value_label)

	weather_controls[property_name] = {
		"type": "float",
		"control": slider,
		"value_label": value_label,
	}


func _add_weather_bool_row(property_name: StringName, label_text: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	weather_controls_container.add_child(row)

	var default_button: Button = _create_weather_default_button()
	default_button.pressed.connect(_on_weather_default_pressed.bind(property_name))
	row.add_child(default_button)

	var property_label: Label = _create_weather_property_label(label_text)
	row.add_child(property_label)

	var check_box: CheckBox = CheckBox.new()
	check_box.text = "Enabled"
	check_box.toggled.connect(_on_weather_bool_changed.bind(property_name))
	row.add_child(check_box)

	weather_controls[property_name] = {
		"type": "bool",
		"control": check_box,
	}


func _add_weather_color_row(property_name: StringName, label_text: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	weather_controls_container.add_child(row)

	var default_button: Button = _create_weather_default_button()
	default_button.pressed.connect(_on_weather_default_pressed.bind(property_name))
	row.add_child(default_button)

	var property_label: Label = _create_weather_property_label(label_text)
	row.add_child(property_label)

	var color_picker: ColorPickerButton = ColorPickerButton.new()
	color_picker.custom_minimum_size = Vector2(110.0, 0.0)
	color_picker.color_changed.connect(_on_weather_color_changed.bind(property_name))
	row.add_child(color_picker)

	weather_controls[property_name] = {
		"type": "color",
		"control": color_picker,
	}


func _create_weather_default_button() -> Button:
	var default_button: Button = Button.new()
	default_button.text = "Def"
	default_button.custom_minimum_size = Vector2(40.0, 0.0)
	return default_button


func _create_weather_property_label(label_text: String) -> Label:
	var property_label: Label = Label.new()
	property_label.text = label_text
	property_label.custom_minimum_size = Vector2(128.0, 0.0)
	property_label.clip_text = true
	return property_label


func _cache_weather_defaults() -> void:
	weather_saved_defaults.clear()

	if sky_manager == null:
		return

	for weather_index: int in range(WEATHER_NAMES.size()):
		var profile: Resource = sky_manager.get_weather_profile(weather_index)
		weather_saved_defaults[weather_index] = _get_weather_profile_values(profile)


func _refresh_weather_selection() -> void:
	if sky_manager == null:
		_set_weather_status("SkyManager not found.")
		weather_save_button.disabled = true
		weather_option_button.disabled = true
		return

	weather_save_button.disabled = false
	weather_option_button.disabled = false
	weather_option_button.select(int(sky_manager.active_weather))
	_refresh_weather_controls()


func _refresh_weather_controls() -> void:
	var profile: Resource = _get_selected_weather_profile()
	if profile == null:
		_set_weather_status("Weather profile not found.")
		return

	for property_name: StringName in weather_controls.keys():
		_set_weather_control_value(property_name, profile.get(property_name))

	_set_weather_status("")


func _set_weather_control_value(property_name: StringName, value: Variant) -> void:
	var control_data: Dictionary = weather_controls[property_name]
	var control_type: String = control_data["type"]

	match control_type:
		"float":
			var slider: HSlider = control_data["control"] as HSlider
			var value_label: Label = control_data["value_label"] as Label
			var float_value: float = 0.0
			if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
				float_value = float(value)
			slider.set_value_no_signal(float_value)
			value_label.text = "%.2f" % float_value

		"bool":
			var check_box: CheckBox = control_data["control"] as CheckBox
			if typeof(value) == TYPE_BOOL:
				check_box.set_pressed_no_signal(bool(value))

		"color":
			var color_picker: ColorPickerButton = control_data["control"] as ColorPickerButton
			if typeof(value) == TYPE_COLOR:
				var color_value: Color = value
				color_picker.color = color_value


func _get_selected_weather_profile() -> Resource:
	if sky_manager == null or weather_option_button == null:
		return null

	return sky_manager.get_weather_profile(weather_option_button.get_selected_id())


func _get_weather_profile_values(profile: Resource) -> Dictionary:
	var values: Dictionary = {}
	if profile == null:
		return values

	for property_data: Array in WEATHER_COLOR_PROPERTIES:
		var property_name: StringName = property_data[0]
		values[property_name] = profile.get(property_name)

	for property_data: Array in WEATHER_BOOL_PROPERTIES:
		var property_name: StringName = property_data[0]
		values[property_name] = profile.get(property_name)

	for property_data: Array in WEATHER_SLIDER_PROPERTIES:
		var property_name: StringName = property_data[0]
		values[property_name] = profile.get(property_name)

	return values


func _get_saved_weather_profile_values(weather_index: int, profile: Resource) -> Dictionary:
	if profile != null and profile.resource_path != "" and ResourceLoader.exists(profile.resource_path):
		var disk_profile: Resource = ResourceLoader.load(profile.resource_path, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource
		if disk_profile != null:
			return _get_weather_profile_values(disk_profile)

	if weather_saved_defaults.has(weather_index):
		return weather_saved_defaults[weather_index]

	return {}


func _set_selected_weather_property(property_name: StringName, value: Variant) -> void:
	var profile: Resource = _get_selected_weather_profile()
	if profile == null:
		return

	profile.set(property_name, value)
	if sky_manager != null:
		sky_manager.apply_weather_now()


func _on_weather_selected(index: int) -> void:
	if sky_manager != null:
		sky_manager.set_active_weather(index)
	_refresh_weather_controls()


func _on_weather_float_changed(value: float, property_name: StringName) -> void:
	_set_selected_weather_property(property_name, value)
	_set_weather_control_value(property_name, value)


func _on_weather_bool_changed(enabled: bool, property_name: StringName) -> void:
	_set_selected_weather_property(property_name, enabled)


func _on_weather_color_changed(color: Color, property_name: StringName) -> void:
	_set_selected_weather_property(property_name, color)


func _on_weather_default_pressed(property_name: StringName) -> void:
	var weather_index: int = weather_option_button.get_selected_id()
	var profile: Resource = _get_selected_weather_profile()
	var saved_values: Dictionary = _get_saved_weather_profile_values(weather_index, profile)
	if not saved_values.has(property_name):
		return

	var saved_value: Variant = saved_values[property_name]
	_set_selected_weather_property(property_name, saved_value)
	_set_weather_control_value(property_name, saved_value)
	_set_weather_status("Default restored for %s." % String(property_name))


func _on_weather_save_pressed() -> void:
	var weather_index: int = weather_option_button.get_selected_id()
	var profile: Resource = _get_selected_weather_profile()
	if profile == null:
		_set_weather_status("Weather profile not found.")
		return

	if profile.resource_path == "":
		_set_weather_status("Profile has no resource path.")
		return

	var error: Error = ResourceSaver.save(profile, profile.resource_path)
	if error != OK:
		_set_weather_status("Save failed: %s" % error_string(error))
		return

	weather_saved_defaults[weather_index] = _get_weather_profile_values(profile)
	_set_weather_status("Saved %s." % profile.resource_path)


func _set_weather_status(message: String) -> void:
	if weather_status_label == null:
		return

	weather_status_label.text = message


func _on_show_grid_data_toggled(enabled: bool) -> void:
	if grid_data_panel == null:
		grid_data_panel = get_tree().get_first_node_in_group("grid_data_panel")

	if grid_data_panel != null:
		grid_data_panel.set_show_data(enabled)
		
func _on_default_wind_strength_pressed() -> void:
	if dev_world_tools != null:
		wind_strength_slider.set_value_no_signal(dev_world_tools.reset_wind_strength())


func _on_default_wind_speed_pressed() -> void:
	if dev_world_tools != null:
		wind_speed_slider.set_value_no_signal(dev_world_tools.reset_wind_speed())


func _on_default_wind_scale_pressed() -> void:
	if dev_world_tools != null:
		wind_scale_slider.set_value_no_signal(dev_world_tools.reset_wind_scale())


func _on_default_wind_direction_x_pressed() -> void:
	if dev_world_tools != null:
		wind_direction_x_slider.set_value_no_signal(dev_world_tools.reset_wind_direction_x())


func _on_default_wind_direction_z_pressed() -> void:
	if dev_world_tools != null:
		wind_direction_z_slider.set_value_no_signal(dev_world_tools.reset_wind_direction_z())
		
func _on_world_tools_toggled(enabled: bool) -> void:
	if dev_world_tools == null:
		dev_world_tools = get_tree().get_first_node_in_group("dev_world_tools")

	if dev_world_tools != null:
		dev_world_tools.set_enabled(enabled)

	_update_world_tools_controls()


func _update_world_tools_controls() -> void:
	world_tools_controls.visible = world_tools_checkbox.button_pressed


func _on_grass_visible_toggled(enabled: bool) -> void:
	if dev_world_tools != null:
		dev_world_tools.set_grass_visible(enabled)


func _on_wind_strength_changed(value: float) -> void:
	if dev_world_tools != null:
		dev_world_tools.set_wind_strength(value)


func _on_wind_speed_changed(value: float) -> void:
	if dev_world_tools != null:
		dev_world_tools.set_wind_speed(value)


func _on_wind_scale_changed(value: float) -> void:
	if dev_world_tools != null:
		dev_world_tools.set_wind_scale(value)


func _on_wind_direction_x_changed(value: float) -> void:
	if dev_world_tools != null:
		dev_world_tools.set_wind_direction_x(value)


func _on_wind_direction_z_changed(value: float) -> void:
	if dev_world_tools != null:
		dev_world_tools.set_wind_direction_z(value)
		
func _on_player_tools_toggled(enabled: bool) -> void:
	if dev_player_tools == null:
		dev_player_tools = get_tree().get_first_node_in_group("dev_player_tools")

	if dev_player_tools != null:
		dev_player_tools.tool_enabled = enabled

	_update_player_tools_controls()


func _on_refill_stamina_pressed() -> void:
	if dev_player_tools == null:
		dev_player_tools = get_tree().get_first_node_in_group("dev_player_tools")

	if dev_player_tools != null:
		dev_player_tools.refill_stamina()


func _update_player_tools_controls() -> void:
	player_tools_controls.visible = player_tools_checkbox.button_pressed
func _on_grid_debugger_toggled(enabled: bool) -> void:
	if dev_grid_debugger == null:
		dev_grid_debugger = get_tree().get_first_node_in_group("dev_grid_debugger")

	if dev_grid_debugger != null:
		dev_grid_debugger.tool_enabled = enabled
	_update_grid_debugger_controls()

func _update_grid_debugger_controls() -> void:
	var enabled := grid_debugger_checkbox.button_pressed

	grid_debugger_controls.visible = enabled
func _on_save_grid_pressed() -> void:
	if dev_grid_debugger != null:
		dev_grid_debugger.save_grid()


func _on_load_grid_pressed() -> void:
	if dev_grid_debugger != null:
		dev_grid_debugger.load_grid()
		

func _on_time_tools_toggled(enabled: bool) -> void:
	if dev_time_tools == null:
		dev_time_tools = get_tree().get_first_node_in_group("dev_time_tools")

	if dev_time_tools != null:
		dev_time_tools.set_enabled(enabled)

	_update_time_tools_controls()


func _update_time_tools_controls() -> void:
	time_tools_controls.visible = time_tools_checkbox.button_pressed

func _on_pause_time_pressed() -> void:
	if dev_time_tools != null:
		dev_time_tools.toggle_pause()


func _on_sleep_pressed() -> void:
	if dev_time_tools != null:
		dev_time_tools.sleep()

func _on_time_scale_1_pressed() -> void:
	if dev_time_tools != null:
		dev_time_tools.set_time_scale(1.0)


func _on_time_scale_10_pressed() -> void:
	if dev_time_tools != null:
		dev_time_tools.set_time_scale(10.0)


func _on_time_scale_200_pressed() -> void:
	if dev_time_tools != null:
		dev_time_tools.set_time_scale(200.0)
