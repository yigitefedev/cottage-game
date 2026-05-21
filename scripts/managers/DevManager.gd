extends Node

var dev_mode := true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_dev_mode"):
		dev_mode = !dev_mode
		print("Dev Mode: ", dev_mode)
