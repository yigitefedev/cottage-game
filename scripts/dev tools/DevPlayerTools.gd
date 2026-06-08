class_name DevPlayerTools
extends Node

@export var tool_enabled := false

var player_stamina: PlayerStamina


func _ready() -> void:
	add_to_group("dev_player_tools")

	await get_tree().process_frame

	player_stamina = get_tree().get_first_node_in_group("player_stamina")


func refill_stamina() -> void:
	if not tool_enabled:
		return

	if player_stamina == null:
		player_stamina = get_tree().get_first_node_in_group("player_stamina")

	if player_stamina == null:
		return

	player_stamina.refill()
