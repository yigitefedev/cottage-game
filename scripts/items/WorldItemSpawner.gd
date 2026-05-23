class_name WorldItemSpawner
extends Node3D

@export var dropped_item_scene: PackedScene

func _ready() -> void:
	add_to_group("world_item_spawner")


func spawn_item(item: ItemInstanceData, position: Vector3, scatter_strength := 3.5) -> DroppedItem:
	if dropped_item_scene == null:
		return null

	var dropped := dropped_item_scene.instantiate() as DroppedItem
	add_child(dropped)

	dropped.global_position = position

	var random_dir := Vector3(
		randf_range(-1.0, 1.0),
		0.0,
		randf_range(-1.0, 1.0)
	).normalized()

	var velocity := Vector3(
		random_dir.x * randf_range(0.7, scatter_strength),
		randf_range(1.5, 2.8),
		random_dir.z * randf_range(0.7, scatter_strength)
	)

	dropped.setup(item, velocity)

	return dropped


func spawn_item_stack(definition: ItemDefinition, amount: int, position: Vector3) -> void:
	if definition == null or amount <= 0:
		return

	var item := ItemInstanceData.new()
	item.definition = definition
	item.amount = amount

	spawn_item(item, position)
