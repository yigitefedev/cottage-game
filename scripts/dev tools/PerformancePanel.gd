class_name PerformancePanel
extends PanelContainer

const UPDATE_INTERVAL: float = 0.25
const WORST_FRAME_WINDOW: float = 1.0
const COLOR_HOLD_SECONDS: float = 0.35
const BYTES_PER_MIB: float = 1048576.0

const COLOR_GOOD: Color = Color(0.45, 1.0, 0.45)
const COLOR_WARN: Color = Color(1.0, 0.65, 0.18)
const COLOR_BAD: Color = Color(1.0, 0.22, 0.18)
const COLOR_CRITICAL: Color = Color(0.45, 0.0, 0.0)
const COLOR_NEUTRAL: Color = Color.WHITE

const COLORED_METRICS: PackedStringArray = [
	"fps",
	"frame_time",
	"worst_frame",
	"process_time",
	"physics_time",
]

var _value_labels: Dictionary = {}
var _color_states: Dictionary = {}
var _frame_samples: Array[Vector2] = []
var _sample_time: float = 0.0
var _update_timer: float = 0.0
var _current_frame_time_ms: float = 0.0
var _current_worst_frame_ms: float = 0.0


func _ready() -> void:
	add_to_group("performance_panel")
	_build_ui()
	visible = DevManager.dev_mode
	DevManager.dev_mode_changed.connect(_on_dev_mode_changed)
	_refresh_values()


func _process(delta: float) -> void:
	_sample_frame_time(delta)
	_update_timer += delta
	if _update_timer < UPDATE_INTERVAL:
		return

	_update_timer = 0.0
	_refresh_values()


func toggle_visible() -> bool:
	visible = not visible
	return visible


func set_panel_visible(enabled: bool) -> void:
	visible = enabled


func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -230.0
	offset_right = -12.0
	offset_top = 12.0
	offset_bottom = 0.0

	var style_box: StyleBoxFlat = StyleBoxFlat.new()
	style_box.bg_color = Color(0.02, 0.025, 0.03, 0.78)
	style_box.border_color = Color(1.0, 1.0, 1.0, 0.16)
	style_box.set_border_width_all(1)
	style_box.set_corner_radius_all(3)
	add_theme_stylebox_override("panel", style_box)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var rows: VBoxContainer = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 1)
	margin.add_child(rows)

	var title: Label = Label.new()
	title.text = "Performance"
	title.add_theme_color_override("font_color", Color(0.75, 0.84, 1.0))
	rows.add_child(title)

	_add_row(rows, "fps", "FPS")
	_add_row(rows, "frame_time", "Frame Time")
	_add_row(rows, "worst_frame", "Worst Frame")
	_add_row(rows, "process_time", "Process")
	_add_row(rows, "physics_time", "Physics")
	_add_row(rows, "draw_calls", "Draw Calls")
	_add_row(rows, "visible_objects", "Visible Objects")
	_add_row(rows, "primitives", "Primitives")
	_add_row(rows, "ram", "RAM")
	_add_row(rows, "vram", "VRAM")
	_add_row(rows, "node_count", "Node Count")
	_add_row(rows, "orphan_nodes", "Orphan Nodes")


func _add_row(parent: VBoxContainer, metric_id: String, label_text: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	parent.add_child(row)

	var name_label: Label = Label.new()
	name_label.text = label_text
	name_label.custom_minimum_size = Vector2(122.0, 0.0)
	name_label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	row.add_child(name_label)

	var value_label: Label = Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(76.0, 0.0)
	value_label.add_theme_color_override("font_color", COLOR_NEUTRAL)
	row.add_child(value_label)

	_value_labels[metric_id] = value_label


func _sample_frame_time(delta: float) -> void:
	_sample_time += delta
	_current_frame_time_ms = delta * 1000.0
	_frame_samples.append(Vector2(_sample_time, _current_frame_time_ms))

	while not _frame_samples.is_empty() and _sample_time - _frame_samples[0].x > WORST_FRAME_WINDOW:
		_frame_samples.pop_front()

	_current_worst_frame_ms = 0.0
	for sample: Vector2 in _frame_samples:
		_current_worst_frame_ms = maxf(_current_worst_frame_ms, sample.y)

	for metric_key: Variant in _color_states.keys():
		var metric_id: String = String(metric_key)
		var state: Dictionary = _color_states[metric_id]
		state["hold"] = maxf(float(state["hold"]) - delta, 0.0)
		_color_states[metric_id] = state


func _refresh_values() -> void:
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	var process_time_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_time_ms: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var ram_mib: float = Performance.get_monitor(Performance.MEMORY_STATIC) / BYTES_PER_MIB
	var vram_mib: float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / BYTES_PER_MIB

	_set_metric("fps", "%.0f" % fps, _color_for_fps(fps))
	_set_metric("frame_time", "%.2f ms" % _current_frame_time_ms, _color_for_frame_time(_current_frame_time_ms))
	_set_metric("worst_frame", "%.2f ms" % _current_worst_frame_ms, _color_for_worst_frame(_current_worst_frame_ms))
	_set_metric("process_time", "%.2f ms" % process_time_ms, _color_for_process_time(process_time_ms))
	_set_metric("physics_time", "%.2f ms" % physics_time_ms, _color_for_physics_time(physics_time_ms))
	_set_metric("draw_calls", "%d" % int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), COLOR_NEUTRAL)
	_set_metric("visible_objects", "%d" % int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)), COLOR_NEUTRAL)
	_set_metric("primitives", "%d" % int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)), COLOR_NEUTRAL)
	_set_metric("ram", "%.1f MiB" % ram_mib, COLOR_NEUTRAL)
	_set_metric("vram", "%.1f MiB" % vram_mib, COLOR_NEUTRAL)
	_set_metric("node_count", "%d" % int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), COLOR_NEUTRAL)
	_set_metric("orphan_nodes", "%d" % int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), COLOR_NEUTRAL)


func _set_metric(metric_id: String, text: String, color: Color) -> void:
	var value_label: Label = _value_labels.get(metric_id) as Label
	if value_label == null:
		return

	value_label.text = text
	if not COLORED_METRICS.has(metric_id):
		value_label.add_theme_color_override("font_color", COLOR_NEUTRAL)
		return

	var stable_color: Color = _get_stable_color(metric_id, color)
	value_label.add_theme_color_override("font_color", stable_color)


func _get_stable_color(metric_id: String, desired_color: Color) -> Color:
	if not _color_states.has(metric_id):
		_color_states[metric_id] = {
			"color": desired_color,
			"hold": COLOR_HOLD_SECONDS,
		}
		return desired_color

	var state: Dictionary = _color_states[metric_id]
	var current_color: Color = state["color"]
	var hold: float = float(state["hold"])
	if current_color != desired_color and hold <= 0.0:
		state["color"] = desired_color
		state["hold"] = COLOR_HOLD_SECONDS
		_color_states[metric_id] = state
		return desired_color

	return current_color


func _color_for_fps(value: float) -> Color:
	if value >= 60.0:
		return COLOR_GOOD
	if value >= 50.0:
		return COLOR_WARN
	if value >= 30.0:
		return COLOR_BAD
	return COLOR_CRITICAL


func _color_for_frame_time(value: float) -> Color:
	if value <= 16.7:
		return COLOR_GOOD
	if value <= 22.0:
		return COLOR_WARN
	if value <= 33.3:
		return COLOR_BAD
	return COLOR_CRITICAL


func _color_for_worst_frame(value: float) -> Color:
	if value <= 20.0:
		return COLOR_GOOD
	if value <= 30.0:
		return COLOR_WARN
	if value <= 50.0:
		return COLOR_BAD
	return COLOR_CRITICAL


func _color_for_process_time(value: float) -> Color:
	if value <= 5.0:
		return COLOR_GOOD
	if value <= 8.0:
		return COLOR_WARN
	if value <= 12.0:
		return COLOR_BAD
	return COLOR_CRITICAL


func _color_for_physics_time(value: float) -> Color:
	if value <= 2.0:
		return COLOR_GOOD
	if value <= 4.0:
		return COLOR_WARN
	if value <= 8.0:
		return COLOR_BAD
	return COLOR_CRITICAL


func _on_dev_mode_changed(enabled: bool) -> void:
	visible = enabled
