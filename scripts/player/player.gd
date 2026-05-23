extends CharacterBody3D

@export var move_speed := 5.0
@export var acceleration := 10.0
@export var friction := 14.0
@export var rotation_speed := 10.0
@export var gravity := 20.0

func _ready() -> void:
	add_to_group("player")
	
func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var input_vector := Vector2.ZERO

	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")

	input_vector = input_vector.normalized()

	var move_direction := Vector3(
		input_vector.x,
		0,
		input_vector.y
	)

	if move_direction != Vector3.ZERO:

		velocity.x = move_toward(velocity.x, move_direction.x * move_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, move_direction.z * move_speed, acceleration * delta)

		var target_rotation := atan2(move_direction.x, move_direction.z)

		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)

	else:

		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

	move_and_slide()
