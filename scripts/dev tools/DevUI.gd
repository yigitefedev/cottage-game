extends Control

func _ready() -> void:
	visible = DevManager.dev_mode

	DevManager.dev_mode_changed.connect(_on_dev_mode_changed)


func _on_dev_mode_changed(enabled: bool) -> void:
	visible = enabled
