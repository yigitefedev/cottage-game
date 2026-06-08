extends Node

signal dev_mode_changed(enabled: bool)

var dev_mode := false


func set_dev_mode(enabled: bool) -> void:
	if dev_mode == enabled:
		return

	dev_mode = enabled
	dev_mode_changed.emit(dev_mode)

	print("[DevManager] Dev Mode: ", dev_mode)


func toggle_dev_mode() -> void:
	set_dev_mode(!dev_mode)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_dev_mode"):
		toggle_dev_mode()
