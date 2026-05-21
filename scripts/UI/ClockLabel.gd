extends Label

func _ready() -> void:
	TimeManager.time_tick.connect(update_text)
	update_text(TimeManager.current_day, TimeManager.current_hour, TimeManager.current_minute)


func update_text(day: int, hour: int, minute: int) -> void:
	text = "Day %d  %02d:%02d" % [day, hour, minute]
