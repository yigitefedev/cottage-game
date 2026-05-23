class_name DroppedItem
extends Node3D

@export var gravity := 14.0
@export var pickup_delay := 0.5
@export var magnet_range := 2.0
@export var collect_range := 0.35
@export var magnet_speed := 6.0
@export var sprite_scale := 0.45
@export var ground_offset := 1.0

@onready var icon_sprite: Sprite3D = $IconSprite

var item_instance: ItemInstanceData
var player: Node3D
var player_inventory: PlayerInventory

var velocity := Vector3.ZERO
var age := 0.0
var can_pickup := false


func setup(item: ItemInstanceData, start_velocity: Vector3 = Vector3.ZERO) -> void:
	item_instance = item
	velocity = start_velocity

	if icon_sprite != null and item_instance != null and item_instance.definition != null:
		icon_sprite.texture = item_instance.definition.icon
		icon_sprite.scale = Vector3.ONE * sprite_scale
	

func _ready() -> void:
	await get_tree().process_frame

	player_inventory = get_tree().get_first_node_in_group("player_inventory")
	player = get_tree().get_first_node_in_group("player") as Node3D


func _physics_process(delta: float) -> void:
	age += delta

	if age >= pickup_delay:
		can_pickup = true

	apply_scatter_motion(delta)

	if can_pickup:
		try_magnet_pickup(delta)


func apply_scatter_motion(delta: float) -> void:
	velocity.y -= gravity * delta

	global_position += velocity * delta

	if global_position.y <= ground_offset:
		global_position.y = ground_offset

		velocity.y = 0

		velocity.x = move_toward(velocity.x, 0.0, 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 4.0 * delta)


func try_magnet_pickup(delta: float) -> void:
	if player == null or player_inventory == null:
		return

	if not can_fit_in_inventory():
		return

	var item_pos := global_position
	var player_pos := player.global_position

	item_pos.y = 0
	player_pos.y = 0

	var distance := item_pos.distance_to(player_pos)

	if distance > magnet_range:
		return

	var pickup_target := player.global_position + Vector3.UP * ground_offset
	var direction := (pickup_target - global_position).normalized()

	global_position += direction * magnet_speed * delta

	if distance <= collect_range:
		collect()

func can_fit_in_inventory() -> bool:
	if item_instance == null or player_inventory == null or player_inventory.inventory == null:
		return false

	for slot_item in player_inventory.inventory.slots:
		if slot_item == null:
			return true

		if slot_item.is_stackable_with(item_instance):
			if slot_item.amount < slot_item.definition.max_stack:
				return true

	return false
	
func collect() -> void:
	var remaining := player_inventory.add_item(item_instance)

	if remaining == null:
		queue_free()
	else:
		item_instance = remaining
