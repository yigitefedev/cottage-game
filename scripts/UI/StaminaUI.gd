class_name StaminaUI
extends Control

@onready var stamina_bar: ProgressBar = $StaminaBar
@onready var stamina_label: Label = $StaminaLabel

var player_stamina: PlayerStamina


func _ready() -> void:
	player_stamina = get_tree().get_first_node_in_group("player_stamina")

	if player_stamina == null:
		push_warning("StaminaUI: PlayerStamina bulunamadı.")
		return

	player_stamina.stamina_changed.connect(update_stamina)
	update_stamina(player_stamina.current_stamina, player_stamina.max_stamina)


func update_stamina(current: int, maximum: int) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current

	stamina_label.text = "%s / %s" % [current, maximum]
