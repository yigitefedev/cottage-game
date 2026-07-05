extends Node

signal dev_mode_changed(enabled: bool)

var dev_mode := true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_dev_mode"):
		toggle_dev_mode()


func set_dev_mode(enabled: bool) -> void:
	if dev_mode == enabled:
		return

	dev_mode = enabled
	dev_mode_changed.emit(dev_mode)

	print("Dev Mode: ", dev_mode)


func toggle_dev_mode() -> void:
	set_dev_mode(!dev_mode)

signal gameplay_input_lock_changed(locked: bool)

var gameplay_input_locked := false


func set_gameplay_input_locked(locked: bool) -> void:
	if gameplay_input_locked == locked:
		return

	gameplay_input_locked = locked
	gameplay_input_lock_changed.emit(gameplay_input_locked)


func is_gameplay_input_locked() -> bool:
	return gameplay_input_locked
