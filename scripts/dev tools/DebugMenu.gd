class_name DebugMenu
extends Control

@onready var panel_container: PanelContainer = $PanelContainer

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
