class_name PlayerStamina
extends Node

@export var base_max_stamina := 100

var max_stamina := 100
var current_stamina := 100

signal stamina_changed(current: int, maximum: int)


func _ready() -> void:
	add_to_group("player_stamina")
	recalculate_max_stamina()
	current_stamina = max_stamina
	stamina_changed.emit(current_stamina, max_stamina)


func recalculate_max_stamina() -> void:
	max_stamina = base_max_stamina


func can_spend(amount: int) -> bool:
	return current_stamina >= amount


func spend(amount: int) -> bool:
	if amount <= 0:
		return true

	if not can_spend(amount):
		return false

	current_stamina -= amount
	stamina_changed.emit(current_stamina, max_stamina)
	return true


func refill() -> void:
	recalculate_max_stamina()
	current_stamina = max_stamina
	stamina_changed.emit(current_stamina, max_stamina)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_refill_stamina"):
		refill()
